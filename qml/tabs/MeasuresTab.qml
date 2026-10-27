import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    property int selectedIndex: 0

    readonly property var measuresModel: [
        {
            id: "SEC-01",
            title: "Изоляция СУБД во внутренний сегмент + патчинг",
            targetVuln: "BDU:2025-01611 / Центральный сервер СУБД PostgreSQL",
            asset: "Клиентская база и условия контрактов (Режим КТ)",
            measureType: "Архитектурная + Патч-менеджмент (п. 22, 25)",
            fstecClass: "ЗИС.2, ЗИС.3 — Защита сетевых взаимодействий",
            tco: "450 000 ₽",
            tcoNum: 450000,
            oldShare: "50-70% компонентов (0.16)",
            newShare: "Менее 10% компонентов (0.10)",
            oldPerimeter: "Доступно из Интернет (0.33)",
            newPerimeter: "Недоступно из Интернет (0.18)",
            iInfrOld: "1.04",
            iInfrNew: "0.83",
            vBase: "4.75",
            vRes: "1.54",
            levelOld: "Высокий",
            levelNew: "Низкий",
            deltaV: "-67.6%",
            deltaAle: "3 210 000 ₽",
            netBenefit: "2 760 000 ₽",
            rosi: "+613.3%",
            status: "Внедрено"
        },
        {
            id: "SEC-02",
            title: "Внедрение Endpoint DLP + блокировка USB-носителей",
            targetVuln: "Конструктор УБИ: Копирование исходного кода инсайдером",
            asset: "Исходный код и алгоритмы (Секрет производства / Ноу-хау)",
            measureType: "Endpoint DLP + Контроль съемных носителей (п. 25)",
            fstecClass: "УПД.3 — Управление правами доступа и контроль утечек",
            tco: "600 000 ₽",
            tcoNum: 600000,
            oldShare: "Более 70% узлов (0.20)",
            newShare: "Менее 10% узлов (0.10)",
            oldPerimeter: "Доступно из Интернет (0.33)",
            newPerimeter: "Недоступно из Интернет (0.18)",
            iInfrOld: "0.78",
            iInfrNew: "0.53",
            vBase: "5.50",
            vRes: "1.82",
            levelOld: "Высокий",
            levelNew: "Низкий",
            deltaV: "-66.9%",
            deltaAle: "4 600 000 ₽",
            netBenefit: "4 000 000 ₽",
            rosi: "+666.7%",
            status: "В плане"
        },
        {
            id: "SEC-03",
            title: "Внедрение Web Application Firewall (WAF кластер)",
            targetVuln: "BDU:2024-01928 / Доступ к БД АСУ ТП (SCADA Node 01)",
            asset: "АСУ ТП Сервер ядра (SCADA)",
            measureType: "Межсетевой экран прикладного уровня L7",
            fstecClass: "ЗИС.2 — Межсетевое экранирование",
            tco: "2 400 000 ₽",
            tcoNum: 2400000,
            oldShare: "Более 50% узлов (0.20)",
            newShare: "Менее 10% узлов (0.10)",
            oldPerimeter: "Доступно из Интернет (0.33)",
            newPerimeter: "Недоступно из Интернет (0.18)",
            iInfrOld: "0.88",
            iInfrNew: "0.22",
            vBase: "8.80",
            vRes: "2.20",
            levelOld: "Критический",
            levelNew: "Средний",
            deltaV: "-75.0%",
            deltaAle: "13 380 000 ₽",
            netBenefit: "10 980 000 ₽",
            rosi: "+457.5%",
            status: "В плане"
        },
        {
            id: "SEC-04",
            title: "Микросегментация сети КИИ и Jump-Host",
            targetVuln: "CVE-2023-38606 / RCE в контроллере домена AD-DC-01",
            asset: "Инфраструктура Active Directory",
            measureType: "Сетевая изоляция и Jump-Host",
            fstecClass: "ИАФ.1 — Идентификация и аутентификация",
            tco: "1 800 000 ₽",
            tcoNum: 1800000,
            oldShare: "Более 50% узлов (0.20)",
            newShare: "От 10% до 50% (0.12)",
            oldPerimeter: "Доступно из Интернет (0.33)",
            newPerimeter: "Недоступно из Интернет (0.18)",
            iInfrOld: "0.78",
            iInfrNew: "0.25",
            vBase: "7.10",
            vRes: "2.25",
            levelOld: "Высокий",
            levelNew: "Средний",
            deltaV: "-68.3%",
            deltaAle: "6 000 000 ₽",
            netBenefit: "4 200 000 ₽",
            rosi: "+233.3%",
            status: "Тест"
        }
    ]

    readonly property var currentMeasure: measuresModel[selectedIndex]

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Master Pane (Left 52%)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.52
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Toolbar
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        CustomTextField {
                            Layout.fillWidth: true
                            placeholderText: "Поиск защитной меры или сценария..."
                            isMonospace: false
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 120
                            model: ["Все статусы", "В плане", "Внедрено", "Тест"]
                        }

                        AppButton {
                            isPrimary: true
                            text: "+ Мера"
                            iconText: "+"
                        }
                    }
                }

                // Table Header
                RowLayout {
                    Layout.fillWidth: true
                    height: 24
                    spacing: 0

                    TableHeaderCell { Layout.preferredWidth: 70; text: "Код" }
                    TableHeaderCell { Layout.fillWidth: true; text: "Наименование меры" }
                    TableHeaderCell { Layout.preferredWidth: 90; text: "TCO (₽)"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 75; text: "V до → пос"; alignment: Text.AlignHCenter }
                    TableHeaderCell { Layout.preferredWidth: 60; text: "ΔV (%)"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 75; text: "Статус"; alignment: Text.AlignHCenter; hasRightBorder: false }
                }

                // Table Rows
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.measuresModel

                    delegate: Rectangle {
                        width: listView.width
                        height: 34
                        color: {
                            if (root.selectedIndex === index) return Style.surfaceActive;
                            if (mouseArea.containsMouse) return Style.surfaceHover;
                            return (index % 2 === 0) ? Style.panelSurface : Style.surfaceLow;
                        }
                        border.color: Style.hairlineBorder
                        border.width: 1

                        Rectangle {
                            visible: root.selectedIndex === index
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 3
                            color: Style.primary
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                Layout.preferredWidth: 64
                                text: modelData.id
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: modelData.title
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    font.weight: Font.DemiBold
                                    color: Style.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.targetVuln
                                    font.family: Style.fontSans
                                    font.pixelSize: 10
                                    color: Style.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                Layout.preferredWidth: 85
                                text: modelData.tco
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                color: Style.textPrimary
                                horizontalAlignment: Text.AlignRight
                            }

                            RowLayout {
                                Layout.preferredWidth: 70
                                spacing: 2
                                Text {
                                    text: modelData.vBase
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    color: Style.getRiskColor(modelData.levelOld)
                                }
                                Text {
                                    text: "→"
                                    font.family: Style.fontSans
                                    font.pixelSize: 10
                                    color: Style.textSecondary
                                }
                                Text {
                                    text: modelData.vRes
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    font.weight: Font.Bold
                                    color: Style.getRiskColor(modelData.levelNew)
                                }
                            }

                            Text {
                                Layout.preferredWidth: 55
                                text: modelData.deltaV
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                                horizontalAlignment: Text.AlignRight
                            }

                            Rectangle {
                                Layout.preferredWidth: 70
                                height: 20
                                color: (modelData.status === "Внедрено") ? Style.surfaceContainerHighest : Style.surfaceContainer
                                radius: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.status
                                    font.family: Style.fontSans
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: Style.textPrimary
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedIndex = index
                        }
                    }
                }

                // Table Footer
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    color: Style.surfaceContainer
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: "Охвачено векторов ФСТЭК: 19 / 24 • Среднее снижение критичности: -71.4%"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Метод: п. 22, 25 ФСТЭК"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textPrimary
                        }
                    }
                }
            }
        }

        // Detail / Inspector Pane (Right 48%)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.48
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Inspector Top Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    color: Style.surfaceContainer
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Rectangle {
                            height: 22
                            implicitWidth: badgeText.implicitWidth + 12
                            color: Style.primary
                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: root.currentMeasure.id
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.Bold
                                color: Style.textOnPrimary
                            }
                        }

                        Text {
                            text: root.currentMeasure.title
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        RiskBadge {
                            level: root.currentMeasure.levelOld
                            text: root.currentMeasure.levelOld.toUpperCase() + " ДО"
                            compact: true
                        }
                        Text { text: "→"; font.family: Style.fontSans; color: Style.textSecondary }
                        RiskBadge {
                            level: root.currentMeasure.levelNew
                            text: root.currentMeasure.levelNew.toUpperCase() + " ПОСЛЕ"
                            compact: true
                        }
                    }
                }

                // Scrollable Inspector Form
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width

                    ColumnLayout {
                        width: parent.width - 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Item { height: 4 }

                        // Group 1: Общие параметры и стоимость владения
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: g1Col.implicitHeight + 16
                            color: Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                id: g1Col
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "1. ОБЩИЕ ПАРАМЕТРЫ И СТОИМОСТЬ ВЛАДЕНИЯ (TCO)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "Формуляр СЗИ"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                }

                                Text { text: "Привязанный сценарий угрозы / актив:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                CustomTextField { Layout.fillWidth: true; text: root.currentMeasure.targetVuln; isMonospace: false }

                                Text { text: "Наименование меры защиты (шаблоны п. 22, 25 ФСТЭК 2025):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                CustomTextField { Layout.fillWidth: true; text: root.currentMeasure.title; isMonospace: false }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Класс меры по ФСТЭК №239:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                        CustomComboBox { Layout.fillWidth: true; model: ["ЗИС.2 — Межсетевое экранирование", "УПД.3 — Управление доступом", "ИАФ.1 — Аутентификация", "АНЗ.1 — Анализ защищенности"] }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: 160
                                        Text { text: "TCO в год (CAPEX+OPEX):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                        CustomTextField { Layout.fillWidth: true; text: root.currentMeasure.tco; suffixText: "₽" }
                                    }
                                }
                            }
                        }

                        // Group 2: Объективное изменение параметров по Таблице 1 ФСТЭК 2025
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: g2Col.implicitHeight + 16
                            color: Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                id: g2Col
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "2. ОБЪЕКТИВНОЕ СНИЖЕНИЕ ПАРАМЕТРОВ ИНФРАСТРУКТУРЫ"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "Таблица 1 ФСТЭК 2025"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                }

                                // 2.1 New Share of vulnerable components
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Новая доля уязвимых узлов (NewShare, l·L):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "Было: " + root.currentMeasure.oldShare; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                                }
                                CustomComboBox {
                                    Layout.fillWidth: true
                                    model: [
                                        "Менее 10% компонентов (l·L = 0.10) [Патчинг/изоляция]",
                                        "От 10% до 50% компонентов (l·L = 0.12)",
                                        "От 50% до 70% компонентов (l·L = 0.16)",
                                        "Более 70% компонентов (l·L = 0.20)"
                                    ]
                                    currentIndex: 0
                                }

                                // 2.2 New Perimeter protection
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Новая защищенность периметра (NewPerimeter, p·P):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "Было: " + root.currentMeasure.oldPerimeter; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                                }
                                SegmentedControl {
                                    Layout.fillWidth: true
                                    items: [
                                        "Недоступно из Интернет (0.18) [МЭ / VPN / Segment]",
                                        "Доступно из Интернет (0.33)"
                                    ]
                                    currentIndex: 0
                                }

                                // Indicator banner
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 48
                                    color: Style.surfaceContainerHighest
                                    border.color: Style.hairlineBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8

                                        ColumnLayout {
                                            spacing: 1
                                            Text { text: "Снижение инфраструктурного показателя:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                            Text {
                                                text: "I_infr: " + root.currentMeasure.iInfrOld + " → " + root.currentMeasure.iInfrNew
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeCodeMd
                                                font.weight: Font.Bold
                                                color: Style.textPrimary
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        ColumnLayout {
                                            spacing: 1
                                            Text { text: "Индекс критичности:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                            Text {
                                                text: "V: " + root.currentMeasure.vBase + " → " + root.currentMeasure.vRes + " (" + root.currentMeasure.deltaV + ")"
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeCodeMd
                                                font.weight: Font.Bold
                                                color: Style.getRiskColor(root.currentMeasure.levelNew)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Group 3: Экономический прогноз (Avoided Loss & Net ROSI)
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: g3Col.implicitHeight + 16
                            color: Style.surfaceContainerHighest
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                id: g3Col
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "3. ЭКОНОМИЧЕСКАЯ ЭФФЕКТИВНОСТЬ МЕРЫ (ROSI FRAMEWORK)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "ENISA / ISO 27005"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 54
                                        color: Style.panelSurface
                                        border.color: Style.hairlineBorder
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 1
                                            Text { text: "Предотвращенный ущерб:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                            Text {
                                                text: root.currentMeasure.deltaAle
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeHeadlineSm
                                                font.weight: Font.Bold
                                                color: Style.textPrimary
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 54
                                        color: Style.panelSurface
                                        border.color: Style.hairlineBorder
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 1
                                            Text { text: "Чистая выгода:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                            Text {
                                                text: root.currentMeasure.netBenefit
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeHeadlineSm
                                                font.weight: Font.Bold
                                                color: Style.textPrimary
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 54
                                        color: Style.panelSurface
                                        border.color: Style.hairlineBorder
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 1
                                            Text { text: "Net ROSI меры:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                            Text {
                                                text: root.currentMeasure.rosi
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeMetricDisplay
                                                font.weight: Font.Bold
                                                color: Style.riskLowText
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { height: 8 }
                    }
                }

                // Action Footer
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    color: Style.surfaceContainer
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "ROSI: " + root.currentMeasure.rosi
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeMd
                            font.weight: Font.Bold
                            color: Style.riskLowText
                        }

                        Item { Layout.fillWidth: true }

                        AppButton {
                            text: "Отмена"
                        }

                        AppButton {
                            isPrimary: true
                            text: "Сохранить меру"
                            iconText: "✓"
                        }
                    }
                }
            }
        }
    }
}
