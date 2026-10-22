#include "appservices.h"

AppServices::AppServices(QObject *parent) : QObject(parent) {
  const QString requestedMode =
      qEnvironmentVariable("IBE_DATA_PROVIDER", "mock").trimmed().toLower();
  if (requestedMode == QStringLiteral("http"))
    m_provider = new HttpDataProvider(this);
  else if (requestedMode == QStringLiteral("mock"))
    m_provider = new MockDataProvider(this);
  else
    qFatal("Unsupported IBE_DATA_PROVIDER value: %s",
           qPrintable(requestedMode));

  m_auth = new AuthService(m_provider, this);
  m_assets = new AssetService(m_provider, this);
  m_risks = new RiskService(m_provider, this);
  m_measures = new MeasureService(m_provider, this);
  m_dashboard = new DashboardService(m_provider, this);
  m_economics = new EconomicsService(m_provider, this);

  connect(m_assets, &AssetService::industrialModeChanged, this,
          [this] {
            m_economics->setIndustrialMode(m_assets->industrialMode());
          });

  connect(m_economics, &ServiceBase::operationFinished, this,
          [this](const QString &, const QString &operation, bool success,
                 const QVariant &data, const QString &) {
            if (success && operation == QStringLiteral("economics.get"))
              m_risks->syncCollections(data.toMap());
          });

  const auto refreshEconomics =
      [this](const QString &, const QString &operation, bool success,
             const QVariant &, const QString &) {
        if (!success || operation.endsWith(QStringLiteral(".list")))
          return;
        if (operation.startsWith(QStringLiteral("assets.")) ||
            operation.startsWith(QStringLiteral("risks.")) ||
            operation.startsWith(QStringLiteral("measures."))) {
          m_economics->refresh();
        }
      };
  connect(m_assets, &ServiceBase::operationFinished, this, refreshEconomics);
  connect(m_risks, &ServiceBase::operationFinished, this, refreshEconomics);
  connect(m_measures, &ServiceBase::operationFinished, this, refreshEconomics);

  connect(m_risks, &ServiceBase::operationFinished, this,
          [this](const QString &, const QString &, bool success,
                 const QVariant &data, const QString &) {
            if (success)
              m_measures->syncCollections(data.toMap());
          });
  connect(m_measures, &ServiceBase::operationFinished, this,
          [this](const QString &, const QString &, bool success,
                 const QVariant &data, const QString &) {
            if (success)
              m_risks->syncCollections(data.toMap());
          });
}

QString AppServices::providerMode() const { return m_provider->modeName(); }

AuthService *AppServices::auth() const { return m_auth; }

AssetService *AppServices::assets() const { return m_assets; }

RiskService *AppServices::risks() const { return m_risks; }

MeasureService *AppServices::measures() const { return m_measures; }

DashboardService *AppServices::dashboard() const { return m_dashboard; }

EconomicsService *AppServices::economics() const { return m_economics; }
