#include "RiskCalculator.h"

#include <algorithm>
#include <cmath>
#include <QLocale>

namespace {

constexpr double kCriticalThreshold = 8.0;

template <typename Enum>
Enum enumFrom(const QVariantMap &m, const char *key, Enum fallback) {
  const auto it = m.constFind(QLatin1String(key));
  return it == m.cend() ? fallback : static_cast<Enum>(it->toInt());
}

double numFrom(const QVariantMap &m, const char *key) {
  return m.value(QLatin1String(key)).toDouble();
}

bool boolFrom(const QVariantMap &m, const char *key, bool fallback) {
  const auto it = m.constFind(QLatin1String(key));
  return it == m.cend() ? fallback : it->toBool();
}

QString strFrom(const QVariantMap &m, const char *key) {
  return m.value(QLatin1String(key)).toString();
}

} // namespace

namespace RiskModel {

// ---------------------------- Коэффициенты ----------------------------

double coefficient(ComponentType v) {
  constexpr double k = 0.5;
  switch (v) {
  case ComponentType::CriticalBusiness:
    return k * 1.1; // 0.55
  case ComponentType::FirewallGateway:
    return k * 0.9; // 0.45
  case ComponentType::TelecomControl:
    return k * 0.8; // 0.40
  case ComponentType::Server:
    return k * 0.7; // 0.35
  case ComponentType::Workstation:
    return k * 0.5; // 0.25
  case ComponentType::Storage:
    return k * 0.4; // 0.20
  case ComponentType::Other:
    return k * 0.1; // 0.05
  }
  return k * 0.1;
}

double coefficient(ComponentShare v) {
  constexpr double l = 0.2;
  switch (v) {
  case ComponentShare::Over70:
    return l * 1.0; // 0.20
  case ComponentShare::From50To70:
    return l * 0.8; // 0.16
  case ComponentShare::From10To50:
    return l * 0.6; // 0.12
  case ComponentShare::Under10:
    return l * 0.5; // 0.10
  }
  return l * 0.5;
}

double coefficient(PerimeterAccess v) {
  constexpr double p = 0.3;
  switch (v) {
  case PerimeterAccess::Internet:
    return p * 1.1; // 0.33
  case PerimeterAccess::Internal:
    return p * 0.6; // 0.18
  }
  return p * 0.6;
}

double coefficient(Exploitability v) {
  constexpr double e = 1.0;
  switch (v) {
  case Exploitability::RealAttacks:
    return e * 0.60;
  case Exploitability::KnownExploit:
    return e * 0.30;
  case Exploitability::Unknown:
    return e * 0.10;
  }
  return e * 0.10;
}

double coefficient(Consequence v) {
  constexpr double h = 1.0;
  switch (v) {
  case Consequence::CodeExecOrPrivEsc:
    return h * 0.50;
  case Consequence::SecurityBypass:
    return h * 0.40;
  case Consequence::CodeInjection:
    return h * 0.34;
  case Consequence::SensitiveLeak:
    return h * 0.30;
  case Consequence::DenialOfService:
    return h * 0.26;
  case Consequence::FileOverwrite:
    return h * 0.22;
  case Consequence::LocalFileWrite:
    return h * 0.20;
  case Consequence::LocalFileRead:
    return h * 0.18;
  }
  return h * 0.18;
}

} // namespace RiskModel

// ---------------------------- Результат расчёта ----------------------------

QVariantMap RiskResult::toVariantMap() const {
  return {
      {QStringLiteral("valid"), valid},
      {QStringLiteral("error"), error},
      {QStringLiteral("assetValue"), assetValue},
      {QStringLiteral("iInfrBase"), iInfrBase},
      {QStringLiteral("iInfrResidual"), iInfrResidual},
      {QStringLiteral("vBase"), vBase},
      {QStringLiteral("vResidual"), vResidual},
      {QStringLiteral("criticalityBase"), criticalityBase},
      {QStringLiteral("criticalityResidual"), criticalityResidual},
      {QStringLiteral("probabilityBase"), probabilityBase},
      {QStringLiteral("probabilityResidual"), probabilityResidual},
      {QStringLiteral("aleBase"), aleBase},
      {QStringLiteral("aleResidual"), aleResidual},
      {QStringLiteral("avoidedLoss"), avoidedLoss},
      {QStringLiteral("netBenefit"), netBenefit},
      {QStringLiteral("rosiPercent"), rosiPercent},
  };
}

// ---------------------------- Логика расчет ----------------------------

RiskCalculator::RiskCalculator(QObject *parent) : QObject(parent) {
  initDefaultData();
  updateEconomicScenarios();
}

double RiskCalculator::vulnerabilityLevel(double iCvss, double iInfr,
                                          double iAt, double iImp) {
  return iCvss * iInfr * (iAt + iImp);
}

double RiskCalculator::calcIinfr(RiskModel::ComponentType k,
                                 RiskModel::ComponentShare l,
                                 RiskModel::PerimeterAccess p) {
  return RiskModel::coefficient(k) + RiskModel::coefficient(l) +
         RiskModel::coefficient(p);
}

QString RiskCalculator::criticalityText(double v) {
  if (v > 8.0)
    return QStringLiteral("Критический");
  if (v >= 5.0)
    return QStringLiteral("Высокий");
  if (v >= 2.0)
    return QStringLiteral("Средний");
  return QStringLiteral("Низкий");
}

QString RiskCalculator::slaFromV(double v) {
  if (v > 8.0)
    return QStringLiteral("До 24 часов");
  if (v >= 5.0)
    return QStringLiteral("До 7 дней");
  if (v >= 2.0)
    return QStringLiteral("До 4 недель");
  return QStringLiteral("До 4 месяцев");
}

double RiskCalculator::probabilityFromV(double v) {
  return std::clamp(v / kCriticalThreshold, 0.0, 1.0);
}

double RiskCalculator::calculateCVSS31(const ThreatScenario &threat) {
  return threat.cvssScore;
}

RiskResult RiskCalculator::calculate(const AssetKT &asset,
                                     const ThreatScenario &threat,
                                     const CompensatingMeasure &measure) const {
  RiskResult r;

  if (measure.costTCO <= 0.0) {
    r.error = QStringLiteral("Стоимость меры (TCO) должна быть больше нуля");
    return r;
  }
  const double cvss =
      threat.fromBDU ? threat.cvssScore : calculateCVSS31(threat);
  if (cvss < 0.0 || cvss > 10.0) {
    r.error = QStringLiteral("CVSS должен быть в диапазоне 0..10");
    return r;
  }

  const double iAt = RiskModel::coefficient(threat.exploitability);
  const double iImp = RiskModel::coefficient(threat.consequence);

  // 1. Базовый уровень V
  r.iInfrBase = calcIinfr(asset.componentType, asset.share, asset.perimeter);
  r.vBase = vulnerabilityLevel(cvss, r.iInfrBase, iAt, iImp);

  // 2. Пересчёт после применения меры
  const auto effShare = measure.affectsShare ? measure.newShare : asset.share;
  const auto effPerimeter =
      measure.affectsPerimeter ? measure.newPerimeter : asset.perimeter;
  r.iInfrResidual = calcIinfr(asset.componentType, effShare, effPerimeter);
  r.vResidual = vulnerabilityLevel(cvss, r.iInfrResidual, iAt, iImp);

  r.criticalityBase = criticalityText(r.vBase);
  r.criticalityResidual = criticalityText(r.vResidual);

  // 3. V -> вероятность
  r.probabilityBase = probabilityFromV(r.vBase);
  r.probabilityResidual = probabilityFromV(r.vResidual);

  // 4. Ожидаемый убыток
  r.assetValue = asset.totalImpactSLE();
  r.aleBase = r.assetValue * r.probabilityBase;
  r.aleResidual = r.assetValue * r.probabilityResidual;

  // 5. Затраты-выгоды, ROSI
  r.avoidedLoss = r.aleBase - r.aleResidual;
  r.netBenefit = r.avoidedLoss - measure.costTCO;
  r.rosiPercent = (measure.costTCO > 0.0) ? (r.netBenefit / measure.costTCO * 100.0) : 0.0;

  r.valid = true;
  return r;
}

QVariantMap RiskCalculator::calculateFromMap(const QVariantMap &asset,
                                             const QVariantMap &threat,
                                             const QVariantMap &measure) const {
  using namespace RiskModel;

  AssetKT a;
  a.primaryAssetName = strFrom(asset, "primaryAssetName");
  a.supportingAssetName = strFrom(asset, "supportingAssetName");
  a.directRecoveryCost = numFrom(asset, "directRecoveryCost");
  a.indirectBusinessLoss = numFrom(asset, "indirectBusinessLoss");
  a.componentType = enumFrom(asset, "componentType", ComponentType::Other);
  a.share = enumFrom(asset, "share", ComponentShare::Under10);
  a.perimeter = enumFrom(asset, "perimeter", PerimeterAccess::Internal);

  ThreatScenario t;
  t.codeBDU = strFrom(threat, "codeBDU");
  t.title = strFrom(threat, "title");
  t.fromBDU = boolFrom(threat, "fromBDU", false);
  t.cvssScore = numFrom(threat, "cvssScore");
  t.exploitability =
      enumFrom(threat, "exploitability", Exploitability::Unknown);
  t.consequence =
      enumFrom(threat, "consequence", Consequence::CodeExecOrPrivEsc);

  CompensatingMeasure m;
  m.name = strFrom(measure, "name");
  m.costTCO = numFrom(measure, "costTCO");
  m.affectsShare = boolFrom(measure, "affectsShare", false);
  m.affectsPerimeter = boolFrom(measure, "affectsPerimeter", false);
  m.newShare = enumFrom(measure, "newShare", ComponentShare::Under10);
  m.newPerimeter = enumFrom(measure, "newPerimeter", PerimeterAccess::Internal);

  const QVariantMap result = calculate(a, t, m).toVariantMap();
  emit const_cast<RiskCalculator *>(this)->calculated(result);

  return result;
}

// ---------------------------- Инициализация начальных данных ----------------------------

void RiskCalculator::initDefaultData() {
  m_assets.clear();
  m_vulnerabilities.clear();
  m_measures.clear();

  // --- Активы ---
  {
    QVariantMap a;
    a["id"] = "AST-01";
    a["primaryAssetName"] = "Клиентская база и условия контрактов";
    a["supportingAssetName"] = "srv-db01 (PostgreSQL)";
    a["directRecoveryCost"] = 1200000.0;
    a["indirectBusinessLoss"] = 6800000.0;
    a["regime98FZCompliant"] = true;
    a["componentType"] = 0; // CriticalBusiness (0.55)
    a["share"] = 1;         // From50To70 (0.16)
    a["perimeter"] = 0;     // Internet (0.33)
    a["measures"] = QStringList{"SEC-01", "Шифрование БД", "Журналирование доступа"};
    a["vulns"] = QStringList{"BDU:2025-01611"};
    m_assets.append(a);
  }
  {
    QVariantMap a;
    a["id"] = "AST-02";
    a["primaryAssetName"] = "Исходный код ядра системы и ноу-хау";
    a["supportingAssetName"] = "srv-git (GitLab Server)";
    a["directRecoveryCost"] = 3000000.0;
    a["indirectBusinessLoss"] = 7000000.0;
    a["regime98FZCompliant"] = true;
    a["componentType"] = 4; // Workstation (0.25)
    a["share"] = 0;         // Over70 (0.20)
    a["perimeter"] = 0;     // Internet (0.33)
    a["measures"] = QStringList{"SEC-02", "Двухфакторная аутентификация"};
    a["vulns"] = QStringList{"Конструктор УБИ"};
    m_assets.append(a);
  }
  {
    QVariantMap a;
    a["id"] = "AST-03";
    a["primaryAssetName"] = "БД клиентов (ПДн)";
    a["supportingAssetName"] = "srv-db02 (PostgreSQL Standby)";
    a["directRecoveryCost"] = 4500000.0;
    a["indirectBusinessLoss"] = 14000000.0;
    a["regime98FZCompliant"] = true;
    a["componentType"] = 3; // Server (0.35)
    a["share"] = 1;         // From50To70 (0.16)
    a["perimeter"] = 1;     // Internal (0.18)
    a["measures"] = QStringList{};
    a["vulns"] = QStringList{};
    m_assets.append(a);
  }
  {
    QVariantMap a;
    a["id"] = "AST-04";
    a["primaryAssetName"] = "Процессинг платежей и SCADA Node 01";
    a["supportingAssetName"] = "app-pay01 (Core Cluster)";
    a["directRecoveryCost"] = 8000000.0;
    a["indirectBusinessLoss"] = 10500000.0;
    a["regime98FZCompliant"] = true;
    a["componentType"] = 0; // CriticalBusiness (0.55)
    a["share"] = 0;         // Over70 (0.20)
    a["perimeter"] = 0;     // Internet (0.33)
    a["measures"] = QStringList{"SEC-03", "WAF", "Сегментация сети", "Резервное копирование"};
    a["vulns"] = QStringList{"BDU:2024-01928", "BDU:2023-05441"};
    m_assets.append(a);
  }
  {
    QVariantMap a;
    a["id"] = "AST-05";
    a["primaryAssetName"] = "Ключи ЭЦП Клиент-Банк";
    a["supportingAssetName"] = "ws-acc03 (АРМ бухгалтера)";
    a["directRecoveryCost"] = 1200000.0;
    a["indirectBusinessLoss"] = 3000000.0;
    a["regime98FZCompliant"] = true;
    a["componentType"] = 4; // Workstation (0.25)
    a["share"] = 3;         // Under10 (0.10)
    a["perimeter"] = 1;     // Internal (0.18)
    a["measures"] = QStringList{"SEC-04"};
    a["vulns"] = QStringList{"BDU:2023-05112"};
    m_assets.append(a);
  }

  // --- Уязвимости ---
  {
    QVariantMap v;
    v["id"] = "BDU:2025-01611";
    v["cve"] = "CVE-2024-3094";
    v["title"] = "RCE в модуле аутентификации PostgreSQL";
    v["desc"] = "Удалённое выполнение произвольного кода без предварительной авторизации через внедрение байт-кодов в подсистему валидации ключей сессий.";
    v["fromBdu"] = true;
    v["cvss"] = 8.8;
    v["vector"] = "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H";
    v["exploitability"] = 1; // KnownExploit (0.30)
    v["consequence"] = 0;    // CodeExecOrPrivEsc (0.50)
    v["eVal"] = "0.30";
    v["eStatus"] = "Есть эксплойт (0.30)";
    v["hVal"] = "0.50";
    v["hStatus"] = "H_01: Полное нарушение К, Ц, Д (0.50)";
    v["vBase"] = "4.75";
    v["level"] = "Высокий";
    v["sla"] = "До 7 дней";
    v["status"] = "Открыта";
    m_vulnerabilities.append(v);
  }
  {
    QVariantMap v;
    v["id"] = "Конструктор УБИ";
    v["cve"] = "Тактика Т9.10";
    v["title"] = "Копирование исходного кода инсайдером на съемный носитель";
    v["desc"] = "Несанкционированное копирование исходных кодов и ноу-хау увольняющимся сотрудником (нарушитель Н2) через интерфейс USB (п. 5.3.3 ФСТЭК 2021).";
    v["fromBdu"] = false;
    v["cvss"] = 5.5;
    v["vector"] = "CVSS:3.1/AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N";
    v["exploitability"] = 1; // KnownExploit (0.30)
    v["consequence"] = 3;    // SensitiveLeak (0.30)
    v["eVal"] = "0.30";
    v["eStatus"] = "Есть эксплойт (0.30)";
    v["hVal"] = "0.30";
    v["hStatus"] = "H_04: Утечка критических данных КТ (0.30)";
    v["vBase"] = "5.50";
    v["level"] = "Высокий";
    v["sla"] = "До 7 дней";
    v["status"] = "В работе";
    m_vulnerabilities.append(v);
  }
  {
    QVariantMap v;
    v["id"] = "BDU:2024-01928";
    v["cve"] = "CVE-2024-21626";
    v["title"] = "Несанкционированный доступ к БД АСУ ТП (SCADA Node 01)";
    v["desc"] = "Побег из контейнера runc с получением привилегий root на хосте ядра SCADA-системы.";
    v["fromBdu"] = true;
    v["cvss"] = 9.8;
    v["vector"] = "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H";
    v["exploitability"] = 0; // RealAttacks (0.60)
    v["consequence"] = 0;    // CodeExecOrPrivEsc (0.50)
    v["eVal"] = "0.60";
    v["eStatus"] = "Реальные атаки (0.60)";
    v["hVal"] = "0.50";
    v["hStatus"] = "H_01: Полное нарушение критических процессов (0.50)";
    v["vBase"] = "8.80";
    v["level"] = "Критический";
    v["sla"] = "До 24 часов";
    v["status"] = "Открыта";
    m_vulnerabilities.append(v);
  }
  {
    QVariantMap v;
    v["id"] = "BDU:2023-05441";
    v["cve"] = "CVE-2023-38606";
    v["title"] = "Эксфильтрация через API платёжного шлюза";
    v["desc"] = "Обход многофакторной аутентификации Kerberos SSO и выгрузка логов транзакций.";
    v["fromBdu"] = true;
    v["cvss"] = 7.5;
    v["vector"] = "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N";
    v["exploitability"] = 2; // Unknown (0.10)
    v["consequence"] = 1;    // SecurityBypass (0.40)
    v["eVal"] = "0.10";
    v["eStatus"] = "Нет сведений (0.10)";
    v["hVal"] = "0.40";
    v["hStatus"] = "H_02: Существенный сбой сервисов обработки (0.40)";
    v["vBase"] = "4.20";
    v["level"] = "Средний";
    v["sla"] = "До 4 недель";
    v["status"] = "В работе";
    m_vulnerabilities.append(v);
  }
  {
    QVariantMap v;
    v["id"] = "BDU:2023-05112";
    v["cve"] = "CVE-2023-27476";
    v["title"] = "Раскрытие отладочной информации Nginx";
    v["desc"] = "Утечка служебных метаданных конфигурации через ошибочную обработку заголовков HTTP/2.";
    v["fromBdu"] = true;
    v["cvss"] = 5.3;
    v["vector"] = "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N";
    v["exploitability"] = 2; // Unknown (0.10)
    v["consequence"] = 7;    // LocalFileRead (0.18)
    v["eVal"] = "0.10";
    v["eStatus"] = "Нет сведений (0.10)";
    v["hVal"] = "0.18";
    v["hStatus"] = "H_08: Незначительное влияние (0.18)";
    v["vBase"] = "1.90";
    v["level"] = "Низкий";
    v["sla"] = "До 4 месяцев";
    v["status"] = "Принято";
    m_vulnerabilities.append(v);
  }

  // --- Меры ---
  {
    QVariantMap m;
    m["id"] = "SEC-01";
    m["title"] = "Изоляция СУБД во внутренний сегмент + патчинг";
    m["targetVuln"] = "BDU:2025-01611";
    m["asset"] = "AST-01";
    m["measureType"] = "Архитектурная + Патч-менеджмент (п. 22, 25)";
    m["fstecClass"] = "ЗИС.2 — Межсетевое экранирование";
    m["costTCO"] = 450000.0;
    m["tcoNum"] = 450000.0;
    m["tco"] = "450 000 ₽";
    m["affectsShare"] = true;
    m["newShare"] = 3; // Under10 (0.10)
    m["affectsPerimeter"] = true;
    m["newPerimeter"] = 1; // Internal (0.18)
    m["status"] = "Внедрено";
    m_measures.append(m);
  }
  {
    QVariantMap m;
    m["id"] = "SEC-02";
    m["title"] = "Внедрение Endpoint DLP + блокировка USB-носителей";
    m["targetVuln"] = "Конструктор УБИ";
    m["asset"] = "AST-02";
    m["measureType"] = "Endpoint DLP + Контроль съемных носителей (п. 25)";
    m["fstecClass"] = "УПД.3 — Управление правами доступа и контроль утечек";
    m["costTCO"] = 600000.0;
    m["tcoNum"] = 600000.0;
    m["tco"] = "600 000 ₽";
    m["affectsShare"] = true;
    m["newShare"] = 3; // Under10 (0.10)
    m["affectsPerimeter"] = true;
    m["newPerimeter"] = 1; // Internal (0.18)
    m["status"] = "В плане";
    m_measures.append(m);
  }
  {
    QVariantMap m;
    m["id"] = "SEC-03";
    m["title"] = "Внедрение Web Application Firewall (WAF кластер) и микросегментации";
    m["targetVuln"] = "BDU:2024-01928";
    m["asset"] = "AST-04";
    m["measureType"] = "WAF L7 Inspection + Микросегментация";
    m["fstecClass"] = "ЗИС.2 — Межсетевое экранирование";
    m["costTCO"] = 2400000.0;
    m["tcoNum"] = 2400000.0;
    m["tco"] = "2 400 000 ₽";
    m["affectsShare"] = true;
    m["newShare"] = 3; // Under10 (0.10)
    m["affectsPerimeter"] = true;
    m["newPerimeter"] = 1; // Internal (0.18)
    m["status"] = "Внедрено";
    m_measures.append(m);
  }
  {
    QVariantMap m;
    m["id"] = "SEC-04";
    m["title"] = "Защищенный ключевой носитель Рутокен ЭЦП 3.0";
    m["targetVuln"] = "BDU:2023-05112";
    m["asset"] = "AST-05";
    m["measureType"] = "Аппаратная криптография + ПИН-код";
    m["fstecClass"] = "ИАФ.1 — Аутентификация";
    m["costTCO"] = 120000.0;
    m["tcoNum"] = 120000.0;
    m["tco"] = "120 000 ₽";
    m["affectsShare"] = true;
    m["newShare"] = 3; // Under10 (0.10)
    m["affectsPerimeter"] = false;
    m["newPerimeter"] = 1; // Internal (0.18)
    m["status"] = "Внедрено";
    m_measures.append(m);
  }
}

// ---------------------------- Расчет экономических сценариев ----------------------------

void RiskCalculator::updateEconomicScenarios() {
  m_economicScenarios.clear();

  double totalAvoided = 0.0;
  double totalTcoVal = 0.0;

  for (int mIdx = 0; mIdx < m_measures.size(); ++mIdx) {
    QVariantMap measure = m_measures[mIdx].toMap();
    const QString measureId = measure.value("id").toString();
    const QString measureTitle = measure.value("title").toString();
    const double tco = measure.value("costTCO", measure.value("tcoNum")).toDouble();
    const bool affectsShare = measure.value("affectsShare", true).toBool();
    const int newShare = measure.value("newShare", 3).toInt();
    const bool affectsPerimeter = measure.value("affectsPerimeter", true).toBool();
    const int newPerimeter = measure.value("newPerimeter", 1).toInt();

    // 1. Поиск привязанного актива
    QVariantMap asset;
    QString targetAssetKey = measure.value("asset").toString();
    for (const QVariant &item : m_assets) {
      QVariantMap a = item.toMap();
      if (a.value("id").toString() == targetAssetKey ||
          a.value("primaryAssetName").toString() == targetAssetKey) {
        asset = a;
        break;
      }
    }
    if (asset.isEmpty()) {
      for (const QVariant &item : m_assets) {
        QVariantMap a = item.toMap();
        QStringList ml = a.value("measures").toStringList();
        if (ml.contains(measureId) || ml.contains(measureTitle)) {
          asset = a;
          break;
        }
      }
    }
    if (asset.isEmpty() && !m_assets.isEmpty()) {
      asset = m_assets.first().toMap();
    }

    // 2. Поиск привязанной уязвимости
    QVariantMap threat;
    QString targetVulnKey = measure.value("targetVuln").toString();
    for (const QVariant &item : m_vulnerabilities) {
      QVariantMap v = item.toMap();
      if (v.value("id").toString() == targetVulnKey ||
          v.value("title").toString() == targetVulnKey ||
          v.value("cve").toString() == targetVulnKey) {
        threat = v;
        break;
      }
    }
    if (threat.isEmpty()) {
      QStringList assetThreats = asset.value("vulns").toStringList();
      for (const QVariant &item : m_vulnerabilities) {
        QVariantMap v = item.toMap();
        if (assetThreats.contains(v.value("id").toString())) {
          threat = v;
          break;
        }
      }
    }
    if (threat.isEmpty() && !m_vulnerabilities.isEmpty()) {
      threat = m_vulnerabilities.first().toMap();
    }

    // Параметры актива
    const double directCost = asset.value("directRecoveryCost").toDouble();
    const double indirectLoss = asset.value("indirectBusinessLoss").toDouble();
    const double sle = directCost + indirectLoss;
    const int compType = asset.value("componentType", 0).toInt();
    const int share = asset.value("share", 1).toInt();
    const int perimeter = asset.value("perimeter", 0).toInt();

    // Параметры угрозы
    const double cvss = threat.value("cvss", 7.5).toDouble();
    const int exploit = threat.value("exploitability", 1).toInt();
    const int consequence = threat.value("consequence", 0).toInt();

    const double iAt = RiskModel::coefficient(static_cast<RiskModel::Exploitability>(exploit));
    const double iImp = RiskModel::coefficient(static_cast<RiskModel::Consequence>(consequence));

    // Расчет до внедрения меры
    const double iInfrBase = calcIinfr(static_cast<RiskModel::ComponentType>(compType),
                                       static_cast<RiskModel::ComponentShare>(share),
                                       static_cast<RiskModel::PerimeterAccess>(perimeter));
    const double vBase = vulnerabilityLevel(cvss, iInfrBase, iAt, iImp);
    const double probBase = probabilityFromV(vBase);
    const double aleBase = sle * probBase;

    // Расчет после применения меры
    const int effShare = affectsShare ? newShare : share;
    const int effPerimeter = affectsPerimeter ? newPerimeter : perimeter;
    const double iInfrRes = calcIinfr(static_cast<RiskModel::ComponentType>(compType),
                                      static_cast<RiskModel::ComponentShare>(effShare),
                                      static_cast<RiskModel::PerimeterAccess>(effPerimeter));
    const double vRes = vulnerabilityLevel(cvss, iInfrRes, iAt, iImp);
    const double probRes = probabilityFromV(vRes);
    const double aleRes = sle * probRes;

    const double avoidedLoss = aleBase - aleRes;
    const double netBenefitVal = avoidedLoss - tco;
    const double rosiPercent = (tco > 0.0) ? (netBenefitVal / tco * 100.0) : 0.0;
    const double paybackMonths = (avoidedLoss > 0.0) ? ((tco / avoidedLoss) * 12.0) : 0.0;
    const double bcr = (tco > 0.0) ? (avoidedLoss / tco) : 0.0;
    const double deltaV = (vBase > 0.0) ? ((vRes - vBase) / vBase * 100.0) : 0.0;

    totalAvoided += avoidedLoss;
    totalTcoVal += tco;

    // Сформировать объект сценария
    QVariantMap sc;
    sc["id"] = measureId;
    sc["asset"] = asset.value("primaryAssetName").toString();
    sc["assetId"] = asset.value("id").toString();
    sc["subAsset"] = asset.value("supportingAssetName").toString();
    sc["threatId"] = threat.value("id").toString();
    sc["threatTitle"] = threat.value("title").toString();
    sc["measure"] = measureTitle;
    sc["measureId"] = measureId;

    sc["sle"] = formatRub(sle);
    sc["sleNum"] = sle;
    sc["vBase"] = vBase;
    sc["vRes"] = vRes;
    sc["criticalityBase"] = criticalityText(vBase);
    sc["criticalityResidual"] = criticalityText(vRes);
    sc["slaBase"] = slaFromV(vBase);
    sc["slaRes"] = slaFromV(vRes);

    sc["probBase"] = formatPercent(probBase * 100.0, 1);
    sc["probBaseNum"] = probBase;
    sc["probRes"] = formatPercent(probRes * 100.0, 1);
    sc["probResNum"] = probRes;
    sc["deltaProbText"] = formatPercent((probRes - probBase) * 100.0, 1);

    sc["aleBase"] = formatRub(aleBase);
    sc["aleBaseNum"] = aleBase;
    sc["aleRes"] = formatRub(aleRes);
    sc["aleResNum"] = aleRes;

    sc["tco"] = formatRub(tco);
    sc["tcoNum"] = tco;
    sc["avoidedLoss"] = formatRub(avoidedLoss);
    sc["avoidedLossNum"] = avoidedLoss;
    sc["netBenefit"] = formatRub(netBenefitVal);
    sc["netBenefitNum"] = netBenefitVal;
    sc["rosi"] = QString((rosiPercent >= 0 ? "+" : "") + formatNumber(rosiPercent, 1) + "%");
    sc["rosiNum"] = rosiPercent;

    sc["deltaV"] = deltaV;
    sc["deltaVText"] = formatPercent(deltaV, 1);
    sc["payback"] = QString::number(paybackMonths, 'f', 1) + " мес.";
    sc["bcr"] = QString::number(bcr, 'f', 2);

    const QString details = QString(
        "Сценарий: %1 / %2\n"
        "1. SLE = %3 + %4 = %5 ₽ (ст. 10 98-ФЗ: %6)\n"
        "2. I_infr_base = %7, I_cvss = %8, (I_at + I_imp) = %9\n"
        "3. V_base = %8 × %7 × %9 = %10 (%11, SLA %12)\n"
        "4. Prob_base = %10 / 8.0 = %13%  ==>  ALE_base = %5 × %13% = %14 ₽\n"
        "5. После внедрения меры: I_infr_res = %15\n"
        "6. V_res = %8 × %15 × %9 = %16 (%17, SLA %18)\n"
        "7. Prob_res = %16 / 8.0 = %19%  ==>  ALE_res = %5 × %19% = %20 ₽\n"
        "8. Предотвращенный ущерб (ΔALE) = %14 - %20 = %21 ₽\n"
        "9. Чистая выгода (Net Benefit) = %21 - %22 = %23 ₽\n"
        "10. Net ROSI = ((%21 - %22) / %22) × 100% = %24")
        .arg(asset.value("primaryAssetName").toString(), measureTitle)
        .arg(formatRub(directCost), formatRub(indirectLoss), formatRub(sle),
             asset.value("regime98FZCompliant").toBool() ? "Да" : "Нет")
        .arg(QString::number(iInfrBase, 'f', 2), QString::number(cvss, 'f', 1),
             QString::number(iAt + iImp, 'f', 2))
        .arg(QString::number(vBase, 'f', 2), criticalityText(vBase), slaFromV(vBase))
        .arg(QString::number(probBase * 100.0, 'f', 1), formatRub(aleBase))
        .arg(QString::number(iInfrRes, 'f', 2))
        .arg(QString::number(vRes, 'f', 2), criticalityText(vRes), slaFromV(vRes))
        .arg(QString::number(probRes * 100.0, 'f', 1), formatRub(aleRes))
        .arg(formatRub(avoidedLoss), formatRub(tco), formatRub(netBenefitVal))
        .arg(QString((rosiPercent >= 0 ? "+" : "") + formatNumber(rosiPercent, 1) + "%"));

    sc["formulaDetails"] = details;
    m_economicScenarios.append(sc);

    // Обновляем меру синхронными рассчитанными полями для MeasuresTab
    measure["vBase"] = QString::number(vBase, 'f', 2);
    measure["vRes"] = QString::number(vRes, 'f', 2);
    measure["levelOld"] = criticalityText(vBase);
    measure["levelNew"] = criticalityText(vRes);
    measure["deltaV"] = formatPercent(deltaV, 1);
    measure["deltaAle"] = formatRub(avoidedLoss);
    measure["netBenefit"] = formatRub(netBenefitVal);
    measure["rosi"] = QString((rosiPercent >= 0 ? "+" : "") + formatNumber(rosiPercent, 1) + "%");
    measure["iInfrOld"] = QString::number(iInfrBase, 'f', 2);
    measure["iInfrNew"] = QString::number(iInfrRes, 'f', 2);
    m_measures[mIdx] = measure;
  }

  // Общий портфельный расчет
  const double totalNetBenefit = totalAvoided - totalTcoVal;
  const double portfolioRosi = (totalTcoVal > 0.0) ? (totalNetBenefit / totalTcoVal * 100.0) : 0.0;

  m_portfolioSummary["totalAvoidedLoss"] = totalAvoided;
  m_portfolioSummary["totalAvoidedLossText"] = formatRub(totalAvoided);
  m_portfolioSummary["totalTco"] = totalTcoVal;
  m_portfolioSummary["totalTcoText"] = formatRub(totalTcoVal);
  m_portfolioSummary["netBenefit"] = totalNetBenefit;
  m_portfolioSummary["netBenefitText"] = formatRub(totalNetBenefit);
  m_portfolioSummary["portfolioRosi"] = portfolioRosi;
  m_portfolioSummary["portfolioRosiText"] = QString((portfolioRosi >= 0 ? "+" : "") + formatNumber(portfolioRosi, 1) + "%");
}

void RiskCalculator::recalculateAll() {
  updateEconomicScenarios();
  emit dataChanged();
  emit measuresChanged();
}

bool RiskCalculator::hasValidRosi() const {
  return !m_economicScenarios.isEmpty() && totalTco() > 0.0;
}

double RiskCalculator::netRosiPercent() const {
  return m_portfolioSummary.value("portfolioRosi").toDouble();
}

double RiskCalculator::netBenefit() const {
  return m_portfolioSummary.value("netBenefit").toDouble();
}

double RiskCalculator::totalAvoidedLoss() const {
  return m_portfolioSummary.value("totalAvoidedLoss").toDouble();
}

double RiskCalculator::totalTco() const {
  return m_portfolioSummary.value("totalTco").toDouble();
}

// ---------------------------- Форматирование ----------------------------

QString RiskCalculator::formatNumber(double value, int decimals) const {
  return QString::number(value, 'f', decimals);
}

QString RiskCalculator::formatRub(double value) const {
  qint64 v = static_cast<qint64>(std::round(value));
  bool negative = v < 0;
  if (negative) v = -v;

  QString s = QString::number(v);
  QString res;
  int count = 0;
  for (int i = s.length() - 1; i >= 0; --i) {
    if (count > 0 && count % 3 == 0) {
      res.prepend(QChar(0x00A0)); // неразрывный пробел
    }
    res.prepend(s[i]);
    count++;
  }
  if (negative) res.prepend(QLatin1String("-"));
  res.append(QChar(0x00A0));
  res.append(QChar(0x20BD)); // символ рубля
  return res;
}

QString RiskCalculator::formatPercent(double value, int decimals) const {
  return QString((value >= 0 ? "+" : "") + QString::number(value, 'f', decimals) + "%");
}

// ---------------------------- Управление активами ----------------------------

QVariantMap RiskCalculator::addAsset(const QVariantMap &assetData) {
  QVariantMap a = assetData;
  if (!a.contains("id") || a.value("id").toString().isEmpty()) {
    a["id"] = QStringLiteral("AST-%1").arg(m_assets.size() + 1, 2, 10, QLatin1Char('0'));
  }
  if (!a.contains("primaryAssetName") || a.value("primaryAssetName").toString().isEmpty()) {
    a["primaryAssetName"] = QStringLiteral("Новый информационный актив");
  }
  if (!a.contains("supportingAssetName")) a["supportingAssetName"] = QStringLiteral("-");
  if (!a.contains("directRecoveryCost")) a["directRecoveryCost"] = 1000000.0;
  if (!a.contains("indirectBusinessLoss")) a["indirectBusinessLoss"] = 2000000.0;
  if (!a.contains("regime98FZCompliant")) a["regime98FZCompliant"] = true;
  if (!a.contains("componentType")) a["componentType"] = 0;
  if (!a.contains("share")) a["share"] = 1;
  if (!a.contains("perimeter")) a["perimeter"] = 0;
  if (!a.contains("measures")) a["measures"] = QStringList{};
  if (!a.contains("vulns")) a["vulns"] = QStringList{};

  m_assets.append(a);
  recalculateAll();
  emit assetsChanged();
  return a;
}

bool RiskCalculator::updateAsset(const QVariantMap &assetData) {
  const QString id = assetData.value("id").toString();
  for (int i = 0; i < m_assets.size(); ++i) {
    if (m_assets[i].toMap().value("id").toString() == id) {
      QVariantMap existing = m_assets[i].toMap();
      for (auto it = assetData.cbegin(); it != assetData.cend(); ++it) {
        existing[it.key()] = it.value();
      }
      m_assets[i] = existing;
      recalculateAll();
      emit assetsChanged();
      return true;
    }
  }
  return false;
}

bool RiskCalculator::deleteAsset(const QString &id) {
  for (int i = 0; i < m_assets.size(); ++i) {
    if (m_assets[i].toMap().value("id").toString() == id) {
      m_assets.removeAt(i);
      recalculateAll();
      emit assetsChanged();
      return true;
    }
  }
  return false;
}

QVariantMap RiskCalculator::getAsset(const QString &id) const {
  for (const QVariant &item : m_assets) {
    QVariantMap a = item.toMap();
    if (a.value("id").toString() == id) return a;
  }
  return {};
}

// ---------------------------- Привязка мер и уязвимостей ----------------------------

bool RiskCalculator::linkMeasureToAsset(const QString &assetId, const QString &measureIdOrTitle) {
  for (int i = 0; i < m_assets.size(); ++i) {
    QVariantMap a = m_assets[i].toMap();
    if (a.value("id").toString() == assetId) {
      QStringList measures = a.value("measures").toStringList();
      if (!measures.contains(measureIdOrTitle)) {
        measures.append(measureIdOrTitle);
        a["measures"] = measures;
        m_assets[i] = a;

        // Связываем меру с активом
        for (int mIdx = 0; mIdx < m_measures.size(); ++mIdx) {
          QVariantMap m = m_measures[mIdx].toMap();
          if (m.value("id").toString() == measureIdOrTitle ||
              m.value("title").toString() == measureIdOrTitle) {
            m["asset"] = assetId;
            m_measures[mIdx] = m;
            break;
          }
        }
        recalculateAll();
        emit assetsChanged();
        emit measuresChanged();
        return true;
      }
    }
  }
  return false;
}

bool RiskCalculator::unlinkMeasureFromAsset(const QString &assetId, const QString &measureIdOrTitle) {
  for (int i = 0; i < m_assets.size(); ++i) {
    QVariantMap a = m_assets[i].toMap();
    if (a.value("id").toString() == assetId) {
      QStringList measures = a.value("measures").toStringList();
      if (measures.removeAll(measureIdOrTitle) > 0) {
        a["measures"] = measures;
        m_assets[i] = a;

        for (int mIdx = 0; mIdx < m_measures.size(); ++mIdx) {
          QVariantMap m = m_measures[mIdx].toMap();
          if (m.value("id").toString() == measureIdOrTitle ||
              m.value("title").toString() == measureIdOrTitle) {
            if (m.value("asset").toString() == assetId) {
              m["asset"] = QString();
              m_measures[mIdx] = m;
            }
            break;
          }
        }
        recalculateAll();
        emit assetsChanged();
        emit measuresChanged();
        return true;
      }
    }
  }
  return false;
}

bool RiskCalculator::linkVulnerabilityToAsset(const QString &assetId, const QString &vulnIdOrTitle) {
  for (int i = 0; i < m_assets.size(); ++i) {
    QVariantMap a = m_assets[i].toMap();
    if (a.value("id").toString() == assetId) {
      QStringList vulns = a.value("vulns").toStringList();
      if (!vulns.contains(vulnIdOrTitle)) {
        vulns.append(vulnIdOrTitle);
        a["vulns"] = vulns;
        m_assets[i] = a;
        recalculateAll();
        emit assetsChanged();
        emit vulnerabilitiesChanged();
        return true;
      }
    }
  }
  return false;
}

bool RiskCalculator::unlinkVulnerabilityFromAsset(const QString &assetId, const QString &vulnIdOrTitle) {
  for (int i = 0; i < m_assets.size(); ++i) {
    QVariantMap a = m_assets[i].toMap();
    if (a.value("id").toString() == assetId) {
      QStringList vulns = a.value("vulns").toStringList();
      if (vulns.removeAll(vulnIdOrTitle) > 0) {
        a["vulns"] = vulns;
        m_assets[i] = a;
        recalculateAll();
        emit assetsChanged();
        emit vulnerabilitiesChanged();
        return true;
      }
    }
  }
  return false;
}

// ---------------------------- Управление уязвимостями ----------------------------

QVariantMap RiskCalculator::addVulnerability(const QVariantMap &vulnData) {
  QVariantMap v = vulnData;
  if (!v.contains("id") || v.value("id").toString().isEmpty()) {
    v["id"] = QStringLiteral("УБИ-%1").arg(m_vulnerabilities.size() + 1, 3, 10, QLatin1Char('0'));
  }
  if (!v.contains("title") || v.value("title").toString().isEmpty()) {
    v["title"] = QStringLiteral("Новый сценарий угрозы безопасности");
  }
  if (!v.contains("cve")) v["cve"] = QStringLiteral("Тактика Т.00");
  if (!v.contains("desc")) v["desc"] = QStringLiteral("Описание сценария угрозы и условий реализации");
  if (!v.contains("cvss")) v["cvss"] = 7.5;
  if (!v.contains("vector")) v["vector"] = QStringLiteral("CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N");
  if (!v.contains("exploitability")) v["exploitability"] = 1; // KnownExploit (0.30)
  if (!v.contains("consequence")) v["consequence"] = 0;    // CodeExecOrPrivEsc (0.50)
  if (!v.contains("eVal")) v["eVal"] = "0.30";
  if (!v.contains("eStatus")) v["eStatus"] = "Есть эксплойт (0.30)";
  if (!v.contains("hVal")) v["hVal"] = "0.50";
  if (!v.contains("hStatus")) v["hStatus"] = "H_01: Полное нарушение К, Ц, Д (0.50)";
  if (!v.contains("vBase")) v["vBase"] = "5.00";
  if (!v.contains("level")) v["level"] = "Высокий";
  if (!v.contains("sla")) v["sla"] = "До 7 дней";
  if (!v.contains("status")) v["status"] = "Открыта";

  m_vulnerabilities.append(v);
  recalculateAll();
  emit vulnerabilitiesChanged();
  return v;
}

bool RiskCalculator::updateVulnerability(const QVariantMap &vulnData) {
  const QString id = vulnData.value("id").toString();
  for (int i = 0; i < m_vulnerabilities.size(); ++i) {
    if (m_vulnerabilities[i].toMap().value("id").toString() == id) {
      QVariantMap existing = m_vulnerabilities[i].toMap();
      for (auto it = vulnData.cbegin(); it != vulnData.cend(); ++it) {
        existing[it.key()] = it.value();
      }
      m_vulnerabilities[i] = existing;
      recalculateAll();
      emit vulnerabilitiesChanged();
      return true;
    }
  }
  return false;
}

bool RiskCalculator::deleteVulnerability(const QString &id) {
  for (int i = 0; i < m_vulnerabilities.size(); ++i) {
    if (m_vulnerabilities[i].toMap().value("id").toString() == id) {
      m_vulnerabilities.removeAt(i);
      // Убираем из привязок активов
      for (int aIdx = 0; aIdx < m_assets.size(); ++aIdx) {
        QVariantMap a = m_assets[aIdx].toMap();
        QStringList vl = a.value("vulns").toStringList();
        if (vl.removeAll(id) > 0) {
          a["vulns"] = vl;
          m_assets[aIdx] = a;
        }
      }
      recalculateAll();
      emit vulnerabilitiesChanged();
      emit assetsChanged();
      return true;
    }
  }
  return false;
}

QVariantMap RiskCalculator::getVulnerability(const QString &id) const {
  for (const QVariant &item : m_vulnerabilities) {
    QVariantMap v = item.toMap();
    if (v.value("id").toString() == id) return v;
  }
  return {};
}

// ---------------------------- Управление мерами ----------------------------

QVariantMap RiskCalculator::addMeasure(const QVariantMap &measureData) {
  QVariantMap m = measureData;
  if (!m.contains("id") || m.value("id").toString().isEmpty()) {
    m["id"] = QStringLiteral("SEC-%1").arg(m_measures.size() + 1, 2, 10, QLatin1Char('0'));
  }
  if (!m.contains("title") || m.value("title").toString().isEmpty()) {
    m["title"] = QStringLiteral("Новая компенсирующая мера защиты");
  }
  if (!m.contains("targetVuln")) m["targetVuln"] = !m_vulnerabilities.isEmpty() ? m_vulnerabilities.first().toMap().value("id").toString() : QString();
  if (!m.contains("asset")) m["asset"] = !m_assets.isEmpty() ? m_assets.first().toMap().value("id").toString() : QString();
  if (!m.contains("measureType")) m["measureType"] = QStringLiteral("Организационно-техническая мера");
  if (!m.contains("fstecClass")) m["fstecClass"] = QStringLiteral("ЗИС.2 — Межсетевое экранирование");
  if (!m.contains("costTCO")) m["costTCO"] = 300000.0;
  if (!m.contains("tcoNum")) m["tcoNum"] = m.value("costTCO");
  if (!m.contains("tco")) m["tco"] = formatRub(m.value("costTCO").toDouble());
  if (!m.contains("affectsShare")) m["affectsShare"] = true;
  if (!m.contains("newShare")) m["newShare"] = 3;
  if (!m.contains("affectsPerimeter")) m["affectsPerimeter"] = true;
  if (!m.contains("newPerimeter")) m["newPerimeter"] = 1;
  if (!m.contains("status")) m["status"] = QStringLiteral("В плане");

  m_measures.append(m);

  // Привязываем к активу, если указан
  QString assetId = m.value("asset").toString();
  if (!assetId.isEmpty()) {
    linkMeasureToAsset(assetId, m.value("id").toString());
  } else {
    recalculateAll();
  }
  emit measuresChanged();
  return m;
}

bool RiskCalculator::updateMeasure(const QVariantMap &measureData) {
  const QString id = measureData.value("id").toString();
  for (int i = 0; i < m_measures.size(); ++i) {
    if (m_measures[i].toMap().value("id").toString() == id) {
      QVariantMap existing = m_measures[i].toMap();
      for (auto it = measureData.cbegin(); it != measureData.cend(); ++it) {
        existing[it.key()] = it.value();
      }
      if (existing.contains("costTCO")) {
        existing["tcoNum"] = existing["costTCO"];
        existing["tco"] = formatRub(existing["costTCO"].toDouble());
      }
      m_measures[i] = existing;
      recalculateAll();
      emit measuresChanged();
      return true;
    }
  }
  return false;
}

bool RiskCalculator::deleteMeasure(const QString &id) {
  for (int i = 0; i < m_measures.size(); ++i) {
    if (m_measures[i].toMap().value("id").toString() == id) {
      m_measures.removeAt(i);
      // Убираем из привязок активов
      for (int aIdx = 0; aIdx < m_assets.size(); ++aIdx) {
        QVariantMap a = m_assets[aIdx].toMap();
        QStringList ml = a.value("measures").toStringList();
        if (ml.removeAll(id) > 0) {
          a["measures"] = ml;
          m_assets[aIdx] = a;
        }
      }
      recalculateAll();
      emit measuresChanged();
      emit assetsChanged();
      return true;
    }
  }
  return false;
}

QVariantMap RiskCalculator::getMeasure(const QString &id) const {
  for (const QVariant &item : m_measures) {
    QVariantMap m = item.toMap();
    if (m.value("id").toString() == id) return m;
  }
  return {};
}
