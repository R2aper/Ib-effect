import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: riskDialog

    property bool isEditMode: false
    property int editIndex: -1

    anchors.fill: parent
    color: Theme.isDark ? "#aa000000" : "#66000000"
    visible: false
    z: 999

    function openForAdd() {
        isEditMode = false;
        editIndex = -1;
        threatInput.text = "";
        vulnInput.text = "";
        impactSelector.selectedVal = 3;
        probSelector.selectedVal = 3;
        populateAssets();
        errorText.text = "";
        visible = true;
    }

    function openForEdit(index, item) {
        isEditMode = true;
        editIndex = index;
        threatInput.text = item.threat || "";
        vulnInput.text = item.vuln || "";
        impactSelector.selectedVal = item.impact || 3;
        probSelector.selectedVal = item.probability || 3;
        populateAssets();
        for (var i = 0; i < assetBox.model.length; i++) {
            if (assetBox.model[i].id === item.assetId) {
                assetBox.currentIndex = i;
                break;
            }
        }
        errorText.text = "";
        visible = true;
    }

    function populateAssets() {
        var names = [];
        for (var a = 0; a < DataStore.assetsList.length; a++) {
            var ast = DataStore.assetsList[a];
            names.push(ast.id + " · " + ast.name + " (Приоритет: " + ast.prio + ")");
        }
        assetBox.model = names;
        if (names.length > 0) assetBox.currentIndex = 0;
    }

    MouseArea { anchors.fill: parent }

    Rectangle {
        id: card
        width: 520
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
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: riskDialog.isEditMode ? qsTr("Редактирование риска") : qsTr("Регистрация и оценка риска")
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
                        onClicked: riskDialog.visible = false
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // Нормативное обоснование
            NormativeExplanationCard {
                title: qsTr("Классификация угроз по БДУ ФСТЭК")
                standard: "ФСТЭК России / ГОСТ Р ИСО/МЭК 27005-2010"
                clause: qsTr("БДУ ФСТЭК (УБИ.xxx); п. 8.2 ГОСТ 27005")
                quote: qsTr("«Идентификация угроз безопасности информации осуществляется с указанием кода угрозы по Банку данных угроз (УБИ.xxx). Оценка вероятности базируется на модели нарушителя» (Методика ФСТЭК от 05.02.2021).")
                practicalNote: qsTr("Указывайте угрозу с кодом по классификатору ФСТЭК (например: «УБИ.031: Угроза несанкционированного доступа к информации»).")
            }

            // Сценарий угрозы
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text { text: qsTr("Сценарий угрозы (желательно с кодом УБИ.xxx):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: threatInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: threatInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        clip: true
                    }
                }
            }

            // Уязвимость
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text { text: qsTr("Уязвимость контура защиты:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: vulnInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: vulnInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        clip: true
                    }
                }
            }

            // Связанный актив
            ColumnLayout {
                visible: !riskDialog.isEditMode
                Layout.fillWidth: true
                spacing: 5
                Text { text: qsTr("Атакуемый актив:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                ComboBox {
                    id: assetBox
                    Layout.fillWidth: true
                }
            }

            // Шкала ущерба I (1..4)
            ColumnLayout {
                id: impactSelector
                property int selectedVal: 3
                Layout.fillWidth: true
                spacing: 5

                Text { text: qsTr("Потенциальный ущерб I (1..4):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                RowLayout {
                    spacing: 8
                    Repeater {
                        model: [
                            { val: 1, label: "1 · Незнач." },
                            { val: 2, label: "2 · Умерен." },
                            { val: 3, label: "3 · Сущест." },
                            { val: 4, label: "4 · Катастр." }
                        ]
                        delegate: Rectangle {
                            id: iBtn
                            required property var modelData
                            implicitWidth: (card.width - 48 - 24) / 4
                            implicitHeight: 32
                            radius: Theme.radiusSm
                            color: impactSelector.selectedVal === modelData.val ? (Theme.isDark ? "#1d293d" : "#eff6ff") : Theme.panelHover
                            border.color: impactSelector.selectedVal === modelData.val ? Theme.accent : Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: iBtn.modelData.label
                                color: impactSelector.selectedVal === iBtn.modelData.val ? Theme.accent : Theme.text
                                font.pixelSize: 11
                                font.weight: impactSelector.selectedVal === iBtn.modelData.val ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: impactSelector.selectedVal = iBtn.modelData.val
                            }
                        }
                    }
                }
            }

            // Шкала вероятности P (1..4)
            ColumnLayout {
                id: probSelector
                property int selectedVal: 3
                Layout.fillWidth: true
                spacing: 5

                Text { text: qsTr("Вероятность реализации P (1..4):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                RowLayout {
                    spacing: 8
                    Repeater {
                        model: [
                            { val: 1, label: "1 · Редкая" },
                            { val: 2, label: "2 · Возмож." },
                            { val: 3, label: "3 · Вероят." },
                            { val: 4, label: "4 · Постоян." }
                        ]
                        delegate: Rectangle {
                            id: pBtn
                            required property var modelData
                            implicitWidth: (card.width - 48 - 24) / 4
                            implicitHeight: 32
                            radius: Theme.radiusSm
                            color: probSelector.selectedVal === modelData.val ? (Theme.isDark ? "#1d293d" : "#eff6ff") : Theme.panelHover
                            border.color: probSelector.selectedVal === modelData.val ? Theme.accent : Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: pBtn.modelData.label
                                color: probSelector.selectedVal === pBtn.modelData.val ? Theme.accent : Theme.text
                                font.pixelSize: 11
                                font.weight: probSelector.selectedVal === pBtn.modelData.val ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: probSelector.selectedVal = pBtn.modelData.val
                            }
                        }
                    }
                }
            }

            // Превью балла
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.radiusSm
                color: Theme.raised
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text {
                        text: qsTr("Расчетный балл: ") + (impactSelector.selectedVal * probSelector.selectedVal * (DataStore.assetsList[assetBox.currentIndex] ? DataStore.assetsList[assetBox.currentIndex].prio : 3))
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }
                    StatusBadge {
                        text: DataStore.getLevelName(DataStore.getLevelByScore(impactSelector.selectedVal * probSelector.selectedVal * (DataStore.assetsList[assetBox.currentIndex] ? DataStore.assetsList[assetBox.currentIndex].prio : 3)))
                        level: DataStore.getLevelByScore(impactSelector.selectedVal * probSelector.selectedVal * (DataStore.assetsList[assetBox.currentIndex] ? DataStore.assetsList[assetBox.currentIndex].prio : 3))
                    }
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
                        onClicked: riskDialog.visible = false
                    }
                }

                Rectangle {
                    implicitWidth: saveRiskBtnText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: saveRiskMouse.containsMouse ? Theme.accentGlow : Theme.accent

                    Text {
                        id: saveRiskBtnText
                        anchors.centerIn: parent
                        text: riskDialog.isEditMode ? qsTr("Сохранить") : qsTr("Добавить риск")
                        color: "#ffffff"
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: saveRiskMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!threatInput.text.trim()) {
                                errorText.text = qsTr("Укажите сценарий угрозы");
                                return;
                            }
                            if (riskDialog.isEditMode) {
                                DataStore.updateRisk(riskDialog.editIndex, threatInput.text.trim(), vulnInput.text.trim(), impactSelector.selectedVal, probSelector.selectedVal);
                            } else {
                                DataStore.addRisk(threatInput.text.trim(), vulnInput.text.trim(), assetBox.currentIndex, impactSelector.selectedVal, probSelector.selectedVal);
                            }
                            riskDialog.visible = false;
                        }
                    }
                }
            }
        }
    }
}
