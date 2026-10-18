import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: assetDialog

    property bool isEditMode: false
    property int editIndex: -1
    property string initialName: ""
    property string initialCategory: "Информ. система"
    property real initialCost: 1000000
    property int initialPriority: 3

    anchors.fill: parent
    color: Theme.isDark ? "#aa000000" : "#66000000"
    visible: false
    z: 999

    function openForAdd() {
        isEditMode = false;
        editIndex = -1;
        nameInput.text = "";
        costInput.text = "1000000";
        prioSelector.selectedPrio = 3;
        categoryBox.currentIndex = 0;
        errorText.text = "";
        visible = true;
    }

    function openForEdit(index, item) {
        isEditMode = true;
        editIndex = index;
        nameInput.text = item.name || "";
        costInput.text = item.cost ? item.cost.toString() : "0";
        prioSelector.selectedPrio = item.prio || 3;
        for (var i = 0; i < categoryBox.model.length; i++) {
            if (categoryBox.model[i] === item.cat) {
                categoryBox.currentIndex = i;
                break;
            }
        }
        errorText.text = "";
        visible = true;
    }

    MouseArea { anchors.fill: parent }

    Rectangle {
        id: card
        width: 480
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
                    text: assetDialog.isEditMode ? qsTr("Редактирование актива") : qsTr("Добавление актива")
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
                        onClicked: assetDialog.visible = false
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // Наименование
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: qsTr("Наименование актива:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
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

            // Категория
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: qsTr("Категория актива:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                ComboBox {
                    id: categoryBox
                    Layout.fillWidth: true
                    model: ["Информ. система", "База данных", "Инфраструктура", "Служба каталога", "Персональные данные"]
                }
            }

            // Стоимость в рублях
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: qsTr("Стоимость актива (₽):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
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

            // Приоритет актива (1..4)
            ColumnLayout {
                id: prioSelector
                property int selectedPrio: 3
                Layout.fillWidth: true
                spacing: 6

                Text { text: qsTr("Приоритет актива (ГОСТ 27000):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }

                RowLayout {
                    spacing: 8
                    Repeater {
                        model: [
                            { prio: 1, label: "1 · Низкий" },
                            { prio: 2, label: "2 · Средний" },
                            { prio: 3, label: "3 · Высокий" },
                            { prio: 4, label: "4 · КИИ" }
                        ]
                        delegate: Rectangle {
                            id: prioBtn
                            required property var modelData
                            implicitWidth: (card.width - 48 - 24) / 4
                            implicitHeight: 34
                            radius: Theme.radiusSm
                            color: prioSelector.selectedPrio === modelData.prio ? (Theme.isDark ? "#1d293d" : "#eff6ff") : Theme.panelHover
                            border.color: prioSelector.selectedPrio === modelData.prio ? Theme.accent : Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: prioBtn.modelData.label
                                color: prioSelector.selectedPrio === prioBtn.modelData.prio ? Theme.accent : Theme.text
                                font.pixelSize: 11
                                font.weight: prioSelector.selectedPrio === prioBtn.modelData.prio ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: prioSelector.selectedPrio = prioBtn.modelData.prio
                            }
                        }
                    }
                }
            }

            Text {
                id: errorText
                color: Theme.riskCritical
                font.pixelSize: Theme.fontCaption
                visible: text !== ""
            }

            // Кнопки Сохранить / Отмена
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
                        onClicked: assetDialog.visible = false
                    }
                }

                Rectangle {
                    implicitWidth: saveBtnText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: saveMouse.containsMouse ? Theme.accentGlow : Theme.accent

                    Text {
                        id: saveBtnText
                        anchors.centerIn: parent
                        text: assetDialog.isEditMode ? qsTr("Сохранить изменения") : qsTr("Добавить актив")
                        color: "#ffffff"
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!nameInput.text.trim()) {
                                errorText.text = qsTr("Укажите наименование актива");
                                return;
                            }
                            var costVal = parseFloat(costInput.text) || 0;
                            if (assetDialog.isEditMode) {
                                DataStore.updateAsset(assetDialog.editIndex, nameInput.text.trim(), categoryBox.currentText, costVal, prioSelector.selectedPrio);
                            } else {
                                DataStore.addAsset(nameInput.text.trim(), categoryBox.currentText, costVal, prioSelector.selectedPrio);
                            }
                            assetDialog.visible = false;
                        }
                    }
                }
            }
        }
    }
}
