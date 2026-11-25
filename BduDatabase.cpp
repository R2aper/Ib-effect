#include "BduDatabase.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRecord>
#include <QRegularExpression>
#include <QDebug>

BduDatabase::BduDatabase(QObject *parent)
    : QObject(parent),
      m_connectionName(QStringLiteral("bdu_db_conn")) {
  init();
}

BduDatabase::~BduDatabase() {
  if (QSqlDatabase::contains(m_connectionName)) {
    {
      QSqlDatabase db = QSqlDatabase::database(m_connectionName);
      if (db.isOpen()) {
        db.close();
      }
    }
    QSqlDatabase::removeDatabase(m_connectionName);
  }
}

QString BduDatabase::findDatabaseFile() {
  const QString appDir = QCoreApplication::applicationDirPath();
  const QString currentDir = QDir::currentPath();

  const QStringList candidates = {
      appDir + QStringLiteral("/bdu.sqlite"),
      currentDir + QStringLiteral("/bdu.sqlite"),
      QStringLiteral("C:/IBtoymat/bdu.sqlite"),
      QDir::cleanPath(appDir + QStringLiteral("/../bdu.sqlite")),
      QDir::cleanPath(appDir + QStringLiteral("/../../bdu.sqlite")),
      QDir::cleanPath(appDir + QStringLiteral("/../../../bdu.sqlite")),
      QStringLiteral("bdu.sqlite")
  };

  for (const QString &path : candidates) {
    QFileInfo fi(path);
    if (fi.exists() && fi.isFile() && fi.size() > 1024 * 1024) {
      return fi.absoluteFilePath();
    }
  }

  return QString();
}

bool BduDatabase::init(const QString &dbPath) {
  QString resolvedPath = dbPath;
  if (resolvedPath.isEmpty()) {
    resolvedPath = findDatabaseFile();
  }

  if (resolvedPath.isEmpty()) {
    qWarning() << "[BduDatabase] bdu.sqlite file not found in search paths.";
    m_available = false;
    return false;
  }

  m_dbPath = resolvedPath;

  if (QSqlDatabase::contains(m_connectionName)) {
    QSqlDatabase::removeDatabase(m_connectionName);
  }

  QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
  db.setConnectOptions(QStringLiteral("QSQLITE_OPEN_READONLY"));
  db.setDatabaseName(m_dbPath);

  if (!db.open()) {
    qWarning() << "[BduDatabase] Failed to open SQLite database:" << db.lastError().text();
    m_available = false;
    return false;
  }

  // Получаем общее количество уязвимостей
  QSqlQuery q(db);
  if (q.exec(QStringLiteral("SELECT COUNT(*) FROM vulnerabilities"))) {
    if (q.next()) {
      m_totalCount = q.value(0).toInt();
    }
  }

  m_available = true;
  qInfo() << "[BduDatabase] Successfully connected to" << m_dbPath << "with" << m_totalCount << "vulnerabilities.";
  return true;
}

QSqlDatabase BduDatabase::getDatabase() {
  if (QSqlDatabase::contains(m_connectionName)) {
    return QSqlDatabase::database(m_connectionName);
  }
  return QSqlDatabase();
}

static QString levelTextFromInt(int sevLevel) {
  switch (sevLevel) {
  case 4: return QStringLiteral("Критический");
  case 3: return QStringLiteral("Высокий");
  case 2: return QStringLiteral("Средний");
  case 1: return QStringLiteral("Низкий");
  default: return QStringLiteral("Средний");
  }
}

QVariantList BduDatabase::search(const QString &query, int severityFilter, int limit,
                                 int sortOrder, bool exploitOnly, bool fixOnly) {
  QVariantList results;
  if (!m_available) return results;

  QSqlDatabase db = getDatabase();
  if (!db.isOpen()) return results;

  const QString qTrimmed = query.trimmed();
  QSqlQuery q(db);
  const auto appendFilters = [severityFilter, exploitOnly, fixOnly](QString &sql) {
    if (severityFilter > 0) {
      sql += QStringLiteral("AND v.severity_level = :sev ");
    }
    if (exploitOnly) {
      sql += QStringLiteral("AND v.has_exploit > 0 ");
    }
    if (fixOnly) {
      sql += QStringLiteral("AND v.has_fix > 0 ");
    }
  };
  const auto orderClause = [sortOrder](const QString &defaultOrder) {
    switch (sortOrder) {
    case 1: return QStringLiteral("ORDER BY v.cvss_score DESC, v.id ASC ");
    case 2: return QStringLiteral("ORDER BY v.identify_year DESC, v.cvss_score DESC ");
    case 3: return QStringLiteral("ORDER BY v.id ASC ");
    default: return defaultOrder;
    }
  };
  const auto bindFilters = [&q, severityFilter](void) {
    if (severityFilter > 0) q.bindValue(QStringLiteral(":sev"), severityFilter);
  };

  auto parseRow = [](const QSqlQuery &queryObj) -> QVariantMap {
    QVariantMap item;
    const QString id = queryObj.value(0).toString();
    const QString name = queryObj.value(1).toString();
    const QString cves = queryObj.value(2).toString();
    const double cvss = queryObj.value(3).toDouble();
    const QString severity = queryObj.value(4).toString();
    const QString software = queryObj.value(5).toString();
    const QString vendor = queryObj.value(6).toString();
    const QString solution = queryObj.value(7).toString();
    const QString identifyDate = queryObj.value(8).toString();
    const QString cvssVector = queryObj.value(9).toString();
    const int severityLevel = queryObj.value(10).toInt();
    const bool hasExploit = queryObj.value(11).toInt() > 0;
    const bool hasFix = queryObj.value(12).toInt() > 0;
    const QString desc = queryObj.value(13).toString();

    item[QStringLiteral("id")] = id;
    item[QStringLiteral("title")] = name;
    item[QStringLiteral("name")] = name;
    item[QStringLiteral("cve")] = cves.isEmpty() ? QStringLiteral("—") : cves;
    item[QStringLiteral("cvss")] = cvss;
    item[QStringLiteral("cvssScore")] = cvss;
    item[QStringLiteral("cvssVector")] = cvssVector;
    item[QStringLiteral("severity")] = severity;
    item[QStringLiteral("severityLevel")] = severityLevel;
    item[QStringLiteral("level")] = levelTextFromInt(severityLevel);
    item[QStringLiteral("software")] = software;
    item[QStringLiteral("vendor")] = vendor;
    item[QStringLiteral("solution")] = solution;
    item[QStringLiteral("identifyDate")] = identifyDate;
    item[QStringLiteral("hasExploit")] = hasExploit;
    item[QStringLiteral("hasFix")] = hasFix;
    item[QStringLiteral("description")] = desc;
    item[QStringLiteral("desc")] = desc;
    item[QStringLiteral("fromBdu")] = true;

    return item;
  };

  if (qTrimmed.isEmpty()) {
    QString sql = QStringLiteral(
        "SELECT v.id, v.name, v.cves_joined, v.cvss_score, v.severity, v.software_names, "
        "       v.vendors, v.solution, v.identify_date, v.cvss_vector, v.severity_level, "
        "       v.has_exploit, v.has_fix, v.description "
        "FROM vulnerabilities v "
        "WHERE (1=1) ");
    appendFilters(sql);
    sql += orderClause(QStringLiteral("ORDER BY v.identify_year DESC, v.cvss_score DESC "));
    sql += QStringLiteral("LIMIT :lim");

    q.prepare(sql);
    bindFilters();
    q.bindValue(QStringLiteral(":lim"), limit);

    if (q.exec()) {
      while (q.next()) results.append(parseRow(q));
    }
    return results;
  }

  // 1. Поиск по прямому BDU:xxxx
  if (qTrimmed.startsWith(QStringLiteral("BDU:"), Qt::CaseInsensitive)) {
    QString sql = QStringLiteral(
        "SELECT v.id, v.name, v.cves_joined, v.cvss_score, v.severity, v.software_names, "
        "       v.vendors, v.solution, v.identify_date, v.cvss_vector, v.severity_level, "
        "       v.has_exploit, v.has_fix, v.description "
        "FROM vulnerabilities v "
        "WHERE v.id LIKE :idPat ");
    appendFilters(sql);
    sql += orderClause(QStringLiteral("ORDER BY v.cvss_score DESC "));
    sql += QStringLiteral("LIMIT :lim");

    q.prepare(sql);
    q.bindValue(QStringLiteral(":idPat"), qTrimmed.toUpper() + QStringLiteral("%"));
    bindFilters();
    q.bindValue(QStringLiteral(":lim"), limit);

    if (q.exec() && q.size() != 0) {
      while (q.next()) results.append(parseRow(q));
      if (!results.isEmpty()) return results;
    }
  }

  // 2. Поиск по CVE-xxxx
  if (qTrimmed.startsWith(QStringLiteral("CVE-"), Qt::CaseInsensitive)) {
    QString sql = QStringLiteral(
        "SELECT v.id, v.name, v.cves_joined, v.cvss_score, v.severity, v.software_names, "
        "       v.vendors, v.solution, v.identify_date, v.cvss_vector, v.severity_level, "
        "       v.has_exploit, v.has_fix, v.description "
        "FROM cves c "
        "JOIN vulnerabilities v ON v.id = c.bdu_id "
        "WHERE c.cve_id LIKE :cvePat ");
    appendFilters(sql);
    sql += orderClause(QStringLiteral("ORDER BY v.cvss_score DESC "));
    sql += QStringLiteral("LIMIT :lim");

    q.prepare(sql);
    q.bindValue(QStringLiteral(":cvePat"), qTrimmed.toUpper() + QStringLiteral("%"));
    bindFilters();
    q.bindValue(QStringLiteral(":lim"), limit);

    if (q.exec()) {
      while (q.next()) results.append(parseRow(q));
      if (!results.isEmpty()) return results;
    }
  }

  // 3. Полнотекстовый поиск FTS5
  QString cleanQ = qTrimmed;
  cleanQ.replace(QRegularExpression(QStringLiteral("[^a-zA-Z0-9а-яА-ЯёЁ_]")), QStringLiteral(" "));
  const QStringList tokens = cleanQ.split(QStringLiteral(" "), Qt::SkipEmptyParts);

  QStringList ftsTerms;
  for (const QString &tok : tokens) {
    if (tok.length() >= 2) {
      ftsTerms.append(QStringLiteral("\"") + tok + QStringLiteral("\"*"));
    }
  }

  if (!ftsTerms.isEmpty()) {
    const QString ftsExpr = ftsTerms.join(QStringLiteral(" AND "));
    QString sql = QStringLiteral(
        "SELECT v.id, v.name, v.cves_joined, v.cvss_score, v.severity, v.software_names, "
        "       v.vendors, v.solution, v.identify_date, v.cvss_vector, v.severity_level, "
        "       v.has_exploit, v.has_fix, v.description "
        "FROM vulnerabilities_fts f "
        "JOIN vulnerabilities v ON v.rowid = f.rowid "
        "WHERE vulnerabilities_fts MATCH :match ");
    appendFilters(sql);
    sql += orderClause(QStringLiteral("ORDER BY v.cvss_score DESC "));
    sql += QStringLiteral("LIMIT :lim");

    q.prepare(sql);
    q.bindValue(QStringLiteral(":match"), ftsExpr);
    bindFilters();
    q.bindValue(QStringLiteral(":lim"), limit);

    if (q.exec()) {
      while (q.next()) results.append(parseRow(q));
      if (!results.isEmpty()) return results;
    }
  }

  // 4. Резервный поиск LIKE
  {
    QString sql = QStringLiteral(
        "SELECT v.id, v.name, v.cves_joined, v.cvss_score, v.severity, v.software_names, "
        "       v.vendors, v.solution, v.identify_date, v.cvss_vector, v.severity_level, "
        "       v.has_exploit, v.has_fix, v.description "
        "FROM vulnerabilities v "
        "WHERE (v.name LIKE :p OR v.software_names LIKE :p OR v.vendors LIKE :p OR v.cves_joined LIKE :p OR v.id LIKE :p) ");
    appendFilters(sql);
    sql += orderClause(QStringLiteral("ORDER BY v.cvss_score DESC "));
    sql += QStringLiteral("LIMIT :lim");

    q.prepare(sql);
    const QString pat = QStringLiteral("%") + qTrimmed + QStringLiteral("%");
    q.bindValue(QStringLiteral(":p"), pat);
    bindFilters();
    q.bindValue(QStringLiteral(":lim"), limit);

    if (q.exec()) {
      while (q.next()) results.append(parseRow(q));
    }
  }

  return results;
}

QVariantMap BduDatabase::getVulnerability(const QString &bduId) {
  QVariantMap item;
  if (!m_available || bduId.trimmed().isEmpty()) return item;

  QSqlDatabase db = getDatabase();
  if (!db.isOpen()) return item;

  QSqlQuery q(db);
  q.prepare(QStringLiteral(
      "SELECT v.id, v.name, v.cves_joined, v.cvss_score, v.severity, v.software_names, "
      "       v.vendors, v.solution, v.identify_date, v.cvss_vector, v.severity_level, "
      "       v.has_exploit, v.has_fix, v.description "
      "FROM vulnerabilities v "
      "WHERE v.id = :id LIMIT 1"));
  q.bindValue(QStringLiteral(":id"), bduId.trimmed());

  if (q.exec() && q.next()) {
    item[QStringLiteral("id")] = q.value(0).toString();
    item[QStringLiteral("title")] = q.value(1).toString();
    item[QStringLiteral("name")] = q.value(1).toString();
    item[QStringLiteral("cve")] = q.value(2).toString();
    item[QStringLiteral("cvss")] = q.value(3).toDouble();
    item[QStringLiteral("cvssScore")] = q.value(3).toDouble();
    item[QStringLiteral("severity")] = q.value(4).toString();
    item[QStringLiteral("software")] = q.value(5).toString();
    item[QStringLiteral("vendor")] = q.value(6).toString();
    item[QStringLiteral("solution")] = q.value(7).toString();
    item[QStringLiteral("identifyDate")] = q.value(8).toString();
    item[QStringLiteral("cvssVector")] = q.value(9).toString();
    item[QStringLiteral("severityLevel")] = q.value(10).toInt();
    item[QStringLiteral("level")] = levelTextFromInt(q.value(10).toInt());
    item[QStringLiteral("hasExploit")] = q.value(11).toInt() > 0;
    item[QStringLiteral("hasFix")] = q.value(12).toInt() > 0;
    item[QStringLiteral("description")] = q.value(13).toString();
    item[QStringLiteral("desc")] = q.value(13).toString();
    item[QStringLiteral("fromBdu")] = true;
  }

  return item;
}
