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

    readonly property var scenarios: [
        {
            asset: "Кейс 1: Клиентская база и контракты",
            subAsset: "Центральный сервер СУБД PostgreSQL",
            sle: "8 000 000 ₽",
            sleNum: 8000000,
            vBase: 4.75,
            probBase: "59.4%",
            aleBase: "4 750 000 ₽",
            measure: "Изоляция СУБД (МЭ) + патчинг",
            tco: "450 000 ₽",
            tcoNum: 450000,
            vRes: 1.54,
            probRes: "19.3%",
            aleRes: "1 540 000 ₽",
            avoidedLoss: "3 210 000 ₽",
            netBenefit: "2 760 000 ₽",
            rosi: "+613.3%",
            payback: "1.7 мес.",
            bcr: "7.13",
            formulaDetails: "Кейс 1 (БДУ BDU:2025-01611):\n" +
                           "1. SLE = 1 200 000 + 6 800 000 = 8 000 000 ₽ (ст. 10 98-ФЗ = Да)\n" +
                           "2. I_infr_base = 0.55 + 0.16 + 0.33 = 1.04\n" +
                           "3. V_base = 8.8 × 1.04 × (0.30 + 0.50) = 4.75 (ВЫСОКИЙ, SLA до 7 дней)\n" +
                           "4. Prob_base = 4.75 / 8.0 = 59.4%  ==>  ALE_base = 8 000 000 × 59.4% = 4 750 000 ₽\n" +
                           "5. После меры: l·L -> 0.10, p·P -> 0.18  ==>  I_infr_res = 0.55 + 0.10 + 0.18 = 0.83\n" +
                           "6. V_res = 8.8 × 0.83 × (0.30 + 0.50) = 1.54 (НИЗКИЙ, SLA до 4 мес.)\n" +
                           "7. Prob_res = 1.54 / 8.0 = 19.3%  ==>  ALE_res = 8 000 000 × 19.3% = 1 540 000 ₽\n" +
                           "8. Avoided Loss (ΔALE) = 4 750 000 - 1 540 000 = 3 210 000 ₽\n" +
                           "9. Net Benefit = 3 210 000 - 450 000 = 2 760 000 ₽\n" +
                           "10. Net ROSI = (2 760 000 / 450 000) × 100% = +613.3% [ОКУПАЕМО]"
        },
        {
            asset: "Кейс 2: Исходный код и ноу-хау",
            subAsset: "АРМ разработчиков и Git-сервер",
            sle: "10 000 000 ₽",
            sleNum: 10000000,
            vBase: 5.50,
            probBase: "68.8%",
            aleBase: "6 880 000 ₽",
            measure: "Endpoint DLP + блокировка USB и внешнего доступа",
            tco: "600 000 ₽",
            tcoNum: 600000,
            vRes: 1.82,
            probRes: "22.8%",
            aleRes: "2 280 000 ₽",
            avoidedLoss: "4 600 000 ₽",
            netBenefit: "4 000 000 ₽",
            rosi: "+666.7%",
            payback: "1.6 мес.",
            bcr: "7.67",
            formulaDetails: "Кейс 2 (Конструктор УБИ п. 5.3.3 ФСТЭК 2021 + CVSS 3.1 AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N):\n" +
                           "1. SLE = 3 000 000 + 7 000 000 = 10 000 000 ₽ (ст. 10 98-ФЗ = Да)\n" +
                           "2. I_infr_base = 0.25 + 0.20 + 0.33 = 0.78, I_cvss = 5.5\n" +
                           "3. V_base = 5.5 × 0.78 × (0.30 + 0.30) = 5.50 (ВЫСОКИЙ, SLA до 7 дней)\n" +
                           "4. Prob_base = 5.50 / 8.0 = 68.8%  ==>  ALE_base = 10 000 000 × 68.8% = 6 880 000 ₽\n" +
                           "5. После меры: l·L -> 0.10, p·P -> 0.18  ==>  I_infr_res = 0.25 + 0.10 + 0.18 = 0.53\n" +
                           "6. V_res = 5.5 × 0.53 × (0.30 + 0.30) = 1.82 (НИЗКИЙ, SLA до 4 мес.)\n" +
                           "7. Avoided Loss = 6 880 000 - 2 280 000 = 4 600 000 ₽\n" +
                           "8. Net Benefit = 4 600 000 - 600 000 = 4 000 000 ₽\n" +
                           "9. Net ROSI = (4 000 000 / 600 000) × 100% = +666.7% [ОКУПАЕМО]"
        },
        {
            asset: "SCADA Node 01",
            subAsset: "АСУ ТП Сервер ядра",
            sle: "18 500 000 ₽",
            sleNum: 18500000,
            vBase: 8.80,
            probBase: "100.0%",
            aleBase: "18 500 000 ₽",
            measure: "Внедрение WAF и микросегментации",
            tco: "2 400 000 ₽",
            tcoNum: 2400000,
            vRes: 2.20,
            probRes: "27.5%",
            aleRes: "5 087 500 ₽",
            avoidedLoss: "13 412 500 ₽",
            netBenefit: "11 012 500 ₽",
            rosi: "+458.9%",
            payback: "2.1 мес.",
            bcr: "5.59",
            formulaDetails: "Сценарий SCADA Node 01:\n" +
                           "1. SLE = 18 500 000 ₽, I_cvss = 9.8, I_infr_base = 0.88, I_at = 0.60, I_imp = 0.50\n" +
                           "2. V_base = 9.8 × 0.88 × (0.60 + 0.50) = 8.80 (КРИТИЧЕСКИЙ, SLA до 24 ч)\n" +
                           "3. Prob_base = min(8.8/8.0, 1.0) = 100%  ==>  ALE_base = 18 500 000 ₽\n" +
                           "4. Avoided Loss = 18 500 000 - 5 087 500 = 13 412 500 ₽\n" +
                           "5. Net Benefit = 13 412 500 - 2 400 000 = 11 012 500 ₽\n" +
                           "6. Net ROSI = (11 012 500 / 2 400 000) × 100% = +458.9%"
        }
    ]

    readonly property var currentScenario: scenarios[selectedScenarioIndex]

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
                value: "-67.6%"
                unitText: "в 3.1 раза"
                footerLeft: "V: 4.75 → 1.54"
                footerRight: "SLA: 4 мес."
                badgeText: "ТАБЛИЦА 2"
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ВЕРОЯТНОСТЬ ИНЦИДЕНТА"
                iconText: "PROB"
                value: "19.3%"
                unitText: "было: 59.4%"
                footerLeft: "Снижение риска:"
                footerRight: "-40.1%"
                badgeText: "ISO 27005"
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ПРЕДОТВРАЩЕННЫЙ УЩЕРБ"
                iconText: "ΔALE"
                value: "3.21M ₽"
                unitText: "в год"
                footerLeft: "Базовый ALE:"
                footerRight: "4.75M ₽"
                badgeText: "ЭКОНОМИЯ"
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ЗАТРАТЫ НА МЕРЫ (TCO)"
                iconText: "TCO"
                value: "450 000 ₽"
                unitText: "CAPEX+OPEX"
                footerLeft: "Срок окупаемости:"
                footerRight: "1.7 мес."
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
                            Rectangle {
                                height: 18
                                implicitWidth: isoTag.implicitWidth + 8
                                color: Style.surfaceContainerHigh
                                radius: 2
                                Text {
                                    id: isoTag
                                    anchors.centerIn: parent
                                    text: "ГОСТ Р ИСО/МЭК 27005 / ENISA"
                                    font.family: Style.fontMono
                                    font.pixelSize: 10
                                    color: Style.textPrimary
                                }
                            }
                        }

                        RowLayout {
                            spacing: 12
                            Text {
                                text: root.currentScenario.rosi
                                font.family: Style.fontMono
                                font.pixelSize: 42
                                font.weight: Font.Bold
                                color: Style.primary
                            }
                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: "Net ROSI (Чистая рентабельность инвестиций)"
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeHeadlineMd
                                    font.weight: Font.DemiBold
                                    color: Style.textPrimary
                                }
                                Text {
                                    text: "Суммарный Net ROSI портфеля мер: +142.8%"
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
                        color: Style.riskLowBg
                        border.color: Style.riskLowBorder
                        border.width: 1
                        radius: 2

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: "✓"
                                font.family: Style.fontMono
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                color: Style.riskLowText
                            }

                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: "ИНВЕСТИЦИЯ ВЫСОКОЭФФЕКТИВНА"
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    font.weight: Font.Bold
                                    color: Style.riskLowText
                                }
                                Text {
                                    text: "Рекомендовано к защите перед CEO / CFO"
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
                            text: "Формула: Net ROSI = ((Avoided Loss - Cost_TCO) / Cost_TCO) × 100% = ((" + root.currentScenario.avoidedLoss + " - " + root.currentScenario.tco + ") / " + root.currentScenario.tco + ") × 100%"
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
                            { label: "Предотвращенный ущерб (ΔALE)", val: root.currentScenario.avoidedLoss, desc: "за 12 месяцев" },
                            { label: "Чистая выгода (Net Benefit)", val: root.currentScenario.netBenefit, desc: "ΔALE - TCO" },
                            { label: "Срок окупаемости (Payback)", val: root.currentScenario.payback, desc: "(TCO / ΔALE) × 12 мес." },
                            { label: "Коэффициент выгоды (BCR)", val: root.currentScenario.bcr, desc: "ΔALE / TCO" }
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
                Layout.preferredWidth: parent.width * 0.50
                implicitHeight: 210
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
                            text: "WATERFALL-ДЕКОМПОЗИЦИЯ ДВИЖЕНИЯ РИСКА (₽)"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Финансовый поток"
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
                            ctx.moveTo(40, h - 24); ctx.lineTo(w - 10, h - 24);
                            ctx.moveTo(40, h / 2);  ctx.lineTo(w - 10, h / 2);
                            ctx.stroke();

                            var barW = 50;
                            var baseY = h - 24;

                            // Bar 1: Базовый ALE (15.5M / 4.75M)
                            ctx.fillStyle = "#27272A";
                            ctx.fillRect(50, 20, barW, baseY - 20);

                            // Bar 2: Avoided Loss (снижение)
                            ctx.fillStyle = "#A1A1AA";
                            ctx.fillRect(140, 20, barW, (baseY - 20) * 0.68);

                            // Bar 3: Остаточный ALE
                            ctx.fillStyle = "#71717A";
                            ctx.fillRect(230, 20 + ((baseY - 20) * 0.68), barW, (baseY - 20) * 0.32);

                            // Bar 4: TCO Затраты
                            ctx.fillStyle = "#18181B";
                            ctx.fillRect(320, baseY - 35, barW, 35);
                        }

                        RowLayout {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 40
                            spacing: 40

                            Text { text: "ALE до"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                            Text { text: "-ΔALE"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                            Text { text: "ALE после"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                            Text { text: "TCO меры"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                        }
                    }
                }
            }

            // Step-by-step formula details box (like test (2).go output)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.50
                implicitHeight: 210
                color: Style.panelSurface
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "ЧИСЛОВАЯ ПОДСТАНОВКА В ФОРМУЛЫ (МЕТОДИКА)"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Протокол аудита"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Style.surfaceLow
                        border.color: Style.hairlineBorder
                        border.width: 1

                        ScrollView {
                            anchors.fill: parent
                            clip: true

                            Text {
                                anchors.fill: parent
                                anchors.margins: 8
                                text: root.currentScenario.formulaDetails
                                font.family: Style.fontMono
                                font.pixelSize: 11
                                color: Style.textPrimary
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        // Summary Data Grid for Portfolio
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 180
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

                        RowLayout {
                            spacing: 6
                            AppButton { text: "PDF Отчет"; iconText: "📄" }
                            AppButton { text: "Excel / CSV"; iconText: "📊" }
                            AppButton { text: "Печать"; iconText: "🖨" }
                        }
                    }
                }

                // Table Header
                RowLayout {
                    Layout.fillWidth: true
                    height: 24
                    spacing: 0

                    TableHeaderCell { Layout.fillWidth: true; text: "Актив КТ / Мера" }
                    TableHeaderCell { Layout.preferredWidth: 80; text: "SLE (₽)"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 50; text: "V до"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 55; text: "Prob до"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 80; text: "ALE до"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 70; text: "TCO (₽)"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 50; text: "V пос"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 80; text: "Avoided Loss"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 80; text: "Net Benefit"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 75; text: "Net ROSI"; alignment: Text.AlignRight; hasRightBorder: false }
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
                        height: 36
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

                            Text { Layout.preferredWidth: 80; text: modelData.sle; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textPrimary }
                            Text { Layout.preferredWidth: 50; text: modelData.vBase.toFixed(2); font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textSecondary }
                            Text { Layout.preferredWidth: 55; text: modelData.probBase; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textSecondary }
                            Text { Layout.preferredWidth: 80; text: modelData.aleBase; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textPrimary }
                            Text { Layout.preferredWidth: 70; text: modelData.tco; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textSecondary }
                            Text { Layout.preferredWidth: 50; text: modelData.vRes.toFixed(2); font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; font.weight: Font.Bold; color: Style.riskLowText }
                            Text { Layout.preferredWidth: 80; text: modelData.avoidedLoss; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; color: Style.textPrimary }
                            Text { Layout.preferredWidth: 80; text: modelData.netBenefit; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; font.weight: Font.DemiBold; color: Style.textPrimary }
                            Text { Layout.preferredWidth: 75; text: modelData.rosi; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; horizontalAlignment: Text.AlignRight; font.weight: Font.Bold; color: Style.riskLowText }
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
