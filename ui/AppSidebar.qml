import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: sidebar

    property int currentTab: 0
    property bool collapsed: false
    property bool compactMode: false
    readonly property bool isCollapsed: collapsed || compactMode
    signal tabSelected(int index)

    color: Theme.sidebar
    border.color: Theme.border
    border.width: 1
    Layout.preferredWidth: isCollapsed ? Theme.sidebarWidthCompact : Theme.sidebarWidthExpanded
    Layout.fillHeight: true

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    Behavior on Layout.preferredWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    readonly property var items: [
        { icon: "dashboard", glyph: "⌂", label: qsTr("Панель эффективности") },
        { icon: "criteria", glyph: "◈", label: qsTr("Модель риска") },
        { icon: "assets", glyph: "▣", label: qsTr("Активы") },
        { icon: "risks", glyph: "△", label: qsTr("Риски") },
        { icon: "measures", glyph: "◉", label: qsTr("Меры защиты") },
        { icon: "economics", glyph: "₽", label: qsTr("Экономика") },
        { icon: "methodology", glyph: "∑", label: qsTr("Методика") }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: sidebar.isCollapsed ? 8 : 14
        spacing: 0

        // --- ШАПКА САЙДБАРА (ЛОГОТИП И КНОПКА СВОРАЧИВАНИЯ) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 20
            spacing: 10

            Rectangle {
                width: 38
                height: 38
                radius: Theme.radiusMd
                color: Theme.accent
                border.color: Theme.accentLight
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "ИБ"
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                visible: !sidebar.isCollapsed
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: qsTr("ИБ-Эффект")
                    color: Theme.text
                    font.pixelSize: Theme.fontH2
                    font.weight: Font.Bold
                }
                Text {
                    text: qsTr("Платформа оценки ИБ")
                    color: Theme.muted
                    font.pixelSize: Theme.fontCaption
                }
            }

            // Кнопка сворачивания/разворачивания
            Rectangle {
                visible: !sidebar.isCollapsed
                width: 28
                height: 28
                radius: Theme.radiusXs
                color: toggleMouse.containsMouse ? Theme.panelHover : "transparent"
                border.color: toggleMouse.containsMouse ? Theme.borderHighlight : "transparent"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "<"
                    color: Theme.muted
                    font.pixelSize: 10
                }

                MouseArea {
                    id: toggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sidebar.collapsed = !sidebar.collapsed
                }

                ToolTip.visible: toggleMouse.containsMouse
                ToolTip.delay: 400
                ToolTip.text: qsTr("Свернуть меню")
            }
        }

        // Если свернуто — отдельная кнопка развернуть
        Rectangle {
            visible: sidebar.isCollapsed && !sidebar.compactMode
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 14
            width: 32
            height: 24
            radius: Theme.radiusXs
            color: expandMouse.containsMouse ? Theme.panelHover : "transparent"

            Text {
                anchors.centerIn: parent
                text: ">"
                color: Theme.muted
                font.pixelSize: 10
            }

            MouseArea {
                id: expandMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sidebar.collapsed = false
            }

            ToolTip.visible: expandMouse.containsMouse
            ToolTip.delay: 400
            ToolTip.text: qsTr("Развернуть меню")
        }

        // Подзаголовок раздела
        Text {
            visible: !sidebar.isCollapsed
            text: qsTr("РАБОЧЕЕ ПРОСТРАНСТВО")
            color: Theme.subtle
            font.pixelSize: Theme.fontMicro
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            Layout.leftMargin: 8
            Layout.bottomMargin: 8
        }

        Rectangle {
            visible: sidebar.isCollapsed
            Layout.fillWidth: true
            height: 1
            color: Theme.border
            Layout.bottomMargin: 8
        }

        // Список навигации
        Repeater {
            model: sidebar.items
            delegate: NavigationButton {
                required property int index
                required property var modelData
                tabIndex: index
                iconName: modelData.icon || ""
                glyph: modelData.glyph || ""
                label: modelData.label
                compact: sidebar.isCollapsed
                checked: sidebar.currentTab === index
                onClicked: sidebar.tabSelected(index)
            }
        }

        Item { Layout.fillHeight: true }

        // --- НИЖНИЙ БЛОК СТАТУСА ПРОЕКТА ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: sidebar.isCollapsed ? 36 : 68
            radius: Theme.radiusSm
            color: Theme.panel
            border.color: Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            ColumnLayout {
                visible: !sidebar.isCollapsed
                anchors.fill: parent
                anchors.margins: 10
                spacing: 3

                RowLayout {
                    spacing: 6
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: Theme.green
                    }
                    Text {
                        text: qsTr("Локальный проект")
                        color: Theme.text
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: qsTr("Готов к расчётам · v0.1")
                    color: Theme.muted
                    font.pixelSize: Theme.fontMicro
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                visible: sidebar.isCollapsed
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: Theme.green

                ToolTip.visible: statusMouse.containsMouse
                ToolTip.text: qsTr("Проект активен · v0.1")

                MouseArea {
                    id: statusMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }
}
