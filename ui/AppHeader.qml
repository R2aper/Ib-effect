import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: header

    required property string currentTitle

    color: Theme.backgroundRaised
    border.color: Theme.border
    border.width: 1
    Layout.fillWidth: true
    Layout.preferredHeight: Theme.headerHeight

    Behavior on color {
        ColorAnimation { duration: 180 }
    }
    Behavior on border.color {
        ColorAnimation { duration: 180 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16

        // --- ХЛЕБНЫЕ КРОШКИ (Четкий контрастный текст) ---
        RowLayout {
            spacing: 8

            Text {
                text: qsTr("Рабочее пространство")
                color: Theme.muted
                font.pixelSize: Theme.fontCaption
                font.weight: Font.Medium
            }
            Text {
                text: "/"
                color: Theme.subtle
                font.pixelSize: Theme.fontCaption
            }
            Text {
                text: header.currentTitle
                color: Theme.text
                font.pixelSize: Theme.fontBody
                font.weight: Font.Bold
            }
        }

        Item { Layout.preferredWidth: 20 }

        // --- ПОЛЕ ГЛОБАЛЬНОГО ПОИСКА (Строгий стиль, без неона) ---
        Rectangle {
            Layout.preferredWidth: Math.min(380, Math.max(220, parent.width * 0.3))
            Layout.preferredHeight: 36
            radius: Theme.radiusSm
            color: searchInput.activeFocus ? (Theme.isDark ? Theme.panelHover : "#ffffff") : (Theme.isDark ? Theme.panel : "#f1f3f7")
            border.color: searchInput.activeFocus ? Theme.accent : Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "⌕"
                    color: searchInput.activeFocus ? Theme.accent : Theme.muted
                    font.pixelSize: 16
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.text
                    font.pixelSize: Theme.fontBody
                    selectByMouse: true
                    clip: true

                    Text {
                        visible: !searchInput.text && !searchInput.activeFocus
                        text: qsTr("Поиск по активам, рискам, мерам...")
                        color: Theme.subtle
                        font.pixelSize: Theme.fontBody
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // --- ПЕРЕКЛЮЧАТЕЛЬ ТЕМЫ (СВЕТЛАЯ / ТЕМНАЯ) ---
        Rectangle {
            implicitHeight: 36
            implicitWidth: themeRow.implicitWidth + 20
            radius: Theme.radiusSm
            color: themeMouse.containsMouse ? Theme.panelHover : Theme.panel
            border.color: themeMouse.containsMouse ? Theme.borderHighlight : Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                id: themeRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: Theme.isDark ? "🌙" : "☀️"
                    font.pixelSize: 13
                }

                Text {
                    text: Theme.isDark ? qsTr("Тёмная") : qsTr("Светлая")
                    color: Theme.text
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: themeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Theme.toggleTheme()
            }

            ToolTip.visible: themeMouse.containsMouse
            ToolTip.delay: 300
            ToolTip.text: Theme.isDark ? qsTr("Переключить на светлую тему") : qsTr("Переключить на тёмную тему")
        }

        // --- СТАТУС / ТИП ПРОФИЛЯ ---
        StatusBadge {
            text: DataStore.currentUser.type === "company" ? qsTr("🏢 Организация") : qsTr("🎓 Студент")
            level: DataStore.currentUser.type === "company" ? "teal" : "info"
        }

        // --- ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ---
        Rectangle {
            implicitHeight: 36
            implicitWidth: profileRow.implicitWidth + 20
            radius: Theme.radiusSm
            color: profileMouse.containsMouse ? Theme.panelHover : Theme.panel
            border.color: profileMouse.containsMouse ? Theme.borderHighlight : Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                id: profileRow
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: Theme.accent
                    border.color: Theme.accentLight
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: DataStore.currentUser.name ? DataStore.currentUser.name.charAt(0) : "И"
                        color: "#ffffff"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: DataStore.currentUser.name || qsTr("Пользователь")
                        color: Theme.text
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.Bold
                    }
                    Text {
                        text: {
                            if (DataStore.currentUser.type === "company") {
                                return (DataStore.currentUser.org ? (DataStore.currentUser.org + " · ") : "") + (DataStore.currentUser.group || qsTr("Отдел ИБ"));
                            } else {
                                return (DataStore.currentUser.group ? (DataStore.currentUser.group + " · ") : "") + (DataStore.currentUser.org || "СибГУТИ");
                            }
                        }
                        color: Theme.muted
                        font.pixelSize: Theme.fontMicro
                    }
                }
            }

            MouseArea {
                id: profileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: DataStore.logout()
            }

            ToolTip.visible: profileMouse.containsMouse
            ToolTip.delay: 300
            ToolTip.text: qsTr("Вы вошли как: %1. Нажмите для смены профиля / выхода").arg(DataStore.currentUser.name)
        }
    }
}
