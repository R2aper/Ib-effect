#include "RiskCalculator.h"

#include <QDebug>
#include <QLocale>
#include <QSet>
#include <algorithm>
#include <cmath>

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

// Уникальный id вида PREFIX-NN. Нельзя брать size()+1: после удаления
// записи такой id уже может существовать (а в БД id - первичный ключ).
QString makeUniqueId(const QString &prefix, int width,
                     const QVariantList &list) {
  QSet<QString> used;
  for (const QVariant &item : list)
    used.insert(item.toMap().value(QStringLiteral("id")).toString());
  int n = list.size() + 1;
  QString id;
  do {
    id = prefix + QStringLiteral("%1").arg(n++, width, 10, QLatin1Char('0'));
  } while (used.contains(id));
  return id;
}

// Индекс сущности по id (или по заголовку); -1, если не найдена
int findIndex(const QVariantList &list, const QString &idOrTitle,
              bool alsoByTitle) {
  for (int i = 0; i < list.size(); ++i) {
    const QVariantMap m = list[i].toMap();
    if (m.value(QStringLiteral("id")).toString() == idOrTitle ||
        (alsoByTitle &&
         m.value(QStringLiteral("title")).toString() == idOrTitle))
      return i;
  }
  return -1;
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

RiskCalculator::RiskCalculator(QObject *parent)
    : RiskCalculator(RiskStorage::defaultPath(), parent) {}

RiskCalculator::RiskCalculator(const QString &storagePath, QObject *parent)
    : QObject(parent) {
  initDefaultData();
  if (m_storage.open(storagePath)) {
    loadFromStorage();
  } else {
    // Приложение продолжает работать, но без сохранения данных
    qWarning() << "[RiskCalculator] storage unavailable:"
               << m_storage.lastError();
  }
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
  r.rosiPercent =
      (measure.costTCO > 0.0) ? (r.netBenefit / measure.costTCO * 100.0) : 0.0;

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

// ---------------------------- Инициализация начальных данных
// ----------------------------

void RiskCalculator::initDefaultData() {
  m_assets.clear();
  m_vulnerabilities.clear();
  m_measures.clear();
}

// ---------------------------- Расчет экономических сценариев
// ----------------------------

void RiskCalculator::updateEconomicScenarios() {
  m_economicScenarios.clear();

  double totalAvoided = 0.0;
  double totalTcoVal = 0.0;

  for (int mIdx = 0; mIdx < m_measures.size(); ++mIdx) {
    QVariantMap measure = m_measures[mIdx].toMap();
    const QString measureId = measure.value("id").toString();
    const QString measureTitle = measure.value("title").toString();
    const double tco =
        measure.value("costTCO", measure.value("tcoNum")).toDouble();
    const bool affectsShare = measure.value("affectsShare", true).toBool();
    const int newShare = measure.value("newShare", 3).toInt();
    const bool affectsPerimeter =
        measure.value("affectsPerimeter", true).toBool();
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

    const double iAt =
        RiskModel::coefficient(static_cast<RiskModel::Exploitability>(exploit));
    const double iImp = RiskModel::coefficient(
        static_cast<RiskModel::Consequence>(consequence));

    // Расчет до внедрения меры
    const double iInfrBase =
        calcIinfr(static_cast<RiskModel::ComponentType>(compType),
                  static_cast<RiskModel::ComponentShare>(share),
                  static_cast<RiskModel::PerimeterAccess>(perimeter));
    const double vBase = vulnerabilityLevel(cvss, iInfrBase, iAt, iImp);
    const double probBase = probabilityFromV(vBase);
    const double aleBase = sle * probBase;

    // Расчет после применения меры
    const int effShare = affectsShare ? newShare : share;
    const int effPerimeter = affectsPerimeter ? newPerimeter : perimeter;
    const double iInfrRes =
        calcIinfr(static_cast<RiskModel::ComponentType>(compType),
                  static_cast<RiskModel::ComponentShare>(effShare),
                  static_cast<RiskModel::PerimeterAccess>(effPerimeter));
    const double vRes = vulnerabilityLevel(cvss, iInfrRes, iAt, iImp);
    const double probRes = probabilityFromV(vRes);
    const double aleRes = sle * probRes;

    const double avoidedLoss = aleBase - aleRes;
    const double netBenefitVal = avoidedLoss - tco;
    const double rosiPercent =
        (tco > 0.0) ? (netBenefitVal / tco * 100.0) : 0.0;
    const double paybackMonths =
        (avoidedLoss > 0.0) ? ((tco / avoidedLoss) * 12.0) : 0.0;
    const double bcr = (tco > 0.0) ? (avoidedLoss / tco) : 0.0;
    const double deltaV =
        (vBase > 0.0) ? ((vRes - vBase) / vBase * 100.0) : 0.0;

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
    sc["rosi"] = QString((rosiPercent >= 0 ? "+" : "") +
                         formatNumber(rosiPercent, 1) + "%");
    sc["rosiNum"] = rosiPercent;

    sc["deltaV"] = deltaV;
    sc["deltaVText"] = formatPercent(deltaV, 1);
    sc["payback"] = QString::number(paybackMonths, 'f', 1) + " мес.";
    sc["bcr"] = QString::number(bcr, 'f', 2);

    const QString details =
        QString(
            "Сценарий: %1 / %2\n\n"
            "1. Единичный ущерб от инцидента (SLE):\n"
            "   SLE = Прямой ущерб (%3 ₽) + Косвенный ущерб (%4 ₽) = %5 ₽\n"
            "   (соблюдение режима коммерческой тайны по ст. 10 98-ФЗ: %6)\n\n"
            "2. Параметры риска до внедрения меры:\n"
            "   • Параметр инфраструктуры (I_инфр_до) = %7 (Таблица 1 ФСТЭК "
            "2025)\n"
            "   • Базовая метрика CVSS (I_cvss) = %8\n"
            "   • Метрики реализации атаки и последствий (I_экспл + I_посл) = "
            "%9\n\n"
            "3. Базовый уровень критичности уязвимости (V_базовый):\n"
            "   V_баз = %8 × %7 × %9 = %10 (%11, регламентный срок устранения "
            "SLA: %12)\n\n"
            "4. Ожидаемый годовой ущерб до внедрения меры (ALE_до):\n"
            "   • Вероятность реализации в год (P_до) = %10 / 8.0 = %13%\n"
            "   • Ожидаемые годовые потери (ALE_до) = %5 ₽ × %13% = %14 "
            "₽/год\n\n"
            "5. Изменение инфраструктуры после внедрения меры:\n"
            "   • Новый параметр инфраструктуры (I_инфр_после) = %15 (снижение "
            "доли уязвимых узлов / изоляция)\n\n"
            "6. Остаточный уровень критичности уязвимости (V_остаточный):\n"
            "   V_ост = %8 × %15 × %9 = %16 (%17, регламентный срок устранения "
            "SLA: %18)\n\n"
            "7. Ожидаемый годовой ущерб после применения меры (ALE_после):\n"
            "   • Новая вероятность реализации в год (P_после) = %16 / 8.0 = "
            "%19%\n"
            "   • Остаточные годовые потери (ALE_после) = %5 ₽ × %19% = %20 "
            "₽/год\n\n"
            "8. Предотвращенный годовой ущерб (ΔALE / Avoided Loss):\n"
            "   Предотвращенный ущерб = ALE_до (%14 ₽) - ALE_после (%20 ₽) = "
            "%21 ₽/год\n\n"
            "9. Совокупная годовая стоимость владения мерой защиты (TCO):\n"
            "   Затраты на меру (TCO) = %22 ₽/год\n\n"
            "10. Чистая экономическая выгода от внедрения (Net Benefit):\n"
            "   Чистая выгода = Предотвращенный ущерб (%21 ₽) - TCO (%22 ₽) = "
            "%23 ₽/год\n\n"
            "11. Рентабельность инвестиций в ИБ (Net ROSI):\n"
            "   Net ROSI = ((Предотвращенный ущерб - TCO) / TCO) × 100% = %24")
            .arg(asset.value("primaryAssetName").toString(), measureTitle)
            .arg(formatRub(directCost), formatRub(indirectLoss), formatRub(sle),
                 asset.value("regime98FZCompliant").toBool() ? "Да" : "Нет")
            .arg(QString::number(iInfrBase, 'f', 2),
                 QString::number(cvss, 'f', 1),
                 QString::number(iAt + iImp, 'f', 2))
            .arg(QString::number(vBase, 'f', 2), criticalityText(vBase),
                 slaFromV(vBase))
            .arg(QString::number(probBase * 100.0, 'f', 1), formatRub(aleBase))
            .arg(QString::number(iInfrRes, 'f', 2))
            .arg(QString::number(vRes, 'f', 2), criticalityText(vRes),
                 slaFromV(vRes))
            .arg(QString::number(probRes * 100.0, 'f', 1), formatRub(aleRes))
            .arg(formatRub(avoidedLoss), formatRub(tco),
                 formatRub(netBenefitVal))
            .arg(QString((rosiPercent >= 0 ? "+" : "") +
                         formatNumber(rosiPercent, 1) + "%"));

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
    measure["rosi"] = QString((rosiPercent >= 0 ? "+" : "") +
                              formatNumber(rosiPercent, 1) + "%");
    measure["iInfrOld"] = QString::number(iInfrBase, 'f', 2);
    measure["iInfrNew"] = QString::number(iInfrRes, 'f', 2);
    measure["oldShare"] =
        share == 0
            ? QStringLiteral("> 70% (0.20)")
            : (share == 1 ? QStringLiteral("50-70% (0.16)")
                          : (share == 2 ? QStringLiteral("10-50% (0.12)")
                                        : QStringLiteral("< 10% (0.10)")));
    measure["oldPerimeter"] = perimeter == 0
                                  ? QStringLiteral("Доступно (0.33)")
                                  : QStringLiteral("Недоступно (0.18)");
    m_measures[mIdx] = measure;
  }

  // Общий портфельный расчет
  const double totalNetBenefit = totalAvoided - totalTcoVal;
  const double portfolioRosi =
      (totalTcoVal > 0.0) ? (totalNetBenefit / totalTcoVal * 100.0) : 0.0;

  m_portfolioSummary["totalAvoidedLoss"] = totalAvoided;
  m_portfolioSummary["totalAvoidedLossText"] = formatRub(totalAvoided);
  m_portfolioSummary["totalTco"] = totalTcoVal;
  m_portfolioSummary["totalTcoText"] = formatRub(totalTcoVal);
  m_portfolioSummary["netBenefit"] = totalNetBenefit;
  m_portfolioSummary["netBenefitText"] = formatRub(totalNetBenefit);
  m_portfolioSummary["portfolioRosi"] = portfolioRosi;
  m_portfolioSummary["portfolioRosiText"] = QString(
      (portfolioRosi >= 0 ? "+" : "") + formatNumber(portfolioRosi, 1) + "%");
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
  if (negative)
    v = -v;

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
  if (negative)
    res.prepend(QLatin1String("-"));
  res.append(QChar(0x00A0));
  res.append(QChar(0x20BD)); // символ рубля
  return res;
}

QString RiskCalculator::formatPercent(double value, int decimals) const {
  return QString((value >= 0 ? "+" : "") +
                 QString::number(value, 'f', decimals) + "%");
}

// ---------------------------- Управление активами ----------------------------

QVariantMap RiskCalculator::addAsset(const QVariantMap &assetData) {
  QVariantMap a = assetData;
  if (!a.contains("id") || a.value("id").toString().isEmpty()) {
    a["id"] = makeUniqueId(QStringLiteral("AST-"), 2, m_assets);
  }
  if (!a.contains("primaryAssetName") ||
      a.value("primaryAssetName").toString().isEmpty()) {
    a["primaryAssetName"] = QStringLiteral("Новый информационный актив");
  }
  if (!a.contains("supportingAssetName"))
    a["supportingAssetName"] = QStringLiteral("-");
  if (!a.contains("directRecoveryCost"))
    a["directRecoveryCost"] = 1000000.0;
  if (!a.contains("indirectBusinessLoss"))
    a["indirectBusinessLoss"] = 2000000.0;
  if (!a.contains("regime98FZCompliant"))
    a["regime98FZCompliant"] = true;
  if (!a.contains("componentType"))
    a["componentType"] = 0;
  if (!a.contains("share"))
    a["share"] = 1;
  if (!a.contains("perimeter"))
    a["perimeter"] = 0;
  if (!a.contains("measures"))
    a["measures"] = QStringList{};
  if (!a.contains("vulns"))
    a["vulns"] = QStringList{};

  m_assets.append(a);
  persist(RiskStorage::Entity::Asset, a);
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
      persist(RiskStorage::Entity::Asset, existing);
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
      forget(RiskStorage::Entity::Asset, id);
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
    if (a.value("id").toString() == id)
      return a;
  }
  return {};
}

// ---------------------------- Привязка мер и уязвимостей
// ----------------------------

bool RiskCalculator::linkMeasureToAsset(const QString &assetId,
                                        const QString &measureIdOrTitle) {
  const int aIdx = findIndex(m_assets, assetId, false);
  const int mIdx = findIndex(m_measures, measureIdOrTitle, true);
  if (aIdx < 0 || mIdx < 0)
    return false;

  QVariantMap a = m_assets[aIdx].toMap();
  QVariantMap m = m_measures[mIdx].toMap();
  const QString measureId = m.value("id").toString();

  QStringList linked = a.value("measures").toStringList();
  if (linked.contains(measureId))
    return false;
  linked.append(measureId);
  a["measures"] = linked;
  m["asset"] = assetId;
  m_assets[aIdx] = a;
  m_measures[mIdx] = m;

  persist(RiskStorage::Entity::Measure, m);
  persist(RiskStorage::Entity::Asset, a);
  recalculateAll();
  emit assetsChanged();
  emit measuresChanged();
  return true;
}

bool RiskCalculator::unlinkMeasureFromAsset(const QString &assetId,
                                            const QString &measureIdOrTitle) {
  const int aIdx = findIndex(m_assets, assetId, false);
  if (aIdx < 0)
    return false;
  const int mIdx = findIndex(m_measures, measureIdOrTitle, true);
  const QString measureId =
      mIdx >= 0 ? m_measures[mIdx].toMap().value("id").toString()
                : measureIdOrTitle;

  QVariantMap a = m_assets[aIdx].toMap();
  QStringList linked = a.value("measures").toStringList();
  if (linked.removeAll(measureId) == 0)
    return false;
  a["measures"] = linked;
  m_assets[aIdx] = a;
  persist(RiskStorage::Entity::Asset, a);

  if (mIdx >= 0) {
    QVariantMap m = m_measures[mIdx].toMap();
    if (m.value("asset").toString() == assetId) {
      m["asset"] = QString();
      m_measures[mIdx] = m;
      persist(RiskStorage::Entity::Measure, m);
    }
  }
  recalculateAll();
  emit assetsChanged();
  emit measuresChanged();
  return true;
}

bool RiskCalculator::linkVulnerabilityToAsset(const QString &assetId,
                                              const QString &vulnIdOrTitle) {
  const int aIdx = findIndex(m_assets, assetId, false);
  const int vIdx = findIndex(m_vulnerabilities, vulnIdOrTitle, true);
  if (aIdx < 0 || vIdx < 0)
    return false;

  QVariantMap a = m_assets[aIdx].toMap();
  const QString vulnId = m_vulnerabilities[vIdx].toMap().value("id").toString();

  QStringList linked = a.value("vulns").toStringList();
  if (linked.contains(vulnId))
    return false;
  linked.append(vulnId);
  a["vulns"] = linked;
  m_assets[aIdx] = a;

  persist(RiskStorage::Entity::Asset, a);
  recalculateAll();
  emit assetsChanged();
  emit vulnerabilitiesChanged();
  return true;
}

bool RiskCalculator::unlinkVulnerabilityFromAsset(
    const QString &assetId, const QString &vulnIdOrTitle) {
  const int aIdx = findIndex(m_assets, assetId, false);
  if (aIdx < 0)
    return false;
  const int vIdx = findIndex(m_vulnerabilities, vulnIdOrTitle, true);
  const QString vulnId =
      vIdx >= 0 ? m_vulnerabilities[vIdx].toMap().value("id").toString()
                : vulnIdOrTitle;

  QVariantMap a = m_assets[aIdx].toMap();
  QStringList linked = a.value("vulns").toStringList();
  if (linked.removeAll(vulnId) == 0)
    return false;
  a["vulns"] = linked;
  m_assets[aIdx] = a;

  persist(RiskStorage::Entity::Asset, a);
  recalculateAll();
  emit assetsChanged();
  emit vulnerabilitiesChanged();
  return true;
}

// ---------------------------- Управление уязвимостями
// ----------------------------

QVariantMap RiskCalculator::addVulnerability(const QVariantMap &vulnData) {
  QVariantMap v = vulnData;
  if (!v.contains("id") || v.value("id").toString().isEmpty()) {
    v["id"] = makeUniqueId(QStringLiteral("УБИ-"), 3, m_vulnerabilities);
  }
  if (!v.contains("title") || v.value("title").toString().isEmpty()) {
    v["title"] = QStringLiteral("Новый сценарий угрозы безопасности");
  }
  if (!v.contains("cve"))
    v["cve"] = QStringLiteral("Тактика Т.00");
  if (!v.contains("desc"))
    v["desc"] = QStringLiteral("Описание сценария угрозы и условий реализации");
  if (!v.contains("cvss"))
    v["cvss"] = 7.5;
  if (!v.contains("vector"))
    v["vector"] =
        QStringLiteral("CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N");
  if (!v.contains("exploitability"))
    v["exploitability"] = 1; // KnownExploit (0.30)
  if (!v.contains("consequence"))
    v["consequence"] = 0; // CodeExecOrPrivEsc (0.50)
  if (!v.contains("eVal"))
    v["eVal"] = "0.30";
  if (!v.contains("eStatus"))
    v["eStatus"] = "Есть эксплойт (0.30)";
  if (!v.contains("hVal"))
    v["hVal"] = "0.50";
  if (!v.contains("hStatus"))
    v["hStatus"] = "H_01: Полное нарушение К, Ц, Д (0.50)";
  if (!v.contains("vBase"))
    v["vBase"] = "5.00";
  if (!v.contains("level"))
    v["level"] = "Высокий";
  if (!v.contains("sla"))
    v["sla"] = "До 7 дней";
  if (!v.contains("status"))
    v["status"] = "Открыта";

  m_vulnerabilities.append(v);
  persist(RiskStorage::Entity::Vulnerability, v);
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
      persist(RiskStorage::Entity::Vulnerability, existing);
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
      forget(RiskStorage::Entity::Vulnerability,
             id); // связи удаляются каскадно
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
    if (v.value("id").toString() == id)
      return v;
  }
  return {};
}

// ---------------------------- Управление мерами ----------------------------

QVariantMap RiskCalculator::addMeasure(const QVariantMap &measureData) {
  QVariantMap m = measureData;
  if (!m.contains("id") || m.value("id").toString().isEmpty()) {
    m["id"] = makeUniqueId(QStringLiteral("SEC-"), 2, m_measures);
  }
  if (!m.contains("title") || m.value("title").toString().isEmpty()) {
    m["title"] = QStringLiteral("Новая компенсирующая мера защиты");
  }
  if (!m.contains("targetVuln"))
    m["targetVuln"] =
        !m_vulnerabilities.isEmpty()
            ? m_vulnerabilities.first().toMap().value("id").toString()
            : QString();
  if (!m.contains("asset"))
    m["asset"] = !m_assets.isEmpty()
                     ? m_assets.first().toMap().value("id").toString()
                     : QString();
  if (!m.contains("measureType"))
    m["measureType"] = QStringLiteral("Организационно-техническая мера");
  if (!m.contains("fstecClass"))
    m["fstecClass"] = QStringLiteral("ЗИС.2 — Межсетевое экранирование");
  if (!m.contains("costTCO"))
    m["costTCO"] = 300000.0;
  if (!m.contains("tcoNum"))
    m["tcoNum"] = m.value("costTCO");
  if (!m.contains("tco"))
    m["tco"] = formatRub(m.value("costTCO").toDouble());
  if (!m.contains("affectsShare"))
    m["affectsShare"] = true;
  if (!m.contains("newShare"))
    m["newShare"] = 3;
  if (!m.contains("affectsPerimeter"))
    m["affectsPerimeter"] = true;
  if (!m.contains("newPerimeter"))
    m["newPerimeter"] = 1;
  if (!m.contains("status"))
    m["status"] = QStringLiteral("В плане");

  m_measures.append(m);
  persist(RiskStorage::Entity::Measure,
          m); // до привязки: связь ссылается на меру

  // Привязываем к активу, если указан
  QString assetId = m.value("asset").toString();
  if (!assetId.isEmpty()) {
    if (!linkMeasureToAsset(assetId, m.value("id").toString()))
      recalculateAll();
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
      if (measureData.contains("costTCO")) {
        double cost = measureData["costTCO"].toDouble();
        existing["costTCO"] = cost;
        existing["tcoNum"] = cost;
        existing["tco"] = formatRub(cost);
      } else if (measureData.contains("tcoNum")) {
        double cost = measureData["tcoNum"].toDouble();
        existing["costTCO"] = cost;
        existing["tcoNum"] = cost;
        existing["tco"] = formatRub(cost);
      } else if (measureData.contains("tco")) {
        QString str = measureData["tco"].toString();
        str.remove(' ').remove(QString::fromUtf8("₽"));
        double cost = str.toDouble();
        existing["costTCO"] = cost;
        existing["tcoNum"] = cost;
        existing["tco"] = formatRub(cost);
      }
      m_measures[i] = existing;
      persist(RiskStorage::Entity::Measure, existing);

      QString assetId = existing.value("asset").toString();
      if (!assetId.isEmpty()) {
        for (int aIdx = 0; aIdx < m_assets.size(); ++aIdx) {
          QVariantMap a = m_assets[aIdx].toMap();
          if (a.value("id").toString() != assetId) {
            QStringList ml = a.value("measures").toStringList();
            if (ml.removeAll(id) > 0) {
              a["measures"] = ml;
              m_assets[aIdx] = a;
              persist(RiskStorage::Entity::Asset, a);
            }
          }
        }
        linkMeasureToAsset(assetId, id);
      }

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
      forget(RiskStorage::Entity::Measure, id); // связи удаляются каскадно
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
    if (m.value("id").toString() == id)
      return m;
  }
  return {};
}

// ---------------------------- Интеграция с БДУ ФСТЭК (bdu.sqlite)
// ----------------------------

QVariantList RiskCalculator::searchBdu(const QString &query, int severityFilter,
                                       int limit) {
  QVariantList list = m_bduDb.search(query, severityFilter, limit);
  for (int i = 0; i < list.size(); ++i) {
    QVariantMap item = list[i].toMap();
    const QString id = item.value(QStringLiteral("id")).toString();
    item[QStringLiteral("alreadyImported")] = isBduVulnerabilityImported(id);
    list[i] = item;
  }
  return list;
}

QVariantMap RiskCalculator::getBduDetails(const QString &bduId) {
  QVariantMap details = m_bduDb.getVulnerability(bduId);
  details[QStringLiteral("alreadyImported")] =
      isBduVulnerabilityImported(bduId);
  return details;
}

bool RiskCalculator::isBduVulnerabilityImported(const QString &bduId) const {
  const QString target = bduId.trimmed().toUpper();
  if (target.isEmpty())
    return false;
  for (const QVariant &item : m_vulnerabilities) {
    const QString id =
        item.toMap().value(QStringLiteral("id")).toString().trimmed().toUpper();
    if (id == target)
      return true;
  }
  return false;
}

QVariantMap RiskCalculator::importFromBdu(const QString &bduId) {
  const QString id = bduId.trimmed();
  if (id.isEmpty())
    return {};

  // Если уже импортирована, возвращаем существующую
  for (const QVariant &item : m_vulnerabilities) {
    QVariantMap v = item.toMap();
    if (v.value(QStringLiteral("id"))
            .toString()
            .compare(id, Qt::CaseInsensitive) == 0) {
      return v;
    }
  }

  // Получаем запись из базы данных БДУ
  QVariantMap bduRec = m_bduDb.getVulnerability(id);
  if (bduRec.isEmpty()) {
    qWarning() << "[RiskCalculator] BDU vulnerability not found in database:"
               << id;
    return {};
  }

  QVariantMap v;
  v[QStringLiteral("id")] = bduRec.value(QStringLiteral("id")).toString();
  v[QStringLiteral("title")] = bduRec.value(QStringLiteral("title")).toString();
  v[QStringLiteral("desc")] =
      bduRec.value(QStringLiteral("description")).toString();
  v[QStringLiteral("cve")] = bduRec.value(QStringLiteral("cve")).toString();
  if (v[QStringLiteral("cve")].toString().isEmpty() ||
      v[QStringLiteral("cve")].toString() == QStringLiteral("—")) {
    v[QStringLiteral("cve")] = QStringLiteral("Тактика Т.00");
  }
  v[QStringLiteral("fromBdu")] = true;

  const double cvss = bduRec.value(QStringLiteral("cvss")).toDouble();
  v[QStringLiteral("cvss")] = cvss > 0.0 ? cvss : 7.5;
  v[QStringLiteral("vector")] =
      bduRec.value(QStringLiteral("cvssVector")).toString();
  if (v[QStringLiteral("vector")].toString().isEmpty()) {
    v[QStringLiteral("vector")] =
        QStringLiteral("CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H");
  }

  const bool hasExploit = bduRec.value(QStringLiteral("hasExploit")).toBool();
  v[QStringLiteral("exploitability")] = hasExploit ? 1 : 2;
  v[QStringLiteral("consequence")] = 0;

  const double eCoeff = hasExploit ? 0.30 : 0.10;
  const double hCoeff = 0.50;
  v[QStringLiteral("eVal")] = QString::number(eCoeff, 'f', 2);
  v[QStringLiteral("eStatus")] = hasExploit
                                     ? QStringLiteral("Есть эксплойт (0.30)")
                                     : QStringLiteral("Нет сведений (0.10)");
  v[QStringLiteral("hVal")] = QString::number(hCoeff, 'f', 2);
  v[QStringLiteral("hStatus")] =
      QStringLiteral("H_01: Полное нарушение К, Ц, Д (0.50)");

  // Вычисляем V_base согласно методике ФСТЭК 2025
  const double vBase = vulnerabilityLevel(v[QStringLiteral("cvss")].toDouble(),
                                          0.5, eCoeff, hCoeff);
  v[QStringLiteral("vBase")] = QString::number(vBase, 'f', 2);
  v[QStringLiteral("level")] = criticalityText(vBase);
  v[QStringLiteral("sla")] = slaFromV(vBase);
  v[QStringLiteral("status")] = QStringLiteral("Открыта");

  v[QStringLiteral("software")] =
      bduRec.value(QStringLiteral("software")).toString();
  v[QStringLiteral("vendor")] =
      bduRec.value(QStringLiteral("vendor")).toString();
  v[QStringLiteral("solution")] =
      bduRec.value(QStringLiteral("solution")).toString();
  v[QStringLiteral("identifyDate")] =
      bduRec.value(QStringLiteral("identifyDate")).toString();

  m_vulnerabilities.append(v);
  persist(RiskStorage::Entity::Vulnerability, v);
  recalculateAll();
  emit vulnerabilitiesChanged();
  return v;
}

// ---------------------------- Локальное хранилище (SQLite)
// ----------------------------

void RiskCalculator::loadFromStorage() {
  m_assets = m_storage.load(RiskStorage::Entity::Asset);
  m_vulnerabilities = m_storage.load(RiskStorage::Entity::Vulnerability);
  m_measures = m_storage.load(RiskStorage::Entity::Measure);

  // Поля стоимости, которые UI читает в разных форматах
  for (int i = 0; i < m_measures.size(); ++i) {
    QVariantMap m = m_measures[i].toMap();
    const double cost = m.value("costTCO").toDouble();
    m["tcoNum"] = cost;
    m["tco"] = formatRub(cost);
    m_measures[i] = m;
  }
}

void RiskCalculator::persist(RiskStorage::Entity entity,
                             const QVariantMap &data) {
  if (!m_storage.isOpen())
    return;
  if (!m_storage.save(entity, data))
    reportStorageError();
}

void RiskCalculator::forget(RiskStorage::Entity entity, const QString &id) {
  if (!m_storage.isOpen())
    return;
  if (!m_storage.remove(entity, id))
    reportStorageError();
}

void RiskCalculator::reportStorageError() {
  emit storageError(m_storage.lastError());
}

void RiskCalculator::clearAllData() {
  m_assets.clear();
  m_vulnerabilities.clear();
  m_measures.clear();
  if (m_storage.isOpen() && !m_storage.clearAll())
    reportStorageError();
  recalculateAll();
  emit assetsChanged();
  emit vulnerabilitiesChanged();
  emit measuresChanged();
}