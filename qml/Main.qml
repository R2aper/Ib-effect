import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."
import "tabs"

ApplicationWindow {
    id: window
    width: 1366
    height: 840
    minimumWidth: 1100
    minimumHeight: 700
    visible: true
    title: "Net ROSI Calculator — КТ / ФСТЭК / ГОСТ Р ИСО/МЭК 27005"
    color: Style.windowBackground

    property int currentTabIndex: 0

    // Top Header
    header: Rectangle {
        height: 56
        color: Style.surfaceLow
        border.color: Style.hairlineBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Row 1: System Title & Project
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                color: Style.surfaceContainer
                border.color: Style.hairlineBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    // Window dot indicators
                    Row {
                        spacing: 4
                        Rectangle { width: 9; height: 9; radius: 5; color: "#EF4444" }
                        Rectangle { width: 9; height: 9; radius: 5; color: "#F59E0B" }
                        Rectangle { width: 9; height: 9; radius: 5; color: "#10B981" }
                    }

                    Item { Layout.preferredWidth: 4 }

                    Text {
                        text: "Net ROSI Calculator • КТ / ФСТЭК 2025 / ГОСТ Р ИСО/МЭК 27005"
                        font.family: Style.fontMono
                        font.pixelSize: Style.fontSizeCodeSm
                        font.weight: Font.DemiBold
                        color: Style.textPrimary
                    }

                    Text { text: "|"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; color: Style.hairlineBorder }

                    Text {
                        text: "ПРОЕКТ: ЗАЩИТА_ПДН_ГИС_2025.rosi"
                        font.family: Style.fontMono
                        font.pixelSize: Style.fontSizeCodeSm
                        font.weight: Font.Bold
                        color: Style.textPrimary
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "ARM64-DESKTOP-NODE"
                        font.family: Style.fontMono
                        font.pixelSize: 10
                        color: Style.textSecondary
                    }

                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        radius: 10
                        color: Style.primary
                        Text {
                            anchors.centerIn: parent
                            text: "U"
                            font.family: Style.fontMono
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Style.textOnPrimary
                        }
                    }
                }
            }

            // Row 2: Menu Bar & Shortcut Indicators
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                color: Style.panelSurface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    // Menu Bar items
                    Row {
                        spacing: 4
                        Repeater {
                            model: ["Файл", "Правка", "Вид", "Расчет", "Инструменты", "Справка"]
                            Rectangle {
                                height: 22
                                implicitWidth: menuText.implicitWidth + 12
                                color: menuMouse.containsMouse ? Style.surfaceHover : "transparent"

                                Text {
                                    id: menuText
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    color: Style.textPrimary
                                }
                                MouseArea {
                                    id: menuMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 16
                        Text { text: "Ctrl+N (Новый)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                        Text { text: "Ctrl+S (Сохранить)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                        Text { text: "F5 (Пересчет)"; font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                    }
                }
            }
        }
    }

    // Main App Body
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar Navigation
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 210
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Sidebar Section Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: "МОДУЛИ"
                        font.family: Style.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Style.textSecondary
                    }
                }

                // Nav Items List
                ListView {
                    id: navList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    interactive: false
                    currentIndex: window.currentTabIndex

                    model: [
                        { icon: "📊", label: "Dashboard" },
                        { icon: "🗄️", label: "Активы" },
                        { icon: "🛡️", label: "Уязвимости" },
                        { icon: "⚙️", label: "Меры" },
                        { icon: "🧮", label: "CVSS 3.1" },
                        { icon: "💳", label: "Экономика" },
                        { icon: "📖", label: "Справка" }
                    ]

                    delegate: Rectangle {
                        width: navList.width
                        height: 34
                        color: (window.currentTabIndex === index) ? Style.surfaceActive : (navMouse.containsMouse ? Style.surfaceHover : "transparent")

                        // Active Indicator Bar
                        Rectangle {
                            visible: window.currentTabIndex === index
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 3
                            color: Style.primary
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: modelData.icon
                                font.pixelSize: 14
                            }

                            Text {
                                text: modelData.label
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodyMd
                                font.weight: (window.currentTabIndex === index) ? Font.DemiBold : Font.Normal
                                color: (window.currentTabIndex === index) ? Style.textPrimary : Style.textSecondary
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentTabIndex = index
                        }
                    }
                }

                // Sidebar Bottom Telemetry
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Всего мер:"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text { text: "14"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "ROSI:"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text { text: "+142.8%"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.primary }
                        }
                    }
                }
            }
        }

        // Main Tab Content Workspace
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Style.windowBackground

            StackLayout {
                id: stackLayout
                anchors.fill: parent
                anchors.margins: 8
                currentIndex: window.currentTabIndex

                DashboardTab {}
                AssetsTab {}
                VulnerabilitiesTab {
                    onOpenCvssCalculator: function(vector, score) {
                        window.currentTabIndex = 4; // Switch to CVSS tab
                    }
                }
                MeasuresTab {}
                CvssCalcTab {}
                EconomicsTab {}
                HelpTab {}
            }
        }
    }

    // Bottom Status Bar
    footer: Rectangle {
        height: 24
        color: Style.surfaceContainer
        border.color: Style.hairlineBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Text {
                text: "ГОСТ Р ИСО/МЭК 27005-2010 • Методика ФСТЭК России от 30.06.2025 г. • ч. 1 ст. 10 98-ФЗ"
                font.family: Style.fontMono
                font.pixelSize: 10
                color: Style.textSecondary
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "База БДУ: BDU-MET-2025.02 | Проект: 2 кейса загружено | Готово"
                font.family: Style.fontMono
                font.pixelSize: 10
                color: Style.textPrimary
            }
        }
    }
}
