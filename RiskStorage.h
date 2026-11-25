#pragma once

#include <QHash>
#include <QSqlDatabase>
#include <QSqlError>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class RiskStorage {
public:
  enum class Entity { Asset, Vulnerability, Measure };

  RiskStorage() = default;
  ~RiskStorage();
  RiskStorage(const RiskStorage &) = delete;
  RiskStorage &operator=(const RiskStorage &) = delete;

  // <AppDataLocation>/userdata.sqlite
  static QString defaultPath();

  // path = ":memory:" - база в памяти (для тестов).
  bool open(const QString &path);
  void close();
  bool isOpen() const;
  QString path() const { return m_path; }
  QString lastError() const { return m_lastError; }

  // Для Asset в карту добавляются списки "measures" и "vulns" (QStringList id).
  QVariantList load(Entity entity);

  // Вставка или обновление по ключу "id".
  // Для Asset, если в карте есть ключи "measures" / "vulns", связи
  // перезаписываются; id несуществующих мер/уязвимостей пропускаются.
  bool save(Entity entity, const QVariantMap &data);

  // Удаляет сущность и все её связи.
  bool remove(Entity entity, const QString &id);

  // Удаляет все данные пользователя.
  bool clearAll();

private:
  QSqlDatabase db() const;
  bool migrate();
  QHash<QString, QStringList> loadLinks(const QString &table,
                                        const QString &otherColumn);
  bool fail(const QString &context, const QSqlError &error);
  bool failMsg(const QString &message);
  void dropConnection();

  QString m_connection;
  QString m_path;
  QString m_lastError;
};