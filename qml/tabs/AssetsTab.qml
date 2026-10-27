import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    // Selection state
    property int selectedIndex: 0

    readonly property var assetsModel: [
        {
            id: "AST-01",
            title: "Клиентская база и контракты",
            mainAsset: "Клиентская база и условия контрактов (Режим КТ)",
            subAsset: "Центральный сервер СУБД PostgreSQL (srv-db01)",
            category: "Сервер БД",
            owner: "Коммерческий департамент / CISO",
            status: "Критический",
            is98FZCompliant: true,
            directCost: "1 200 000 ₽",
            indirectCost: "6 800 000 ₽",
            sleTotal: "8 000 000 ₽",
            kType: "СУБД / Сервер",
            kVal: "0.55",
            lShare: "50-70% компонентов",
            lVal: "0.16",
            internet: true,
            pVal: "0.33",
            iInfr: "1.04"
        },
        {
            id: "AST-02",
            title: "Исходный код ядра системы",
            mainAsset: "Исходный код и алгоритмы (Секрет производства / Ноу-хау)",
            subAsset: "АРМ разработчиков и внутренний Git-сервер (srv-git)",
            category: "Репозиторий",
            owner: "R&D департамент / Lead Architect",
            status: "Высокий",
            is98FZCompliant: true,
            directCost: "3 000 000 ₽",
            indirectCost: "7 000 000 ₽",
            sleTotal: "10 000 000 ₽",
            kType: "АРМ разработчика",
            kVal: "0.25",
            lShare: "Более 70% узлов",
            lVal: "0.20",
            internet: true,
            pVal: "0.33",
            iInfr: "0.78"
        },
        {
            id: "AST-03",
            title: "БД Клиентов (ПДн)",
            mainAsset: "Информация КТ / ПДн субъектов (152-ФЗ)",
            subAsset: "СУБД PostgreSQL cluster (srv-db02)",
            category: "Сервер БД",
            owner: "Отдел клиентского сервиса / CISO",
            status: "Критический",
            is98FZCompliant: false,
            directCost: "4 500 000 ₽",
            indirectCost: "14 000 000 ₽",
            sleTotal: "18 500 000 ₽",
            kType: "СУБД",
            kVal: "0.45",
            lShare: "Более 50% узлов",
            lVal: "0.50",
            internet: true,
            pVal: "0.33",
            iInfr: "0.78"
        },
        {
            id: "AST-04",
            title: "Процессинг платежей",
            mainAsset: "Транзакции и платёжные шлюзы ЦБ РФ",
            subAsset: "Сервер авторизации (app-pay01)",
            category: "Сервер прилож.",
            owner: "Финтех-департамент / DevOps",
            status: "Критический",
            is98FZCompliant: true,
            directCost: "8 000 000 ₽",
            indirectCost: "24 000 000 ₽",
            sleTotal: "32 000 000 ₽",
            kType: "ПО приложений",
            kVal: "0.35",
            lShare: "Тотальное поражение",
            lVal: "0.75",
            internet: true,
            pVal: "0.33",
            iInfr: "0.85"
        },
        {
            id: "AST-05",
            title: "АРМ Главного бухгалтера",
            mainAsset: "Финансовая тайна, ключи ЭЦП Клиент-Банк",
            subAsset: "Windows 11 Enterprise (ws-acc03)",
            category: "АРМ",
            owner: "Главная бухгалтерия",
            status: "Средний",
            is98FZCompliant: true,
            directCost: "1 200 000 ₽",
            indirectCost: "3 000 000 ₽",
            sleTotal: "4 200 000 ₽",
            kType: "АРМ пользователя",
            kVal: "0.20",
            lShare: "Менее 10% узлов",
            lVal: "0.10",
            internet: false,
            pVal: "0.18",
            iInfr: "0.48"
        }
    ]

    readonly property var currentAsset: assetsModel[selectedIndex]

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Master Pane (Left 55%)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.55
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Master Toolbar
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
                            placeholderText: "Поиск актива, хоста или реквизитов..."
                            isMonospace: false
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 140
                            model: ["Все категории", "Сервер БД", "Сервер прилож.", "Репозиторий", "АРМ"]
                        }

                        AppButton {
                            isPrimary: true
                            text: "+ Актив (Ins)"
                            iconText: "+"
                        }

                        AppButton {
                            text: "CSV"
                            iconText: "↓"
                        }
                    }
                }

                // Table Header
                RowLayout {
                    Layout.fillWidth: true
                    height: 24
                    spacing: 0

                    TableHeaderCell { Layout.preferredWidth: 70; text: "Код" }
                    TableHeaderCell { Layout.fillWidth: true; text: "Основной актив (Информация КТ)" }
                    TableHeaderCell { Layout.preferredWidth: 130; text: "Вспомогательный" }
                    TableHeaderCell { Layout.preferredWidth: 90; text: "SLE (₽)"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 50; text: "I_infr"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 75; text: "Статус"; alignment: Text.AlignHCenter; hasRightBorder: false }
                }

                // Table Rows ListView
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.assetsModel

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
                                    text: modelData.mainAsset
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    font.weight: Font.DemiBold
                                    color: Style.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.owner
                                    font.family: Style.fontSans
                                    font.pixelSize: 10
                                    color: Style.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                Layout.preferredWidth: 125
                                text: modelData.subAsset
                                font.family: Style.fontMono
                                font.pixelSize: 10
                                color: Style.textSecondary
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 85
                                text: modelData.sleTotal
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                Layout.preferredWidth: 45
                                text: modelData.iInfr
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                color: Style.textSecondary
                                horizontalAlignment: Text.AlignRight
                            }

                            RiskBadge {
                                Layout.preferredWidth: 70
                                level: modelData.status
                                compact: true
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

                // Left Pane Summary Footer
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
                            text: "Кумулятивный SLE портфеля: 73 500 000 ₽"
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Средний I_infr: 0.68"
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeSm
                            color: Style.textSecondary
                        }
                    }
                }
            }
        }

        // Detail / Inspector Pane (Right 45%)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.45
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
                                text: root.currentAsset.id
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.Bold
                                color: Style.textOnPrimary
                            }
                        }

                        Text {
                            text: root.currentAsset.title
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        RiskBadge {
                            level: root.currentAsset.status
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

                        // 98-FZ Compliance Box
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: fzColumn.implicitHeight + 16
                            color: root.currentAsset.is98FZCompliant ? Style.riskLowBg : Style.riskCriticalBg
                            border.color: root.currentAsset.is98FZCompliant ? Style.riskLowBorder : Style.riskCriticalBorder
                            border.width: 1

                            ColumnLayout {
                                id: fzColumn
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                RowLayout {
                                    spacing: 8
                                    CheckBox {
                                        id: chk98FZ
                                        checked: root.currentAsset.is98FZCompliant
                                    }
                                    Text {
                                        text: "Соблюдены требования ч. 1 ст. 10 98-ФЗ (Режим КТ установлен)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodyMd
                                        font.weight: Font.DemiBold
                                        color: root.currentAsset.is98FZCompliant ? Style.riskLowText : Style.riskCriticalText
                                    }
                                }

                                Text {
                                    visible: !chk98FZ.checked
                                    text: "ВНИМАНИЕ! Режим коммерческой тайны не подтвержден документально. Судебная защита и взыскание убытков по ст. 15 ГК РФ НЕВОЗМОЖНЫ!"
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    color: Style.riskCriticalText
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Group 1: Идентификация актива
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
                                        text: "1. ИДЕНТИФИКАЦИЯ АКТИВА (ГОСТ 27005)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "Приложение В"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                }

                                Text { text: "Основной актив (Информация КТ / Бизнес-процесс):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                CustomTextField { Layout.fillWidth: true; text: root.currentAsset.mainAsset; isMonospace: false }

                                Text { text: "Вспомогательный актив (Хост / СУБД / ПО / Сеть):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                CustomTextField { Layout.fillWidth: true; text: root.currentAsset.subAsset; isMonospace: true }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Владелец актива:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                        CustomTextField { Layout.fillWidth: true; text: root.currentAsset.owner; isMonospace: false }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Категория КИИ (187-ФЗ):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                        CustomComboBox { Layout.fillWidth: true; model: ["1 категория значимости", "2 категория значимости", "3 категория значимости", "Не категорируется"] }
                                    }
                                }
                            }
                        }

                        // Group 2: Расчет единичного ущерба (SLE)
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
                                        text: "2. ЕДИНИЧНЫЙ УЩЕРБ ПРИ ИНЦИДЕНТЕ (SLE)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "SLE = D_direct + D_indirect"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Прямой ущерб (D_direct, ₽):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                        CustomTextField { Layout.fillWidth: true; text: root.currentAsset.directCost; suffixText: "₽" }
                                        Text { text: "Восстановление, замена, форензика"; font.family: Style.fontSans; font.pixelSize: 9; color: Style.textMuted }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Косвенный ущерб (D_indirect, ₽):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                        CustomTextField { Layout.fillWidth: true; text: root.currentAsset.indirectCost; suffixText: "₽" }
                                        Text { text: "Упущенная выгода, штрафы по NDA, У2"; font.family: Style.fontSans; font.pixelSize: 9; color: Style.textMuted }
                                    }
                                }

                                // Total SLE Display Box
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
                                            Text {
                                                text: "Полная ценность актива (SLE):"
                                                font.family: Style.fontSans
                                                font.pixelSize: Style.fontSizeBodySm
                                                color: Style.textSecondary
                                            }
                                            Text {
                                                text: "Используется для расчетных формул ALE = SLE × Prob"
                                                font.family: Style.fontSans
                                                font.pixelSize: 9
                                                color: Style.textMuted
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            text: root.currentAsset.sleTotal
                                            font.family: Style.fontMono
                                            font.pixelSize: Style.fontSizeMetricDisplay
                                            font.weight: Font.Bold
                                            color: Style.textPrimary
                                        }
                                    }
                                }
                            }
                        }

                        // Group 3: Параметры инфраструктуры (ФСТЭК 2025 г.)
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: g3Col.implicitHeight + 16
                            color: Style.surfaceLow
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
                                        text: "3. ПАРАМЕТРЫ ИНФРАСТРУКТУРЫ (ТАБЛИЦА 1 ФСТЭК)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "I_infr = k·K + l·L + p·P"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                }

                                // 3.1 Component Type K
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Тип компонента (K):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "k·K = " + root.currentAsset.kVal; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                                }
                                SegmentedControl {
                                    Layout.fillWidth: true
                                    items: ["ОС (0.45)", "СУБД (0.55)", "ПО (0.35)", "Сеть (0.25)"]
                                    currentIndex: 1
                                }

                                // 3.2 Share of vulnerable components L
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Доля уязвимых компонентов (L):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "l·L = " + root.currentAsset.lVal; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                                }
                                CustomComboBox {
                                    Layout.fillWidth: true
                                    model: [
                                        "Более 70% компонентов (l·L = 0.20)",
                                        "От 50% до 70% компонентов (l·L = 0.16)",
                                        "От 10% до 50% компонентов (l·L = 0.12)",
                                        "Менее 10% компонентов (l·L = 0.10)"
                                    ]
                                    currentIndex: 1
                                }

                                // 3.3 Internet Perimeter P
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Доступность из сети Интернет (P):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "p·P = " + root.currentAsset.pVal; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                                }
                                SegmentedControl {
                                    Layout.fillWidth: true
                                    items: ["Доступно из Интернет (0.33)", "Недоступно из Интернет (0.18)"]
                                    currentIndex: root.currentAsset.internet ? 0 : 1
                                }
                            }
                        }

                        Item { height: 8 }
                    }
                }

                // Detail Action Footer
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
                            text: "I_infr: " + root.currentAsset.iInfr
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeMd
                            font.weight: Font.Bold
                            color: Style.textPrimary
                        }

                        Item { Layout.fillWidth: true }

                        AppButton {
                            text: "Отмена"
                        }

                        AppButton {
                            isPrimary: true
                            text: "Сохранить"
                            iconText: "✓"
                            shortcutText: "Ctrl+S"
                        }
                    }
                }
            }
        }
    }
}
