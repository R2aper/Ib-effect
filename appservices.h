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
  void syncCollections(const QVariantMap &collections);

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
  Q_PROPERTY(bool industrialMode READ industrialMode NOTIFY industrialModeChanged)

public:
  explicit AssetService(DataProvider *provider, QObject *parent = nullptr);

  bool industrialMode() const;
  Q_INVOKABLE QString loadPreset(bool industrial);

signals:
  void industrialModeChanged();

private:
  bool m_industrialMode = false;
};

class RiskService final : public EntityService {
  Q_OBJECT
public:
  explicit RiskService(DataProvider *provider, QObject *parent = nullptr);

  Q_INVOKABLE QString importScenario(const QString &scenarioCode,
                                     const QString &assetId,
                                     const QVariantMap &scenario);
  Q_INVOKABLE QString bindMeasure(const QString &riskId,
                                  const QString &measureId);
  Q_INVOKABLE QString unbindMeasure(const QString &riskId);
};

class MeasureService final : public EntityService {
  Q_OBJECT
public:
  explicit MeasureService(DataProvider *provider, QObject *parent = nullptr);

  Q_INVOKABLE QString addIndustrialPreset();
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

class EconomicsService final : public ServiceBase {
  Q_OBJECT
  Q_PROPERTY(QVariantMap summary READ summary NOTIFY summaryChanged)
  Q_PROPERTY(int riskAppetite READ riskAppetite NOTIFY criteriaChanged)
  Q_PROPERTY(double pointCost READ pointCost NOTIFY criteriaChanged)
  Q_PROPERTY(double downtimeHourlyCost READ downtimeHourlyCost CONSTANT)
  Q_PROPERTY(int mttrHours READ mttrHours CONSTANT)

public:
  explicit EconomicsService(DataProvider *provider, QObject *parent = nullptr);

  QVariantMap summary() const;
  int riskAppetite() const;
  double pointCost() const;
  double downtimeHourlyCost() const;
  int mttrHours() const;

  Q_INVOKABLE QString refresh();
  Q_INVOKABLE void saveCriteria(int appetite, double cost);

signals:
  void summaryChanged();
  void criteriaChanged();

private:
  QVariantMap m_summary;
  int m_riskAppetite = 16;
  double m_pointCost = 250000;
  double m_downtimeHourlyCost = 1500000;
  int m_mttrHours = 8;
  bool m_industrialMode = false;

  void setIndustrialMode(bool industrial);
  friend class AppServices;
};

class AppServices final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString providerMode READ providerMode CONSTANT)
  Q_PROPERTY(AuthService *auth READ auth CONSTANT)
  Q_PROPERTY(AssetService *assets READ assets CONSTANT)
  Q_PROPERTY(RiskService *risks READ risks CONSTANT)
  Q_PROPERTY(MeasureService *measures READ measures CONSTANT)
  Q_PROPERTY(DashboardService *dashboard READ dashboard CONSTANT)
  Q_PROPERTY(EconomicsService *economics READ economics CONSTANT)

public:
  explicit AppServices(QObject *parent = nullptr);

  QString providerMode() const;
  AuthService *auth() const;
  AssetService *assets() const;
  RiskService *risks() const;
  MeasureService *measures() const;
  DashboardService *dashboard() const;
  EconomicsService *economics() const;

private:
  DataProvider *m_provider;
  AuthService *m_auth;
  AssetService *m_assets;
  RiskService *m_risks;
  MeasureService *m_measures;
  DashboardService *m_dashboard;
  EconomicsService *m_economics;
};
