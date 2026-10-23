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
        anchors.leftMargin: header.width < 1000 ? 12 : 20
        anchors.rightMargin: header.width < 1000 ? 12 : 20
        spacing: header.width < 1000 ? 8 : 16

        // --- ХЛЕБНЫЕ КРОШКИ (Четкий контрастный текст) ---
        RowLayout {
            spacing: 8
            Layout.maximumWidth: header.width < 1000 ? 160 : 300

            Text {
                visible: header.width >= 1000
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
                elide: Text.ElideRight
                Layout.maximumWidth: 180
            }
        }

        Item { visible: header.width >= 1100; Layout.preferredWidth: 20 }



        Item { Layout.fillWidth: true }

        // --- ПЕРЕКЛЮЧАТЕЛЬ КОНТУРА (КОРПОРАТИВНЫЙ IT / АСУ ТП И КИИ) ---
        Rectangle {
            implicitHeight: 36
            implicitWidth: domainRow.implicitWidth + 24
            radius: Theme.radiusSm
            color: domainMouse.containsMouse ? (AssetService.industrialMode ? (Theme.isDark ? "#172b3c" : "#e0f2fe") : Theme.panelHover) : (AssetService.industrialMode ? (Theme.isDark ? "#0f2334" : "#f0f9ff") : Theme.panel)
            border.color: AssetService.industrialMode ? Theme.teal : Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                id: domainRow
                z: 1
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: AssetService.industrialMode ? qsTr("Контур: АСУ ТП (КИИ)") : qsTr("Контур: IT-системы")
                    color: AssetService.industrialMode ? (Theme.isDark ? Theme.tealLight : Theme.teal) : Theme.text
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.Bold
                }

                StatusBadge {
                    text: AssetService.industrialMode ? qsTr("Промышленный профиль") : qsTr("Корпоративный профиль")
                    level: AssetService.industrialMode ? "teal" : "info"
                }
            }

            MouseArea {
                id: domainMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    AssetService.loadPreset(!AssetService.industrialMode);
                }
            }

            ToolTip.visible: domainMouse.containsMouse
            ToolTip.text: qsTr("Нажмите для переключения между корпоративным IT-контуром и промышленным контуром АСУ ТП КИИ")
        }

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
            text: AuthService.user.type === "company" ? qsTr("Организация") : qsTr("Студент")
            level: AuthService.user.type === "company" ? "teal" : "info"
        }

        Text {
            visible: AuthService.loading || AuthService.error !== ""
            text: AuthService.loading ? qsTr("Обновление профиля…") : AuthService.error
            color: AuthService.error !== "" ? Theme.riskCritical : Theme.muted
            font.pixelSize: Theme.fontMicro
            elide: Text.ElideRight
            Layout.maximumWidth: 180
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
                        text: AuthService.user.name ? AuthService.user.name.charAt(0) : "И"
                        color: "#ffffff"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: AuthService.user.name || qsTr("Пользователь")
                        color: Theme.text
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        Layout.maximumWidth: 150
                    }
                    Text {
                        text: {
                            if (AuthService.user.type === "company") {
                                return (AuthService.user.org ? (AuthService.user.org + " · ") : "") + (AuthService.user.group || qsTr("Отдел ИБ"));
                            } else {
                                return (AuthService.user.group ? (AuthService.user.group + " · ") : "") + (AuthService.user.org || "СибГУТИ");
                            }
                        }
                        color: Theme.muted
                        font.pixelSize: Theme.fontMicro
                        elide: Text.ElideRight
                        Layout.maximumWidth: 150
                    }
                }
            }

            Layout.maximumWidth: 210

            MouseArea {
                id: profileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AuthService.logout()
            }

            ToolTip.visible: profileMouse.containsMouse
            ToolTip.delay: 300
            ToolTip.text: qsTr("Вы вошли как: %1. Нажмите для смены профиля / выхода").arg(AuthService.user.name)
        }
    }
}
