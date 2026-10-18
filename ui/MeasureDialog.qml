import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: measureDialog

    property bool isEditMode: false
    property int editIndex: -1

    anchors.fill: parent
    color: Theme.isDark ? "#aa000000" : "#66000000"
    visible: false
    z: 999

    function openForAdd() {
        isEditMode = false;
        editIndex = -1;
        nameInput.text = "";
        costInput.text = "1000000";
        typeBox.currentIndex = 0;
        dmgSlider.value = 50;
        probSlider.value = 60;
        errorText.text = "";
        visible = true;
    }

    function openForEdit(index, item) {
        isEditMode = true;
        editIndex = index;
        nameInput.text = item.name || "";
        costInput.text = item.cost ? item.cost.toString() : "0";
        typeBox.currentIndex = (item.type === "Организационная") ? 1 : 0;
        dmgSlider.value = item.dmgRed || 50;
        probSlider.value = item.probRed || 60;
        errorText.text = "";
        visible = true;
    }

    MouseArea { anchors.fill: parent }

    Rectangle {
        id: card
        width: 500
        height: dialogCol.implicitHeight + 48
        implicitHeight: height
        anchors.centerIn: parent
        radius: Theme.radiusLg
        color: Theme.panel
        border.color: Theme.border
        border.width: 1

        MultiEffect {
            source: card
            anchors.fill: card
            shadowEnabled: true
            shadowColor: Theme.isDark ? "#80000000" : "#20000000"
            shadowBlur: 0.5
            shadowOpacity: 0.3
            shadowVerticalOffset: 4
            z: -1
        }

        ColumnLayout {
            id: dialogCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: measureDialog.isEditMode ? qsTr("Редактирование меры защиты") : qsTr("Новое защитное мероприятие")
                    color: Theme.text
                    font.pixelSize: Theme.fontH2
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }
                Text {
                    text: "✕"
                    color: Theme.muted
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: measureDialog.visible = false
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // Название меры
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: qsTr("Наименование защитной меры:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: nameInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: nameInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        clip: true
                    }
                }
            }

            // Класс меры и Стоимость в 2 колонки
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: qsTr("Класс меры:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                    ComboBox {
                        id: typeBox
                        Layout.fillWidth: true
                        model: ["Техническая", "Организационная"]
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: qsTr("Затраты (CAPEX+OPEX ₽):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Theme.radiusSm
                        color: Theme.isDark ? Theme.panelHover : "#ffffff"
                        border.color: costInput.activeFocus ? Theme.accent : Theme.border
                        border.width: 1

                        TextInput {
                            id: costInput
                            anchors.fill: parent
                            anchors.margins: 10
                            color: Theme.text
                            font.pixelSize: Theme.fontBody
                            validator: DoubleValidator { bottom: 0 }
                            clip: true
                        }
                    }
                }
            }

            // Снижение ущерба (%)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("Снижение ущерба:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    Text { text: "-" + Math.round(dmgSlider.value) + "%"; color: Theme.green; font.pixelSize: Theme.fontBody; font.weight: Font.Bold }
                }

                Slider {
                    id: dmgSlider
                    Layout.fillWidth: true
                    from: 5
                    to: 90
                    stepSize: 5
                    value: 50
                }
            }

            // Снижение вероятности (%)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("Снижение вероятности атаки:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    Text { text: "-" + Math.round(probSlider.value) + "%"; color: Theme.green; font.pixelSize: Theme.fontBody; font.weight: Font.Bold }
                }

                Slider {
                    id: probSlider
                    Layout.fillWidth: true
                    from: 5
                    to: 90
                    stepSize: 5
                    value: 60
                }
            }

            Text {
                id: errorText
                color: Theme.riskCritical
                font.pixelSize: Theme.fontCaption
                visible: text !== ""
            }

            // Кнопки
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 12

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: cancelText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: cancelMouse.containsMouse ? Theme.panelHover : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        id: cancelText
                        anchors.centerIn: parent
                        text: qsTr("Отмена")
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: measureDialog.visible = false
                    }
                }

                Rectangle {
                    implicitWidth: saveMeasureBtnText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: saveMeasureMouse.containsMouse ? Theme.accentGlow : Theme.accent

                    Text {
                        id: saveMeasureBtnText
                        anchors.centerIn: parent
                        text: measureDialog.isEditMode ? qsTr("Сохранить") : qsTr("Добавить меру")
                        color: "#ffffff"
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: saveMeasureMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!nameInput.text.trim()) {
                                errorText.text = qsTr("Укажите наименование меры защиты");
                                return;
                            }
                            var costVal = parseFloat(costInput.text) || 0;
                            if (measureDialog.isEditMode) {
                                DataStore.updateMeasure(measureDialog.editIndex, nameInput.text.trim(), typeBox.currentText, costVal, Math.round(dmgSlider.value), Math.round(probSlider.value));
                            } else {
                                DataStore.addMeasure(nameInput.text.trim(), typeBox.currentText, costVal, Math.round(dmgSlider.value), Math.round(probSlider.value));
                            }
                            measureDialog.visible = false;
                        }
                    }
                }
            }
        }
    }
}
