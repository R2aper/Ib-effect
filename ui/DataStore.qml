pragma Singleton

import QtQuick

QtObject {
    id: store

    // Модели потерь от простоя (Downtime Economics)
    property real downtimeHourlyCost: 1500000 // 1 500 000 руб/час аварийного простоя линии
    property real mttrHours: 8 // 8 часов среднего времени восстановления (MTTR)
    property real potentialDowntimeLoss: downtimeHourlyCost * mttrHours

    function setDowntimeModel(costPerHour, hours) {
        downtimeHourlyCost = Math.max(0, costPerHour);
        mttrHours = Math.max(1, hours);
        potentialDowntimeLoss = downtimeHourlyCost * mttrHours;
        recalculateAll();
    }

    // --- ПАРАМЕТРЫ КРИТЕРИЕВ И БАЛЛЬНОЙ СИСТЕМЫ (ГОСТ Р ИСО/МЭК 27005-2010, ГОСТ Р 59339-2021) ---
    property int riskAppetite: 16
    property real pointCost: 250000
    property int scoreLowMax: 8
    property int scoreMedMax: 16
    property int scoreHighMax: 32

    function saveCriteria(appetite, pCost) {
        riskAppetite = appetite;
        pointCost = pCost;
        recalculateAll();
    }

    function getLevelByScore(score) {
        if (score > scoreHighMax) return "critical";
        if (score > scoreMedMax) return "high";
        if (score > scoreLowMax) return "medium";
        return "low";
    }

    function getLevelName(level) {
        switch (level) {
            case "critical": return "Критический";
            case "high": return "Высокий";
            case "medium": return "Средний";
            default: return "Низкий";
        }
    }

    // Legacy snapshot retained for the not-yet-migrated economics page.

    // 1. Активы
    property var assetsList: [
        { id: "ACT-01", name: "Автоматизированная банковская система (АБС)", cat: "Информ. система", cost: 24000000, prio: 4, oaCode: "ОА.003", oaTitle: "Промышленный сервер", domain: "IT", status: "На защите", statusLevel: "success" },
        { id: "ACT-02", name: "Центральная СУБД PostgreSQL (Клиентские данные)", cat: "База данных", cost: 12500000, prio: 4, oaCode: "ОА.004", oaTitle: "Сервер архивов / баз данных", domain: "IT", status: "На защите", statusLevel: "success" },
        { id: "ACT-03", name: "Корпоративный почтовый сервер и веб-шлюз", cat: "Инфраструктура", cost: 5300000, prio: 3, oaCode: "ОА.001", oaTitle: "АРМ оператора / сервер", domain: "IT", status: "На контроле", statusLevel: "high" },
        { id: "ACT-04", name: "Контроллер домена Active Directory", cat: "Служба каталога", cost: 4000000, prio: 3, oaCode: "ОА.001", oaTitle: "АРМ оператора / сервер", domain: "IT", status: "На защите", statusLevel: "success" }
    ]

    // 2. Риски (с привязкой к Банку данных угроз ФСТЭК России - УБИ.xxx / УТП:xx)
    property var risksList: [
        {
            id: "RSK-01",
            threat: "УБИ.031: Несанкционированный доступ и хищение платежных данных",
            threatCode: "УБИ.031",
            scenarioCode: "",
            vuln: "Слабая аутентификация в административном контуре",
            assetId: "ACT-01",
            assetName: "АБС Банка",
            impact: 4,
            probability: 3,
            assetPriority: 4,
            score: 48,
            scoreLevel: "critical",
            boundMeasureId: "MSR-01",
            boundMeasureName: "Внедрение PAM-системы",
            status: "В плане",
            statusLevel: "high"
        },
        {
            id: "RSK-02",
            threat: "УБИ.027: Внедрение вредоносного ПО (Ransomware) в контур СУБД",
            threatCode: "УБИ.027",
            scenarioCode: "",
            vuln: "Отсутствие сегментации сетевого контура СУБД",
            assetId: "ACT-02",
            assetName: "СУБД PostgreSQL",
            impact: 4,
            probability: 3,
            assetPriority: 4,
            score: 36,
            scoreLevel: "high",
            boundMeasureId: "MSR-02",
            boundMeasureName: "Сегментация сети + NGFW",
            status: "На контроле",
            statusLevel: "high"
        },
        {
            id: "RSK-03",
            threat: "УБИ.072: Целевой фишинг учетных записей администраторов домена",
            threatCode: "УБИ.072",
            scenarioCode: "",
            vuln: "Отсутствие второго фактора авторизации сотрудников",
            assetId: "ACT-03",
            assetName: "Почтовый шлюз",
            impact: 3,
            probability: 3,
            assetPriority: 3,
            score: 27,
            scoreLevel: "high",
            boundMeasureId: "MSR-03",
            boundMeasureName: "МФА + Anti-Phishing",
            status: "Закрыт",
            statusLevel: "success"
        },
        {
            id: "RSK-04",
            threat: "УБИ.098: Отказ в обслуживании (DDoS) сервиса авторизации и каталога",
            threatCode: "УБИ.098",
            scenarioCode: "",
            vuln: "Недостаточная емкость шлюза и отсутствие кластеризации",
            assetId: "ACT-04",
            assetName: "Active Directory",
            impact: 3,
            probability: 2,
            assetPriority: 3,
            score: 18,
            scoreLevel: "medium",
            boundMeasureId: "MSR-04",
            boundMeasureName: "Кластеризация DNS/AD",
            status: "Закрыт",
            statusLevel: "success"
        }
    ]

    // 3. Меры защиты
    property var measuresList: [
        {
            id: "MSR-01",
            name: "Внедрение системы контроля привилегированного доступа (PAM)",
            type: "Техническая",
            cost: 2400000,
            dmgRed: 60,
            probRed: 75,
            boundRiskId: "RSK-01",
            status: "Внедряется",
            statusLevel: "high"
        },
        {
            id: "MSR-02",
            name: "Сегментация сети ЦОД и СУБД межсетевыми экранами (NGFW)",
            type: "Техническая",
            cost: 1800000,
            dmgRed: 50,
            probRed: 60,
            boundRiskId: "RSK-02",
            status: "В плане",
            statusLevel: "info"
        },
        {
            id: "MSR-03",
            name: "Аппаратная многофакторная аутентификация (MFA / FIDO2)",
            type: "Техническая",
            cost: 950000,
            dmgRed: 30,
            probRed: 80,
            boundRiskId: "RSK-03",
            status: "Внедрено",
            statusLevel: "success"
        },
        {
            id: "MSR-04",
            name: "Регулярные тренинги по киберграмотности и фишинг-тесты",
            type: "Организационная",
            cost: 450000,
            dmgRed: 20,
            probRed: 65,
            boundRiskId: "RSK-04",
            status: "Внедрено",
            statusLevel: "success"
        }
    ]

    // Сигнал об обновлении данных
    signal dataChanged()

    // --- РАСЧЁТЫ МЕТРИК ---
    property real totalAssetsCost: 0
    property real initialLosses: 0
    property real residualLosses: 0
    property real avoidedDamage: 0
    property real totalMeasuresCost: 0
    property real netBenefit: 0
    property int rosi: 0
    property string multiplier: "0.0"

    property int criticalRisksCount: 0
    property int highRisksCount: 0
    property int mediumRisksCount: 0
    property int lowRisksCount: 0
    property real averageScore: 0

    function recalculateAll() {
        var aCost = 0;
        for (var a = 0; a < assetsList.length; a++) {
            aCost += (assetsList[a].cost || 0);
        }
        totalAssetsCost = aCost;

        var mCost = 0;
        for (var m = 0; m < measuresList.length; m++) {
            mCost += (measuresList[m].cost || 0);
        }
        totalMeasuresCost = mCost;

        var initL = 0;
        var resL = 0;
        var sumScore = 0;
        var cCount = 0;
        var hCount = 0;
        var mCount = 0;
        var lCount = 0;

        for (var r = 0; r < risksList.length; r++) {
            var risk = risksList[r];
            var iScore = risk.impact * risk.probability * risk.assetPriority;
            risk.score = iScore;
            risk.scoreLevel = getLevelByScore(iScore);

            // Если это риск АСУ ТП с угрозой отказа или срыва, учитываем вес времени простоя
            var effectivePointCost = pointCost;
            if (AssetService.industrialMode && (risk.threatCode === "УТП:05" || risk.threatCode === "УТП:08" || risk.threatCode === "УТП:06")) {
                effectivePointCost = Math.max(pointCost, downtimeHourlyCost * 0.25);
            }

            initL += iScore * effectivePointCost;
            sumScore += iScore;

            if (risk.scoreLevel === "critical") cCount++;
            else if (risk.scoreLevel === "high") hCount++;
            else if (risk.scoreLevel === "medium") mCount++;
            else lCount++;

            // Остаточный ущерб при привязке меры
            var boundMeasure = null;
            if (risk.boundMeasureId) {
                for (var b = 0; b < measuresList.length; b++) {
                    if (measuresList[b].id === risk.boundMeasureId) {
                        boundMeasure = measuresList[b];
                        break;
                    }
                }
            }

            if (boundMeasure) {
                var resImpact = risk.impact * (1.0 - (boundMeasure.dmgRed / 100.0));
                var resProb = risk.probability * (1.0 - (boundMeasure.probRed / 100.0));
                var resScore = Math.ceil(resImpact * resProb * risk.assetPriority);
                resL += resScore * effectivePointCost;
            } else {
                resL += iScore * effectivePointCost;
            }
        }

        initialLosses = initL;
        residualLosses = resL;
        avoidedDamage = Math.max(0, initL - resL);
        netBenefit = avoidedDamage - totalMeasuresCost;

        if (totalMeasuresCost > 0) {
            rosi = Math.round(((avoidedDamage - totalMeasuresCost) / totalMeasuresCost) * 100);
            multiplier = (avoidedDamage / totalMeasuresCost).toFixed(1) + "x";
        } else {
            rosi = 0;
            multiplier = "0.0x";
        }

        criticalRisksCount = cCount;
        highRisksCount = hCount;
        mediumRisksCount = mCount;
        lowRisksCount = lCount;
        averageScore = risksList.length > 0 ? (sumScore / risksList.length) : 0;

        dataChanged();
    }

    Component.onCompleted: {
        recalculateAll();
    }
}
