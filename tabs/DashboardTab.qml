import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

ScrollView {
    id: root
    contentWidth: width
    clip: true

    readonly property var vulns: (typeof riskCalculator !== "undefined") ? riskCalculator.vulnerabilities : []
    readonly property var assets: (typeof riskCalculator !== "undefined") ? riskCalculator.assets : []
    readonly property var scenarios: (typeof riskCalculator !== "undefined") ? riskCalculator.economicScenarios : []

    // Подсчет распределения критичности угроз из реальной базы проекта
    readonly property int countCrit: {
        var c = 0
        for (var i = 0; i < vulns.length; ++i) {
            if (vulns[i].level === "Критический" || vulns[i].cvss >= 9.0) c++
        }
        return c
    }
    readonly property int countHigh: {
        var c = 0
        for (var i = 0; i < vulns.length; ++i) {
            if (vulns[i].level === "Высокий" || (vulns[i].cvss >= 7.0 && vulns[i].cvss < 9.0)) c++
        }
        return c
    }
    readonly property int countMed: {
        var c = 0
        for (var i = 0; i < vulns.length; ++i) {
            if (vulns[i].level === "Средний" || (vulns[i].cvss >= 4.0 && vulns[i].cvss < 7.0)) c++
        }
        return c
    }
    readonly property int countLow: {
        var c = 0
        for (var i = 0; i < vulns.length; ++i) {
            if (vulns[i].level === "Низкий" || (vulns[i].cvss > 0 && vulns[i].cvss < 4.0)) c++
        }
        return c
    }
    readonly property int totalThreats: countCrit + countHigh + countMed + countLow

    // Топ-5 активов по убытку SLE
    readonly property var topAssets: {
        var list = root.assets.slice()
        list.sort(function(a, b) {
            var sA = (a.directRecoveryCost || 0) + (a.indirectBusinessLoss || 0)
            var sB = (b.directRecoveryCost || 0) + (b.indirectBusinessLoss || 0)
            return sB - sA
        })
        return list.slice(0, 5)
    }

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
                value: (typeof riskCalculator !== "undefined") ? riskCalculator.totalAssetsCount.toString() : "0"
                unitText: "активов"
                footerLeft: (typeof riskCalculator !== "undefined" && riskCalculator.totalAssetsCount > 0) ? "Режим ст. 10 98-ФЗ: соблюден" : "Нет добавленных активов"
                footerRight: (typeof riskCalculator !== "undefined" && riskCalculator.totalAssetsCount > 0) ? "100%" : "—"
                badgeText: (typeof riskCalculator !== "undefined" && riskCalculator.totalAssetsCount > 0) ? "ЗАЩИЩЕНО" : "ПУСТО"
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ОТСЛЕЖИВАЕМЫЕ УЯЗВИМОСТИ"
                iconText: "УБИ"
                value: (typeof riskCalculator !== "undefined") ? riskCalculator.totalVulnsCount.toString() : "0"
                unitText: "сценариев угроз"
                footerLeft: "Методика ФСТЭК 2025"
                footerRight: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable) ? "БДУ: 86k зап." : "БДУ ФСТЭК"
                badgeText: (typeof riskCalculator !== "undefined" && riskCalculator.totalVulnsCount > 0) ? "ФСТЭК 2025" : "ПУСТО"
                badgeColor: Style.surfaceContainerHighest
                badgeTextColor: Style.textPrimary
            }

            MetricCard {
                Layout.fillWidth: true
                title: "ПЛАН ЗАЩИТНЫХ МЕР"
                iconText: "СЗИ"
                value: (typeof riskCalculator !== "undefined") ? riskCalculator.totalMeasuresCount.toString() : "0"
                unitText: "комплексов мер"
                footerLeft: (typeof riskCalculator !== "undefined" && riskCalculator.totalMeasuresCount > 0) ? ("TCO: " + riskCalculator.formatRub(riskCalculator.totalTco)) : "TCO: —"
                footerRight: "ГОСТ 27005"
                badgeText: (typeof riskCalculator !== "undefined" && riskCalculator.totalMeasuresCount > 0) ? "В ПЛАНЕ" : "ПУСТО"
                badgeColor: Style.surfaceContainerHigh
                badgeTextColor: Style.textPrimary
            }

            MetricCard {
                Layout.fillWidth: true
                title: "СУММАРНЫЙ NET ROSI"
                iconText: "ROSI"
                value: (typeof riskCalculator !== "undefined" && riskCalculator.hasValidRosi)
                       ? ((riskCalculator.netRosiPercent >= 0 ? "+" : "") + riskCalculator.formatNumber(riskCalculator.netRosiPercent, 1) + "%")
                       : "—"
                valueColor: (typeof riskCalculator !== "undefined" && riskCalculator.hasValidRosi && riskCalculator.netBenefit >= 0)
                            ? Style.riskLowText
                            : (typeof riskCalculator !== "undefined" && riskCalculator.hasValidRosi ? Style.riskCriticalText : Style.textSecondary)
                badgeText: (typeof riskCalculator !== "undefined" && riskCalculator.hasValidRosi)
                           ? (riskCalculator.netBenefit >= 0 ? "ЭФФЕКТИВНО" : "УБЫТОЧНО")
                           : "НЕТ ДАННЫХ"
                footerLeft: "ΔALE экономия:"
                footerRight: (typeof riskCalculator !== "undefined" && riskCalculator.hasValidRosi)
                             ? (riskCalculator.formatRub(riskCalculator.totalAvoidedLoss) + " / год")
                             : "—"
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
                                text: "(N=" + root.totalThreats + ")"
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
                            clip: true

                            Text {
                                anchors.centerIn: parent
                                visible: root.totalThreats === 0
                                text: "Угрозы еще не добавлены в проект"
                                font.family: Style.fontSans
                                font.pixelSize: 10
                                color: Style.textMuted
                            }

                            Row {
                                anchors.fill: parent
                                visible: root.totalThreats > 0

                                Rectangle {
                                    width: root.totalThreats > 0 ? (parent.width * (root.countCrit / root.totalThreats)) : 0
                                    height: parent.height
                                    color: Style.riskCriticalText
                                    visible: width > 0
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.countCrit.toString()
                                        color: Style.textOnPrimary
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                                Rectangle {
                                    width: root.totalThreats > 0 ? (parent.width * (root.countHigh / root.totalThreats)) : 0
                                    height: parent.height
                                    color: "#444748"
                                    visible: width > 0
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.countHigh.toString()
                                        color: Style.textOnPrimary
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                                Rectangle {
                                    width: root.totalThreats > 0 ? (parent.width * (root.countMed / root.totalThreats)) : 0
                                    height: parent.height
                                    color: "#A1A1AA"
                                    visible: width > 0
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.countMed.toString()
                                        color: Style.textPrimary
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                                Rectangle {
                                    width: root.totalThreats > 0 ? (parent.width * (root.countLow / root.totalThreats)) : 0
                                    height: parent.height
                                    color: Style.surfaceContainerHighest
                                    visible: width > 0
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.countLow.toString()
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
                                    { name: "Критический", count: root.countCrit.toString(), pct: root.totalThreats > 0 ? ((root.countCrit / root.totalThreats * 100).toFixed(1) + "%") : "0%", color: Style.riskCriticalText },
                                    { name: "Высокий", count: root.countHigh.toString(), pct: root.totalThreats > 0 ? ((root.countHigh / root.totalThreats * 100).toFixed(1) + "%") : "0%", color: "#444748" },
                                    { name: "Средний", count: root.countMed.toString(), pct: root.totalThreats > 0 ? ((root.countMed / root.totalThreats * 100).toFixed(1) + "%") : "0%", color: "#A1A1AA" },
                                    { name: "Низкий", count: root.countLow.toString(), pct: root.totalThreats > 0 ? ((root.countLow / root.totalThreats * 100).toFixed(1) + "%") : "0%", color: Style.surfaceContainerHighest }
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

                        Text {
                            visible: root.scenarios.length === 0
                            text: "Нет данных для отображения.\nДобавьте активы, уязвимости и назначьте защитные меры на вкладке «Меры»."
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodySm
                            color: Style.textMuted
                            font.italic: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.topMargin: 40
                        }

                        // Comparative Pair Bars
                        Repeater {
                            model: root.scenarios.slice(0, 4)

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
                                            text: modelData.measureId + ": " + modelData.measureTitle
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
                                                text: modelData.deltaVText
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
                                                width: Math.min(parent.width, parent.width * (modelData.vBase / 10.0))
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
                                                width: Math.min(parent.width, parent.width * (modelData.vRes / 10.0))
                                                height: parent.height
                                                color: "#A1A1AA"
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
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

                        Text {
                            visible: root.scenarios.length === 0
                            text: "Меры защиты не добавлены. Создайте меры на вкладке «Меры»."
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodySm
                            color: Style.textMuted
                            font.italic: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.topMargin: 20
                        }

                        Repeater {
                            model: root.scenarios.slice(0, 4)

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: modelData.measureId + ": " + modelData.measureTitle
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
                                        color: modelData.netBenefitNum >= 0 ? Style.riskLowText : Style.riskCriticalText
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    color: Style.surfaceContainer

                                    Rectangle {
                                        width: Math.min(parent.width, Math.max(8, parent.width * Math.min(1.0, Math.max(0.05, (modelData.rosiNum + 100.0) / 400.0))))
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
                                        text: "ΔALE: " + modelData.avoidedLoss + " / год"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
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
                                text: "Топ активов по единичному ущербу (SLE)"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeHeadlineMd
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                            }
                            Text {
                                text: "Ранжирование по совокупной стоимости актива (₽)"
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
                                text: "Проект"
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

                        TableHeaderCell { Layout.fillWidth: true; Layout.preferredWidth: 130; text: "Актив / Угроза" }
                        TableHeaderCell { Layout.preferredWidth: 70; text: "SLE"; alignment: Text.AlignRight }
                        TableHeaderCell { Layout.preferredWidth: 44; text: "I_infr"; alignment: Text.AlignRight }
                        TableHeaderCell { Layout.preferredWidth: 70; text: "Прямой"; alignment: Text.AlignRight }
                        TableHeaderCell { Layout.preferredWidth: 64; text: "Статус"; alignment: Text.AlignHCenter; hasRightBorder: false }
                    }

                    Text {
                        visible: root.topAssets.length === 0
                        text: "Нет добавленных активов.\nСоздайте активы на вкладке «Активы»."
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeBodySm
                        color: Style.textMuted
                        font.italic: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        Layout.topMargin: 40
                    }

                    // Table Rows
                    Repeater {
                        model: root.topAssets

                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            color: (index % 2 === 0) ? Style.panelSurface : Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            readonly property real sleVal: (modelData.directRecoveryCost || 0) + (modelData.indirectBusinessLoss || 0)
                            readonly property string vCode: (modelData.vulns && modelData.vulns.length > 0) ? modelData.vulns[0] : "Без угроз"

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
                                            color: vCode !== "Без угроз" ? Style.riskHigh : Style.textMuted
                                        }
                                        Text {
                                            text: modelData.primaryAssetName || ""
                                            font.family: Style.fontSans
                                            font.pixelSize: Style.fontSizeBodySm
                                            font.weight: Font.DemiBold
                                            color: Style.textPrimary
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Text {
                                        text: (modelData.supportingAssetName && modelData.supportingAssetName !== "-") ? modelData.supportingAssetName : vCode
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: 70
                                    text: typeof riskCalculator !== "undefined" ? riskCalculator.formatRub(sleVal) : "—"
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    color: Style.textPrimary
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 44
                                    text: {
                                        var k = (modelData.componentType === 0 ? 0.55 : (modelData.componentType === 3 ? 0.35 : 0.25))
                                        var l = (modelData.share === 0 ? 0.20 : (modelData.share === 1 ? 0.16 : 0.10))
                                        var p = (modelData.perimeter === 0 ? 0.33 : 0.18)
                                        return (k + l + p).toFixed(2)
                                    }
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    color: Style.textSecondary
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 70
                                    text: typeof riskCalculator !== "undefined" ? riskCalculator.formatRub(modelData.directRecoveryCost || 0) : "—"
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    color: Style.textSecondary
                                    horizontalAlignment: Text.AlignRight
                                }

                                RiskBadge {
                                    Layout.preferredWidth: 64
                                    level: vCode !== "Без угроз" ? "Высокий" : "Низкий"
                                    text: vCode !== "Без угроз" ? "УГРОЗА" : "ЧИСТО"
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
