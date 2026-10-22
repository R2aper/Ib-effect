#include "mockdatahelpers.h"

#include <QtMath>

namespace MockDataHelpers {



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
    risk.insert(QStringLiteral("score"), score);
    risk.insert(QStringLiteral("scoreLevel"), level);
    risk.insert(QStringLiteral("scoreLevelName"),
                riskLevelName(level));

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
    const QString residualLevel = riskLevel(residualScore);
    risk.insert(QStringLiteral("inherentScore"), score);
    risk.insert(QStringLiteral("residualScore"), residualScore);
    risk.insert(QStringLiteral("residualScoreLevel"), residualLevel);
    risk.insert(QStringLiteral("residualScoreLevelName"),
                riskLevelName(residualLevel));
    risk.insert(QStringLiteral("appetiteExceeded"),
                residualScore > riskAppetite);
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

} // namespace MockDataHelpers
