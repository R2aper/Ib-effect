import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: authModal

    anchors.fill: parent
    color: Theme.isDark ? "#bb000000" : "#77000000"
    visible: !AuthService.authenticated
    z: 9999

    Behavior on opacity { NumberAnimation { duration: 200 } }

    MouseArea {
        anchors.fill: parent
    }

    Connections {
        target: AuthService
        function onOperationFinished(requestId, operation, success, data, error) {
            if (requestId !== card.pendingRequestId)
                return;
            card.pendingRequestId = "";
            if (!success)
                card.errorMessage = error;
        }
    }

    Rectangle {
        id: card
        width: 480
        height: contentCol.implicitHeight + 48
        anchors.centerIn: parent
        radius: Theme.radiusLg
        color: Theme.panel
        border.color: Theme.border
        border.width: 1

        MultiEffect {
            source: card
            anchors.fill: card
            shadowEnabled: true
            shadowColor: Theme.isDark ? "#80000000" : "#25000000"
            shadowBlur: 0.5
            shadowOpacity: 0.4
            shadowVerticalOffset: 6
            z: -1
        }

        property bool isRegisterMode: false
        property string audienceType: "student" // "student" | "company"
        property string errorMessage: ""
        property string pendingRequestId: ""

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 26
            spacing: 14

            // Логотип и заголовок
            RowLayout {
                spacing: 12
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 40
                    height: 40
                    radius: Theme.radiusMd
                    color: Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "ИБ"
                        color: "#ffffff"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: qsTr("ИБ-Эффект")
                        color: Theme.text
                        font.pixelSize: Theme.fontH1
                        font.weight: Font.Bold
                    }
                    Text {
                        text: qsTr("Оценка рисков и экономической эффективности")
                        color: Theme.muted
                        font.pixelSize: Theme.fontCaption
                    }
                }
            }

            // Переключатель «Вход» ⟷ «Регистрация»
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Theme.radiusSm
                color: Theme.raised
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusSm
                        color: !card.isRegisterMode ? Theme.panel : "transparent"
                        border.width: !card.isRegisterMode ? 1 : 0
                        border.color: Theme.borderHighlight

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("Вход в систему")
                            color: !card.isRegisterMode ? Theme.accent : Theme.muted
                            font.pixelSize: Theme.fontBody
                            font.weight: !card.isRegisterMode ? Font.Bold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.isRegisterMode = false;
                                card.errorMessage = "";
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusSm
                        color: card.isRegisterMode ? Theme.panel : "transparent"
                        border.width: card.isRegisterMode ? 1 : 0
                        border.color: Theme.borderHighlight

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("Регистрация")
                            color: card.isRegisterMode ? Theme.accent : Theme.muted
                            font.pixelSize: Theme.fontBody
                            font.weight: card.isRegisterMode ? Font.Bold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.isRegisterMode = true;
                                card.errorMessage = "";
                            }
                        }
                    }
                }
            }

            // Вкладки выбора профиля: «Студент / Вуз» ⟷ «Организация»
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.radiusSm
                color: Theme.isDark ? "#171a22" : "#f1f3f7"
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    spacing: 4
                    anchors.margins: 3

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusXs
                        color: card.audienceType === "student" ? Theme.panel : "transparent"
                        border.color: card.audienceType === "student" ? Theme.borderHighlight : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "🎓"
                                font.pixelSize: 13
                            }
                            Text {
                                text: qsTr("Студент / Вуз")
                                color: card.audienceType === "student" ? Theme.accent : Theme.muted
                                font.pixelSize: Theme.fontCaption
                                font.weight: card.audienceType === "student" ? Font.Bold : Font.Normal
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.audienceType = "student";
                                card.errorMessage = "";
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusXs
                        color: card.audienceType === "company" ? Theme.panel : "transparent"
                        border.color: card.audienceType === "company" ? Theme.borderHighlight : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "🏢"
                                font.pixelSize: 13
                            }
                            Text {
                                text: qsTr("Организация")
                                color: card.audienceType === "company" ? Theme.accent : Theme.muted
                                font.pixelSize: Theme.fontCaption
                                font.weight: card.audienceType === "company" ? Font.Bold : Font.Normal
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.audienceType = "company";
                                card.errorMessage = "";
                            }
                        }
                    }
                }
            }

            // --- БЛОК 1: ПОЛЯ РЕГИСТРАЦИИ ДЛЯ СТУДЕНТА ---
            ColumnLayout {
                visible: card.isRegisterMode && card.audienceType === "student"
                Layout.fillWidth: true
                spacing: 8

                Text { text: qsTr("ФИО студента:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 36; radius: Theme.radiusSm; color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: studentNameField.activeFocus ? Theme.accent : Theme.border; border.width: 1
                    TextInput { id: studentNameField; anchors.fill: parent; anchors.margins: 8; color: Theme.text; font.pixelSize: Theme.fontBody; clip: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: qsTr("Учебная группа:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 36; radius: Theme.radiusSm; color: Theme.isDark ? Theme.panelHover : "#ffffff"
                            border.color: studentGroupField.activeFocus ? Theme.accent : Theme.border; border.width: 1
                            TextInput { id: studentGroupField; anchors.fill: parent; anchors.margins: 8; color: Theme.text; font.pixelSize: Theme.fontBody; clip: true }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: qsTr("ВУЗ / Кафедра:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 36; radius: Theme.radiusSm; color: Theme.isDark ? Theme.panelHover : "#ffffff"
                            border.color: studentUnivField.activeFocus ? Theme.accent : Theme.border; border.width: 1
                            TextInput { id: studentUnivField; anchors.fill: parent; anchors.margins: 8; text: "СибГУТИ, Кафедра БИТ"; color: Theme.text; font.pixelSize: Theme.fontBody; clip: true }
                        }
                    }
                }
            }

            // --- БЛОК 2: ПОЛЯ РЕГИСТРАЦИИ ДЛЯ ОРГАНИЗАЦИИ ---
            ColumnLayout {
                visible: card.isRegisterMode && card.audienceType === "company"
                Layout.fillWidth: true
                spacing: 8

                Text { text: qsTr("Наименование организации:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 36; radius: Theme.radiusSm; color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: companyNameField.activeFocus ? Theme.accent : Theme.border; border.width: 1
                    TextInput { id: companyNameField; anchors.fill: parent; anchors.margins: 8; color: Theme.text; font.pixelSize: Theme.fontBody; clip: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: qsTr("ФИО специалиста:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 36; radius: Theme.radiusSm; color: Theme.isDark ? Theme.panelHover : "#ffffff"
                            border.color: companyContactField.activeFocus ? Theme.accent : Theme.border; border.width: 1
                            TextInput { id: companyContactField; anchors.fill: parent; anchors.margins: 8; color: Theme.text; font.pixelSize: Theme.fontBody; clip: true }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: qsTr("Отдел / Должность:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 36; radius: Theme.radiusSm; color: Theme.isDark ? Theme.panelHover : "#ffffff"
                            border.color: companyDeptField.activeFocus ? Theme.accent : Theme.border; border.width: 1
                            TextInput { id: companyDeptField; anchors.fill: parent; anchors.margins: 8; color: Theme.text; font.pixelSize: Theme.fontBody; clip: true }
                        }
                    }
                }
            }

            // --- ОБЩИЕ ПОЛЯ: ЛОГИН И ПАРОЛЬ ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: card.audienceType === "student" ? qsTr("Логин студента:") : qsTr("Корпоративный логин:")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: loginField.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: loginField
                        anchors.fill: parent
                        anchors.margins: 8
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        clip: true
                    }
                }

                Text {
                    text: qsTr("Пароль:")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: passField.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 6

                        TextInput {
                            id: passField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Theme.text
                            font.pixelSize: Theme.fontBody
                            echoMode: showPassBtn.checked ? TextInput.Normal : TextInput.Password
                            clip: true
                        }

                        Button {
                            id: showPassBtn
                            checkable: true
                            implicitWidth: 28
                            implicitHeight: 28
                            flat: true

                            contentItem: AppIcon {
                                anchors.centerIn: parent
                                name: showPassBtn.checked ? "eye" : "eye-off"
                                size: 15
                                color: Theme.muted
                            }

                            background: Rectangle {
                                color: "transparent"
                            }
                        }
                    }
                }
            }

            // Ошибка валидации
            Text {
                visible: card.errorMessage !== ""
                text: card.errorMessage
                color: Theme.riskCritical
                font.pixelSize: Theme.fontCaption
                font.weight: Font.Bold
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                visible: AuthService.loading
                text: qsTr("Выполняется запрос…")
                color: Theme.muted
                font.pixelSize: Theme.fontCaption
                Layout.alignment: Qt.AlignHCenter
            }

            // Кнопка подтверждения
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.radiusSm
                color: authBtnMouse.containsMouse ? Theme.accentGlow : Theme.accent

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (card.isRegisterMode) {
                            return card.audienceType === "student" ? qsTr("Зарегистрировать студента") : qsTr("Зарегистрировать организацию");
                        } else {
                            return card.audienceType === "student" ? qsTr("Войти как студент") : qsTr("Войти как организация");
                        }
                    }
                    color: "#ffffff"
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: authBtnMouse
                    anchors.fill: parent
                    enabled: !AuthService.loading
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        card.errorMessage = "";
                        if (card.isRegisterMode) {
                            if (card.audienceType === "student") {
                                card.pendingRequestId = AuthService.registerUser({
                                    login: loginField.text.trim(),
                                    password: passField.text,
                                    name: studentNameField.text.trim(),
                                    type: "student",
                                    group: studentGroupField.text.trim(),
                                    org: studentUnivField.text.trim() || "СибГУТИ",
                                    role: "Студент"
                                });
                            } else {
                                card.pendingRequestId = AuthService.registerUser({
                                    login: loginField.text.trim(),
                                    password: passField.text,
                                    name: companyContactField.text.trim(),
                                    type: "company",
                                    group: companyDeptField.text.trim() || "Отдел ИБ",
                                    org: companyNameField.text.trim(),
                                    role: "Специалист ИБ"
                                });
                            }
                        } else {
                            card.pendingRequestId = AuthService.login(
                                loginField.text.trim(), passField.text);
                        }
                    }
                }
            }


        }
    }
}
