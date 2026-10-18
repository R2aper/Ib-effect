import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: scenarioDialog

    anchors.fill: parent
    color: Theme.isDark ? "#aa000000" : "#66000000"
    visible: false
    z: 999

    signal scenarioImported(int count)

    function openDialog() {
        populateAssets();
        scenarioBox.currentIndex = 0;
        updateScenarioPreview();
        visible = true;
    }

    function populateAssets() {
        var names = [];
        for (var a = 0; a < DataStore.assetsList.length; a++) {
            var ast = DataStore.assetsList[a];
            var prefix = ast.oaCode ? ("[" + ast.oaCode + "] ") : "";
            names.push(prefix + ast.id + " · " + ast.name);
        }
        targetAssetBox.model = names;
        if (names.length > 0) targetAssetBox.currentIndex = 0;
    }

    function updateScenarioPreview() {
        var scList = DataStore.bduScenarios;
        if (!scList || scList.length === 0) return;
        var sc = scList[scenarioBox.currentIndex];
        if (sc) {
            scenarioTitleText.text = sc.title;
            scenarioTypeText.text = sc.scenario_type || qsTr("Типовой сценарий АСУ ТП");
            stepsRepeater.model = sc.steps || [];
        }
    }

    MouseArea { anchors.fill: parent }

    Rectangle {
        id: card
        width: 620
        implicitHeight: dialogCol.implicitHeight + 48
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
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: qsTr("Импорт типового сценария атаки ФСТЭК России")
                        color: Theme.text
                        font.pixelSize: Theme.fontH2
                        font.weight: Font.Bold
                    }
                    Text {
                        text: qsTr("Банк данных угроз АСУ ТП (bduasutp.fstec.ru) · 49 сценариев С1–С3")
                        color: Theme.muted
                        font.pixelSize: Theme.fontCaption
                    }
                }
                Text {
                    text: "✕"
                    color: Theme.muted
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: scenarioDialog.visible = false
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // Выбор сценария
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: qsTr("Выберите типовой сценарий атаки:");
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                }
                ComboBox {
                    id: scenarioBox
                    Layout.fillWidth: true
                    model: {
                        var titles = [];
                        var scList = DataStore.bduScenarios;
                        for (var i = 0; i < scList.length; i++) {
                            titles.push((scList[i].code ? ("[" + scList[i].code + "] ") : "") + scList[i].title);
                        }
                        return titles;
                    }
                    onActivated: scenarioDialog.updateScenarioPreview()
                }
            }

            // Целевой актив
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: qsTr("Привязать шаги атаки к активу:");
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                }
                ComboBox {
                    id: targetAssetBox
                    Layout.fillWidth: true
                }
            }

            // Инфо-блок сценария
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: scInfoCol.implicitHeight + 20
                radius: Theme.radiusSm
                color: Theme.isDark ? "#161d2b" : "#f1f5f9"
                border.color: Theme.isDark ? "#283b56" : "#cbd5e1"
                border.width: 1

                ColumnLayout {
                    id: scInfoCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        StatusBadge {
                            id: scTypeBadge
                            text: qsTr("Сценарий ФСТЭК")
                            level: "teal"
                        }
                        Text {
                            id: scenarioTypeText
                            text: ""
                            color: Theme.textSecondary
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }

                    Text {
                        id: scenarioTitleText
                        text: ""
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: qsTr("Последовательность шагов kill-chain (цепочки атаки):")
                        color: Theme.muted
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.DemiBold
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            id: stepsRepeater
                            delegate: Rectangle {
                                id: stepRow
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: stepCol.implicitHeight + 12
                                radius: 4
                                color: Theme.isDark ? "#1e293b" : "#ffffff"
                                border.color: Theme.border
                                border.width: 1

                                ColumnLayout {
                                    id: stepCol
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 4

                                    RowLayout {
                                        StatusBadge {
                                            text: qsTr("Шаг ") + stepRow.modelData.step_number
                                            level: stepRow.index === (stepsRepeater.count - 1) ? "critical" : "high"
                                        }
                                        StatusBadge {
                                            text: stepRow.modelData.threat_code || "УТП"
                                            level: "teal"
                                        }
                                        Text {
                                            text: stepRow.modelData.threat_title || ""
                                            color: Theme.text
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        text: stepRow.modelData.description || ""
                                        color: Theme.muted
                                        font.pixelSize: 11
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Кнопки действия
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 12

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: cancelBtnText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: cancelMouse.containsMouse ? Theme.panelHover : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        id: cancelBtnText
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
                        onClicked: scenarioDialog.visible = false
                    }
                }

                Rectangle {
                    implicitWidth: importBtnText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: importMouse.containsMouse ? Theme.accentGlow : Theme.accent

                    Text {
                        id: importBtnText
                        anchors.centerIn: parent
                        text: qsTr("Импортировать все шаги атаки в реестр")
                        color: "#ffffff"
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: importMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var scList = DataStore.bduScenarios;
                            var sc = scList[scenarioBox.currentIndex];
                            if (sc) {
                                var count = DataStore.importScenario(sc.code || sc.title, targetAssetBox.currentIndex);
                                scenarioDialog.scenarioImported(count);
                            }
                            scenarioDialog.visible = false;
                        }
                    }
                }
            }
        }
    }
}
