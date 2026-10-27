import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

ScrollView {
    id: root
    contentWidth: width
    clip: true

    ColumnLayout {
        width: root.width
        spacing: 12

        // Top Row: 4 Metric Cards
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 8
            columnSpacing: 8

            MetricCard {
                Layout.fillWidth: true
                title: "АКТИВЫ КОММЕРЧЕСКОЙ ТАЙНЫ"
                iconText: "КТ"
                value: "14"
                unitText: "активов"
                footerLeft: "Режим ст. 10 98-ФЗ: 12 из 14"
                footerRight: "85.7%"
                badgeText: "ЗАЩИЩЕНО"
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ОТСЛЕЖИВАЕМЫЕ УЯЗВИМОСТИ"
                iconText: "УБИ"
                value: "38"
                unitText: "сценариев угроз"
                footerLeft: "Крит: 4 | Выс: 11 | Ср: 17 | Низ: 6"
                badgeText: "ФСТЭК 2025"
                badgeColor: Style.surfaceContainerHighest
                badgeTextColor: Style.textPrimary
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ПЛАН ЗАЩИТНЫХ МЕР"
                iconText: "СЗИ"
                value: "12"
                unitText: "комплексов мер"
                footerLeft: "CAPEX+OPEX: 12.8M ₽"
                footerRight: "Охват 86%"
                badgeText: "В ПЛАНЕ"
                badgeColor: Style.surfaceContainerHigh
                badgeTextColor: Style.textPrimary
            }

            MetricCard {
                Layout.fillWidth: true
                title: "СУММАРНЫЙ NET ROSI"
                iconText: "ROSI"
                value: "+142.8%"
                valueColor: Style.textPrimary
                badgeText: "ЭФФЕКТИВНО"
                footerLeft: "ΔALE экономия:"
                footerRight: "31.1M ₽ / год"
            }
        }

        // Analytical Split Workspace
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Layout.alignment: Qt.AlignTop

            // Left Workspace: 58% Width
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.58
                spacing: 12

                // Block 1: Severity Distribution Matrix
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 120
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
                                text: "Распределение угроз по степени критичности"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeHeadlineMd
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                            }
                            Text {
                                text: "(N=38)"
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                color: Style.textSecondary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "Методика БДУ ФСТЭК от 30.06.2025"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodySm
                                color: Style.textSecondary
                            }
                        }

                        // Segmented Stacked Density Bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 20
                            color: Style.surfaceContainer

                            Row {
                                anchors.fill: parent
                                Rectangle {
                                    width: parent.width * 0.105
                                    height: parent.height
                                    color: Style.riskCriticalText
                                    Text {
                                        anchors.centerIn: parent
                                        text: "4"
                                        color: Style.textOnPrimary
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                                Rectangle {
                                    width: parent.width * 0.289
                                    height: parent.height
                                    color: "#444748"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "11"
                                        color: Style.textOnPrimary
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                                Rectangle {
                                    width: parent.width * 0.447
                                    height: parent.height
                                    color: "#A1A1AA"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "17"
                                        color: Style.textPrimary
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                                Rectangle {
                                    width: parent.width * 0.159
                                    height: parent.height
                                    color: Style.surfaceContainerHighest
                                    Text {
                                        anchors.centerIn: parent
                                        text: "6"
                                        color: Style.textPrimary
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }

                        // Legend with Precise Percentages
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: [
                                    { name: "Критический", count: "4", pct: "10.5%", color: Style.riskCriticalText },
                                    { name: "Высокий", count: "11", pct: "28.9%", color: "#444748" },
                                    { name: "Средний", count: "17", pct: "44.7%", color: "#A1A1AA" },
                                    { name: "Низкий", count: "6", pct: "15.9%", color: Style.surfaceContainerHighest }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    color: Style.surfaceLow
                                    border.color: Style.hairlineBorder
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        spacing: 1

                                        RowLayout {
                                            spacing: 4
                                            Rectangle {
                                                width: 8
                                                height: 8
                                                color: modelData.color
                                            }
                                            Text {
                                                text: modelData.name
                                                font.family: Style.fontSans
                                                font.pixelSize: Style.fontSizeBodySm
                                                color: Style.textPrimary
                                            }
                                        }

                                        RowLayout {
                                            Text {
                                                text: modelData.count
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeCodeSm
                                                font.weight: Font.DemiBold
                                                color: Style.textPrimary
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: modelData.pct
                                                font.family: Style.fontMono
                                                font.pixelSize: 10
                                                color: Style.textSecondary
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Block 2: Vulnerability Level Reduction Chart (V до → V после)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 270
                    color: Style.panelSurface
                    border.color: Style.hairlineBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "Снижение уровня критичности (V до мер → V после мер)"
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeHeadlineMd
                                    font.weight: Font.DemiBold
                                    color: Style.textPrimary
                                }
                                Text {
                                    text: "Порог отсечения: Критический V > 8.0 | Высокий V ≥ 5.0 | Средний V ≥ 2.0"
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    color: Style.textSecondary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            RowLayout {
                                spacing: 10
                                RowLayout {
                                    spacing: 4
                                    Rectangle { width: 10; height: 10; color: "#27272A" }
                                    Text { text: "До СЗИ"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                }
                                RowLayout {
                                    spacing: 4
                                    Rectangle { width: 10; height: 10; color: "#A1A1AA" }
                                    Text { text: "После СЗИ"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                }
                            }
                        }

                        // Comparative Pair Bars
                        Repeater {
                            model: [
                                { title: "Кейс 1: BDU:2025-01611 / Центральный сервер СУБД PostgreSQL", vBase: 4.75, vRes: 1.54, delta: "-67.6%" },
                                { title: "Кейс 2: Конструктор УБИ / АРМ разработчиков и Git-сервер", vBase: 5.50, vRes: 1.82, delta: "-66.9%" },
                                { title: "BDU:2024-01928 / Доступ к БД АСУ ТП (SCADA Node 01)", vBase: 8.80, vRes: 2.20, delta: "-75.0%" },
                                { title: "CVE-2023-38606 / RCE в контроллере домена (AD-DC-01)", vBase: 9.50, vRes: 3.00, delta: "-68.4%" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 46
                                color: Style.surfaceLow
                                border.color: Style.hairlineBorder
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 3

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.title
                                            font.family: Style.fontSans
                                            font.pixelSize: Style.fontSizeBodySm
                                            font.weight: Font.DemiBold
                                            color: Style.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Rectangle {
                                            height: 16
                                            implicitWidth: deltaText.implicitWidth + 8
                                            color: Style.surfaceContainerHighest
                                            radius: 2
                                            Text {
                                                id: deltaText
                                                anchors.centerIn: parent
                                                text: modelData.delta
                                                font.family: Style.fontMono
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                color: Style.textPrimary
                                            }
                                        }
                                    }

                                    // Pair Bars (Max V = 10.0)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: modelData.vBase.toFixed(2)
                                            font.family: Style.fontMono
                                            font.pixelSize: 10
                                            color: Style.textSecondary
                                            width: 32
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 6
                                            color: Style.surfaceContainer

                                            Rectangle {
                                                width: parent.width * (modelData.vBase / 10.0)
                                                height: parent.height
                                                color: "#27272A"
                                            }
                                        }

                                        Text {
                                            text: modelData.vRes.toFixed(2)
                                            font.family: Style.fontMono
                                            font.pixelSize: 10
                                            color: Style.textPrimary
                                            font.weight: Font.DemiBold
                                            width: 32
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 6
                                            color: Style.surfaceContainer

                                            Rectangle {
                                                width: parent.width * (modelData.vRes / 10.0)
                                                height: parent.height
                                                color: "#A1A1AA"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Block 3: Net ROSI by Countermeasure
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 200
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
                                text: "Net ROSI по внедряемым мерам защиты"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeHeadlineMd
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "Сортировка по окупаемости"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodySm
                                color: Style.textSecondary
                            }
                        }

                        Repeater {
                            model: [
                                { code: "Кейс 1", name: "Изоляция СУБД во внутренний сегмент (МЭ) + патчинг", rosi: "+613.3%", tco: "450 000 ₽", deltaAle: "3 210 000 ₽", pct: 0.85 },
                                { code: "Кейс 2", name: "Внедрение Endpoint DLP + блокировка USB и внешнего контура", rosi: "+666.7%", tco: "600 000 ₽", deltaAle: "4 600 000 ₽", pct: 0.88 },
                                { code: "М-03", name: "Сегментация сети КИИ (NGFW / Микросегментация)", rosi: "+215.4%", tco: "3.2M ₽", deltaAle: "10.1M ₽", pct: 0.78 },
                                { code: "М-01", name: "Внедрение EDR-агентов на АРМ операторов КИИ", rosi: "+168.0%", tco: "2.5M ₽", deltaAle: "6.7M ₽", pct: 0.62 }
                            ]

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: modelData.code + ": " + modelData.name
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.rosi
                                        font.family: Style.fontMono
                                        font.pixelSize: Style.fontSizeCodeMd
                                        font.weight: Font.Bold
                                        color: Style.textPrimary
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    color: Style.surfaceContainer

                                    Rectangle {
                                        width: parent.width * modelData.pct
                                        height: parent.height
                                        color: Style.primary
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "TCO: " + modelData.tco
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "ΔALE: " + modelData.deltaAle + " / год"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Right Workspace: 42% Width (Top-5 by ALE Data Grid)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.42
                Layout.fillHeight: true
                color: Style.panelSurface
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: "Топ-5 по ожидаемому убытку (ALE)"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeHeadlineMd
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                            }
                            Text {
                                text: "Ранжирование сценариев до мер защиты (₽)"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodySm
                                color: Style.textSecondary
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            height: 20
                            implicitWidth: 64
                            color: Style.surfaceContainerHigh
                            Text {
                                anchors.centerIn: parent
                                text: "Год 2025"
                                font.family: Style.fontMono
                                font.pixelSize: 10
                                color: Style.textPrimary
                            }
                        }
                    }

                    // Table Header
                    RowLayout {
                        Layout.fillWidth: true
                        height: 24
                        spacing: 0

                        TableHeaderCell { Layout.fillWidth: true; Layout.preferredWidth: 130; text: "Угроза / Актив" }
                        TableHeaderCell { Layout.preferredWidth: 60; text: "SLE"; alignment: Text.AlignRight }
                        TableHeaderCell { Layout.preferredWidth: 44; text: "ARO"; alignment: Text.AlignRight }
                        TableHeaderCell { Layout.preferredWidth: 64; text: "ALE до"; alignment: Text.AlignRight }
                        TableHeaderCell { Layout.preferredWidth: 64; text: "ALE пос"; alignment: Text.AlignRight }
                        TableHeaderCell { Layout.preferredWidth: 64; text: "Статус"; alignment: Text.AlignHCenter; hasRightBorder: false }
                    }

                    // Table Rows
                    Repeater {
                        model: [
                            {
                                threat: "BDU:2024-01928",
                                asset: "SCADA Node 01",
                                sle: "18.5M",
                                aro: "0.65",
                                aleBase: "12.0M",
                                aleRes: "3.0M",
                                status: "Критический",
                                statusShort: "КРИТИЧ"
                            },
                            {
                                threat: "CVE-2023-38606",
                                asset: "AD-DC-01 (Kerberos)",
                                sle: "11.0M",
                                aro: "0.80",
                                aleBase: "8.8M",
                                aleRes: "2.8M",
                                status: "Критический",
                                statusShort: "КРИТИЧ"
                            },
                            {
                                threat: "Кейс 2 (УБИ.027)",
                                asset: "Git-сервер и АРМ",
                                sle: "10.0M",
                                aro: "0.69",
                                aleBase: "6.9M",
                                aleRes: "2.3M",
                                status: "Высокий",
                                statusShort: "ВЫСОК"
                            },
                            {
                                threat: "BDU:2023-05441",
                                asset: "API Gateway Prod",
                                sle: "14.2M",
                                aro: "0.45",
                                aleBase: "6.4M",
                                aleRes: "1.8M",
                                status: "Высокий",
                                statusShort: "ВЫСОК"
                            },
                            {
                                threat: "Кейс 1 (01611)",
                                asset: "СУБД PostgreSQL",
                                sle: "8.0M",
                                aro: "0.59",
                                aleBase: "4.8M",
                                aleRes: "1.5M",
                                status: "Высокий",
                                statusShort: "ВЫСОК"
                            }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            color: (index % 2 === 0) ? Style.panelSurface : Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 4

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 130
                                    spacing: 0

                                    RowLayout {
                                        spacing: 4
                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: Style.getRiskColor(modelData.status)
                                        }
                                        Text {
                                            text: modelData.threat
                                            font.family: Style.fontMono
                                            font.pixelSize: Style.fontSizeCodeSm
                                            font.weight: Font.DemiBold
                                            color: Style.textPrimary
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Text {
                                        text: modelData.asset
                                        font.family: Style.fontSans
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: 60
                                    text: modelData.sle
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    color: Style.textPrimary
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 44
                                    text: modelData.aro
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    color: Style.textSecondary
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 64
                                    text: modelData.aleBase
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    font.weight: Font.DemiBold
                                    color: Style.textPrimary
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 64
                                    text: modelData.aleRes
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    color: Style.textSecondary
                                    horizontalAlignment: Text.AlignRight
                                }

                                RiskBadge {
                                    Layout.preferredWidth: 64
                                    level: modelData.status
                                    text: modelData.statusShort
                                    compact: true
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
