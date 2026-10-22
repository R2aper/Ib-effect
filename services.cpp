#include "services.h"

#include <QMetaType>
#include <QUuid>
#include <utility>

namespace {
QString newRequestId() {
  return QUuid::createUuid().toString(QUuid::WithoutBraces);
}
} // namespace

ServiceBase::ServiceBase(DataProvider *provider, QObject *parent)
    : QObject(parent), m_provider(provider) {
  connect(m_provider, &DataProvider::requestFinished, this,
          &ServiceBase::handleRequestFinished);
}

bool ServiceBase::loading() const { return !m_pendingRequests.isEmpty(); }

QString ServiceBase::error() const { return m_error; }

QString ServiceBase::providerMode() const { return m_provider->modeName(); }

QString ServiceBase::sendRequest(const QString &operation,
                                 const QVariantMap &payload) {
  const QString requestId = newRequestId();
  const bool wasLoading = loading();
  m_pendingRequests.insert(requestId);
  m_error.clear();

  if (wasLoading != loading())
    emit loadingChanged();

  emit errorChanged();
  m_provider->request(requestId, operation, payload);

  return requestId;
}

void ServiceBase::handleRequestFinished(const QString &requestId,
                                        const QString &operation, bool success,
                                        const QVariant &data,
                                        const QString &errorMessage) {
  if (!m_pendingRequests.remove(requestId))
    return;

  emit loadingChanged();
  if (m_error != errorMessage) {
    m_error = errorMessage;
    emit errorChanged();
  }

  emit operationFinished(requestId, operation, success, data, errorMessage);
}

AuthService::AuthService(DataProvider *provider, QObject *parent)
    : ServiceBase(provider, parent) {
  connect(this, &ServiceBase::operationFinished, this,
          [this](const QString &, const QString &operation, bool success,
                 const QVariant &data, const QString &) {
            if (operation != QStringLiteral("auth.login") &&
                operation != QStringLiteral("auth.register") &&
                operation != QStringLiteral("auth.logout"))
              return;
            if (!success)
              return;

            const bool authenticated =
                operation != QStringLiteral("auth.logout");

            if (m_authenticated != authenticated) {
              m_authenticated = authenticated;
              emit authenticatedChanged();
            }

            const QVariantMap nextUser =
                authenticated ? data.toMap() : QVariantMap{};

            if (m_user != nextUser) {
              m_user = nextUser;
              emit userChanged();
            }
          });
}

bool AuthService::authenticated() const { return m_authenticated; }

QVariantMap AuthService::user() const { return m_user; }

QString AuthService::login(const QString &loginValue, const QString &password) {
  return sendRequest(QStringLiteral("auth.login"),
                     {{QStringLiteral("login"), loginValue},
                      {QStringLiteral("password"), password}});
}

QString AuthService::registerUser(const QVariantMap &userValue) {
  return sendRequest(QStringLiteral("auth.register"), userValue);
}

QString AuthService::logout() {
  return sendRequest(QStringLiteral("auth.logout"));
}

EntityService::EntityService(DataProvider *provider, QString entityName,
                             QObject *parent)
    : ServiceBase(provider, parent), m_entityName(std::move(entityName)) {
  connect(this, &ServiceBase::operationFinished, this,
          [this](const QString &, const QString &operation, bool success,
                 const QVariant &data, const QString &) {
            if (!success)
              return;

            if (operation.startsWith(m_entityName + u'.') &&
                data.metaType().id() == QMetaType::QVariantList) {
              m_items = data.toList();
              emit itemsChanged();
              return;
            }

            const QVariantMap result = data.toMap();
            syncCollections(result);
          });
}

QVariantList EntityService::items() const { return m_items; }

void EntityService::syncCollections(const QVariantMap &collections) {
  const auto it = collections.constFind(m_entityName);
  if (it == collections.cend() ||
      it->metaType().id() != QMetaType::QVariantList)
    return;

  const QVariantList nextItems = it->toList();
  if (m_items == nextItems)
    return;

  m_items = nextItems;
  emit itemsChanged();
}

QString EntityService::load() {
  return sendRequest(m_entityName + QStringLiteral(".list"));
}

QString EntityService::create(const QVariantMap &entity) {
  return sendRequest(m_entityName + QStringLiteral(".create"), entity);
}

QString EntityService::update(const QString &id, const QVariantMap &entity) {
  return sendRequest(
      m_entityName + QStringLiteral(".update"),
      {{QStringLiteral("id"), id}, {QStringLiteral("entity"), entity}});
}

QString EntityService::remove(const QString &id) {
  return sendRequest(m_entityName + QStringLiteral(".delete"),
                     {{QStringLiteral("id"), id}});
}

AssetService::AssetService(DataProvider *provider, QObject *parent)
    : EntityService(provider, QStringLiteral("assets"), parent) {
  connect(this, &ServiceBase::operationFinished, this,
          [this](const QString &, const QString &operation, bool success,
                 const QVariant &data, const QString &) {
            if (operation != QStringLiteral("assets.preset") || !success)
              return;
            const bool industrial =
                data.toMap().value(QStringLiteral("industrialMode")).toBool();
            if (m_industrialMode != industrial) {
              m_industrialMode = industrial;
              emit industrialModeChanged();
            }
          });
}

bool AssetService::industrialMode() const { return m_industrialMode; }

QString AssetService::loadPreset(bool industrial) {
  return sendRequest(QStringLiteral("assets.preset"),
                     {{QStringLiteral("industrial"), industrial}});
}

RiskService::RiskService(DataProvider *provider, QObject *parent)
    : EntityService(provider, QStringLiteral("risks"), parent) {}

QString RiskService::importScenario(const QString &scenarioCode,
                                    const QString &assetId,
                                    const QVariantMap &scenario,
                                    int riskAppetite) {
  return sendRequest(QStringLiteral("risks.importScenario"),
                     {{QStringLiteral("scenarioCode"), scenarioCode},
                      {QStringLiteral("assetId"), assetId},
                      {QStringLiteral("scenario"), scenario},
                      {QStringLiteral("riskAppetite"), riskAppetite}});
}

QString RiskService::bindMeasure(const QString &riskId,
                                 const QString &measureId) {
  return sendRequest(QStringLiteral("risks.bindMeasure"),
                     {{QStringLiteral("riskId"), riskId},
                      {QStringLiteral("measureId"), measureId}});
}

QString RiskService::unbindMeasure(const QString &riskId) {
  return sendRequest(QStringLiteral("risks.unbindMeasure"),
                     {{QStringLiteral("riskId"), riskId}});
}

MeasureService::MeasureService(DataProvider *provider, QObject *parent)
    : EntityService(provider, QStringLiteral("measures"), parent) {}

QString MeasureService::addIndustrialPreset() {
  return sendRequest(QStringLiteral("measures.preset"));
}

DashboardService::DashboardService(DataProvider *provider, QObject *parent)
    : ServiceBase(provider, parent) {
  connect(this, &ServiceBase::operationFinished, this,
          [this](const QString &, const QString &operation, bool success,
                 const QVariant &data, const QString &) {
            if (operation == QStringLiteral("dashboard.get") && success) {
              m_summary = data.toMap();
              emit summaryChanged();
            }
          });
}

QVariantMap DashboardService::summary() const { return m_summary; }

QString DashboardService::refresh() {
  return sendRequest(QStringLiteral("dashboard.get"));
}

EconomicsService::EconomicsService(DataProvider *provider, QObject *parent)
    : ServiceBase(provider, parent) {
  m_summary = {{QStringLiteral("assets"), QVariantList{}},
               {QStringLiteral("risks"), QVariantList{}},
               {QStringLiteral("measures"), QVariantList{}},
               {QStringLiteral("measureBreakdown"), QVariantList{}},
               {QStringLiteral("totalAssetsCost"), 0.0},
               {QStringLiteral("initialLosses"), 0.0},
               {QStringLiteral("residualLosses"), 0.0},
               {QStringLiteral("avoidedDamage"), 0.0},
               {QStringLiteral("totalMeasuresCost"), 0.0},
               {QStringLiteral("netBenefit"), 0.0},
               {QStringLiteral("rosi"), 0},
               {QStringLiteral("multiplier"), QStringLiteral("0.0x")},
               {QStringLiteral("riskAppetite"), m_riskAppetite},
               {QStringLiteral("pointCost"), m_pointCost},
               {QStringLiteral("downtimeHourlyCost"), m_downtimeHourlyCost},
               {QStringLiteral("mttrHours"), m_mttrHours},
               {QStringLiteral("industrialMode"), m_industrialMode},
               {QStringLiteral("criticalRisksCount"), 0},
               {QStringLiteral("highRisksCount"), 0},
               {QStringLiteral("mediumRisksCount"), 0},
               {QStringLiteral("lowRisksCount"), 0},
               {QStringLiteral("averageScore"), 0.0}};

  connect(this, &ServiceBase::operationFinished, this,
          [this](const QString &, const QString &operation, bool success,
                 const QVariant &data, const QString &) {
            if (operation != QStringLiteral("economics.get") || !success)
              return;
            m_summary = data.toMap();
            emit summaryChanged();
          });
}

QVariantMap EconomicsService::summary() const { return m_summary; }

int EconomicsService::riskAppetite() const { return m_riskAppetite; }

double EconomicsService::pointCost() const { return m_pointCost; }

double EconomicsService::downtimeHourlyCost() const {
  return m_downtimeHourlyCost;
}

int EconomicsService::mttrHours() const { return m_mttrHours; }

QString EconomicsService::refresh() {
  return sendRequest(
      QStringLiteral("economics.get"),
      {{QStringLiteral("riskAppetite"), m_riskAppetite},
       {QStringLiteral("pointCost"), m_pointCost},
       {QStringLiteral("downtimeHourlyCost"), m_downtimeHourlyCost},
       {QStringLiteral("mttrHours"), m_mttrHours},
       {QStringLiteral("industrialMode"), m_industrialMode}});
}

void EconomicsService::saveCriteria(int appetite, double cost) {
  m_riskAppetite = appetite;
  m_pointCost = cost;
  emit criteriaChanged();
  refresh();
}

void EconomicsService::setIndustrialMode(bool industrial) {
  if (m_industrialMode == industrial)
    return;
  m_industrialMode = industrial;
  refresh();
}

