#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QSqlDatabase>

class BduDatabase : public QObject {
  Q_OBJECT

public:
  explicit BduDatabase(QObject *parent = nullptr);
  ~BduDatabase();

  bool init(const QString &dbPath = QString());
  bool isAvailable() const { return m_available; }
  int totalCount() const { return m_totalCount; }
  QString databasePath() const { return m_dbPath; }

  QVariantList search(const QString &query, int severityFilter = 0, int limit = 50,
                      int sortOrder = 0, bool exploitOnly = false,
                      bool fixOnly = false);
  QVariantMap getVulnerability(const QString &bduId);

private:
  static QString findDatabaseFile();
  QSqlDatabase getDatabase();

  bool m_available = false;
  int m_totalCount = 0;
  QString m_dbPath;
  QString m_connectionName;
};
