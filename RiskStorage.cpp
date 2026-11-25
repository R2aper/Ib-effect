#include "RiskStorage.h"

#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QUuid>
#include <QVector>

namespace {

constexpr int kSchemaVersion = 1;

// ---------------------------- Описание таблиц ----------------------------

enum class Kind { Text, Int, Real, Bool };

struct Field {
  const char *key;    // ключ в QVariantMap (то, что видит QML)
  const char *column; // колонка в SQLite
  Kind kind;
};

struct EntitySpec {
  const char *table;
  QVector<Field> fields;   // fields[0] - всегда id
  QSet<QString> transient; // ключи, которые не сохраняются в extra
};

const EntitySpec &specFor(RiskStorage::Entity e) {
  static const EntitySpec asset{
      "assets",
      {{"id", "id", Kind::Text},
       {"primaryAssetName", "primary_name", Kind::Text},
       {"supportingAssetName", "supporting_name", Kind::Text},
       {"directRecoveryCost", "direct_recovery_cost", Kind::Real},
       {"indirectBusinessLoss", "indirect_business_loss", Kind::Real},
       {"regime98FZCompliant", "regime_98fz", Kind::Bool},
       {"componentType", "component_type", Kind::Int},
       {"share", "share", Kind::Int},
       {"perimeter", "perimeter", Kind::Int}},
      // связи хранятся в отдельных таблицах
      {QStringLiteral("measures"), QStringLiteral("vulns")}};

  static const EntitySpec vuln{"vulnerabilities",
                               {{"id", "id", Kind::Text},
                                {"title", "title", Kind::Text},
                                {"cve", "cve", Kind::Text},
                                {"desc", "description", Kind::Text},
                                {"cvss", "cvss", Kind::Real},
                                {"vector", "cvss_vector", Kind::Text},
                                {"exploitability", "exploitability", Kind::Int},
                                {"consequence", "consequence", Kind::Int},
                                {"status", "status", Kind::Text},
                                {"fromBdu", "from_bdu", Kind::Bool}},
                               {}};

  static const EntitySpec measure{
      "measures",
      {{"id", "id", Kind::Text},
       {"title", "title", Kind::Text},
       {"targetVuln", "target_vuln_id", Kind::Text},
       {"asset", "asset_id", Kind::Text},
       {"measureType", "measure_type", Kind::Text},
       {"fstecClass", "fstec_class", Kind::Text},
       {"costTCO", "cost_tco", Kind::Real},
       {"affectsShare", "affects_share", Kind::Bool},
       {"newShare", "new_share", Kind::Int},
       {"affectsPerimeter", "affects_perimeter", Kind::Bool},
       {"newPerimeter", "new_perimeter", Kind::Int},
       {"status", "status", Kind::Text}},
      // вычисляемые поля, их заполняет RiskCalculator::updateEconomicScenarios
      {QStringLiteral("tco"), QStringLiteral("tcoNum"), QStringLiteral("vBase"),
       QStringLiteral("vRes"), QStringLiteral("levelOld"),
       QStringLiteral("levelNew"), QStringLiteral("deltaV"),
       QStringLiteral("deltaAle"), QStringLiteral("netBenefit"),
       QStringLiteral("rosi"), QStringLiteral("iInfrOld"),
       QStringLiteral("iInfrNew"), QStringLiteral("oldShare"),
       QStringLiteral("oldPerimeter")}};

  switch (e) {
  case RiskStorage::Entity::Asset:
    return asset;
  case RiskStorage::Entity::Vulnerability:
    return vuln;
  case RiskStorage::Entity::Measure:
    return measure;
  }
  return asset;
}

// ---------------------------- Преобразования ----------------------------

QVariant toSql(const QVariantMap &m, const Field &f) {
  const QVariant v = m.value(QLatin1String(f.key));
  switch (f.kind) {
  case Kind::Text:
    return v.toString();
  case Kind::Int:
    return v.toLongLong();
  case Kind::Real:
    return v.toDouble();
  case Kind::Bool:
    return v.toBool() ? 1 : 0;
  }
  return {};
}

QVariant fromSql(const QVariant &v, Kind kind) {
  switch (kind) {
  case Kind::Text:
    return v.toString();
  case Kind::Int:
    return v.toInt();
  case Kind::Real:
    return v.toDouble();
  case Kind::Bool:
    return v.toInt() != 0;
  }
  return {};
}

QString extraJson(const EntitySpec &spec, const QVariantMap &map) {
  QSet<QString> known = spec.transient;
  for (const Field &f : spec.fields)
    known.insert(QLatin1String(f.key));

  QVariantMap extra;
  for (auto it = map.cbegin(); it != map.cend(); ++it) {
    if (!known.contains(it.key()))
      extra.insert(it.key(), it.value());
  }
  return QString::fromUtf8(QJsonDocument(QJsonObject::fromVariantMap(extra))
                               .toJson(QJsonDocument::Compact));
}

QString createTableSql(const EntitySpec &spec) {
  QStringList cols;
  for (int i = 0; i < spec.fields.size(); ++i) {
    const Field &f = spec.fields[i];
    QString def = QLatin1String(f.column) + QLatin1Char(' ');
    if (i == 0) {
      def += QStringLiteral("TEXT PRIMARY KEY NOT NULL");
    } else {
      switch (f.kind) {
      case Kind::Text:
        def += QStringLiteral("TEXT NOT NULL DEFAULT ''");
        break;
      case Kind::Int:
      case Kind::Bool:
        def += QStringLiteral("INTEGER NOT NULL DEFAULT 0");
        break;
      case Kind::Real:
        def += QStringLiteral("REAL NOT NULL DEFAULT 0");
        break;
      }
    }
    cols << def;
  }
  cols << QStringLiteral("extra TEXT NOT NULL DEFAULT '{}'")
       << QStringLiteral("created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP")
       << QStringLiteral("updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP");
  return QStringLiteral("CREATE TABLE IF NOT EXISTS %1 (%2)")
      .arg(QLatin1String(spec.table), cols.join(QStringLiteral(", ")));
}

// Транзакция с автоматическим откатом, если commit() не был вызван.
class Transaction {
public:
  explicit Transaction(QSqlDatabase db)
      : m_db(db), m_active(db.transaction()) {}
  ~Transaction() {
    if (m_active)
      m_db.rollback();
  }
  Transaction(const Transaction &) = delete;
  Transaction &operator=(const Transaction &) = delete;

  bool active() const { return m_active; }
  bool commit() {
    if (!m_active)
      return false;
    m_active = false;
    return m_db.commit();
  }

private:
  QSqlDatabase m_db;
  bool m_active;
};

const QString kAssetMeasures = QStringLiteral("asset_measures");
const QString kAssetVulns = QStringLiteral("asset_vulnerabilities");

} // namespace

// ---------------------------- Жизненный цикл ----------------------------

RiskStorage::~RiskStorage() { close(); }

QString RiskStorage::defaultPath() {
  QString base =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  if (base.isEmpty())
    base = QDir::homePath() + QStringLiteral("/.risk-calculator");
  return QDir(base).filePath(QStringLiteral("userdata.sqlite"));
}

QSqlDatabase RiskStorage::db() const {
  return QSqlDatabase::database(m_connection, false);
}

bool RiskStorage::isOpen() const {
  return !m_connection.isEmpty() && db().isOpen();
}

bool RiskStorage::fail(const QString &context, const QSqlError &error) {
  m_lastError = QStringLiteral("%1: %2").arg(context, error.text());
  qWarning().noquote() << "[RiskStorage]" << m_lastError;
  return false;
}

bool RiskStorage::failMsg(const QString &message) {
  m_lastError = message;
  qWarning().noquote() << "[RiskStorage]" << m_lastError;
  return false;
}

void RiskStorage::dropConnection() {
  if (m_connection.isEmpty())
    return;
  {
    QSqlDatabase d = QSqlDatabase::database(m_connection, false);
    if (d.isValid() && d.isOpen())
      d.close();
  } // d должен выйти из области видимости до removeDatabase
  QSqlDatabase::removeDatabase(m_connection);
  m_connection.clear();
}

void RiskStorage::close() {
  dropConnection();
  m_path.clear();
}

bool RiskStorage::open(const QString &path) {
  close();

  if (path != QLatin1String(":memory:"))
    QDir().mkpath(QFileInfo(path).absolutePath());

  m_connection = QStringLiteral("risk_storage_%1")
                     .arg(QUuid::createUuid().toString(QUuid::WithoutBraces));

  bool ok = false;
  {
    QSqlDatabase d =
        QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connection);
    d.setDatabaseName(path);
    if (!d.open()) {
      fail(QStringLiteral("open %1").arg(path), d.lastError());
    } else {
      QSqlQuery q(d);
      ok = q.exec(QStringLiteral("PRAGMA foreign_keys = ON"));
      if (!ok)
        fail(QStringLiteral("pragma foreign_keys"), q.lastError());
      q.exec(QStringLiteral("PRAGMA journal_mode = WAL"));
      q.exec(QStringLiteral("PRAGMA synchronous = NORMAL"));
    }
  }
  if (!ok) {
    dropConnection();
    return false;
  }

  m_path = path;
  if (!migrate()) {
    close();
    return false;
  }
  return true;
}

// ---------------------------- Схема и миграции ----------------------------

bool RiskStorage::migrate() {
  QSqlDatabase d = db();
  QSqlQuery q(d);

  if (!q.exec(QStringLiteral("PRAGMA user_version")) || !q.next())
    return fail(QStringLiteral("read user_version"), q.lastError());
  const int version = q.value(0).toInt();
  q.finish();

  if (version > kSchemaVersion)
    return failMsg(
        QStringLiteral(
            "База данных создана более новой версией приложения (schema v%1)")
            .arg(version));
  if (version == kSchemaVersion)
    return true;

  Transaction tx(d);
  if (!tx.active())
    return fail(QStringLiteral("begin migration"), d.lastError());

  const auto run = [&](const QString &sql) {
    if (!q.exec(sql))
      return fail(QStringLiteral("migration: %1").arg(sql), q.lastError());
    return true;
  };

  if (version < 1) {
    const bool ok =
        run(createTableSql(specFor(Entity::Asset))) &&
        run(createTableSql(specFor(Entity::Vulnerability))) &&
        run(createTableSql(specFor(Entity::Measure))) &&
        run(QStringLiteral("CREATE TABLE IF NOT EXISTS asset_measures ("
                           " asset_id TEXT NOT NULL REFERENCES assets(id)"
                           "   ON DELETE CASCADE ON UPDATE CASCADE,"
                           " measure_id TEXT NOT NULL REFERENCES measures(id)"
                           "   ON DELETE CASCADE ON UPDATE CASCADE,"
                           " PRIMARY KEY (asset_id, measure_id))")) &&
        run(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS asset_vulnerabilities ("
            " asset_id TEXT NOT NULL REFERENCES assets(id)"
            "   ON DELETE CASCADE ON UPDATE CASCADE,"
            " vulnerability_id TEXT NOT NULL REFERENCES vulnerabilities(id)"
            "   ON DELETE CASCADE ON UPDATE CASCADE,"
            " PRIMARY KEY (asset_id, vulnerability_id))")) &&
        run(QStringLiteral(
            "CREATE INDEX IF NOT EXISTS idx_asset_measures_measure"
            " ON asset_measures(measure_id)")) &&
        run(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_asset_vulns_vuln"
                           " ON asset_vulnerabilities(vulnerability_id)"));
    if (!ok)
      return false;
  }
  // if (version < 2) { ... ALTER TABLE ... }  <- будущие миграции сюда

  if (!run(QStringLiteral("PRAGMA user_version = %1").arg(kSchemaVersion)))
    return false;
  if (!tx.commit())
    return fail(QStringLiteral("commit migration"), d.lastError());
  return true;
}

// ---------------------------- Чтение ----------------------------

QHash<QString, QStringList> RiskStorage::loadLinks(const QString &table,
                                                   const QString &otherColumn) {
  QHash<QString, QStringList> result;
  QSqlQuery q(db());
  if (!q.exec(QStringLiteral("SELECT asset_id, %1 FROM %2 ORDER BY rowid")
                  .arg(otherColumn, table))) {
    fail(QStringLiteral("load links %1").arg(table), q.lastError());
    return result;
  }
  while (q.next())
    result[q.value(0).toString()].append(q.value(1).toString());
  return result;
}

QVariantList RiskStorage::load(Entity entity) {
  QVariantList list;
  if (!isOpen()) {
    failMsg(QStringLiteral("storage is not open"));
    return list;
  }

  const EntitySpec &spec = specFor(entity);
  QStringList cols;
  for (const Field &f : spec.fields)
    cols << QLatin1String(f.column);
  cols << QStringLiteral("extra");

  QSqlQuery q(db());
  if (!q.exec(QStringLiteral("SELECT %1 FROM %2 ORDER BY rowid")
                  .arg(cols.join(QStringLiteral(", ")),
                       QLatin1String(spec.table)))) {
    fail(QStringLiteral("load %1").arg(QLatin1String(spec.table)),
         q.lastError());
    return list;
  }

  const int extraCol = spec.fields.size();
  while (q.next()) {
    QVariantMap m =
        QJsonDocument::fromJson(q.value(extraCol).toString().toUtf8())
            .object()
            .toVariantMap();
    for (int i = 0; i < spec.fields.size(); ++i)
      m.insert(QLatin1String(spec.fields[i].key),
               fromSql(q.value(i), spec.fields[i].kind));
    list.append(m);
  }

  if (entity == Entity::Asset) {
    const auto measures =
        loadLinks(kAssetMeasures, QStringLiteral("measure_id"));
    const auto vulns =
        loadLinks(kAssetVulns, QStringLiteral("vulnerability_id"));
    for (int i = 0; i < list.size(); ++i) {
      QVariantMap a = list[i].toMap();
      const QString id = a.value(QStringLiteral("id")).toString();
      a.insert(QStringLiteral("measures"),
               QVariant::fromValue(measures.value(id)));
      a.insert(QStringLiteral("vulns"), QVariant::fromValue(vulns.value(id)));
      list[i] = a;
    }
  }
  return list;
}

// ---------------------------- Запись ----------------------------

bool RiskStorage::save(Entity entity, const QVariantMap &data) {
  if (!isOpen())
    return failMsg(QStringLiteral("storage is not open"));

  const QString id = data.value(QStringLiteral("id")).toString();
  if (id.isEmpty())
    return failMsg(QStringLiteral("save: пустой id"));

  // У меры стоимость может прийти как tcoNum (формат старого кода UI)
  QVariantMap map = data;
  if (entity == Entity::Measure && !map.contains(QStringLiteral("costTCO")) &&
      map.contains(QStringLiteral("tcoNum")))
    map.insert(QStringLiteral("costTCO"), map.value(QStringLiteral("tcoNum")));

  const EntitySpec &spec = specFor(entity);
  QSqlDatabase d = db();

  Transaction tx(d);
  if (!tx.active())
    return fail(QStringLiteral("begin"), d.lastError());

  // --- upsert основной строки ---
  QStringList cols, placeholders, updates;
  QVariantList values;
  for (int i = 0; i < spec.fields.size(); ++i) {
    const Field &f = spec.fields[i];
    cols << QLatin1String(f.column);
    placeholders << QStringLiteral("?");
    values << toSql(map, f);
    if (i > 0)
      updates
          << QStringLiteral("%1 = excluded.%1").arg(QLatin1String(f.column));
  }
  cols << QStringLiteral("extra");
  placeholders << QStringLiteral("?");
  values << extraJson(spec, map);
  updates << QStringLiteral("extra = excluded.extra")
          << QStringLiteral("updated_at = CURRENT_TIMESTAMP");

  QSqlQuery q(d);
  q.prepare(QStringLiteral("INSERT INTO %1 (%2) VALUES (%3) "
                           "ON CONFLICT(id) DO UPDATE SET %4")
                .arg(QLatin1String(spec.table), cols.join(QStringLiteral(", ")),
                     placeholders.join(QStringLiteral(", ")),
                     updates.join(QStringLiteral(", "))));
  for (const QVariant &v : values)
    q.addBindValue(v);
  if (!q.exec())
    return fail(
        QStringLiteral("save %1 '%2'").arg(QLatin1String(spec.table), id),
        q.lastError());

  // --- связи актива ---
  if (entity == Entity::Asset) {
    const auto replaceLinks = [&](const QString &linkTable,
                                  const QString &otherColumn,
                                  const QString &otherTable,
                                  const QString &mapKey) {
      if (!map.contains(mapKey))
        return true; // ключ не передан - связи не трогаем

      QSqlQuery del(d);
      del.prepare(
          QStringLiteral("DELETE FROM %1 WHERE asset_id = ?").arg(linkTable));
      del.addBindValue(id);
      if (!del.exec())
        return fail(QStringLiteral("clear links %1").arg(linkTable),
                    del.lastError());

      // INSERT ... SELECT вставит строку, только если мера/уязвимость
      // реально существует, поэтому нарушения внешнего ключа невозможны.
      QSqlQuery ins(d);
      ins.prepare(QStringLiteral("INSERT OR IGNORE INTO %1 (asset_id, %2) "
                                 "SELECT ?, id FROM %3 WHERE id = ?")
                      .arg(linkTable, otherColumn, otherTable));
      const QStringList ids = map.value(mapKey).toStringList();
      for (const QString &otherId : ids) {
        ins.addBindValue(id);
        ins.addBindValue(otherId);
        if (!ins.exec())
          return fail(QStringLiteral("insert link %1").arg(linkTable),
                      ins.lastError());
      }
      return true;
    };

    if (!replaceLinks(kAssetMeasures, QStringLiteral("measure_id"),
                      QStringLiteral("measures"), QStringLiteral("measures")) ||
        !replaceLinks(kAssetVulns, QStringLiteral("vulnerability_id"),
                      QStringLiteral("vulnerabilities"),
                      QStringLiteral("vulns")))
      return false;
  }

  if (!tx.commit())
    return fail(QStringLiteral("commit"), d.lastError());
  return true;
}

bool RiskStorage::remove(Entity entity, const QString &id) {
  if (!isOpen())
    return failMsg(QStringLiteral("storage is not open"));

  QSqlQuery q(db());
  q.prepare(QStringLiteral("DELETE FROM %1 WHERE id = ?")
                .arg(QLatin1String(specFor(entity).table)));
  q.addBindValue(id);
  if (!q.exec())
    return fail(QStringLiteral("remove '%1'").arg(id), q.lastError());
  return true; // связи удаляются каскадно
}

bool RiskStorage::clearAll() {
  if (!isOpen())
    return failMsg(QStringLiteral("storage is not open"));

  QSqlDatabase d = db();
  Transaction tx(d);
  if (!tx.active())
    return fail(QStringLiteral("begin"), d.lastError());

  QSqlQuery q(d);
  const QStringList tables = {
      kAssetMeasures, kAssetVulns, QStringLiteral("assets"),
      QStringLiteral("vulnerabilities"), QStringLiteral("measures")};
  for (const QString &t : tables) {
    if (!q.exec(QStringLiteral("DELETE FROM %1").arg(t)))
      return fail(QStringLiteral("clear %1").arg(t), q.lastError());
  }
  if (!tx.commit())
    return fail(QStringLiteral("commit"), d.lastError());
  return true;
}