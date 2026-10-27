import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

ScrollView {
    id: root
    contentWidth: width
    clip: true

    // Metric properties with defaults (matching Stitch CVSS 9.8)
    property string av: "N" // N, A, L, P
    property string ac: "L" // L, H
    property string pr: "N" // N, L, H
    property string ui: "N" // N, R
    property string s:  "U" // U, C
    property string c:  "H" // N, L, H
    property string i:  "H" // N, L, H
    property string a:  "H" // N, L, H

    property string vectorString: "CVSS:3.1/AV:" + av + "/AC:" + ac + "/PR:" + pr + "/UI:" + ui + "/S:" + s + "/C:" + c + "/I:" + i + "/A:" + a

    // Base score calculation helper
    readonly property double score: calculateScore()
    readonly property string severity: {
        if (score >= 9.0) return "Критический";
        if (score >= 7.0) return "Высокий";
        if (score >= 4.0) return "Средний";
        if (score > 0.0)  return "Низкий";
        return "None";
    }

    function calculateScore() {
        // Exploitability calculation
        var avWeights = { "N": 0.85, "A": 0.62, "L": 0.55, "P": 0.20 };
        var acWeights = { "L": 0.77, "H": 0.44 };
        var prWeightsU = { "N": 0.85, "L": 0.62, "H": 0.27 };
        var prWeightsC = { "N": 0.85, "L": 0.68, "H": 0.50 };
        var uiWeights = { "N": 0.85, "R": 0.62 };
        var cWeights = { "N": 0.0, "L": 0.22, "H": 0.56 };

        var avVal = avWeights[av] || 0.85;
        var acVal = acWeights[ac] || 0.77;
        var prVal = (s === "U") ? (prWeightsU[pr] || 0.85) : (prWeightsC[pr] || 0.85);
        var uiVal = uiWeights[ui] || 0.85;

        var exploitability = 8.22 * avVal * acVal * prVal * uiVal;

        // ISS & Impact calculation
        var cVal = cWeights[c] || 0.56;
        var iVal = cWeights[i] || 0.56;
        var aVal = cWeights[a] || 0.56;

        var iss = 1.0 - (1.0 - cVal) * (1.0 - iVal) * (1.0 - aVal);
        var impact = 0.0;
        if (s === "U") {
            impact = 6.42 * iss;
        } else {
            impact = 7.52 * (iss - 0.029) - 3.25 * Math.pow((iss - 0.02), 15);
        }

        if (impact <= 0) return 0.0;

        var base = (s === "U") ? Math.min(impact + exploitability, 10.0) : Math.min(1.08 * (impact + exploitability), 10.0);
        // RoundUp to 0.1
        return Math.ceil(base * 10.0) / 10.0;
    }

    RowLayout {
        width: root.width
        spacing: 12
        Layout.alignment: Qt.AlignTop

        // Left Column: 60% Width (Metrics Groups)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.60
            spacing: 10

            // Group 1: Exploitability Metrics
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: g1Col.implicitHeight + 20
                color: Style.panelSurface
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g1Col
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "1. МЕТРИКИ ЭКСПЛОЙТАБЕЛЬНОСТИ (EXPLOITABILITY)"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "FIRST CVSS 3.1 / п. 13 ФСТЭК"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    // Attack Vector (AV)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Attack Vector (AV) / Вектор атаки:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text { text: "Сетевой доступ (0.85)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                        }
                        SegmentedControl {
                            Layout.fillWidth: true
                            items: ["Network (N)", "Adjacent (A)", "Local (L)", "Physical (P)"]
                            currentIndex: (root.av === "N") ? 0 : ((root.av === "A") ? 1 : ((root.av === "L") ? 2 : 3))
                            onIndexChanged: function(idx) {
                                var map = ["N", "A", "L", "P"];
                                root.av = map[idx];
                            }
                        }
                    }

                    // Attack Complexity (AC)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Attack Complexity (AC) / Сложность атаки:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text { text: "Низкая сложность (0.77)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                        }
                        SegmentedControl {
                            Layout.fillWidth: true
                            items: ["Low (L)", "High (H)"]
                            currentIndex: (root.ac === "L") ? 0 : 1
                            onIndexChanged: function(idx) { root.ac = (idx === 0) ? "L" : "H"; }
                        }
                    }

                    // Privileges Required (PR)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Privileges Required (PR) / Уровень привилегий:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text { text: "Привилегий не требуется (0.85)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                        }
                        SegmentedControl {
                            Layout.fillWidth: true
                            items: ["None (N)", "Low (L)", "High (H)"]
                            currentIndex: (root.pr === "N") ? 0 : ((root.pr === "L") ? 1 : 2)
                            onIndexChanged: function(idx) {
                                var map = ["N", "L", "H"];
                                root.pr = map[idx];
                            }
                        }
                    }

                    // User Interaction (UI)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "User Interaction (UI) / Взаимодействие с пользователем:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text { text: "Действий пользователя не требуется (0.85)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                        }
                        SegmentedControl {
                            Layout.fillWidth: true
                            items: ["None (N)", "Required (R)"]
                            currentIndex: (root.ui === "N") ? 0 : 1
                            onIndexChanged: function(idx) { root.ui = (idx === 0) ? "N" : "R"; }
                        }
                    }
                }
            }

            // Group 2: Scope Metric
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: g2Col.implicitHeight + 20
                color: Style.panelSurface
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g2Col
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "2. ОБЛАСТЬ ВЗАИМОДЕЙСТВИЯ (SCOPE)"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Множитель пересчета"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Scope (S) / Выход за пределы контекста безопасности:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                    }

                    SegmentedControl {
                        Layout.fillWidth: true
                        items: [
                            "Unchanged (U) — В пределах одного компонента",
                            "Changed (C) — Выход за границы полномочий"
                        ]
                        currentIndex: (root.s === "U") ? 0 : 1
                        onIndexChanged: function(idx) { root.s = (idx === 0) ? "U" : "C"; }
                    }
                }
            }

            // Group 3: Impact Metrics
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: g3Col.implicitHeight + 20
                color: Style.panelSurface
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g3Col
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "3. МЕТРИКИ ПОСЛЕДСТВИЙ (IMPACT METRICS)"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "К, Ц, Д последствия"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    // Confidentiality (C)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Confidentiality (C) / Конфиденциальность:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text { text: "Полная компрометация данных (0.56)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                        }
                        SegmentedControl {
                            Layout.fillWidth: true
                            items: ["None (N)", "Low (L)", "High (H)"]
                            currentIndex: (root.c === "N") ? 0 : ((root.c === "L") ? 1 : 2)
                            onIndexChanged: function(idx) {
                                var map = ["N", "L", "H"];
                                root.c = map[idx];
                            }
                        }
                    }

                    // Integrity (I)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Integrity (I) / Целостность:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text { text: "Полная модификация данных (0.56)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                        }
                        SegmentedControl {
                            Layout.fillWidth: true
                            items: ["None (N)", "Low (L)", "High (H)"]
                            currentIndex: (root.i === "N") ? 0 : ((root.i === "L") ? 1 : 2)
                            onIndexChanged: function(idx) {
                                var map = ["N", "L", "H"];
                                root.i = map[idx];
                            }
                        }
                    }

                    // Availability (A)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Availability (A) / Доступность:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text { text: "Полный отказ в обслуживании (0.56)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                        }
                        SegmentedControl {
                            Layout.fillWidth: true
                            items: ["None (N)", "Low (L)", "High (H)"]
                            currentIndex: (root.a === "N") ? 0 : ((root.a === "L") ? 1 : 2)
                            onIndexChanged: function(idx) {
                                var map = ["N", "L", "H"];
                                root.a = map[idx];
                            }
                        }
                    }
                }
            }
        }

        // Right Column: 40% Width (Gauge, Vector, Binding)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.40
            spacing: 10

            // Circular Gauge Card
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

                    // Circular Indicator Canvas
                    Canvas {
                        id: gaugeCanvas
                        Layout.alignment: Qt.AlignHCenter
                        width: 140
                        height: 140

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var centerX = width / 2;
                            var centerY = height / 2;
                            var radius = width / 2 - 12;

                            // Background Circle
                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
                            ctx.lineWidth = 10;
                            ctx.strokeStyle = Style.surfaceContainer;
                            ctx.stroke();

                            // Active Progress Arc
                            var pct = root.score / 10.0;
                            var startAngle = -Math.PI / 2;
                            var endAngle = startAngle + (2 * Math.PI * pct);

                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
                            ctx.lineWidth = 10;
                            ctx.strokeStyle = Style.getRiskColor(root.severity);
                            ctx.stroke();
                        }

                        Connections {
                            target: root
                            function onScoreChanged() { gaugeCanvas.requestPaint(); }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0
                            Text {
                                text: root.score.toFixed(1)
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

                    // Severity Badge
                    RiskBadge {
                        Layout.alignment: Qt.AlignHCenter
                        level: root.severity
                        text: root.severity.toUpperCase() + " (CVSS: " + root.score.toFixed(1) + ")"
                    }

                    // Subscores Grid
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            color: Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text { text: "Exploitability"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                Text { text: "3.9 / 3.9"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            color: Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text { text: "Impact"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                Text { text: "5.9 / 5.9"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                            }
                        }
                    }
                }
            }

            // Vector String Card
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
                            text: root.vectorString
                            readOnly: true
                            isMonospace: true
                        }

                        AppButton {
                            text: "Копировать"
                            iconText: "📋"
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

            // Target Vulnerability Binding Card
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

                    Text { text: "Целевая уязвимость из паспорта модели угроз:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }

                    CustomComboBox {
                        Layout.fillWidth: true
                        model: [
                            "BDU:2025-01611 — RCE в модуле PostgreSQL",
                            "Конструктор УБИ — Копирование исходного кода инсайдером",
                            "BDU:2024-01928 — Доступ к БД АСУ ТП (SCADA)",
                            "BDU:2023-05441 — Эксфильтрация через API платёжного шлюза"
                        ]
                    }

                    AppButton {
                        Layout.fillWidth: true
                        isPrimary: true
                        text: "Применить I_cvss (" + root.score.toFixed(1) + ") к уязвимости"
                        iconText: "✓"
                    }
                }
            }
        }
    }
}
