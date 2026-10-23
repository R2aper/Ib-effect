#include "dataprovider.h"
#include "mockdatahelpers.h"

#include <QTimer>
#include <QtMath>
#include <algorithm>

using namespace MockDataHelpers;

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
    const QString loginKey = login.toLower();
    if (false /* login.isEmpty() || password.isEmpty()*/) {
      success = false;
      error = QStringLiteral("Укажите логин и пароль.");
    } else if (operation == QStringLiteral("auth.login")) {
      if (false/*!m_passwords.contains(loginKey) ||
          m_passwords.value(loginKey) != password*/) {
        success = false;
        error = QStringLiteral("Пользователь не найден или неверный пароль.");
      } else {
        m_user = m_users.value(loginKey);
        m_authenticated = true;
        result = m_user;
      }
    } else {
      if (m_users.contains(loginKey)) {
        success = false;
        error = QStringLiteral("Данный логин уже занят.");
      } else if (payload.value(QStringLiteral("name"))
                     .toString()
                     .trimmed()
                     .isEmpty() ||
                 (payload.value(QStringLiteral("type")).toString() ==
                      QStringLiteral("student") &&
                  payload.value(QStringLiteral("group"))
                      .toString()
                      .trimmed()
                      .isEmpty()) ||
                 (payload.value(QStringLiteral("type")).toString() ==
                      QStringLiteral("company") &&
                  payload.value(QStringLiteral("org"))
                      .toString()
                      .trimmed()
                      .isEmpty())) {
        success = false;
        error = QStringLiteral("Заполните все обязательные поля.");
      } else {
        m_user = payload;
        m_user.remove(QStringLiteral("password"));
        m_user.insert(QStringLiteral("login"), login);
        m_users.insert(loginKey, m_user);
        m_passwords.insert(loginKey, password);
        m_authenticated = true;
        result = m_user;
      }
    }

  } else if (operation == QStringLiteral("auth.logout")) {
    m_authenticated = false;
    m_user.clear();
  } else if (operation == QStringLiteral("economics.get")) {
    result = calculateEconomics(payload, m_collections);
  } else if (operation == QStringLiteral("dashboard.get")) {
    const QVariantList risks = m_collections.value(QStringLiteral("risks"));
    const QVariantList measures =
        m_collections.value(QStringLiteral("measures"));
    int criticalCount = 0;
    int highCount = 0;
    int mediumCount = 0;
    int lowCount = 0;
    double scoreTotal = 0;
    double measureCost = 0;
    double initialLoss = 0;
    double residualLoss = 0;
    for (const QVariant &value : measures)
      measureCost += value.toMap().value(QStringLiteral("cost")).toDouble();
    for (const QVariant &value : risks) {
      const QVariantMap risk = value.toMap();
      const int score = risk.value(QStringLiteral("impact")).toInt() *
                        risk.value(QStringLiteral("probability")).toInt() *
                        risk.value(QStringLiteral("assetPriority")).toInt();
      const QString level = riskLevel(score);
      if (level == QStringLiteral("critical"))
        ++criticalCount;
      else if (level == QStringLiteral("high"))
        ++highCount;
      else if (level == QStringLiteral("medium"))
        ++mediumCount;
      else
        ++lowCount;
      scoreTotal += score;
      initialLoss += score * 250000;

      int residualScore = score;
      const QString measureId =
          risk.value(QStringLiteral("boundMeasureId")).toString();
      for (const QVariant &measureValue : measures) {
        const QVariantMap measure = measureValue.toMap();
        if (measure.value(QStringLiteral("id")).toString() == measureId) {
          const double impact =
              risk.value(QStringLiteral("impact")).toDouble() *
              (1.0 -
               measure.value(QStringLiteral("dmgRed")).toDouble() / 100.0);
          const double probability =
              risk.value(QStringLiteral("probability")).toDouble() *
              (1.0 -
               measure.value(QStringLiteral("probRed")).toDouble() / 100.0);
          residualScore =
              qCeil(impact * probability *
                    risk.value(QStringLiteral("assetPriority")).toDouble());
          break;
        }
      }
      residualLoss += residualScore * 250000;
    }
    const double avoidedDamage = qMax(0.0, initialLoss - residualLoss);
    const double netBenefit = avoidedDamage - measureCost;
    const int rosi =
        measureCost > 0 ? qRound(netBenefit / measureCost * 100.0) : 0;
    result = QVariantMap{{QStringLiteral("assetCount"),
                          m_collections.value(QStringLiteral("assets")).size()},
                         {QStringLiteral("riskCount"), risks.size()},
                         {QStringLiteral("measureCount"), measures.size()},
                         {QStringLiteral("criticalRisksCount"), criticalCount},
                         {QStringLiteral("highRisksCount"), highCount},
                         {QStringLiteral("mediumRisksCount"), mediumCount},
                         {QStringLiteral("lowRisksCount"), lowCount},
                         {QStringLiteral("averageScore"),
                          risks.isEmpty() ? 0.0 : scoreTotal / risks.size()},
                         {QStringLiteral("totalMeasuresCost"), measureCost},
                         {QStringLiteral("netBenefit"), netBenefit},
                         {QStringLiteral("rosi"), rosi},
                         {QStringLiteral("mock"), true}};

  } else if (operation.endsWith(QStringLiteral(".list"))) {
    result = m_collections.value(entity);
  } else if (operation == QStringLiteral("assets.preset")) {
    const bool industrial =
        payload.value(QStringLiteral("industrial")).toBool();
    QVariantList assets;
    if (industrial) {
      assets = {
          QVariantMap{
              {QStringLiteral("id"), QStringLiteral("ACT-OT-01")},
              {QStringLiteral("name"),
               QStringLiteral("ПЛК агрегата компрессии (Siemens S7-1500)")},
              {QStringLiteral("cat"), QStringLiteral("Контроллер (ПЛК)")},
              {QStringLiteral("cost"), 18500000},
              {QStringLiteral("prio"), 4},
              {QStringLiteral("oaCode"), QStringLiteral("ОА.006")},
              {QStringLiteral("oaTitle"),
               QStringLiteral(
                   "Программируемый логический контроллер (ПЛК / PLC)")},
              {QStringLiteral("domain"), QStringLiteral("OT")},
              {QStringLiteral("status"), QStringLiteral("На защите")},
              {QStringLiteral("statusLevel"), QStringLiteral("success")}},
          QVariantMap{
              {QStringLiteral("id"), QStringLiteral("ACT-OT-02")},
              {QStringLiteral("name"),
               QStringLiteral("Инженерная станция АСУ ТП (TIA Portal)")},
              {QStringLiteral("cat"), QStringLiteral("АРМ инженера")},
              {QStringLiteral("cost"), 9800000},
              {QStringLiteral("prio"), 4},
              {QStringLiteral("oaCode"), QStringLiteral("ОА.002")},
              {QStringLiteral("oaTitle"),
               QStringLiteral("АРМ инженера (инженерная станция)")},
              {QStringLiteral("domain"), QStringLiteral("OT")},
              {QStringLiteral("status"), QStringLiteral("На защите")},
              {QStringLiteral("statusLevel"), QStringLiteral("success")}},
          QVariantMap{
              {QStringLiteral("id"), QStringLiteral("ACT-OT-03")},
              {QStringLiteral("name"),
               QStringLiteral(
                   "Технологический съемный накопитель (USB-Flash)")},
              {QStringLiteral("cat"), QStringLiteral("Съемный носитель")},
              {QStringLiteral("cost"), 1200000},
              {QStringLiteral("prio"), 4},
              {QStringLiteral("oaCode"), QStringLiteral("ОА.009")},
              {QStringLiteral("oaTitle"),
               QStringLiteral("Съемный носитель информации (USB, flash)")},
              {QStringLiteral("domain"), QStringLiteral("OT")},
              {QStringLiteral("status"), QStringLiteral("На контроле")},
              {QStringLiteral("statusLevel"), QStringLiteral("high")}},
          QVariantMap{
              {QStringLiteral("id"), QStringLiteral("ACT-OT-04")},
              {QStringLiteral("name"),
               QStringLiteral("Главный SCADA-сервер диспетчеризации (WinCC)")},
              {QStringLiteral("cat"), QStringLiteral("Промышленный сервер")},
              {QStringLiteral("cost"), 26000000},
              {QStringLiteral("prio"), 4},
              {QStringLiteral("oaCode"), QStringLiteral("ОА.003")},
              {QStringLiteral("oaTitle"),
               QStringLiteral("Промышленный сервер (SCADA/DCS)")},
              {QStringLiteral("domain"), QStringLiteral("OT")},
              {QStringLiteral("status"), QStringLiteral("На защите")},
              {QStringLiteral("statusLevel"), QStringLiteral("success")}},
          QVariantMap{
              {QStringLiteral("id"), QStringLiteral("ACT-OT-05")},
              {QStringLiteral("name"),
               QStringLiteral(
                   "Панель оператора на технологической установке (HMI)")},
              {QStringLiteral("cat"), QStringLiteral("Панель оператора")},
              {QStringLiteral("cost"), 4300000},
              {QStringLiteral("prio"), 3},
              {QStringLiteral("oaCode"), QStringLiteral("ОА.005")},
              {QStringLiteral("oaTitle"),
               QStringLiteral("Сенсорная панель оператора (HMI)")},
              {QStringLiteral("domain"), QStringLiteral("OT")},
              {QStringLiteral("status"), QStringLiteral("На контроле")},
              {QStringLiteral("statusLevel"), QStringLiteral("high")}}};
    } else {
      assets = {
          QVariantMap{
              {QStringLiteral("id"), QStringLiteral("ACT-01")},
              {QStringLiteral("name"),
               QStringLiteral("Автоматизированная банковская система (АБС)")},
              {QStringLiteral("cat"), QStringLiteral("Информ. система")},
              {QStringLiteral("cost"), 24000000},
              {QStringLiteral("prio"), 4},
              {QStringLiteral("oaCode"), QStringLiteral("ОА.003")},
              {QStringLiteral("oaTitle"),
               QStringLiteral("Промышленный сервер")},
              {QStringLiteral("domain"), QStringLiteral("IT")},
              {QStringLiteral("status"), QStringLiteral("На защите")},
              {QStringLiteral("statusLevel"), QStringLiteral("success")}},
          QVariantMap{
              {QStringLiteral("id"), QStringLiteral("ACT-02")},
              {QStringLiteral("name"),
               QStringLiteral(
                   "Центральная СУБД PostgreSQL (Клиентские данные)")},
              {QStringLiteral("cat"), QStringLiteral("База данных")},
              {QStringLiteral("cost"), 12500000},
              {QStringLiteral("prio"), 4},
              {QStringLiteral("oaCode"), QStringLiteral("ОА.004")},
              {QStringLiteral("oaTitle"),
               QStringLiteral("Сервер архивов / баз данных")},
              {QStringLiteral("domain"), QStringLiteral("IT")},
              {QStringLiteral("status"), QStringLiteral("На защите")},
              {QStringLiteral("statusLevel"), QStringLiteral("success")}},
          QVariantMap{
              {QStringLiteral("id"), QStringLiteral("ACT-03")},
              {QStringLiteral("name"),
               QStringLiteral("Корпоративный почтовый сервер и веб-шлюз")},
              {QStringLiteral("cat"), QStringLiteral("Инфраструктура")},
              {QStringLiteral("cost"), 5300000},
              {QStringLiteral("prio"), 3},
              {QStringLiteral("oaCode"), QStringLiteral("ОА.001")},
              {QStringLiteral("oaTitle"),
               QStringLiteral("АРМ оператора / сервер")},
              {QStringLiteral("domain"), QStringLiteral("IT")},
              {QStringLiteral("status"), QStringLiteral("На контроле")},
              {QStringLiteral("statusLevel"), QStringLiteral("high")}},
          QVariantMap{
              {QStringLiteral("id"), QStringLiteral("ACT-04")},
              {QStringLiteral("name"),
               QStringLiteral("Контроллер домена Active Directory")},
              {QStringLiteral("cat"), QStringLiteral("Служба каталога")},
              {QStringLiteral("cost"), 4000000},
              {QStringLiteral("prio"), 3},
              {QStringLiteral("oaCode"), QStringLiteral("ОА.001")},
              {QStringLiteral("oaTitle"),
               QStringLiteral("АРМ оператора / сервер")},
              {QStringLiteral("domain"), QStringLiteral("IT")},
              {QStringLiteral("status"), QStringLiteral("На защите")},
              {QStringLiteral("statusLevel"), QStringLiteral("success")}}};
    }
    m_collections.insert(QStringLiteral("assets"), assets);
    QVariantList risks = m_collections.value(QStringLiteral("risks"));
    for (qsizetype i = 0; i < risks.size(); ++i) {
      QVariantMap risk = risks.at(i).toMap();
      const QVariantMap asset = assets.at(i % assets.size()).toMap();
      risk.insert(QStringLiteral("assetId"), asset.value(QStringLiteral("id")));
      risk.insert(QStringLiteral("assetName"),
                  asset.value(QStringLiteral("name")));
      const int priority = asset.value(QStringLiteral("prio")).toInt();
      risk.insert(QStringLiteral("assetPriority"), priority);
      const int score = risk.value(QStringLiteral("impact")).toInt() *
                        risk.value(QStringLiteral("probability")).toInt() *
                        priority;
      risk.insert(QStringLiteral("score"), score);
      risk.insert(QStringLiteral("scoreLevel"), riskLevel(score));
      risks[i] = risk;
    }
    m_collections.insert(QStringLiteral("risks"), risks);
    result = QVariantMap{{QStringLiteral("assets"), assets},
                         {QStringLiteral("risks"), risks},
                         {QStringLiteral("industrialMode"), industrial}};
  } else if (operation == QStringLiteral("measures.preset")) {
    QVariantList measures = m_collections.value(QStringLiteral("measures"));
    const QVariantList presets{
        QVariantMap{{QStringLiteral("name"),
                     QStringLiteral("Аппаратный однонаправленный шлюз (Диод "
                                    "данных) контура SCADA")},
                    {QStringLiteral("type"),
                     QStringLiteral("Техническая (Приказ № 239)")},
                    {QStringLiteral("cost"), 3200000},
                    {QStringLiteral("dmgRed"), 60},
                    {QStringLiteral("probRed"), 95}},
        QVariantMap{{QStringLiteral("name"),
                     QStringLiteral("Станция очистки и доверенной загрузки "
                                    "съемных накопителей USB (ОА.009)")},
                    {QStringLiteral("type"),
                     QStringLiteral("Техническая (Приказ № 239)")},
                    {QStringLiteral("cost"), 1800000},
                    {QStringLiteral("dmgRed"), 50},
                    {QStringLiteral("probRed"), 90}},
        QVariantMap{{QStringLiteral("name"),
                     QStringLiteral("Промышленный МЭ с глубоким анализом "
                                    "протоколов (Modbus/Profinet DPI)")},
                    {QStringLiteral("type"),
                     QStringLiteral("Техническая (Приказ № 239)")},
                    {QStringLiteral("cost"), 2900000},
                    {QStringLiteral("dmgRed"), 70},
                    {QStringLiteral("probRed"), 75}},
        QVariantMap{{QStringLiteral("name"),
                     QStringLiteral("Система мониторинга целостности прошивок "
                                    "и конфигураций ПЛК (ОА.006)")},
                    {QStringLiteral("type"),
                     QStringLiteral("Техническая (Приказ № 239)")},
                    {QStringLiteral("cost"), 2100000},
                    {QStringLiteral("dmgRed"), 85},
                    {QStringLiteral("probRed"), 80}}};
    for (const QVariant &presetValue : presets) {
      QVariantMap measure = presetValue.toMap();
      int nextNumber = 1;
      QString id;
      while (true) {
        id = QStringLiteral("MSR-OT-%1")
                 .arg(nextNumber < 10 ? QStringLiteral("0") : QString(""))
                 .arg(nextNumber++);
        const bool exists = std::any_of(
            measures.cbegin(), measures.cend(), [&id](const QVariant &value) {
              return value.toMap().value(QStringLiteral("id")).toString() == id;
            });
        if (!exists)
          break;
      }
      measure.insert(QStringLiteral("id"), id);
      measure.insert(QStringLiteral("status"), QStringLiteral("В плане"));
      measure.insert(QStringLiteral("statusLevel"), QStringLiteral("info"));
      measures.append(measure);
    }
    m_collections.insert(QStringLiteral("measures"), measures);
    result = measures;
  } else if (operation.endsWith(QStringLiteral(".create"))) {
    QVariantMap item = payload;
    QVariantList items = m_collections.value(entity);
    const int riskAppetite =
        item.value(QStringLiteral("riskAppetite"), 16).toInt();
    item.remove(QStringLiteral("riskAppetite"));
    bool industrial =
        item.value(QStringLiteral("domain")).toString() == QStringLiteral("OT");
    if (entity == QStringLiteral("risks")) {
      bool assetFound = false;
      for (const QVariant &assetValue :
           m_collections.value(QStringLiteral("assets"))) {
        const QVariantMap asset = assetValue.toMap();
        if (asset.value(QStringLiteral("id")).toString() ==
            item.value(QStringLiteral("assetId")).toString()) {
          assetFound = true;
          industrial = asset.value(QStringLiteral("domain")).toString() ==
                       QStringLiteral("OT");
          item.insert(QStringLiteral("assetName"),
                      asset.value(QStringLiteral("name")));
          item.insert(QStringLiteral("assetPriority"),
                      asset.value(QStringLiteral("prio")));
          break;
        }
      }
      if (!assetFound) {
        success = false;
        error = QStringLiteral("Выбранный актив не найден в mock-хранилище.");
      }
    }
    if (success) {
      const QString entityPrefix =
          entity == QStringLiteral("assets")  ? QStringLiteral("ACT-")
          : entity == QStringLiteral("risks") ? QStringLiteral("RSK-")
                                              : QStringLiteral("MSR-");
      const QString prefix =
          entityPrefix + (industrial ? QStringLiteral("OT-") : QString());
      int nextNumber = 1;
      bool foundId = false;
      do {
        foundId = false;
        const QString candidate =
            prefix + (nextNumber < 10 ? QStringLiteral("0") : QString()) +
            QString::number(nextNumber++);
        for (const QVariant &value : items) {
          if (value.toMap().value(QStringLiteral("id")).toString() ==
              candidate) {
            foundId = true;
            break;
          }
        }
        if (!foundId)
          item.insert(QStringLiteral("id"), candidate);
      } while (foundId);
      if (entity == QStringLiteral("risks")) {
        const int score =
            item.value(QStringLiteral("impact")).toInt() *
            item.value(QStringLiteral("probability")).toInt() *
            item.value(QStringLiteral("assetPriority"), 3).toInt();
        item.insert(QStringLiteral("score"), score);
        item.insert(QStringLiteral("scoreLevel"), riskLevel(score));
        item.insert(QStringLiteral("boundMeasureId"), QString());
        item.insert(QStringLiteral("boundMeasureName"),
                    QStringLiteral("Не назначена"));
        item.insert(QStringLiteral("status"), score > riskAppetite
                                                  ? QStringLiteral("В плане")
                                                  : QStringLiteral("Принят"));
        item.insert(QStringLiteral("statusLevel"),
                    score > riskAppetite ? QStringLiteral("high")
                                         : QStringLiteral("success"));
      } else if (entity == QStringLiteral("measures")) {
        item.insert(QStringLiteral("boundRiskId"), QString());
        item.insert(QStringLiteral("status"), QStringLiteral("В плане"));
        item.insert(QStringLiteral("statusLevel"), QStringLiteral("info"));
      } else {
        item.insert(QStringLiteral("status"), QStringLiteral("На защите"));
        item.insert(QStringLiteral("statusLevel"), QStringLiteral("success"));
      }
      items.append(item);
      m_collections.insert(entity, items);
      result = items;
    }

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
        if (entity == QStringLiteral("risks")) {
          const int score = item.value(QStringLiteral("impact")).toInt() *
                            item.value(QStringLiteral("probability")).toInt() *
                            item.value(QStringLiteral("assetPriority")).toInt();
          item.insert(QStringLiteral("score"), score);
          item.insert(QStringLiteral("scoreLevel"), riskLevel(score));
        }
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
      if (entity == QStringLiteral("measures")) {
        const QString measureId = id;
        QString updatedName;
        for (const QVariant &value : items) {
          const QVariantMap measure = value.toMap();
          if (measure.value(QStringLiteral("id")).toString() == measureId)
            updatedName = measure.value(QStringLiteral("name")).toString();
        }
        QVariantList risks = m_collections.value(QStringLiteral("risks"));
        for (QVariant &value : risks) {
          QVariantMap risk = value.toMap();
          if (risk.value(QStringLiteral("boundMeasureId")).toString() ==
              measureId) {
            risk.insert(QStringLiteral("boundMeasureName"), updatedName);
            value = risk;
          }
        }
        m_collections.insert(QStringLiteral("risks"), risks);
        QVariantMap updatedCollections;
        updatedCollections.insert(QStringLiteral("measures"), items);
        updatedCollections.insert(QStringLiteral("risks"), risks);
        result = updatedCollections;
      } else {
        result = items;
      }
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
      if (entity == QStringLiteral("risks")) {
        QVariantList measures = m_collections.value(QStringLiteral("measures"));
        for (QVariant &value : measures) {
          QVariantMap measure = value.toMap();
          if (measure.value(QStringLiteral("boundRiskId")).toString() == id) {
            measure.remove(QStringLiteral("boundRiskId"));
            measure.insert(QStringLiteral("status"), QStringLiteral("В плане"));
            measure.insert(QStringLiteral("statusLevel"),
                           QStringLiteral("info"));
            value = measure;
          }
        }
        m_collections.insert(QStringLiteral("measures"), measures);
        QVariantMap updatedCollections;
        updatedCollections.insert(QStringLiteral("risks"), items);
        updatedCollections.insert(QStringLiteral("measures"), measures);
        result = updatedCollections;
      } else if (entity == QStringLiteral("measures")) {
        QVariantList risks = m_collections.value(QStringLiteral("risks"));
        for (QVariant &value : risks) {
          QVariantMap risk = value.toMap();
          if (risk.value(QStringLiteral("boundMeasureId")).toString() == id) {
            risk.remove(QStringLiteral("boundMeasureId"));
            risk.insert(QStringLiteral("boundMeasureName"),
                        QStringLiteral("Не назначена"));
            risk.insert(QStringLiteral("status"), QStringLiteral("В плане"));
            risk.insert(QStringLiteral("statusLevel"), QStringLiteral("high"));
            value = risk;
          }
        }
        m_collections.insert(QStringLiteral("risks"), risks);
        QVariantMap updatedCollections;
        updatedCollections.insert(QStringLiteral("measures"), items);
        updatedCollections.insert(QStringLiteral("risks"), risks);
        result = updatedCollections;
      } else {
        result = items;
      }
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
          risk.value(QStringLiteral("boundMeasureId")).toString();

      if (operation == QStringLiteral("risks.bindMeasure")) {
        QVariantMap measure = measures.at(measureIndex).toMap();
        const QString previousRiskId =
            measure.value(QStringLiteral("boundRiskId")).toString();

        for (QVariant &value : risks) {
          QVariantMap item = value.toMap();
          if (item.value(QStringLiteral("id")).toString() == previousRiskId &&
              previousRiskId != riskId) {
            item.remove(QStringLiteral("boundMeasureId"));
            item.insert(QStringLiteral("boundMeasureName"),
                        QStringLiteral("Не назначена"));
            item.insert(QStringLiteral("status"), QStringLiteral("В плане"));
            item.insert(QStringLiteral("statusLevel"), QStringLiteral("high"));
            value = item;
            break;
          }
        }

        for (QVariant &value : measures) {
          QVariantMap item = value.toMap();

          if (item.value(QStringLiteral("id")).toString() ==
                  previousMeasureId &&
              previousMeasureId != measureId) {
            item.remove(QStringLiteral("boundRiskId"));
            item.insert(QStringLiteral("status"), QStringLiteral("В плане"));
            item.insert(QStringLiteral("statusLevel"), QStringLiteral("info"));
            value = item;
            break;
          }
        }

        risk.insert(QStringLiteral("boundMeasureId"), measureId);
        risk.insert(QStringLiteral("boundMeasureName"),
                    measure.value(QStringLiteral("name")));
        risk.insert(QStringLiteral("status"), QStringLiteral("На защите"));
        risk.insert(QStringLiteral("statusLevel"), QStringLiteral("success"));
        measure.insert(QStringLiteral("boundRiskId"), riskId);
        measure.insert(QStringLiteral("status"), QStringLiteral("Внедряется"));
        measure.insert(QStringLiteral("statusLevel"), QStringLiteral("high"));
        risks[riskIndex] = risk;
        measures[measureIndex] = measure;

      } else {
        risk.remove(QStringLiteral("boundMeasureId"));
        risk.insert(QStringLiteral("boundMeasureName"),
                    QStringLiteral("Не назначена"));
        risk.insert(QStringLiteral("status"), QStringLiteral("В плане"));
        risk.insert(QStringLiteral("statusLevel"), QStringLiteral("high"));
        risks[riskIndex] = risk;

        for (QVariant &value : measures) {
          QVariantMap item = value.toMap();
          if (item.value(QStringLiteral("boundRiskId")).toString() == riskId) {
            item.remove(QStringLiteral("boundRiskId"));
            item.insert(QStringLiteral("status"), QStringLiteral("В плане"));
            item.insert(QStringLiteral("statusLevel"), QStringLiteral("info"));
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
    const QVariantMap scenario =
        payload.value(QStringLiteral("scenario")).toMap();
    const QVariantList steps = scenario.value(QStringLiteral("steps")).toList();
    const QString assetId = payload.value(QStringLiteral("assetId")).toString();
    QVariantMap asset;
    for (const QVariant &value :
         m_collections.value(QStringLiteral("assets"))) {
      const QVariantMap candidate = value.toMap();
      if (candidate.value(QStringLiteral("id")).toString() == assetId) {
        asset = candidate;
        break;
      }
    }

    if (scenario.isEmpty() || steps.isEmpty()) {
      success = false;
      error = QStringLiteral("В выбранном сценарии нет шагов для импорта.");
    } else if (asset.isEmpty()) {
      success = false;
      error = QStringLiteral("Выбранный актив не найден в mock-хранилище.");
    } else {
      QVariantList risks = m_collections.value(QStringLiteral("risks"));
      const QString scenarioCode =
          payload.value(QStringLiteral("scenarioCode")).toString();
      const int riskAppetite =
          payload.value(QStringLiteral("riskAppetite"), 16).toInt();
      const QString riskPrefix =
          asset.value(QStringLiteral("domain")).toString() ==
                  QStringLiteral("OT")
              ? QStringLiteral("RSK-OT-")
              : QStringLiteral("RSK-");
      for (qsizetype stepIndex = 0; stepIndex < steps.size(); ++stepIndex) {
        const QVariantMap step = steps.at(stepIndex).toMap();
        const int impact =
            stepIndex == steps.size() - 1 ? 4 : (stepIndex >= 2 ? 3 : 2);
        const int probability = stepIndex == 0 ? 4 : 3;
        const int priority = asset.value(QStringLiteral("prio"), 3).toInt();
        const int score = impact * probability * priority;
        int nextNumber = 1;
        QString riskId;
        while (true) {
          riskId = riskPrefix +
                   QStringLiteral("%1%2")
                       .arg(nextNumber < 10 ? QStringLiteral("0") : QString())
                       .arg(nextNumber++);
          const bool exists = std::any_of(
              risks.cbegin(), risks.cend(), [&riskId](const QVariant &value) {
                return value.toMap().value(QStringLiteral("id")).toString() ==
                       riskId;
              });
          if (!exists)
            break;
        }
        const QString threatCode =
            step.value(QStringLiteral("threat_code")).toString();
        const QString threatTitle =
            step.value(QStringLiteral("threat_title")).toString();
        const QString threat =
            (threatCode.isEmpty() ? QString()
                                  : threatCode + QStringLiteral(": ")) +
            (threatTitle.isEmpty()
                 ? scenario.value(QStringLiteral("title")).toString()
                 : threatTitle) +
            QStringLiteral(" [") + scenarioCode + QStringLiteral(" · Шаг ") +
            step.value(QStringLiteral("step_number")).toString() +
            QStringLiteral("]");
        const bool appetiteExceeded = score > riskAppetite;
        const QString status = appetiteExceeded ? QStringLiteral("В плане")
                                                : QStringLiteral("Принят");
        QVariantMap risk = makeRisk(
            riskId, threat, threatCode,
            step.value(QStringLiteral("description")).toString(), assetId,
            asset.value(QStringLiteral("name")).toString(), impact, probability,
            priority, QString(), QStringLiteral("Не назначена"), status,
            appetiteExceeded ? QStringLiteral("high")
                             : QStringLiteral("success"));
        risk.insert(QStringLiteral("scenarioCode"), scenarioCode);
        risks.append(risk);
      }
      m_collections.insert(QStringLiteral("risks"), risks);
      result = QVariantMap{{QStringLiteral("risks"), risks},
                           {QStringLiteral("count"), steps.size()}};
    }
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
