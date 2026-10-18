import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: linkDialog

    property int measureIndex: -1
    property var measureItem: null

    anchors.fill: parent
    color: Theme.isDark ? "#aa000000" : "#66000000"
    visible: false
    z: 999

    function openForLink(index, item) {
        measureIndex = index;
        measureItem = item;
        populateRisks();
        visible = true;
    }

    function populateRisks() {
        var names = [];
        for (var r = 0; r < DataStore.risksList.length; r++) {
            var rsk = DataStore.risksList[r];
            names.push(rsk.id + " · " + rsk.threat.substring(0, 45) + "... (Балл: " + rsk.score + ")");
        }
        riskPicker.model = names;
        if (names.length > 0) riskPicker.currentIndex = 0;
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
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: qsTr("Привязка меры к риску")
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
                        onClicked: linkDialog.visible = false
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // Инфо о мере
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: qsTr("Выбранная мера защиты:")
                    color: Theme.muted
                    font.pixelSize: Theme.fontCaption
                }
                Text {
                    text: linkDialog.measureItem ? (linkDialog.measureItem.id + " · " + linkDialog.measureItem.name) : ""
                    color: Theme.text
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                Text {
                    text: linkDialog.measureItem ? (qsTr("Эффект: -") + linkDialog.measureItem.dmgRed + qsTr("% ущерба, -") + linkDialog.measureItem.probRed + qsTr("% вероятности")) : ""
                    color: Theme.green
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.Bold
                }
            }

            // Выбор целевого риска
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: qsTr("Целевой сценарий риска для нейтрализации:")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                }

                ComboBox {
                    id: riskPicker
                    Layout.fillWidth: true
                }
            }

            // Карточка прогноза эффекта
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 70
                radius: Theme.radiusSm
                color: Theme.raised
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        Text { text: qsTr("Базовый балл риска"); color: Theme.muted; font.pixelSize: Theme.fontMicro }
                        Text {
                            text: {
                                var r = DataStore.risksList[riskPicker.currentIndex];
                                return r ? (r.score + " баллов") : "—";
                            }
                            color: Theme.riskHigh
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Bold
                        }
                    }

                    Text { text: "➔"; color: Theme.muted; font.pixelSize: 18 }

                    ColumnLayout {
                        spacing: 2
                        Text { text: qsTr("Остаточный балл после меры"); color: Theme.muted; font.pixelSize: Theme.fontMicro }
                        Text {
                            text: {
                                var r = DataStore.risksList[riskPicker.currentIndex];
                                var m = linkDialog.measureItem;
                                if (r && m) {
                                    var resI = r.impact * (1.0 - m.dmgRed / 100.0);
                                    var resP = r.probability * (1.0 - m.probRed / 100.0);
                                    var resScore = Math.ceil(resI * resP * r.assetPriority);
                                    return resScore + " баллов (компенсирован)";
                                }
                                return "—";
                            }
                            color: Theme.green
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Bold
                        }
                    }
                }
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
                        onClicked: linkDialog.visible = false
                    }
                }

                Rectangle {
                    implicitWidth: linkBtnText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: linkBtnMouse.containsMouse ? Theme.accentGlow : Theme.accent

                    Text {
                        id: linkBtnText
                        anchors.centerIn: parent
                        text: qsTr("Привязать меру")
                        color: "#ffffff"
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: linkBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (riskPicker.currentIndex >= 0) {
                                DataStore.bindMeasureToRisk(linkDialog.measureIndex, riskPicker.currentIndex);
                            }
                            linkDialog.visible = false;
                        }
                    }
                }
            }
        }
    }
}
