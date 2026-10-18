import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: distBar

    property string title: qsTr("Распределение рисков по критичности")
    property int criticalCount: 2
    property int highCount: 5
    property int mediumCount: 8
    property int lowCount: 3

    readonly property int total: Math.max(1, criticalCount + highCount + mediumCount + lowCount)
    readonly property real critPct: (criticalCount / total) * 100
    readonly property real highPct: (highCount / total) * 100
    readonly property real medPct: (mediumCount / total) * 100
    readonly property real lowPct: (lowCount / total) * 100

    implicitHeight: 146
    Layout.fillWidth: true

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.panel
        border.color: Theme.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    MultiEffect {
        source: surface
        anchors.fill: surface
        shadowEnabled: true
        shadowColor: Theme.isDark ? "#40000000" : "#10000000"
        shadowBlur: 0.35
        shadowOpacity: Theme.isDark ? 0.35 : 0.12
        shadowVerticalOffset: 1
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 2
                Text {
                    text: qsTr("СТАТИСТИКА РАСПРЕДЕЛЕНИЯ")
                    color: Theme.accent
                    font.pixelSize: Theme.fontMicro
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                }
                Text {
                    text: distBar.title
                    color: Theme.text
                    font.pixelSize: Theme.fontH3
                    font.weight: Font.Bold
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: qsTr("Всего: ") + (distBar.total === 1 && distBar.criticalCount === 0 ? "0" : distBar.total)
                color: Theme.muted
                font.pixelSize: Theme.fontCaption
                font.weight: Font.Bold
            }
        }

        // Составной прогресс-бар
        Rectangle {
            Layout.fillWidth: true
            height: 14
            radius: 7
            color: Theme.isDark ? Theme.backgroundRaised : "#e9edf3"
            clip: true

            Row {
                anchors.fill: parent
                spacing: 2

                Rectangle {
                    width: parent.width * (distBar.criticalCount / distBar.total)
                    height: parent.height
                    color: Theme.riskCritical
                    visible: distBar.criticalCount > 0
                }

                Rectangle {
                    width: parent.width * (distBar.highCount / distBar.total)
                    height: parent.height
                    color: Theme.riskHigh
                    visible: distBar.highCount > 0
                }

                Rectangle {
                    width: parent.width * (distBar.mediumCount / distBar.total)
                    height: parent.height
                    color: Theme.riskMedium
                    visible: distBar.mediumCount > 0
                }

                Rectangle {
                    width: parent.width * (distBar.lowCount / distBar.total)
                    height: parent.height
                    color: Theme.riskLow
                    visible: distBar.lowCount > 0
                }
            }
        }

        // Легенда
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // Критические
            RowLayout {
                spacing: 6
                Rectangle { width: 8; height: 8; radius: 4; color: Theme.riskCritical }
                Text {
                    text: qsTr("Крит.") + " " + distBar.criticalCount + " (" + Math.round(distBar.critPct) + "%)"
                    color: Theme.muted
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.Medium
                }
            }

            // Высокие
            RowLayout {
                spacing: 6
                Rectangle { width: 8; height: 8; radius: 4; color: Theme.riskHigh }
                Text {
                    text: qsTr("Выс.") + " " + distBar.highCount + " (" + Math.round(distBar.highPct) + "%)"
                    color: Theme.muted
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.Medium
                }
            }

            // Средние
            RowLayout {
                spacing: 6
                Rectangle { width: 8; height: 8; radius: 4; color: Theme.riskMedium }
                Text {
                    text: qsTr("Сред.") + " " + distBar.mediumCount + " (" + Math.round(distBar.medPct) + "%)"
                    color: Theme.muted
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.Medium
                }
            }

            // Низкие
            RowLayout {
                spacing: 6
                Rectangle { width: 8; height: 8; radius: 4; color: Theme.riskLow }
                Text {
                    text: qsTr("Низ.") + " " + distBar.lowCount + " (" + Math.round(distBar.lowPct) + "%)"
                    color: Theme.muted
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.Medium
                }
            }
        }
    }
}
