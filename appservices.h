#pragma once

#include <QHash>
#include <QObject>
#include <QSet>
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
};

class HttpDataProvider final : public DataProvider {
  Q_OBJECT
public:
  explicit HttpDataProvider(QObject *parent = nullptr);

  QString modeName() const override;
  void request(const QString &requestId, const QString &operation,
               const QVariantMap &payload) override;
};

class ServiceBase : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
  Q_PROPERTY(QString error READ error NOTIFY errorChanged)
  Q_PROPERTY(QString providerMode READ providerMode CONSTANT)

public:
  explicit ServiceBase(DataProvider *provider, QObject *parent = nullptr);

  bool loading() const;
  QString error() const;
  QString providerMode() const;

signals:
  void loadingChanged();
  void errorChanged();
  void operationFinished(const QString &requestId, const QString &operation,
                         bool success, const QVariant &data,
                         const QString &error);

protected:
  QString sendRequest(const QString &operation,
                      const QVariantMap &payload = {});

private slots:
  void handleRequestFinished(const QString &requestId, const QString &operation,
                             bool success, const QVariant &data,
                             const QString &error);

private:
  DataProvider *m_provider;
  QSet<QString> m_pendingRequests;
  QString m_error;
};

class AuthService final : public ServiceBase {
  Q_OBJECT
  Q_PROPERTY(bool authenticated READ authenticated NOTIFY authenticatedChanged)
  Q_PROPERTY(QVariantMap user READ user NOTIFY userChanged)

public:
  explicit AuthService(DataProvider *provider, QObject *parent = nullptr);

  bool authenticated() const;
  QVariantMap user() const;

  Q_INVOKABLE QString login(const QString &login, const QString &password);
  Q_INVOKABLE QString registerUser(const QVariantMap &user);
  Q_INVOKABLE QString logout();

signals:
  void authenticatedChanged();
  void userChanged();

private:
  QVariantMap m_user;
  bool m_authenticated = false;
};

class EntityService : public ServiceBase {
  Q_OBJECT
  Q_PROPERTY(QVariantList items READ items NOTIFY itemsChanged)

public:
  QVariantList items() const;

  Q_INVOKABLE QString load();
  Q_INVOKABLE QString create(const QVariantMap &entity);
  Q_INVOKABLE QString update(const QString &id, const QVariantMap &entity);
  Q_INVOKABLE QString remove(const QString &id);

signals:
  void itemsChanged();

protected:
  EntityService(DataProvider *provider, QString entityName,
                QObject *parent = nullptr);

private:
  QString m_entityName;
  QVariantList m_items;
};

class AssetService final : public EntityService {
  Q_OBJECT
public:
  explicit AssetService(DataProvider *provider, QObject *parent = nullptr);
};

class RiskService final : public EntityService {
  Q_OBJECT
public:
  explicit RiskService(DataProvider *provider, QObject *parent = nullptr);

  Q_INVOKABLE QString importScenario(const QString &scenarioCode,
                                     const QString &assetId);
  Q_INVOKABLE QString bindMeasure(const QString &riskId,
                                  const QString &measureId);
  Q_INVOKABLE QString unbindMeasure(const QString &riskId);
};

class MeasureService final : public EntityService {
  Q_OBJECT
public:
  explicit MeasureService(DataProvider *provider, QObject *parent = nullptr);
};

class DashboardService final : public ServiceBase {
  Q_OBJECT
  Q_PROPERTY(QVariantMap summary READ summary NOTIFY summaryChanged)

public:
  explicit DashboardService(DataProvider *provider, QObject *parent = nullptr);

  QVariantMap summary() const;
  Q_INVOKABLE QString refresh();

signals:
  void summaryChanged();

private:
  QVariantMap m_summary;
};

class AppServices final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString providerMode READ providerMode CONSTANT)
  Q_PROPERTY(AuthService *auth READ auth CONSTANT)
  Q_PROPERTY(AssetService *assets READ assets CONSTANT)
  Q_PROPERTY(RiskService *risks READ risks CONSTANT)
  Q_PROPERTY(MeasureService *measures READ measures CONSTANT)
  Q_PROPERTY(DashboardService *dashboard READ dashboard CONSTANT)

public:
  explicit AppServices(QObject *parent = nullptr);

  QString providerMode() const;
  AuthService *auth() const;
  AssetService *assets() const;
  RiskService *risks() const;
  MeasureService *measures() const;
  DashboardService *dashboard() const;

private:
  DataProvider *m_provider;
  AuthService *m_auth;
  AssetService *m_assets;
  RiskService *m_risks;
  MeasureService *m_measures;
  DashboardService *m_dashboard;
};
