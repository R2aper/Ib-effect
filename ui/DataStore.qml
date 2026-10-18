pragma Singleton

import QtQuick

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
        { id: "ACT-01", name: "Автоматизированная банковская система (АБС)", cat: "Информ. система", cost: 24000000, prio: 4, status: "На защите", statusLevel: "success" },
        { id: "ACT-02", name: "Центральная СУБД PostgreSQL (Клиентские данные)", cat: "База данных", cost: 12500000, prio: 4, status: "На защите", statusLevel: "success" },
        { id: "ACT-03", name: "Корпоративный почтовый сервер и веб-шлюз", cat: "Инфраструктура", cost: 5300000, prio: 3, status: "На контроле", statusLevel: "high" },
        { id: "ACT-04", name: "Контроллер домена Active Directory", cat: "Служба каталога", cost: 4000000, prio: 3, status: "На защите", statusLevel: "success" }
    ]

    // 2. Риски (с привязкой к Банку данных угроз ФСТЭК России - УБИ.xxx)
    property var risksList: [
        {
            id: "RSK-01",
            threat: "УБИ.031: Несанкционированный доступ и хищение платежных данных",
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

            initL += iScore * pointCost;
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
                resL += resScore * pointCost;
            } else {
                resL += iScore * pointCost;
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
    function addAsset(name, cat, cost, prio) {
        var newId = "ACT-0" + (assetsList.length + 1);
        var item = {
            id: newId,
            name: name,
            cat: cat,
            cost: cost,
            prio: prio,
            status: "На защите",
            statusLevel: "success"
        };
        var list = assetsList.slice();
        list.push(item);
        assetsList = list;
        recalculateAll();
    }

    function updateAsset(index, name, cat, cost, prio) {
        if (index >= 0 && index < assetsList.length) {
            var list = assetsList.slice();
            list[index].name = name;
            list[index].cat = cat;
            list[index].cost = cost;
            list[index].prio = prio;
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
    function addRisk(threat, vuln, assetIndex, impact, prob) {
        var newId = "RSK-0" + (risksList.length + 1);
        var asset = assetsList[assetIndex] || { id: "ACT-01", name: "Неизвестный актив", prio: 3 };
        var score = impact * prob * asset.prio;
        var item = {
            id: newId,
            threat: threat,
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

    function updateRisk(index, threat, vuln, impact, prob) {
        if (index >= 0 && index < risksList.length) {
            var list = risksList.slice();
            list[index].threat = threat;
            list[index].vuln = vuln;
            list[index].impact = impact;
            list[index].probability = prob;
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

    // --- CRUD ДЛЯ МЕР ЗАЩИТЫ ---
    function addMeasure(name, type, cost, dmgRed, probRed) {
        var newId = "MSR-0" + (measuresList.length + 1);
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
            // Отвязать от рисков, если была привязана
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

    Component.onCompleted: {
        recalculateAll();
    }
}
