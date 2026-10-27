import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    property int selectedIndex: 0
    signal openCvssCalculator(string vector, double score)

    readonly property var vulnModel: [
        {
            id: "BDU:2025-01611",
            cve: "CVE-2024-3094",
            title: "RCE в модуле аутентификации PostgreSQL",
            desc: "Удалённое выполнение произвольного кода без предварительной авторизации через внедрение байт-кодов в подсистему валидации ключей сессий.",
            fromBdu: true,
            cvss: "8.8",
            vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H",
            eStatus: "Есть эксплойт (0.30)",
            eVal: "0.30",
            hStatus: "H_01: Полное нарушение К, Ц, Д (0.50)",
            hVal: "0.50",
            vBase: "4.75",
            level: "Высокий",
            sla: "До 7 дней",
            status: "Открыта"
        },
        {
            id: "Конструктор УБИ",
            cve: "Тактика Т9.10",
            title: "Копирование исходного кода инсайдером на съемный носитель",
            desc: "Несанкционированное копирование исходных кодов и ноу-хау увольняющимся сотрудником (нарушитель Н2) через интерфейс USB (п. 5.3.3 ФСТЭК 2021).",
            fromBdu: false,
            cvss: "5.5",
            vector: "CVSS:3.1/AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N",
            eStatus: "Есть эксплойт (0.30)",
            eVal: "0.30",
            hStatus: "H_04: Утечка критических данных КТ (0.30)",
            hVal: "0.30",
            vBase: "5.50",
            level: "Высокий",
            sla: "До 7 дней",
            status: "В работе"
        },
        {
            id: "BDU:2024-01928",
            cve: "CVE-2024-21626",
            title: "Несанкционированный доступ к БД АСУ ТП (SCADA Node 01)",
            desc: "Побег из контейнера runc с получением привилегий root на хосте ядра SCADA-системы.",
            fromBdu: true,
            cvss: "9.8",
            vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H",
            eStatus: "Реальные атаки (0.60)",
            eVal: "0.60",
            hStatus: "H_01: Полное нарушение критических процессов (0.50)",
            hVal: "0.50",
            vBase: "8.80",
            level: "Критический",
            sla: "До 24 часов",
            status: "Открыта"
        },
        {
            id: "BDU:2023-05441",
            cve: "CVE-2023-38606",
            title: "Эксфильтрация через API платёжного шлюза",
            desc: "Обход многофакторной аутентификации Kerberos SSO и выгрузка логов транзакций.",
            fromBdu: true,
            cvss: "7.5",
            vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N",
            eStatus: "Нет сведений (0.10)",
            eVal: "0.10",
            hStatus: "H_02: Существенный сбой сервисов обработки (0.40)",
            hVal: "0.40",
            vBase: "4.20",
            level: "Средний",
            sla: "До 4 недель",
            status: "В работе"
        },
        {
            id: "BDU:2023-05112",
            cve: "CVE-2023-27476",
            title: "Раскрытие отладочной информации Nginx",
            desc: "Утечка служебных метаданных конфигурации через ошибочную обработку заголовков HTTP/2.",
            fromBdu: true,
            cvss: "5.3",
            vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N",
            eStatus: "Нет сведений (0.10)",
            eVal: "0.10",
            hStatus: "H_08: Незначительное влияние (0.18)",
            hVal: "0.18",
            vBase: "1.90",
            level: "Низкий",
            sla: "До 4 месяцев",
            status: "Принято"
        }
    ]

    readonly property var currentVuln: vulnModel[selectedIndex]

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
                            placeholderText: "Поиск BDU, CVE или тактики..."
                            isMonospace: false
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 130
                            model: ["Все статусы", "Открыта", "В работе", "Критические", "Высокие"]
                        }

                        AppButton {
                            isPrimary: true
                            text: "+ Угроза"
                            iconText: "+"
                        }

                        AppButton {
                            text: "Импорт БДУ"
                            iconText: "↓"
                        }
                    }
                }

                // Table Header
                RowLayout {
                    Layout.fillWidth: true
                    height: 24
                    spacing: 0

                    TableHeaderCell { Layout.preferredWidth: 90; text: "Код / BDU" }
                    TableHeaderCell { Layout.fillWidth: true; text: "Сценарий угрозы" }
                    TableHeaderCell { Layout.preferredWidth: 44; text: "CVSS"; alignment: Text.AlignHCenter }
                    TableHeaderCell { Layout.preferredWidth: 44; text: "I_at"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 44; text: "I_imp"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 50; text: "V_base"; alignment: Text.AlignRight }
                    TableHeaderCell { Layout.preferredWidth: 80; text: "Критичность"; alignment: Text.AlignHCenter }
                    TableHeaderCell { Layout.preferredWidth: 64; text: "Статус"; alignment: Text.AlignHCenter; hasRightBorder: false }
                }

                // Table Rows
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.vulnModel

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
                                Layout.preferredWidth: 84
                                text: modelData.id
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                                elide: Text.ElideRight
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
                                    text: modelData.cve
                                    font.family: Style.fontMono
                                    font.pixelSize: 10
                                    color: Style.textSecondary
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                Layout.preferredWidth: 40
                                text: modelData.cvss
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.Bold
                                color: Style.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.preferredWidth: 40
                                text: modelData.eVal
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                color: Style.textSecondary
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                Layout.preferredWidth: 40
                                text: modelData.hVal
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                color: Style.textSecondary
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                Layout.preferredWidth: 46
                                text: modelData.vBase
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.Bold
                                color: Style.getRiskColor(modelData.level)
                                horizontalAlignment: Text.AlignRight
                            }

                            RiskBadge {
                                Layout.preferredWidth: 76
                                level: modelData.level
                                compact: true
                            }

                            Text {
                                Layout.preferredWidth: 60
                                text: modelData.status
                                font.family: Style.fontSans
                                font.pixelSize: 10
                                color: (modelData.status === "Открыта") ? Style.riskCriticalText : Style.textSecondary
                                horizontalAlignment: Text.AlignHCenter
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
                            text: "Формула: V = I_cvss × I_infr × (I_at + I_imp) • Методика ФСТЭК 2025"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "БДУ ФСТЭК: 2025 г."
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textPrimary
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
                                text: root.currentVuln.id
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.Bold
                                color: Style.textOnPrimary
                            }
                        }

                        Text {
                            text: root.currentVuln.title
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        RiskBadge {
                            level: root.currentVuln.level
                        }
                    }
                }

                // Scrollable Form
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

                        // Source Toggle Control
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            color: Style.surfaceLow
                            border.color: Style.hairlineBorder
                            border.width: 1

                            SegmentedControl {
                                anchors.fill: parent
                                anchors.margins: 2
                                items: [
                                    "Найдено в БДУ ФСТЭК (FromBDU=true)",
                                    "Собственный сценарий УБИ (п. 5.3.3)"
                                ]
                                currentIndex: root.currentVuln.fromBdu ? 0 : 1
                            }
                        }

                        // Group 1: Основные атрибуты
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
                                        text: "1. ОСНОВНЫЕ АТРИБУТЫ СЦЕНАРИЯ"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "Спецификация БДУ"
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
                                        Text { text: "Код в БДУ ФСТЭК:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                        CustomTextField { Layout.fillWidth: true; text: root.currentVuln.id; isMonospace: true }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Связанный CVE / Тактика:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                        CustomTextField { Layout.fillWidth: true; text: root.currentVuln.cve; isMonospace: true }
                                    }
                                }

                                Text { text: "Описание механизма реализации угрозы:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 56
                                    color: Style.panelSurface
                                    border.color: Style.hairlineBorder
                                    border.width: 1

                                    TextEdit {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        text: root.currentVuln.desc
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textPrimary
                                        wrapMode: TextEdit.WordWrap
                                        selectByMouse: true
                                    }
                                }

                                // CVSS v3.1 Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 50
                                    color: Style.surfaceContainerHighest
                                    border.color: Style.hairlineBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 10

                                        Rectangle {
                                            width: 34
                                            height: 34
                                            color: Style.primary
                                            Text {
                                                anchors.centerIn: parent
                                                text: root.currentVuln.cvss
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeCodeMd
                                                font.weight: Font.Bold
                                                color: Style.textOnPrimary
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                text: "Базовый балл CVSS v3.1 (I_cvss)"
                                                font.family: Style.fontSans
                                                font.pixelSize: Style.fontSizeBodySm
                                                font.weight: Font.DemiBold
                                                color: Style.textPrimary
                                            }
                                            Text {
                                                text: root.currentVuln.vector
                                                font.family: Style.fontMono
                                                font.pixelSize: 10
                                                color: Style.textSecondary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        AppButton {
                                            isPrimary: true
                                            text: "CVSS Калькулятор"
                                            iconText: "↗"
                                            onClicked: root.openCvssCalculator(root.currentVuln.vector, parseFloat(root.currentVuln.cvss))
                                        }
                                    }
                                }
                            }
                        }

                        // Group 2: Факторы методики ФСТЭК 2025
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
                                        text: "2. ФАКТОРЫ МЕТОДИКИ ФСТЭК 2025"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "Таблица 1 ФСТЭК"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                    }
                                }

                                // Exploitation status E -> I_at
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Статус эксплуатации (E → I_at):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "I_at = " + root.currentVuln.eVal; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                                }
                                SegmentedControl {
                                    Layout.fillWidth: true
                                    items: [
                                        "Реальные атаки (0.60)",
                                        "Есть эксплойт (0.30)",
                                        "Нет сведений (0.10)"
                                    ]
                                    currentIndex: (root.currentVuln.eVal === "0.60") ? 0 : ((root.currentVuln.eVal === "0.30") ? 1 : 2)
                                }

                                // Consequence severity H -> I_imp
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Тяжесть последствий (H → I_imp):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "I_imp = " + root.currentVuln.hVal; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                                }
                                CustomComboBox {
                                    Layout.fillWidth: true
                                    model: [
                                        "H_01: Полное нарушение К, Ц, Д критических процессов (0.50)",
                                        "H_02: Существенный сбой сервисов обработки платежей (0.40)",
                                        "H_03: Локальное нарушение доступности второстепенных узлов (0.34)",
                                        "H_04: Утечка сведений коммерческой тайны и ноу-хау (0.30)",
                                        "H_05: Несанкционированная модификация конфигураций (0.26)",
                                        "H_06: Временная деградация производительности кластера (0.22)",
                                        "H_07: Единичные сбои и отказы клиентских коннектов (0.20)",
                                        "H_08: Незначительное влияние без остановки функционала (0.18)",
                                        "H_09: Нарушение вспомогательных сервисов логирования (0.12)",
                                        "H_10: Минимальное локальное воздействие (0.10)"
                                    ]
                                    currentIndex: (root.currentVuln.hVal === "0.50") ? 0 : ((root.currentVuln.hVal === "0.40") ? 1 : 3)
                                }
                            }
                        }

                        // Group 3: Живой расчет и нормативный регламент ФСТЭК
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
                                        text: "3. ИТОГОВЫЙ ИНДЕКС КРИТИЧНОСТИ V И СРОК УСТРАНЕНИЯ"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "п. 18, 21 ФСТЭК"
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
                                        height: 52
                                        color: Style.panelSurface
                                        border.color: Style.hairlineBorder
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 1
                                            Text { text: "Базовый индекс V:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                            Text {
                                                text: root.currentVuln.vBase
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeMetricDisplay
                                                font.weight: Font.Bold
                                                color: Style.getRiskColor(root.currentVuln.level)
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 52
                                        color: Style.panelSurface
                                        border.color: Style.hairlineBorder
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 1
                                            Text { text: "Уровень Таблицы 2:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                            RiskBadge {
                                                level: root.currentVuln.level
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 52
                                        color: Style.panelSurface
                                        border.color: Style.hairlineBorder
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 1
                                            Text { text: "Нормативный SLA:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                            Text {
                                                text: root.currentVuln.sla
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeHeadlineSm
                                                font.weight: Font.Bold
                                                color: Style.textPrimary
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
                            text: "V_base: " + root.currentVuln.vBase + " (" + root.currentVuln.level + ")"
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeMd
                            font.weight: Font.Bold
                            color: Style.getRiskColor(root.currentVuln.level)
                        }

                        Item { Layout.fillWidth: true }

                        AppButton {
                            text: "Отмена"
                        }

                        AppButton {
                            isPrimary: true
                            text: "Сохранить"
                            iconText: "✓"
                        }
                    }
                }
            }
        }
    }
}
