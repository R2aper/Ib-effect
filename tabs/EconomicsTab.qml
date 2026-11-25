import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

ScrollView {
    id: root
    contentWidth: width
    clip: true

    property int selectedScenarioIndex: 0

    // Сценарии динамически рассчитываются из C++ RiskCalculator
    readonly property var scenarios: (typeof riskCalculator !== "undefined") ? riskCalculator.economicScenarios : []
    readonly property var currentScenario: (scenarios && scenarios.length > selectedScenarioIndex)
                                            ? scenarios[selectedScenarioIndex]
                                            : (scenarios && scenarios.length > 0 ? scenarios[0] : null)

    Connections {
        target: (typeof riskCalculator !== "undefined") ? riskCalculator : null
        function onDataChanged() {
            waterfallCanvas.requestPaint()
        }
    }

    onSelectedScenarioIndexChanged: {
        waterfallCanvas.requestPaint()
    }

    ColumnLayout {
        width: root.width
        spacing: 12

        // Top 4 Metrics Cards
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 8
            columnSpacing: 8

            MetricCard {
                Layout.fillWidth: true
                title: "СНИЖЕНИЕ КРИТИЧНОСТИ (V)"
                iconText: "ΔV"
                value: root.currentScenario ? root.currentScenario.deltaVText : "—"
                footerLeft: root.currentScenario ? ("V: " + root.currentScenario.vBase.toFixed(2) + " → " + root.currentScenario.vRes.toFixed(2)) : "V: —"
                footerRight: root.currentScenario ? ("SLA: " + root.currentScenario.slaRes) : ""
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ВЕРОЯТНОСТЬ ИНЦИДЕНТА"
                iconText: "PROB"
                value: root.currentScenario ? root.currentScenario.probRes : "—"
                unitText: root.currentScenario ? ("было: " + root.currentScenario.probBase) : ""
                footerLeft: "Снижение риска:"
                footerRight: root.currentScenario ? root.currentScenario.deltaProbText : "—"
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ПРЕДОТВРАЩЕННЫЙ УЩЕРБ"
                iconText: "ΔALE"
                value: root.currentScenario ? root.currentScenario.avoidedLoss : "—"
                unitText: "в год"
                footerLeft: "Базовый ALE:"
                footerRight: root.currentScenario ? root.currentScenario.aleBase : "—"
                badgeText: "ЭКОНОМИЯ"
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ЗАТРАТЫ НА МЕРЫ (TCO)"
                iconText: "TCO"
                value: root.currentScenario ? root.currentScenario.tco : "—"
                unitText: "CAPEX+OPEX"
                footerLeft: "Срок окупаемости:"
                footerRight: root.currentScenario ? root.currentScenario.payback : "—"
                badgeText: "БЮДЖЕТ"
                badgeColor: Style.surfaceContainerHighest
                badgeTextColor: Style.textPrimary
            }
        }

        // Hero Primary Result Banner
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 180
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        RowLayout {
                            spacing: 8
                            Text {
                                text: "КЛЮЧЕВОЙ ПОКАЗАТЕЛЬ ОКУПАЕМОСТИ ИНВЕСТИЦИЙ В ИБ"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodySm
                                font.weight: Font.DemiBold
                                color: Style.textSecondary
                            }

                        }

                        RowLayout {
                            spacing: 12
                            Text {
                                text: root.currentScenario ? root.currentScenario.rosi : (typeof riskCalculator !== "undefined" ? ((riskCalculator.netRosiPercent >= 0 ? "+" : "") + riskCalculator.formatNumber(riskCalculator.netRosiPercent, 1) + "%") : "+0.0%")
                                font.family: Style.fontMono
                                font.pixelSize: 42
                                font.weight: Font.Bold
                                color: (root.currentScenario ? root.currentScenario.netBenefitNum >= 0 : true) ? Style.primary : Style.riskCriticalText
                            }
                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: "Net ROSI"
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeHeadlineMd
                                    font.weight: Font.DemiBold
                                    color: Style.textPrimary
                                }
                                Text {
                                    text: typeof riskCalculator !== "undefined"
                                          ? ("Суммарный Net ROSI портфеля мер: " + (riskCalculator.netRosiPercent >= 0 ? "+" : "") + riskCalculator.formatNumber(riskCalculator.netRosiPercent, 1) + "%")
                                          : "Суммарный Net ROSI портфеля мер: —"
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    color: Style.textSecondary
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Verdict Badge
                    Rectangle {
                        implicitHeight: 52
                        implicitWidth: 260
                        color: (root.currentScenario ? root.currentScenario.netBenefitNum >= 0 : (typeof riskCalculator !== "undefined" && riskCalculator.netBenefit >= 0)) ? Style.riskLowBg : Style.riskCriticalBg
                        border.color: (root.currentScenario ? root.currentScenario.netBenefitNum >= 0 : (typeof riskCalculator !== "undefined" && riskCalculator.netBenefit >= 0)) ? Style.riskLowBorder : Style.riskCriticalBorder
                        border.width: 1
                        radius: 2

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: (root.currentScenario ? root.currentScenario.netBenefitNum >= 0 : true) ? "✓" : "⚠"
                                font.family: Style.fontMono
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                color: (root.currentScenario ? root.currentScenario.netBenefitNum >= 0 : true) ? Style.riskLowText : Style.riskCriticalText
                            }

                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: (root.currentScenario ? root.currentScenario.netBenefitNum >= 0 : (typeof riskCalculator !== "undefined" && riskCalculator.netBenefit >= 0)) ? "ИНВЕСТИЦИЯ ВЫСОКОЭФФЕКТИВНА" : "ТРЕБУЕТСЯ ОПТИМИЗАЦИЯ"
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    font.weight: Font.Bold
                                    color: (root.currentScenario ? root.currentScenario.netBenefitNum >= 0 : true) ? Style.riskLowText : Style.riskCriticalText
                                }
                                Text {
                                    text: (root.currentScenario ? root.currentScenario.netBenefitNum >= 0 : true) ? "Рекомендовано к защите перед CEO / CFO" : "Затраты превышают предотвращенный ущерб"
                                    font.family: Style.fontSans
                                    font.pixelSize: 10
                                    color: Style.textSecondary
                                }
                            }
                        }
                    }
                }

                // Formula description box
                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Text {
                            text: root.currentScenario
                                  ? ("Формула: Net ROSI = ((Предотвращенный ущерб - TCO) / TCO) × 100% = ((" + root.currentScenario.avoidedLoss + " - " + root.currentScenario.tco + ") / " + root.currentScenario.tco + ") × 100% = " + root.currentScenario.rosi)
                                  : "Формула: Net ROSI = ((Предотвращенный ущерб - TCO) / TCO) × 100%"
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeSm
                            color: Style.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "Порог эффективности: > 0%"
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                    }
                }

                // Secondary financial metrics row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "Предотвращенный ущерб", val: root.currentScenario ? root.currentScenario.avoidedLoss : "—", desc: "за 12 месяцев" },
                            { label: "Чистая выгода", val: root.currentScenario ? root.currentScenario.netBenefit : "—", desc: "ΔALE - TCO" },
                            { label: "Срок окупаемости", val: root.currentScenario ? root.currentScenario.payback : "—", desc: "(TCO / ΔALE) × 12 мес." },
                            { label: "Коэффициент выгоды", val: root.currentScenario ? root.currentScenario.bcr : "—", desc: "ΔALE / TCO" }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            color: Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 0
                                Text { text: modelData.label; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                Text { text: modelData.val; font.family: Style.fontMono; font.pixelSize: Style.fontSizeHeadlineSm; font.weight: Font.Bold; color: Style.textPrimary }
                                Text { text: modelData.desc; font.family: Style.fontMono; font.pixelSize: 9; color: Style.textMuted }
                            }
                        }
                    }
                }
            }
        }

        // Waterfall Chart & Formula Inspection Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Waterfall Chart Representation
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.45
                implicitHeight: 220
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
                            text: "WATERFALL-ДЕКОМПОЗИЦИЯ ДВИЖЕНИЯ РИСКА"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    // Waterfall Canvas
                    Canvas {
                        id: waterfallCanvas
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var w = width;
                            var h = height;

                            // Grid Lines
                            ctx.strokeStyle = Style.hairlineBorder;
                            ctx.lineWidth = 1;
                            ctx.beginPath();
                            ctx.moveTo(30, h - 24); ctx.lineTo(w - 10, h - 24);
                            ctx.moveTo(30, (h - 24) / 2);  ctx.lineTo(w - 10, (h - 24) / 2);
                            ctx.stroke();

                            if (!root.currentScenario) return;

                            var barW = Math.max(30, Math.min(50, (w - 100) / 4));
                            var baseY = h - 24;
                            var maxVal = Math.max(1.0,
                                                  root.currentScenario.aleBaseNum || 0,
                                                  root.currentScenario.tcoNum || 0,
                                                  root.currentScenario.avoidedLossNum || 0);
                            var scaleH = (baseY - 30) / maxVal;

                            var hAleBase = Math.max(4, (root.currentScenario.aleBaseNum || 0) * scaleH);
                            var hAvoided = Math.max(4, (root.currentScenario.avoidedLossNum || 0) * scaleH);
                            var hAleRes  = Math.max(4, (root.currentScenario.aleResNum || 0) * scaleH);
                            var hTco     = Math.max(4, (root.currentScenario.tcoNum || 0) * scaleH);

                            var x1 = 40;
                            var x2 = x1 + barW + 30;
                            var x3 = x2 + barW + 30;
                            var x4 = x3 + barW + 30;

                            // Bar 1: Базовый ALE
                            ctx.fillStyle = "#3F3F46";
                            ctx.fillRect(x1, baseY - hAleBase, barW, hAleBase);

                            // Bar 2: Avoided Loss (снижение)
                            ctx.fillStyle = "#10B981";
                            ctx.fillRect(x2, baseY - hAvoided, barW, hAvoided);

                            // Bar 3: Остаточный ALE
                            ctx.fillStyle = "#71717A";
                            ctx.fillRect(x3, baseY - hAleRes, barW, hAleRes);

                            // Bar 4: TCO Затраты
                            ctx.fillStyle = "#EF4444";
                            ctx.fillRect(x4, baseY - hTco, barW, hTco);
                        }

                        RowLayout {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 35
                            spacing: 20

                            Text { text: "ALE до (ущерб)"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                            Text { text: "-ΔALE (экономия)"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                            Text { text: "ALE после (остаток)"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                            Text { text: "TCO (затраты)"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                        }
                    }
                }
            }


        }

        // Summary Data Grid for Portfolio
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 220
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: "СВОДНЫЙ РАСЧЕТ РЕНТАБЕЛЬНОСТИ ИНВЕСТИЦИЙ ПО ПОРТФЕЛЮ УГРОЗ"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: typeof riskCalculator !== "undefined"
                                  ? ("Суммарная чистая выгода: " + riskCalculator.formatRub(riskCalculator.netBenefit))
                                  : ""
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeSm
                            font.weight: Font.Bold
                            color: (typeof riskCalculator !== "undefined" && riskCalculator.netBenefit >= 0) ? Style.riskLowText : Style.riskCriticalText
                        }
                    }
                }

                // Table Header
                RowLayout {
                    Layout.fillWidth: true
                    height: 24
                    spacing: 0

                    TableHeaderCell { Layout.fillWidth: true; text: "Актив КТ / Мера" }
                    TableHeaderCell { Layout.preferredWidth: 95; text: "SLE (₽)"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 50; text: "V до"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 60; text: "P до (%)"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 95; text: "ALE до (₽)"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 85; text: "TCO (₽)"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 50; text: "V пос"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 95; text: "Пред. ущерб"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 95; text: "Чистая выгода"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 85; text: "Net ROSI"; alignment: Text.AlignRight; hasRightBorder: false }
                }

                // Table Rows
                ListView {
                    id: scenListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.scenarios

                    delegate: Rectangle {
                        width: scenListView.width
                        height: 38
                        color: {
                            if (root.selectedScenarioIndex === index) return Style.surfaceActive;
                            if (mouseArea.containsMouse) return Style.surfaceHover;
                            return (index % 2 === 0) ? Style.panelSurface : Style.surfaceLow;
                        }
                        border.color: Style.hairlineBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 4

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: modelData.asset
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    font.weight: Font.DemiBold
                                    color: Style.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.measure
                                    font.family: Style.fontSans
                                    font.pixelSize: 10
                                    color: Style.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text { Layout.preferredWidth: 95; text: modelData.sle; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textPrimary }
                            Text { Layout.preferredWidth: 50; text: modelData.vBase.toFixed(2); font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textSecondary }
                            Text { Layout.preferredWidth: 60; text: modelData.probBase; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textSecondary }
                            Text { Layout.preferredWidth: 95; text: modelData.aleBase; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textPrimary }
                            Text { Layout.preferredWidth: 85; text: modelData.tco; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textSecondary }
                            Text { Layout.preferredWidth: 50; text: modelData.vRes.toFixed(2); font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; font.weight: Font.Bold; color: Style.riskLowText }
                            Text { Layout.preferredWidth: 95; text: modelData.avoidedLoss; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textPrimary }
                            Text { Layout.preferredWidth: 95; text: modelData.netBenefit; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; font.weight: Font.DemiBold; color: Style.textPrimary }
                            Text { Layout.preferredWidth: 85; text: modelData.rosi; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; font.weight: Font.Bold; color: (modelData.netBenefitNum >= 0) ? Style.riskLowText : Style.riskCriticalText }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedScenarioIndex = index
                        }
                    }
                }
            }
        }
    }
}
