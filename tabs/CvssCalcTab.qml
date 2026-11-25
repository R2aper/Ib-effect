import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

ScrollView {
    id: root
    contentWidth: availableWidth
    clip: true

    property string targetVulnerabilityId: ""
    property var vulnerabilityModel: (typeof riskCalculator !== "undefined")
                                      ? riskCalculator.vulnerabilities : []
    property var vulnerabilityLabels: []

    Connections {
        target: (typeof riskCalculator !== "undefined") ? riskCalculator : null
        function onVulnerabilitiesChanged() {
            root.rebuildVulnerabilityList()
        }
    }

    function rebuildVulnerabilityList() {
        root.vulnerabilityModel = (typeof riskCalculator !== "undefined")
                                  ? riskCalculator.vulnerabilities : []
        var labels = []
        var selectedIndex = -1
        for (var i = 0; i < root.vulnerabilityModel.length; ++i) {
            var item = root.vulnerabilityModel[i].toMap ? root.vulnerabilityModel[i].toMap()
                                                       : root.vulnerabilityModel[i]
            var id = item.id || ""
            var title = item.title || "Сценарий угрозы"
            labels.push((id ? id + " — " : "") + title)
            if (id === root.targetVulnerabilityId)
                selectedIndex = i
        }
        root.vulnerabilityLabels = labels
        if (root.vulnerabilityModel.length > 0) {
            vulnCombo.currentIndex = selectedIndex >= 0
                                      ? selectedIndex
                                      : 0
        }
    }

    function selectedVulnerabilityId() {
        if (vulnCombo.currentIndex < 0
                || vulnCombo.currentIndex >= root.vulnerabilityModel.length)
            return ""
        var item = root.vulnerabilityModel[vulnCombo.currentIndex]
        item = item.toMap ? item.toMap() : item
        return item.id || ""
    }

    function openWithVector(id, vector, score) {
        root.targetVulnerabilityId = id || ""
        if (vector)
            calc.applyVector(vector)
        root.rebuildVulnerabilityList()
    }

    Component.onCompleted: rebuildVulnerabilityList()

    // ------------------------------------------------------------------
    // Вся логика расчёта - в C++ (CvssCalculator)
    // ------------------------------------------------------------------
    CvssCalculator { id: calc }

    // Порядок ключей совпадает с порядком элементов в SegmentedControl
    readonly property var avKeys:  ["N", "A", "L", "P"]
    readonly property var acKeys:  ["L", "H"]
    readonly property var prKeys:  ["N", "L", "H"]
    readonly property var uiKeys:  ["N", "R"]
    readonly property var sKeys:   ["U", "C"]
    readonly property var ciaKeys: ["N", "L", "H"]

    // ------------------------------------------------------------------
    // Подсказки справа от метрик (значения весов соответствуют CVSS 3.1)
    // ------------------------------------------------------------------
    function avHint(v) {
        return { "N": "Сетевой доступ (0.85)",
                 "A": "Смежная сеть (0.62)",
                 "L": "Локальный доступ (0.55)",
                 "P": "Физический доступ (0.20)" }[v];
    }
    function acHint(v) {
        return { "L": "Низкая сложность (0.77)",
                 "H": "Высокая сложность (0.44)" }[v];
    }
    function prHint(v, scope) {
        var changed = (scope === "C");
        var w = { "N": "0.85", "L": changed ? "0.68" : "0.62", "H": changed ? "0.50" : "0.27" }[v];
        var t = { "N": "Привилегий не требуется",
                  "L": "Низкий уровень привилегий",
                  "H": "Высокий уровень привилегий" }[v];
        return t + " (" + w + ")";
    }
    function uiHint(v) {
        return { "N": "Действий пользователя не требуется (0.85)",
                 "R": "Требуется действие пользователя (0.62)" }[v];
    }
    function cHint(v) {
        return { "N": "Нет влияния (0.00)",
                 "L": "Частичное раскрытие данных (0.22)",
                 "H": "Полная компрометация данных (0.56)" }[v];
    }
    function iHint(v) {
        return { "N": "Нет влияния (0.00)",
                 "L": "Частичная модификация данных (0.22)",
                 "H": "Полная модификация данных (0.56)" }[v];
    }
    function aHint(v) {
        return { "N": "Нет влияния (0.00)",
                 "L": "Снижение доступности (0.22)",
                 "H": "Полный отказ в обслуживании (0.56)" }[v];
    }

    // ------------------------------------------------------------------
    // Переиспользуемые компоненты (убирают дублирование разметки)
    // ------------------------------------------------------------------

    // Строка метрики: заголовок + подсказка + SegmentedControl
    component MetricRow: ColumnLayout {
        id: row
        property string title: ""
        property string hint: ""
        property var items: []
        property int currentIndex: 0
        signal picked(int idx)

        Layout.fillWidth: true
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: row.title
                font.family: Style.fontSans
                font.pixelSize: Style.fontSizeBodySm
                color: Style.textSecondary
            }
            Item { Layout.fillWidth: true }
            Text {
                text: row.hint
                font.family: Style.fontMono
                font.pixelSize: 10
                color: Style.textSecondary
            }
        }

        SegmentedControl {
            Layout.fillWidth: true
            items: row.items
            currentIndex: row.currentIndex
            onIndexChanged: function(idx) { row.picked(idx); }
        }
    }

    // Карточка-группа с заголовком
    component GroupCard: Rectangle {
        id: card
        property string title: ""
        property string tag: ""
        default property alias content: body.data

        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 24
        color: Style.panelSurface
        border.color: Style.hairlineBorder
        border.width: 1

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: card.title
                    font.family: Style.fontSans
                    font.pixelSize: Style.fontSizeHeadlineSm
                    font.weight: Font.DemiBold
                    color: Style.textPrimary
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: card.tag
                    font.family: Style.fontMono
                    font.pixelSize: 10
                    color: Style.textSecondary
                }
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                spacing: 10
            }
        }
    }

    // ------------------------------------------------------------------
    // Разметка
    // ------------------------------------------------------------------
    RowLayout {
        width: root.availableWidth
        spacing: 12

        // ============ Левая колонка: 60% (группы метрик) ============
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.60
            Layout.alignment: Qt.AlignTop
            spacing: 10

            // ---- 1. Exploitability ----
            GroupCard {
                title: "1. МЕТРИКИ ЭКСПЛОЙТАБЕЛЬНОСТИ (EXPLOITABILITY)"
                tag: "FIRST CVSS 3.1 / п. 13 ФСТЭК"

                MetricRow {
                    title: "Attack Vector (AV) / Вектор атаки:"
                    hint: root.avHint(calc.av)
                    items: ["Network (N)", "Adjacent (A)", "Local (L)", "Physical (P)"]
                    currentIndex: root.avKeys.indexOf(calc.av)
                    onPicked: function(idx) { calc.av = root.avKeys[idx]; }
                }

                MetricRow {
                    title: "Attack Complexity (AC) / Сложность атаки:"
                    hint: root.acHint(calc.ac)
                    items: ["Low (L)", "High (H)"]
                    currentIndex: root.acKeys.indexOf(calc.ac)
                    onPicked: function(idx) { calc.ac = root.acKeys[idx]; }
                }

                MetricRow {
                    title: "Privileges Required (PR) / Уровень привилегий:"
                    hint: root.prHint(calc.pr, calc.s)
                    items: ["None (N)", "Low (L)", "High (H)"]
                    currentIndex: root.prKeys.indexOf(calc.pr)
                    onPicked: function(idx) { calc.pr = root.prKeys[idx]; }
                }

                MetricRow {
                    title: "User Interaction (UI) / Взаимодействие с пользователем:"
                    hint: root.uiHint(calc.ui)
                    items: ["None (N)", "Required (R)"]
                    currentIndex: root.uiKeys.indexOf(calc.ui)
                    onPicked: function(idx) { calc.ui = root.uiKeys[idx]; }
                }
            }

            // ---- 2. Scope ----
            GroupCard {
                title: "2. ОБЛАСТЬ ВЗАИМОДЕЙСТВИЯ (SCOPE)"
                tag: "Множитель пересчета"

                MetricRow {
                    title: "Scope (S) / Выход за пределы контекста безопасности:"
                    hint: ""
                    items: [
                        "Unchanged (U) — В пределах одного компонента",
                        "Changed (C) — Выход за границы полномочий"
                    ]
                    currentIndex: root.sKeys.indexOf(calc.s)
                    onPicked: function(idx) { calc.s = root.sKeys[idx]; }
                }
            }

            // ---- 3. Impact ----
            GroupCard {
                title: "3. МЕТРИКИ ПОСЛЕДСТВИЙ (IMPACT METRICS)"
                tag: "К, Ц, Д последствия"

                MetricRow {
                    title: "Confidentiality (C) / Конфиденциальность:"
                    hint: root.cHint(calc.c)
                    items: ["None (N)", "Low (L)", "High (H)"]
                    currentIndex: root.ciaKeys.indexOf(calc.c)
                    onPicked: function(idx) { calc.c = root.ciaKeys[idx]; }
                }

                MetricRow {
                    title: "Integrity (I) / Целостность:"
                    hint: root.iHint(calc.i)
                    items: ["None (N)", "Low (L)", "High (H)"]
                    currentIndex: root.ciaKeys.indexOf(calc.i)
                    onPicked: function(idx) { calc.i = root.ciaKeys[idx]; }
                }

                MetricRow {
                    title: "Availability (A) / Доступность:"
                    hint: root.aHint(calc.a)
                    items: ["None (N)", "Low (L)", "High (H)"]
                    currentIndex: root.ciaKeys.indexOf(calc.a)
                    onPicked: function(idx) { calc.a = root.ciaKeys[idx]; }
                }
            }
        }

        // ============ Правая колонка: 40% (шкала, вектор, привязка) ============
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.40
            Layout.alignment: Qt.AlignTop
            spacing: 10

            // ---- Карточка со шкалой ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 280
                color: Style.panelSurface
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "БАЗОВАЯ ОЦЕНКА (BASE SCORE)"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "v3.1 Final"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    Canvas {
                        id: gaugeCanvas
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 140

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var cx = width / 2;
                            var cy = height / 2;
                            var radius = width / 2 - 12;

                            // Фоновое кольцо
                            ctx.beginPath();
                            ctx.arc(cx, cy, radius, 0, 2 * Math.PI, false);
                            ctx.lineWidth = 10;
                            ctx.strokeStyle = Style.surfaceContainer;
                            ctx.stroke();

                            // Активная дуга
                            var pct = calc.score / 10.0;
                            if (pct > 0) {
                                var start = -Math.PI / 2;
                                ctx.beginPath();
                                ctx.arc(cx, cy, radius, start, start + 2 * Math.PI * pct, false);
                                ctx.lineWidth = 10;
                                ctx.strokeStyle = Style.getRiskColor(calc.severity);
                                ctx.stroke();
                            }
                        }

                        // score/severity уведомляют через resultChanged
                        Connections {
                            target: calc
                            function onResultChanged() { gaugeCanvas.requestPaint(); }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0
                            Text {
                                text: calc.score.toFixed(1)
                                font.family: Style.fontMono
                                font.pixelSize: 32
                                font.weight: Font.Bold
                                color: Style.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "из 10.0"
                                font.family: Style.fontSans
                                font.pixelSize: 10
                                color: Style.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    RiskBadge {
                        Layout.alignment: Qt.AlignHCenter
                        level: calc.severity
                        text: calc.severity.toUpperCase() + " (CVSS: " + calc.score.toFixed(1) + ")"
                    }

                    // Подоценки (теперь реальные значения из C++)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            color: Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    text: "Exploitability"
                                    font.family: Style.fontSans
                                    font.pixelSize: 10
                                    color: Style.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: calc.exploitability.toFixed(1)
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    font.weight: Font.Bold
                                    color: Style.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            color: Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    text: "Impact"
                                    font.family: Style.fontSans
                                    font.pixelSize: 10
                                    color: Style.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: calc.impact.toFixed(1)
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    font.weight: Font.Bold
                                    color: Style.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }

            // ---- Карточка с вектором ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 110
                color: Style.panelSurface
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Вектор CVSS v3.1 (RFC):"
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeHeadlineSm
                        font.weight: Font.DemiBold
                        color: Style.textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        CustomTextField {
                            Layout.fillWidth: true
                            text: calc.vectorString
                            readOnly: true
                            isMonospace: true
                        }

                        AppButton {
                            text: "Копировать"
                            iconText: "📋"
                            onClicked: calc.copyVectorToClipboard()
                        }
                    }

                    Text {
                        text: "Строка вектора для внесения в паспорта ИСПДн/ГИС и формуляры ФСТЭК."
                        font.family: Style.fontSans
                        font.pixelSize: 10
                        color: Style.textMuted
                    }
                }
            }

            // ---- Привязка к реестру уязвимостей ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 140
                color: Style.panelSurface
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "ПРИВЯЗКА К РЕЕСТРУ УЯЗВИМОСТЕЙ"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Вкладка 3"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    Text {
                        text: "Целевая уязвимость из паспорта модели угроз:"
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeBodySm
                        color: Style.textSecondary
                    }

                    CustomComboBox {
                        id: vulnCombo
                        Layout.fillWidth: true
                        model: root.vulnerabilityLabels
                        onCurrentIndexChanged: {
                            var id = root.selectedVulnerabilityId()
                            if (id !== "")
                                root.targetVulnerabilityId = id
                        }
                    }

                    AppButton {
                        Layout.fillWidth: true
                        isPrimary: true
                        text: "Применить I_cvss (" + calc.score.toFixed(1) + ") к уязвимости"
                        iconText: "✓"
                        enabled: root.selectedVulnerabilityId() !== ""
                        onClicked: {
                            var targetId = root.selectedVulnerabilityId()
                            if (typeof riskCalculator !== "undefined" && targetId !== "") {
                                riskCalculator.updateVulnerability({
                                    id: targetId,
                                    cvss: calc.score,
                                    vector: calc.vectorString
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}

