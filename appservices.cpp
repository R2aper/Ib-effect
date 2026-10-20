#include "appservices.h"

#include <QTimer>
#include <QUuid>
#include <utility>

namespace {

QString newRequestId() {
  return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QString entityFromOperation(const QString &operation) {
  const qsizetype separator = operation.indexOf(u'.');
  return separator < 0 ? QString() : operation.left(separator);
}

} // namespace

MockDataProvider::MockDataProvider(QObject *parent) : DataProvider(parent) {}

QString MockDataProvider::modeName() const { return QStringLiteral("mock"); }

void MockDataProvider::request(const QString &requestId,
                               const QString &operation,
                               const QVariantMap &payload) {
  bool success = true;
  QString error;
  QVariant result;
  const QString entity = entityFromOperation(operation);

  if (operation == QStringLiteral("auth.login") ||
      operation == QStringLiteral("auth.register")) {
    const QString login =
        payload.value(QStringLiteral("login")).toString().trimmed();
    const QString password =
        payload.value(QStringLiteral("password")).toString();

    if (login.isEmpty() || password.isEmpty()) {
      success = false;
      error = QStringLiteral("Укажите логин и пароль.");
    } else {
      m_authenticated = true;
      m_user = {{QStringLiteral("login"), login},
                {QStringLiteral("displayName"), login},
                {QStringLiteral("mock"), true}};
      result = m_user;
    }

  } else if (operation == QStringLiteral("auth.logout")) {
    m_authenticated = false;
    m_user.clear();
  } else if (operation == QStringLiteral("dashboard.get")) {
    result =
        QVariantMap{{QStringLiteral("assetCount"),
                     m_collections.value(QStringLiteral("assets")).size()},
                    {QStringLiteral("riskCount"),
                     m_collections.value(QStringLiteral("risks")).size()},
                    {QStringLiteral("measureCount"),
                     m_collections.value(QStringLiteral("measures")).size()},
                    {QStringLiteral("mock"), true}};

  } else if (operation.endsWith(QStringLiteral(".list"))) {
    result = m_collections.value(entity);
  } else if (operation.endsWith(QStringLiteral(".create"))) {
    QVariantMap item = payload;
    item.insert(QStringLiteral("id"),
                QUuid::createUuid().toString(QUuid::WithoutBraces));
    QVariantList items = m_collections.value(entity);
    items.append(item);
    m_collections.insert(entity, items);
    result = items;

  } else if (operation.endsWith(QStringLiteral(".update"))) {
    QVariantList items = m_collections.value(entity);
    const QString id = payload.value(QStringLiteral("id")).toString();
    bool found = false;
    for (QVariant &value : items) {
      QVariantMap item = value.toMap();

      if (item.value(QStringLiteral("id")).toString() == id) {
        const QVariantMap changes =
            payload.value(QStringLiteral("entity")).toMap();

        for (auto it = changes.cbegin(); it != changes.cend(); ++it)
          item.insert(it.key(), it.value());
        value = item;
        found = true;
        break;
      }
    }

    if (!found) {
      success = false;
      error = QStringLiteral("Запись не найдена в mock-хранилище.");
    } else {
      m_collections.insert(entity, items);
      result = items;
    }

  } else if (operation.endsWith(QStringLiteral(".delete"))) {
    QVariantList items = m_collections.value(entity);
    const QString id = payload.value(QStringLiteral("id")).toString();
    const qsizetype oldSize = items.size();

    for (qsizetype i = items.size(); i > 0; --i) {
      if (items.at(i - 1).toMap().value(QStringLiteral("id")).toString() == id)
        items.removeAt(i - 1);
    }

    if (items.size() == oldSize) {
      success = false;
      error = QStringLiteral("Запись не найдена в mock-хранилище.");
    } else {
      m_collections.insert(entity, items);
      result = items;
    }

  } else if (operation == QStringLiteral("risks.bindMeasure") ||
             operation == QStringLiteral("risks.unbindMeasure")) {
    QVariantList risks = m_collections.value(QStringLiteral("risks"));
    QVariantList measures = m_collections.value(QStringLiteral("measures"));
    const QString riskId = payload.value(QStringLiteral("riskId")).toString();
    const QString measureId =
        payload.value(QStringLiteral("measureId")).toString();
    qsizetype riskIndex = -1;
    qsizetype measureIndex = -1;

    for (qsizetype i = 0; i < risks.size(); ++i) {
      if (risks.at(i).toMap().value(QStringLiteral("id")).toString() ==
          riskId) {
        riskIndex = i;
        break;
      }
    }

    if (operation == QStringLiteral("risks.bindMeasure")) {
      for (qsizetype i = 0; i < measures.size(); ++i) {
        if (measures.at(i).toMap().value(QStringLiteral("id")).toString() ==
            measureId) {
          measureIndex = i;
          break;
        }
      }
    }

    if (riskIndex < 0 || (operation == QStringLiteral("risks.bindMeasure") &&
                          measureIndex < 0)) {
      success = false;
      error = QStringLiteral("Не найдены риск или мера в mock-хранилище.");
    } else {
      QVariantMap risk = risks.at(riskIndex).toMap();
      const QString previousMeasureId =
          risk.value(QStringLiteral("measureId")).toString();

      if (operation == QStringLiteral("risks.bindMeasure")) {
        QVariantMap measure = measures.at(measureIndex).toMap();
        const QString previousRiskId =
            measure.value(QStringLiteral("riskId")).toString();

        for (QVariant &value : risks) {
          QVariantMap item = value.toMap();
          if (item.value(QStringLiteral("id")).toString() == previousRiskId &&
              previousRiskId != riskId) {
            item.remove(QStringLiteral("measureId"));
            value = item;
            break;
          }
        }

        for (QVariant &value : measures) {
          QVariantMap item = value.toMap();

          if (item.value(QStringLiteral("id")).toString() ==
                  previousMeasureId &&
              previousMeasureId != measureId) {
            item.remove(QStringLiteral("riskId"));
            value = item;
            break;
          }
        }

        risk.insert(QStringLiteral("measureId"), measureId);
        measure.insert(QStringLiteral("riskId"), riskId);
        risks[riskIndex] = risk;
        measures[measureIndex] = measure;

      } else {
        risk.remove(QStringLiteral("measureId"));
        risks[riskIndex] = risk;

        for (QVariant &value : measures) {
          QVariantMap item = value.toMap();
          if (item.value(QStringLiteral("riskId")).toString() == riskId) {
            item.remove(QStringLiteral("riskId"));
            value = item;
          }
        }
      }

      m_collections.insert(QStringLiteral("risks"), risks);
      m_collections.insert(QStringLiteral("measures"), measures);
      QVariantMap updatedCollections;
      updatedCollections.insert(QStringLiteral("risks"), risks);
      updatedCollections.insert(QStringLiteral("measures"), measures);
      result = updatedCollections;
    }

  } else if (operation == QStringLiteral("risks.importScenario")) {
    success = false;
    error =
        QStringLiteral("Импорт сценариев требует подключённого каталога БДУ.");
  } else {
    success = false;
    error = QStringLiteral("Неизвестная операция mock-провайдера: %1")
                .arg(operation);
  }

  QTimer::singleShot(
      0, this, [this, requestId, operation, success, result, error] {
        emit requestFinished(requestId, operation, success, result, error);
      });
}

HttpDataProvider::HttpDataProvider(QObject *parent) : DataProvider(parent) {}

QString HttpDataProvider::modeName() const { return QStringLiteral("http"); }

void HttpDataProvider::request(const QString &requestId,
                               const QString &operation,
                               const QVariantMap &payload) {
  Q_UNUSED(payload);
  QTimer::singleShot(0, this, [this, requestId, operation] {
    emit requestFinished(requestId, operation, false, {},
                         QStringLiteral("TODO: HTTP"));
  });
}

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

            const bool authenticated =
                success && operation != QStringLiteral("auth.logout");

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
            if (result.contains(m_entityName)) {
              m_items = result.value(m_entityName).toList();
              emit itemsChanged();
            }
          });
}

QVariantList EntityService::items() const { return m_items; }

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
    : EntityService(provider, QStringLiteral("assets"), parent) {}

RiskService::RiskService(DataProvider *provider, QObject *parent)
    : EntityService(provider, QStringLiteral("risks"), parent) {}

QString RiskService::importScenario(const QString &scenarioCode,
                                    const QString &assetId) {
  return sendRequest(QStringLiteral("risks.importScenario"),
                     {{QStringLiteral("scenarioCode"), scenarioCode},
                      {QStringLiteral("assetId"), assetId}});
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
}

QString AppServices::providerMode() const { return m_provider->modeName(); }

AuthService *AppServices::auth() const { return m_auth; }

AssetService *AppServices::assets() const { return m_assets; }

RiskService *AppServices::risks() const { return m_risks; }

MeasureService *AppServices::measures() const { return m_measures; }

DashboardService *AppServices::dashboard() const { return m_dashboard; }
