#pragma once

#include <QHash>
#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class DataProvider : public QObject {
  Q_OBJECT
public:
  using QObject::QObject;

  virtual QString modeName() const = 0;
  virtual void request(const QString &requestId, const QString &operation,
                       const QVariantMap &payload) = 0;

signals:
  void requestFinished(const QString &requestId, const QString &operation,
                       bool success, const QVariant &data,
                       const QString &error);
};

class MockDataProvider final : public DataProvider {
  Q_OBJECT
public:
  explicit MockDataProvider(QObject *parent = nullptr);

  QString modeName() const override;
  void request(const QString &requestId, const QString &operation,
               const QVariantMap &payload) override;

private:
  QVariantMap m_user;
  bool m_authenticated = false;
  QHash<QString, QVariantList> m_collections;
  QHash<QString, QString> m_passwords;
  QHash<QString, QVariantMap> m_users;
};

class HttpDataProvider final : public DataProvider {
  Q_OBJECT
public:
  explicit HttpDataProvider(QObject *parent = nullptr);

  QString modeName() const override;
  void request(const QString &requestId, const QString &operation,
               const QVariantMap &payload) override;
};
