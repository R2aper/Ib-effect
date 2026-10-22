#include "appservices.h"

#include <algorithm>
#include <QtMath>
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

QString riskLevel(int score) {
  if (score > 32)
    return QStringLiteral("critical");
  if (score > 16)
    return QStringLiteral("high");
  if (score > 8)
    return QStringLiteral("medium");
  return QStringLiteral("low");
}

QString riskLevelName(const QString &level) {
  if (level == QStringLiteral("critical"))
    return QStringLiteral("Критический");
  if (level == QStringLiteral("high"))
    return QStringLiteral("Высокий");
  if (level == QStringLiteral("medium"))
    return QStringLiteral("Средний");
  return QStringLiteral("Низкий");
}

QVariantMap calculateEconomics(const QVariantMap &payload,
                               const QHash<QString, QVariantList> &collections) {
  const QVariantList assets = collections.value(QStringLiteral("assets"));
  const QVariantList risks = collections.value(QStringLiteral("risks"));
  const QVariantList measures = collections.value(QStringLiteral("measures"));
  const double pointCost = payload.value(QStringLiteral("pointCost")).toDouble();
  const double downtimeHourlyCost =
      payload.value(QStringLiteral("downtimeHourlyCost")).toDouble();
  const int riskAppetite = payload.value(QStringLiteral("riskAppetite")).toInt();
  const bool industrial =
      payload.value(QStringLiteral("industrialMode")).toBool();

  double totalAssetsCost = 0;
  for (const QVariant &value : assets)
    totalAssetsCost += value.toMap().value(QStringLiteral("cost")).toDouble();

  double totalMeasuresCost = 0;
  for (const QVariant &value : measures)
    totalMeasuresCost += value.toMap().value(QStringLiteral("cost")).toDouble();

  double initialLosses = 0;
  double residualLosses = 0;
  double scoreTotal = 0;
  int criticalRisksCount = 0;
  int highRisksCount = 0;
  int mediumRisksCount = 0;
  int lowRisksCount = 0;

  QVariantList calculatedRisks;
  for (const QVariant &value : risks) {
    QVariantMap risk = value.toMap();
    const int impact = risk.value(QStringLiteral("impact")).toInt();
    const int probability = risk.value(QStringLiteral("probability")).toInt();
    const int priority = risk.value(QStringLiteral("assetPriority")).toInt();
    const int score = impact * probability * priority;
    const QString level = riskLevel(score);
    const int riskScore = risk.value(QStringLiteral("score"), score).toInt();
    const QString riskScoreLevel =
        risk.value(QStringLiteral("scoreLevel"), level).toString();
    risk.insert(QStringLiteral("score"), riskScore);
    risk.insert(QStringLiteral("scoreLevel"), riskScoreLevel);
    risk.insert(QStringLiteral("scoreLevelName"),
                riskLevelName(riskScoreLevel));

    double effectivePointCost = pointCost;
    const QString threatCode = risk.value(QStringLiteral("threatCode")).toString();
    if (industrial &&
        (threatCode == QStringLiteral("УТП:05") ||
         threatCode == QStringLiteral("УТП:08") ||
         threatCode == QStringLiteral("УТП:06"))) {
      effectivePointCost = qMax(pointCost, downtimeHourlyCost * 0.25);
    }

    const double baseLoss = score * effectivePointCost;
    initialLosses += baseLoss;
    scoreTotal += score;
    if (level == QStringLiteral("critical"))
      ++criticalRisksCount;
    else if (level == QStringLiteral("high"))
      ++highRisksCount;
    else if (level == QStringLiteral("medium"))
      ++mediumRisksCount;
    else
      ++lowRisksCount;

    int residualScore = score;
    const QString measureId =
        risk.value(QStringLiteral("boundMeasureId")).toString();
    for (const QVariant &measureValue : measures) {
      const QVariantMap measure = measureValue.toMap();
      if (measure.value(QStringLiteral("id")).toString() == measureId) {
        const double residualImpact =
            impact * (1.0 - measure.value(QStringLiteral("dmgRed")).toDouble() /
                                100.0);
        const double residualProbability =
            probability *
            (1.0 - measure.value(QStringLiteral("probRed")).toDouble() / 100.0);
        residualScore =
            qCeil(residualImpact * residualProbability * priority);
        break;
      }
    }
    residualLosses += residualScore * effectivePointCost;
    calculatedRisks.append(risk);
  }

  const double avoidedDamage = qMax(0.0, initialLosses - residualLosses);
  const double netBenefit = avoidedDamage - totalMeasuresCost;
  const int rosi = totalMeasuresCost > 0
                       ? qRound(netBenefit / totalMeasuresCost * 100.0)
                       : 0;
  const QString multiplier =
      totalMeasuresCost > 0
          ? QString::number(avoidedDamage / totalMeasuresCost, 'f', 1) +
                QStringLiteral("x")
          : QStringLiteral("0.0x");

  QVariantList breakdown;
  for (const QVariant &measureValue : measures) {
    const QVariantMap measure = measureValue.toMap();
    const QString measureId = measure.value(QStringLiteral("id")).toString();
    QVariantMap row = measure;
    QVariantMap matchedRisk;
    for (const QVariant &riskValue : calculatedRisks) {
      const QVariantMap risk = riskValue.toMap();
      if (risk.value(QStringLiteral("boundMeasureId")).toString() == measureId) {
        matchedRisk = risk;
        break;
      }
    }

    const bool hasRisk = !matchedRisk.isEmpty();
    double avoided = 0;
    double net = 0;
    int measureRosi = 0;
    if (hasRisk) {
      double effectivePointCost = pointCost;
      const QString threatCode =
          matchedRisk.value(QStringLiteral("threatCode")).toString();
      if (industrial &&
          (threatCode == QStringLiteral("УТП:05") ||
           threatCode == QStringLiteral("УТП:08") ||
           threatCode == QStringLiteral("УТП:06"))) {
        effectivePointCost = qMax(pointCost, downtimeHourlyCost * 0.25);
      }
      const double baseLoss =
          matchedRisk.value(QStringLiteral("impact")).toDouble() *
          matchedRisk.value(QStringLiteral("probability")).toDouble() *
          matchedRisk.value(QStringLiteral("assetPriority")).toDouble() *
          effectivePointCost;
      const double residualImpact =
          matchedRisk.value(QStringLiteral("impact")).toDouble() *
          (1.0 - measure.value(QStringLiteral("dmgRed")).toDouble() / 100.0);
      const double residualProbability =
          matchedRisk.value(QStringLiteral("probability")).toDouble() *
          (1.0 - measure.value(QStringLiteral("probRed")).toDouble() / 100.0);
      const double residualLoss =
          qCeil(residualImpact * residualProbability *
                matchedRisk.value(QStringLiteral("assetPriority")).toDouble()) *
          effectivePointCost;
      avoided = qMax(0.0, baseLoss - residualLoss);
      net = avoided - measure.value(QStringLiteral("cost")).toDouble();
      const double cost = measure.value(QStringLiteral("cost")).toDouble();
      measureRosi = cost > 0 ? qRound(net / cost * 100.0) : 0;
    }

    row.insert(QStringLiteral("hasRisk"), hasRisk);
    row.insert(QStringLiteral("avoidedDamage"), avoided);
    row.insert(QStringLiteral("netBenefit"), net);
    row.insert(QStringLiteral("rosi"), measureRosi);
    row.insert(QStringLiteral("riskId"),
               matchedRisk.value(QStringLiteral("id")));
    breakdown.append(row);
  }

  return {{QStringLiteral("assets"), assets},
          {QStringLiteral("risks"), calculatedRisks},
          {QStringLiteral("measures"), measures},
          {QStringLiteral("measureBreakdown"), breakdown},
          {QStringLiteral("totalAssetsCost"), totalAssetsCost},
          {QStringLiteral("initialLosses"), initialLosses},
          {QStringLiteral("residualLosses"), residualLosses},
          {QStringLiteral("avoidedDamage"), avoidedDamage},
          {QStringLiteral("totalMeasuresCost"), totalMeasuresCost},
          {QStringLiteral("netBenefit"), netBenefit},
          {QStringLiteral("rosi"), rosi},
          {QStringLiteral("multiplier"), multiplier},
          {QStringLiteral("riskAppetite"), riskAppetite},
          {QStringLiteral("pointCost"), pointCost},
          {QStringLiteral("downtimeHourlyCost"), downtimeHourlyCost},
          {QStringLiteral("mttrHours"), payload.value(QStringLiteral("mttrHours"))},
          {QStringLiteral("industrialMode"), industrial},
          {QStringLiteral("criticalRisksCount"), criticalRisksCount},
          {QStringLiteral("highRisksCount"), highRisksCount},
          {QStringLiteral("mediumRisksCount"), mediumRisksCount},
          {QStringLiteral("lowRisksCount"), lowRisksCount},
          {QStringLiteral("averageScore"),
           risks.isEmpty() ? 0.0 : scoreTotal / risks.size()}};
}

QVariantMap makeRisk(const QString &id, const QString &threat,
                     const QString &threatCode, const QString &vulnerability,
                     const QString &assetId, const QString &assetName,
                     int impact, int probability, int priority,
                     const QString &measureId, const QString &measureName,
                     const QString &status, const QString &statusLevel) {
  const int score = impact * probability * priority;
  return {{QStringLiteral("id"), id},
          {QStringLiteral("threat"), threat},
          {QStringLiteral("threatCode"), threatCode},
          {QStringLiteral("scenarioCode"), QString()},
          {QStringLiteral("vuln"), vulnerability},
          {QStringLiteral("assetId"), assetId},
          {QStringLiteral("assetName"), assetName},
          {QStringLiteral("impact"), impact},
          {QStringLiteral("probability"), probability},
          {QStringLiteral("assetPriority"), priority},
          {QStringLiteral("score"), score},
          {QStringLiteral("scoreLevel"), riskLevel(score)},
          {QStringLiteral("boundMeasureId"), measureId},
          {QStringLiteral("boundMeasureName"), measureName},
          {QStringLiteral("status"), status},
          {QStringLiteral("statusLevel"), statusLevel}};
}

QVariantMap makeMeasure(const QString &id, const QString &name,
                        const QString &type, int cost, int damageReduction,
                        int probabilityReduction, const QString &riskId,
                        const QString &status, const QString &statusLevel) {
  return {{QStringLiteral("id"), id},
          {QStringLiteral("name"), name},
          {QStringLiteral("type"), type},
          {QStringLiteral("cost"), cost},
          {QStringLiteral("dmgRed"), damageReduction},
          {QStringLiteral("probRed"), probabilityReduction},
          {QStringLiteral("boundRiskId"), riskId},
          {QStringLiteral("status"), status},
          {QStringLiteral("statusLevel"), statusLevel}};
}

} // namespace

MockDataProvider::MockDataProvider(QObject *parent) : DataProvider(parent) {
  m_collections.insert(
      QStringLiteral("assets"),
      QVariantList{
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-01")},
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
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-02")},
                      {QStringLiteral("name"),
                       QStringLiteral("Центральная СУБД PostgreSQL (Клиентские данные)")},
                      {QStringLiteral("cat"), QStringLiteral("База данных")},
                      {QStringLiteral("cost"), 12500000},
                      {QStringLiteral("prio"), 4},
                      {QStringLiteral("oaCode"), QStringLiteral("ОА.004")},
                      {QStringLiteral("oaTitle"),
                       QStringLiteral("Сервер архивов / баз данных")},
                      {QStringLiteral("domain"), QStringLiteral("IT")},
                      {QStringLiteral("status"), QStringLiteral("На защите")},
                      {QStringLiteral("statusLevel"), QStringLiteral("success")}},
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-03")},
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
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-04")},
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
                      {QStringLiteral("statusLevel"), QStringLiteral("success")}}});

  m_collections.insert(
      QStringLiteral("risks"),
      {makeRisk(QStringLiteral("RSK-01"),
                QStringLiteral("УБИ.031: Несанкционированный доступ и хищение платежных данных"),
                QStringLiteral("УБИ.031"),
                QStringLiteral("Слабая аутентификация в административном контуре"),
                QStringLiteral("ACT-01"), QStringLiteral("АБС Банка"), 4, 3, 4,
                QStringLiteral("MSR-01"), QStringLiteral("Внедрение PAM-системы"),
                QStringLiteral("В плане"), QStringLiteral("high")),
       makeRisk(QStringLiteral("RSK-02"),
                QStringLiteral("УБИ.027: Внедрение вредоносного ПО (Ransomware) в контур СУБД"),
                QStringLiteral("УБИ.027"),
                QStringLiteral("Отсутствие сегментации сетевого контура СУБД"),
                QStringLiteral("ACT-02"), QStringLiteral("СУБД PostgreSQL"), 4, 3, 4,
                QStringLiteral("MSR-02"), QStringLiteral("Сегментация сети + NGFW"),
                QStringLiteral("На контроле"), QStringLiteral("high")),
       makeRisk(QStringLiteral("RSK-03"),
                QStringLiteral("УБИ.072: Целевой фишинг учетных записей администраторов домена"),
                QStringLiteral("УБИ.072"),
                QStringLiteral("Отсутствие второго фактора авторизации сотрудников"),
                QStringLiteral("ACT-03"), QStringLiteral("Почтовый шлюз"), 3, 3, 3,
                QStringLiteral("MSR-03"), QStringLiteral("МФА + Anti-Phishing"),
                QStringLiteral("Закрыт"), QStringLiteral("success")),
       makeRisk(QStringLiteral("RSK-04"),
                QStringLiteral("УБИ.098: Отказ в обслуживании сервиса авторизации и каталога"),
                QStringLiteral("УБИ.098"),
                QStringLiteral("Недостаточная емкость шлюза и отсутствие кластеризации"),
                QStringLiteral("ACT-04"), QStringLiteral("Active Directory"), 3, 2, 3,
                QStringLiteral("MSR-04"), QStringLiteral("Кластеризация DNS/AD"),
                QStringLiteral("Закрыт"), QStringLiteral("success"))});
  m_collections.insert(
      QStringLiteral("measures"),
      {makeMeasure(QStringLiteral("MSR-01"),
                   QStringLiteral("Внедрение системы контроля привилегированного доступа (PAM)"),
                   QStringLiteral("Техническая"), 2400000, 60, 75,
                   QStringLiteral("RSK-01"), QStringLiteral("Внедряется"),
                   QStringLiteral("high")),
       makeMeasure(QStringLiteral("MSR-02"),
                   QStringLiteral("Сегментация сети ЦОД и СУБД межсетевыми экранами (NGFW)"),
                   QStringLiteral("Техническая"), 1800000, 50, 60,
                   QStringLiteral("RSK-02"), QStringLiteral("В плане"),
                   QStringLiteral("info")),
       makeMeasure(QStringLiteral("MSR-03"),
                   QStringLiteral("Аппаратная многофакторная аутентификация (MFA / FIDO2)"),
                   QStringLiteral("Техническая"), 950000, 30, 80,
                   QStringLiteral("RSK-03"), QStringLiteral("Внедрено"),
                   QStringLiteral("success")),
       makeMeasure(QStringLiteral("MSR-04"),
                   QStringLiteral("Регулярные тренинги по киберграмотности и фишинг-тесты"),
                   QStringLiteral("Организационная"), 450000, 20, 65,
                   QStringLiteral("RSK-04"), QStringLiteral("Внедрено"),
                   QStringLiteral("success"))});

  m_users.insert(QStringLiteral("ostrenko"),
                 {{QStringLiteral("login"), QStringLiteral("ostrenko")},
                  {QStringLiteral("name"), QStringLiteral("Иван Остренко")},
                  {QStringLiteral("type"), QStringLiteral("student")},
                  {QStringLiteral("group"), QStringLiteral("БС-304")},
                  {QStringLiteral("org"), QStringLiteral("СибГУТИ, Кафедра БИТ")},
                  {QStringLiteral("role"), QStringLiteral("Студент")}});
  m_passwords.insert(QStringLiteral("ostrenko"), QStringLiteral("123"));
  m_users.insert(QStringLiteral("ciso"),
                 {{QStringLiteral("login"), QStringLiteral("ciso")},
                  {QStringLiteral("name"), QStringLiteral("Александр Смирнов")},
                  {QStringLiteral("type"), QStringLiteral("company")},
                  {QStringLiteral("group"), QStringLiteral("Отдел ИБ")},
                  {QStringLiteral("org"), QStringLiteral("ПАО Банк")},
                  {QStringLiteral("role"), QStringLiteral("CISO")}});
  m_passwords.insert(QStringLiteral("ciso"), QStringLiteral("123"));
  m_users.insert(QStringLiteral("admin"),
                 {{QStringLiteral("login"), QStringLiteral("admin")},
                  {QStringLiteral("name"), QStringLiteral("Администратор СУИБ")},
                  {QStringLiteral("type"), QStringLiteral("company")},
                  {QStringLiteral("group"), QStringLiteral("Служба безопасности")},
                  {QStringLiteral("org"), QStringLiteral("ИБ-Эффект")},
                  {QStringLiteral("role"), QStringLiteral("Администратор")}});
  m_passwords.insert(QStringLiteral("admin"), QStringLiteral("admin"));
}

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
    if (login.isEmpty() || password.isEmpty()) {
      success = false;
      error = QStringLiteral("Укажите логин и пароль.");
    } else if (operation == QStringLiteral("auth.login")) {
      if (!m_passwords.contains(loginKey) ||
          m_passwords.value(loginKey) != password) {
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
      } else if (payload.value(QStringLiteral("name")).toString().trimmed().isEmpty() ||
                 (payload.value(QStringLiteral("type")).toString() ==
                      QStringLiteral("student") &&
                  payload.value(QStringLiteral("group")).toString().trimmed().isEmpty()) ||
                 (payload.value(QStringLiteral("type")).toString() ==
                      QStringLiteral("company") &&
                  payload.value(QStringLiteral("org")).toString().trimmed().isEmpty())) {
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
    const QVariantList measures = m_collections.value(QStringLiteral("measures"));
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
              (1.0 - measure.value(QStringLiteral("dmgRed")).toDouble() / 100.0);
          const double probability =
              risk.value(QStringLiteral("probability")).toDouble() *
              (1.0 - measure.value(QStringLiteral("probRed")).toDouble() / 100.0);
          residualScore = qCeil(impact * probability *
                                risk.value(QStringLiteral("assetPriority")).toDouble());
          break;
        }
      }
      residualLoss += residualScore * 250000;
    }
    const double avoidedDamage = qMax(0.0, initialLoss - residualLoss);
    const double netBenefit = avoidedDamage - measureCost;
    const int rosi = measureCost > 0
                         ? qRound(netBenefit / measureCost * 100.0)
                         : 0;
    result = QVariantMap{
        {QStringLiteral("assetCount"),
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
    const bool industrial = payload.value(QStringLiteral("industrial")).toBool();
    QVariantList assets;
    if (industrial) {
      assets = {
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-OT-01")},
                      {QStringLiteral("name"),
                       QStringLiteral("ПЛК агрегата компрессии (Siemens S7-1500)")},
                      {QStringLiteral("cat"), QStringLiteral("Контроллер (ПЛК)")},
                      {QStringLiteral("cost"), 18500000},
                      {QStringLiteral("prio"), 4},
                      {QStringLiteral("oaCode"), QStringLiteral("ОА.006")},
                      {QStringLiteral("oaTitle"),
                       QStringLiteral("Программируемый логический контроллер (ПЛК / PLC)")},
                      {QStringLiteral("domain"), QStringLiteral("OT")},
                      {QStringLiteral("status"), QStringLiteral("На защите")},
                      {QStringLiteral("statusLevel"), QStringLiteral("success")}},
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-OT-02")},
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
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-OT-03")},
                      {QStringLiteral("name"),
                       QStringLiteral("Технологический съемный накопитель (USB-Flash)")},
                      {QStringLiteral("cat"), QStringLiteral("Съемный носитель")},
                      {QStringLiteral("cost"), 1200000},
                      {QStringLiteral("prio"), 4},
                      {QStringLiteral("oaCode"), QStringLiteral("ОА.009")},
                      {QStringLiteral("oaTitle"),
                       QStringLiteral("Съемный носитель информации (USB, flash)")},
                      {QStringLiteral("domain"), QStringLiteral("OT")},
                      {QStringLiteral("status"), QStringLiteral("На контроле")},
                      {QStringLiteral("statusLevel"), QStringLiteral("high")}},
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-OT-04")},
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
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-OT-05")},
                      {QStringLiteral("name"),
                       QStringLiteral("Панель оператора на технологической установке (HMI)")},
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
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-01")},
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
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-02")},
                      {QStringLiteral("name"),
                       QStringLiteral("Центральная СУБД PostgreSQL (Клиентские данные)")},
                      {QStringLiteral("cat"), QStringLiteral("База данных")},
                      {QStringLiteral("cost"), 12500000},
                      {QStringLiteral("prio"), 4},
                      {QStringLiteral("oaCode"), QStringLiteral("ОА.004")},
                      {QStringLiteral("oaTitle"),
                       QStringLiteral("Сервер архивов / баз данных")},
                      {QStringLiteral("domain"), QStringLiteral("IT")},
                      {QStringLiteral("status"), QStringLiteral("На защите")},
                      {QStringLiteral("statusLevel"), QStringLiteral("success")}},
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-03")},
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
          QVariantMap{{QStringLiteral("id"), QStringLiteral("ACT-04")},
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
      risk.insert(QStringLiteral("assetId"),
                  asset.value(QStringLiteral("id")));
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
                     QStringLiteral("Аппаратный однонаправленный шлюз (Диод данных) контура SCADA")},
                    {QStringLiteral("type"),
                     QStringLiteral("Техническая (Приказ № 239)")},
                    {QStringLiteral("cost"), 3200000},
                    {QStringLiteral("dmgRed"), 60},
                    {QStringLiteral("probRed"), 95}},
        QVariantMap{{QStringLiteral("name"),
                     QStringLiteral("Станция очистки и доверенной загрузки съемных накопителей USB (ОА.009)")},
                    {QStringLiteral("type"),
                     QStringLiteral("Техническая (Приказ № 239)")},
                    {QStringLiteral("cost"), 1800000},
                    {QStringLiteral("dmgRed"), 50},
                    {QStringLiteral("probRed"), 90}},
        QVariantMap{{QStringLiteral("name"),
                     QStringLiteral("Промышленный МЭ с глубоким анализом протоколов (Modbus/Profinet DPI)")},
                    {QStringLiteral("type"),
                     QStringLiteral("Техническая (Приказ № 239)")},
                    {QStringLiteral("cost"), 2900000},
                    {QStringLiteral("dmgRed"), 70},
                    {QStringLiteral("probRed"), 75}},
        QVariantMap{{QStringLiteral("name"),
                     QStringLiteral("Система мониторинга целостности прошивок и конфигураций ПЛК (ОА.006)")},
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
                 .arg(nextNumber < 10 ? QStringLiteral("0") : QString())
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
        entity == QStringLiteral("assets") ? QStringLiteral("ACT-")
        : entity == QStringLiteral("risks") ? QStringLiteral("RSK-")
                                             : QStringLiteral("MSR-");
    const QString prefix = entityPrefix +
                           (industrial ? QStringLiteral("OT-") : QString());
    int nextNumber = 1;
    bool foundId = false;
    do {
      foundId = false;
      const QString candidate =
          prefix + (nextNumber < 10 ? QStringLiteral("0") : QString()) +
          QString::number(nextNumber++);
      for (const QVariant &value : items) {
        if (value.toMap().value(QStringLiteral("id")).toString() == candidate) {
          foundId = true;
          break;
        }
      }
      if (!foundId)
        item.insert(QStringLiteral("id"), candidate);
    } while (foundId);
    if (entity == QStringLiteral("risks")) {
      const int score = item.value(QStringLiteral("impact")).toInt() *
                        item.value(QStringLiteral("probability")).toInt() *
                        item.value(QStringLiteral("assetPriority"), 3).toInt();
      item.insert(QStringLiteral("score"), score);
      item.insert(QStringLiteral("scoreLevel"), riskLevel(score));
      item.insert(QStringLiteral("boundMeasureId"), QString());
      item.insert(QStringLiteral("boundMeasureName"),
                  QStringLiteral("Не назначена"));
      item.insert(QStringLiteral("status"),
                  score > 16 ? QStringLiteral("В плане")
                             : QStringLiteral("Принят"));
      item.insert(QStringLiteral("statusLevel"),
                  score > 16 ? QStringLiteral("high")
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
            measure.insert(QStringLiteral("statusLevel"), QStringLiteral("info"));
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
    const QVariantMap scenario = payload.value(QStringLiteral("scenario")).toMap();
    const QVariantList steps = scenario.value(QStringLiteral("steps")).toList();
    const QString assetId = payload.value(QStringLiteral("assetId")).toString();
    QVariantMap asset;
    for (const QVariant &value : m_collections.value(QStringLiteral("assets"))) {
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
      const QString riskPrefix =
          asset.value(QStringLiteral("domain")).toString() == QStringLiteral("OT")
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
          riskId = riskPrefix + QStringLiteral("%1%2")
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
            (threatCode.isEmpty() ? QString() : threatCode + QStringLiteral(": ")) +
            (threatTitle.isEmpty() ? scenario.value(QStringLiteral("title")).toString()
                                   : threatTitle) +
            QStringLiteral(" [") + scenarioCode + QStringLiteral(" · Шаг ") +
            step.value(QStringLiteral("step_number")).toString() +
            QStringLiteral("]");
        const QString status = score > 16 ? QStringLiteral("В плане")
                                          : QStringLiteral("Принят");
        QVariantMap risk =
            makeRisk(riskId, threat, threatCode,
                     step.value(QStringLiteral("description")).toString(),
                     assetId, asset.value(QStringLiteral("name")).toString(),
                     impact, probability, priority, QString(),
                     QStringLiteral("Не назначена"), status,
                     score > 16 ? QStringLiteral("high")
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
                                    const QVariantMap &scenario) {
  return sendRequest(QStringLiteral("risks.importScenario"),
                     {{QStringLiteral("scenarioCode"), scenarioCode},
                      {QStringLiteral("assetId"), assetId},
                      {QStringLiteral("scenario"), scenario}});
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
