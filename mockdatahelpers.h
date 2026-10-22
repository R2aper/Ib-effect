#pragma once

#include <QHash>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

namespace MockDataHelpers {

QString entityFromOperation(const QString &operation);
QString riskLevel(int score);
QVariantMap calculateEconomics(
    const QVariantMap &payload,
    const QHash<QString, QVariantList> &collections);
QVariantMap makeRisk(const QString &id, const QString &threat,
                     const QString &threatCode, const QString &vulnerability,
                     const QString &assetId, const QString &assetName,
                     int impact, int probability, int priority,
                     const QString &measureId, const QString &measureName,
                     const QString &status, const QString &statusLevel);
QVariantMap makeMeasure(const QString &id, const QString &name,
                        const QString &type, int cost, int damageReduction,
                        int probabilityReduction, const QString &riskId,
                        const QString &status, const QString &statusLevel);

} // namespace MockDataHelpers
