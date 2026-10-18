pragma Singleton

import QtQuick
import "BduData.js" as BduData

QtObject {
    id: store

    // --- АВТОРИЗАЦИЯ И ПОЛЬЗОВАТЕЛЬ (ЛОКАЛЬНАЯ СЕССИЯ КЛИЕНТА) ---
    property bool isAuthenticated: false
    property var currentUser: ({
        login: "ostrenko",
        name: "Иван Остренко",
        type: "student", // "student" | "company"
        group: "БС-304",
        org: "СибГУТИ, Кафедра БИТ",
        role: "Студент"
    })

    // Локальный список зарегистрированных пользователей
    property var registeredUsers: [
        { login: "ostrenko", pass: "123", name: "Иван Остренко", type: "student", group: "БС-304", org: "СибГУТИ, Кафедра БИТ", role: "Студент" },
        { login: "ciso", pass: "123", name: "Александр Смирнов", type: "company", group: "Отдел ИБ", org: "ПАО Банк", role: "CISO" },
        { login: "admin", pass: "admin", name: "Администратор СУИБ", type: "company", group: "Служба безопасности", org: "ИБ-Эффект", role: "Администратор" }
    ]

    function login(loginInput, passInput, userType) {
        if (!loginInput || !passInput) {
            return { success: false, error: "Заполните логин и пароль" };
        }
        for (var i = 0; i < registeredUsers.length; i++) {
            var u = registeredUsers[i];
            if (u.login.toLowerCase() === loginInput.trim().toLowerCase() && u.pass === passInput) {
                currentUser = {
                    login: u.login,
                    name: u.name,
                    type: u.type || userType || "student",
                    group: u.group || "",
                    org: u.org || "",
                    role: u.role || (u.type === "company" ? "Специалист ИБ" : "Студент")
                };
                isAuthenticated = true;
                return { success: true };
            }
        }
        return { success: false, error: "Пользователь не найден или неверный пароль" };
    }

    function registerStudent(fullName, groupName, university, loginInput, passInput) {
        if (!fullName || !groupName || !loginInput || !passInput) {
            return { success: false, error: "Заполните все обязательные поля" };
        }
        for (var i = 0; i < registeredUsers.length; i++) {
            if (registeredUsers[i].login.toLowerCase() === loginInput.trim().toLowerCase()) {
                return { success: false, error: "Данный логин уже занят" };
            }
        }
        var newUser = {
            login: loginInput.trim(),
            pass: passInput,
            name: fullName.trim(),
            type: "student",
            group: groupName.trim(),
            org: (university ? university.trim() : "СибГУТИ"),
            role: "Студент"
        };
        registeredUsers.push(newUser);
        currentUser = newUser;
        isAuthenticated = true;
        return { success: true };
    }

    function registerCompany(companyName, contactName, department, loginInput, passInput) {
        if (!companyName || !contactName || !loginInput || !passInput) {
            return { success: false, error: "Заполните все обязательные поля" };
        }
        for (var i = 0; i < registeredUsers.length; i++) {
            if (registeredUsers[i].login.toLowerCase() === loginInput.trim().toLowerCase()) {
                return { success: false, error: "Данный логин уже занят" };
            }
        }
        var newUser = {
            login: loginInput.trim(),
            pass: passInput,
            name: contactName.trim(),
            type: "company",
            group: (department ? department.trim() : "Отдел ИБ"),
            org: companyName.trim(),
            role: "Специалист ИБ"
        };
        registeredUsers.push(newUser);
        currentUser = newUser;
        isAuthenticated = true;
        return { success: true };
    }

    function logout() {
        isAuthenticated = false;
    }

    // --- ДВУХКОНТУРНАЯ МОДЕЛЬ (IT КОРПОРАТИВНЫЙ / OT АСУ ТП КИИ) ---
    property bool isIndustrialMode: false
    property string activeDomainTitle: isIndustrialMode ? "АСУ ТП и КИИ (Приказ ФСТЭК № 239)" : "Корпоративный IT (ГОСТ Р ИСО/МЭК 27005)"

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

    // Справочники БДУ ФСТЭК России
    property var bduObjects: BduData.getInfluenceObjects()
    property var bduThreatsOT: BduData.getAsutpThreats()
    property var bduThreatsIT: BduData.getItThreats()
    property var bduScenarios: BduData.getAsutpScenarios()
    property var bduMethods: BduData.getAsutpMethods()
    property var bduObjectThreatsMap: BduData.getObjectThreatsMap()

    function getThreatsForAssetOa(oaCode) {
        return BduData.getThreatsForObject(oaCode);
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

    // --- МОДЕЛИ ДАННЫХ (ДИНАМИЧЕСКИЕ ДЛЯ CRUD) ---

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
            if (isIndustrialMode && (risk.threatCode === "УТП:05" || risk.threatCode === "УТП:08" || risk.threatCode === "УТП:06")) {
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

    // --- CRUD ДЛЯ АКТИВОВ ---
    function addAsset(name, cat, cost, prio, oaCode, oaTitle, domain) {
        var newId = (domain === "OT" || isIndustrialMode ? "ACT-OT-" : "ACT-") + (assetsList.length + 1 < 10 ? "0" : "") + (assetsList.length + 1);
        var item = {
            id: newId,
            name: name,
            cat: cat,
            cost: cost,
            prio: prio,
            oaCode: oaCode || "",
            oaTitle: oaTitle || "",
            domain: domain || (isIndustrialMode ? "OT" : "IT"),
            status: "На защите",
            statusLevel: "success"
        };
        var list = assetsList.slice();
        list.push(item);
        assetsList = list;
        recalculateAll();
    }

    function updateAsset(index, name, cat, cost, prio, oaCode, oaTitle, domain) {
        if (index >= 0 && index < assetsList.length) {
            var list = assetsList.slice();
            list[index].name = name;
            list[index].cat = cat;
            list[index].cost = cost;
            list[index].prio = prio;
            if (oaCode !== undefined) list[index].oaCode = oaCode;
            if (oaTitle !== undefined) list[index].oaTitle = oaTitle;
            if (domain !== undefined) list[index].domain = domain;
            assetsList = list;
            recalculateAll();
        }
    }

    function deleteAsset(index) {
        if (index >= 0 && index < assetsList.length) {
            var list = assetsList.slice();
            list.splice(index, 1);
            assetsList = list;
            recalculateAll();
        }
    }

    // --- CRUD ДЛЯ РИСКОВ ---
    function addRisk(threat, vuln, assetIndex, impact, prob, threatCode, scenarioCode) {
        var newId = (isIndustrialMode ? "RSK-OT-" : "RSK-") + (risksList.length + 1 < 10 ? "0" : "") + (risksList.length + 1);
        var asset = assetsList[assetIndex] || { id: "ACT-01", name: "Неизвестный актив", prio: 3 };
        var score = impact * prob * asset.prio;
        var item = {
            id: newId,
            threat: threat,
            threatCode: threatCode || "",
            scenarioCode: scenarioCode || "",
            vuln: vuln,
            assetId: asset.id,
            assetName: asset.name,
            impact: impact,
            probability: prob,
            assetPriority: asset.prio,
            score: score,
            scoreLevel: getLevelByScore(score),
            boundMeasureId: "",
            boundMeasureName: "Не назначена",
            status: score > riskAppetite ? "В плане" : "Принят",
            statusLevel: score > riskAppetite ? "high" : "success"
        };
        var list = risksList.slice();
        list.push(item);
        risksList = list;
        recalculateAll();
    }

    function updateRisk(index, threat, vuln, impact, prob, threatCode, scenarioCode) {
        if (index >= 0 && index < risksList.length) {
            var list = risksList.slice();
            list[index].threat = threat;
            list[index].vuln = vuln;
            list[index].impact = impact;
            list[index].probability = prob;
            if (threatCode !== undefined) list[index].threatCode = threatCode;
            if (scenarioCode !== undefined) list[index].scenarioCode = scenarioCode;
            var score = impact * prob * list[index].assetPriority;
            list[index].score = score;
            list[index].scoreLevel = getLevelByScore(score);
            risksList = list;
            recalculateAll();
        }
    }

    function deleteRisk(index) {
        if (index >= 0 && index < risksList.length) {
            var list = risksList.slice();
            list.splice(index, 1);
            risksList = list;
            recalculateAll();
        }
    }

    // --- ИМПОРТ ТИПОВОГО СЦЕНАРИЯ АТАКИ ФСТЭК (С1–С3) ---
    function importScenario(scenarioCode, targetAssetIndex) {
        var scList = bduScenarios;
        var targetSc = null;
        for (var i = 0; i < scList.length; i++) {
            if (scList[i].code === scenarioCode || scList[i].title.indexOf(scenarioCode) !== -1) {
                targetSc = scList[i];
                break;
            }
        }
        if (!targetSc || !targetSc.steps || targetSc.steps.length === 0) return 0;

        var asset = assetsList[targetAssetIndex] || (assetsList.length > 0 ? assetsList[0] : null);
        if (!asset) return 0;

        var list = risksList.slice();
        var added = 0;

        for (var s = 0; s < targetSc.steps.length; s++) {
            var step = targetSc.steps[s];
            var newId = "RSK-" + (list.length + 1 < 10 ? "0" : "") + (list.length + 1);
            var imp = (s === targetSc.steps.length - 1) ? 4 : (s >= 2 ? 3 : 2);
            var prb = (s === 0) ? 4 : 3;
            var score = imp * prb * asset.prio;

            var thrTitle = (step.threat_code ? (step.threat_code + ": ") : "") + (step.threat_title ? step.threat_title : targetSc.title);
            var thrNameFull = thrTitle + " [" + scenarioCode + " · Шаг " + step.step_number + "]";

            var item = {
                id: newId,
                threat: thrNameFull,
                threatCode: step.threat_code || "",
                scenarioCode: scenarioCode,
                vuln: step.description || "Уязвимость конфигурации и разграничения доступа",
                assetId: asset.id,
                assetName: asset.name,
                impact: imp,
                probability: prb,
                assetPriority: asset.prio,
                score: score,
                scoreLevel: getLevelByScore(score),
                boundMeasureId: "",
                boundMeasureName: "Не назначена",
                status: score > riskAppetite ? "В плане" : "Принят",
                statusLevel: score > riskAppetite ? "high" : "success"
            };
            list.push(item);
            added++;
        }
        risksList = list;
        recalculateAll();
        return added;
    }

    // --- CRUD ДЛЯ МЕР ЗАЩИТЫ ---
    function addMeasure(name, type, cost, dmgRed, probRed) {
        var newId = (isIndustrialMode ? "MSR-OT-" : "MSR-") + (measuresList.length + 1 < 10 ? "0" : "") + (measuresList.length + 1);
        var item = {
            id: newId,
            name: name,
            type: type,
            cost: cost,
            dmgRed: dmgRed,
            probRed: probRed,
            boundRiskId: "",
            status: "В плане",
            statusLevel: "info"
        };
        var list = measuresList.slice();
        list.push(item);
        measuresList = list;
        recalculateAll();
    }

    function updateMeasure(index, name, type, cost, dmgRed, probRed) {
        if (index >= 0 && index < measuresList.length) {
            var list = measuresList.slice();
            list[index].name = name;
            list[index].type = type;
            list[index].cost = cost;
            list[index].dmgRed = dmgRed;
            list[index].probRed = probRed;
            measuresList = list;
            recalculateAll();
        }
    }

    function deleteMeasure(index) {
        if (index >= 0 && index < measuresList.length) {
            var list = measuresList.slice();
            var measureId = list[index].id;
            for (var r = 0; r < risksList.length; r++) {
                if (risksList[r].boundMeasureId === measureId) {
                    risksList[r].boundMeasureId = "";
                    risksList[r].boundMeasureName = "Не назначена";
                }
            }
            list.splice(index, 1);
            measuresList = list;
            recalculateAll();
        }
    }

    // --- СВЯЗЫВАНИЕ МЕР И РИСКОВ ---
    function bindMeasureToRisk(measureIndex, riskIndex) {
        if (measureIndex >= 0 && measureIndex < measuresList.length &&
            riskIndex >= 0 && riskIndex < risksList.length) {
            var mList = measuresList.slice();
            var rList = risksList.slice();

            var measure = mList[measureIndex];
            var risk = rList[riskIndex];

            measure.boundRiskId = risk.id;
            measure.status = "Внедряется";
            measure.statusLevel = "high";

            risk.boundMeasureId = measure.id;
            risk.boundMeasureName = measure.name;
            risk.status = "На защите";
            risk.statusLevel = "success";

            measuresList = mList;
            risksList = rList;
            recalculateAll();
        }
    }

    function unbindMeasure(measureIndex) {
        if (measureIndex >= 0 && measureIndex < measuresList.length) {
            var mList = measuresList.slice();
            var rList = risksList.slice();

            var measure = mList[measureIndex];
            for (var r = 0; r < rList.length; r++) {
                if (rList[r].boundMeasureId === measure.id) {
                    rList[r].boundMeasureId = "";
                    rList[r].boundMeasureName = "Не назначена";
                    rList[r].status = "В плане";
                    rList[r].statusLevel = "high";
                }
            }

            measure.boundRiskId = "";
            measure.status = "В плане";
            measure.statusLevel = "info";

            measuresList = mList;
            risksList = rList;
            recalculateAll();
        }
    }

    // --- ПАКЕТНЫЕ ПРЕСЕТЫ И ПРОМЫШЛЕННЫЕ МЕРЫ ПО ПРИКАЗУ ФСТЭК № 239 ---
    function addIndustrialMeasuresPreset() {
        var presets = [
            {
                name: "Аппаратный однонаправленный шлюз (Диод данных) контура SCADA",
                type: "Техническая (Приказ № 239)",
                cost: 3200000,
                dmgRed: 60,
                probRed: 95
            },
            {
                name: "Станция очистки и доверенной загрузки съемных накопителей USB (ОА.009)",
                type: "Техническая (Приказ № 239)",
                cost: 1800000,
                dmgRed: 50,
                probRed: 90
            },
            {
                name: "Промышленный МЭ с глубоким анализом протоколов (Modbus/Profinet DPI)",
                type: "Техническая (Приказ № 239)",
                cost: 2900000,
                dmgRed: 70,
                probRed: 75
            },
            {
                name: "Система мониторинга целостности прошивок и конфигураций ПЛК (ОА.006)",
                type: "Техническая (Приказ № 239)",
                cost: 2100000,
                dmgRed: 85,
                probRed: 80
            }
        ];

        for (var i = 0; i < presets.length; i++) {
            var p = presets[i];
            addMeasure(p.name, p.type, p.cost, p.dmgRed, p.probRed);
        }
    }

    function loadIndustrialPreset() {
        isIndustrialMode = true;
        assetsList = [
            { id: "ACT-OT-01", name: "ПЛК агрегата компрессии (Siemens S7-1500)", cat: "Контроллер (ПЛК)", cost: 18500000, prio: 4, oaCode: "ОА.006", oaTitle: "Программируемый логический контроллер (ПЛК / PLC)", domain: "OT", status: "На защите", statusLevel: "success" },
            { id: "ACT-OT-02", name: "Инженерная станция АСУ ТП (TIA Portal)", cat: "АРМ инженера", cost: 9800000, prio: 4, oaCode: "ОА.002", oaTitle: "АРМ инженера (инженерная станция)", domain: "OT", status: "На защите", statusLevel: "success" },
            { id: "ACT-OT-03", name: "Технологический съемный накопитель (USB-Flash)", cat: "Съемный носитель", cost: 1200000, prio: 4, oaCode: "ОА.009", oaTitle: "Съемный носитель информации (USB, flash)", domain: "OT", status: "На контроле", statusLevel: "high" },
            { id: "ACT-OT-04", name: "Главный SCADA-сервер диспетчеризации (WinCC)", cat: "Промышленный сервер", cost: 26000000, prio: 4, oaCode: "ОА.003", oaTitle: "Промышленный сервер (SCADA/DCS)", domain: "OT", status: "На защите", statusLevel: "success" },
            { id: "ACT-OT-05", name: "Панель оператора на технологической установке (HMI)", cat: "Панель оператора", cost: 4300000, prio: 3, oaCode: "ОА.005", oaTitle: "Сенсорная панель оператора (HMI)", domain: "OT", status: "На контроле", statusLevel: "high" }
        ];

        risksList = [
            {
                id: "RSK-OT-01",
                threat: "УТП:05: Несанкционированная модификация конфигурации и прошивки ПЛК [С3.19 · Шаг 3]",
                threatCode: "УТП:05",
                scenarioCode: "С3.19",
                vuln: "СПА.23.001: Загрузка вредоносного конфигурационного проекта без проверки подписи",
                assetId: "ACT-OT-01",
                assetName: "ПЛК Siemens S7-1500",
                impact: 4,
                probability: 3,
                assetPriority: 4,
                score: 48,
                scoreLevel: "critical",
                boundMeasureId: "MSR-OT-04",
                boundMeasureName: "Контроль целостности прошивок ПЛК",
                status: "На защите",
                statusLevel: "success"
            },
            {
                id: "RSK-OT-02",
                threat: "УТП:01: Заражение через технологический USB-носитель [СПА.13.008]",
                threatCode: "УТП:01",
                scenarioCode: "С1.18",
                vuln: "Отсутствие принудительной проверки и изоляции съемных носителей ОА.009",
                assetId: "ACT-OT-03",
                assetName: "USB-Flash инженера",
                impact: 4,
                probability: 4,
                assetPriority: 4,
                score: 64,
                scoreLevel: "critical",
                boundMeasureId: "MSR-OT-02",
                boundMeasureName: "Станция очистки USB (ОА.009)",
                status: "На защите",
                statusLevel: "success"
            },
            {
                id: "RSK-OT-03",
                threat: "УТП:03: Удаленный доступ из корпоративной сети в технологический контур SCADA",
                threatCode: "УТП:03",
                scenarioCode: "С3.3",
                vuln: "Слабая сетевая сегментация между корпоративным сегментом и зоной АСУ ТП (Purdue Level 2-3)",
                assetId: "ACT-OT-04",
                assetName: "SCADA WinCC",
                impact: 4,
                probability: 3,
                assetPriority: 4,
                score: 48,
                scoreLevel: "critical",
                boundMeasureId: "MSR-OT-01",
                boundMeasureName: "Однонаправленный шлюз (Диод данных)",
                status: "На защите",
                statusLevel: "success"
            },
            {
                id: "RSK-OT-04",
                threat: "УТП:08: Искажение параметров и команд телеуправления HMI-панели",
                threatCode: "УТП:08",
                scenarioCode: "С2.1",
                vuln: "Отсутствие шифрования и взаимной аутентификации в протоколе Modbus TCP / Profinet",
                assetId: "ACT-OT-05",
                assetName: "HMI Comfort Panel",
                impact: 3,
                probability: 2,
                assetPriority: 3,
                score: 18,
                scoreLevel: "medium",
                boundMeasureId: "MSR-OT-03",
                boundMeasureName: "Промышленный МЭ с DPI",
                status: "На защите",
                statusLevel: "success"
            }
        ];

        measuresList = [
            {
                id: "MSR-OT-01",
                name: "Аппаратный однонаправленный шлюз (Диод данных) контура SCADA",
                type: "Техническая (Приказ № 239)",
                cost: 3200000,
                dmgRed: 60,
                probRed: 95,
                boundRiskId: "RSK-OT-03",
                status: "Внедрено",
                statusLevel: "success"
            },
            {
                id: "MSR-OT-02",
                name: "Станция очистки и проверки съемных накопителей USB (ОА.009)",
                type: "Техническая (Приказ № 239)",
                cost: 1800000,
                dmgRed: 50,
                probRed: 90,
                boundRiskId: "RSK-OT-02",
                status: "Внедрено",
                statusLevel: "success"
            },
            {
                id: "MSR-OT-03",
                name: "Промышленный МЭ с глубоким анализом протоколов (Modbus/Profinet DPI)",
                type: "Техническая (Приказ № 239)",
                cost: 2900000,
                dmgRed: 70,
                probRed: 75,
                boundRiskId: "RSK-OT-04",
                status: "Внедрено",
                statusLevel: "success"
            },
            {
                id: "MSR-OT-04",
                name: "Система мониторинга целостности прошивок и конфигураций ПЛК",
                type: "Техническая (Приказ № 239)",
                cost: 2100000,
                dmgRed: 85,
                probRed: 80,
                boundRiskId: "RSK-OT-01",
                status: "Внедряется",
                statusLevel: "high"
            }
        ];

        recalculateAll();
    }

    function loadCorporatePreset() {
        isIndustrialMode = false;
        assetsList = [
            { id: "ACT-01", name: "Автоматизированная банковская система (АБС)", cat: "Информ. система", cost: 24000000, prio: 4, oaCode: "ОА.003", oaTitle: "Промышленный сервер", domain: "IT", status: "На защите", statusLevel: "success" },
            { id: "ACT-02", name: "Центральная СУБД PostgreSQL (Клиентские данные)", cat: "База данных", cost: 12500000, prio: 4, oaCode: "ОА.004", oaTitle: "Сервер архивов / баз данных", domain: "IT", status: "На защите", statusLevel: "success" },
            { id: "ACT-03", name: "Корпоративный почтовый сервер и веб-шлюз", cat: "Инфраструктура", cost: 5300000, prio: 3, oaCode: "ОА.001", oaTitle: "АРМ оператора / сервер", domain: "IT", status: "На контроле", statusLevel: "high" },
            { id: "ACT-04", name: "Контроллер домена Active Directory", cat: "Служба каталога", cost: 4000000, prio: 3, oaCode: "ОА.001", oaTitle: "АРМ оператора / сервер", domain: "IT", status: "На защите", statusLevel: "success" }
        ];

        risksList = [
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
        ];

        measuresList = [
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
        ];

        recalculateAll();
    }

    Component.onCompleted: {
        recalculateAll();
    }
}
