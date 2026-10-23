import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: gauge

    property string title: qsTr("Интегральный уровень риска")
    property real score: 38
    property real maxScore: 64
    property string statusText: qsTr("Высокий")
    property string statusLevel: "high" // "critical" | "high" | "medium" | "low"

    implicitHeight: 146
    Layout.fillWidth: true

    readonly property real ratio: Math.min(1.0, Math.max(0.0, score / maxScore))

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
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: qsTr("ОЦЕНКА СОСТОЯНИЯ")
                    color: Theme.accent
                    font.pixelSize: Theme.fontMicro
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                }
                Text {
                    text: gauge.title
                    color: Theme.text
                    font.pixelSize: Theme.fontH3
                    font.weight: Font.Bold
                }
            }

            StatusBadge {
                text: gauge.statusText
                level: gauge.statusLevel
            }
        }

        RowLayout {
            spacing: 8
            Text {
                text: Math.round(gauge.score)
                color: {
                    if (gauge.statusLevel === "critical") return Theme.riskCritical
                    if (gauge.statusLevel === "high") return Theme.riskHigh
                    if (gauge.statusLevel === "medium") return Theme.riskMedium
                    return Theme.riskLow
                }
                font.pixelSize: Theme.fontMetricBig
                font.weight: Font.Bold
            }
            Text {
                text: "/ " + Math.round(gauge.maxScore) + " " + qsTr("баллов")
                color: Theme.muted
                font.pixelSize: Theme.fontCaption
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignBaseline
            }
        }

        // Шкала риска
        Item {
            Layout.fillWidth: true
            height: 12

            Rectangle {
                id: track
                anchors.fill: parent
                radius: 6
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.riskLow }
                    GradientStop { position: 0.45; color: Theme.riskMedium }
                    GradientStop { position: 0.75; color: Theme.riskHigh }
                    GradientStop { position: 1.0; color: Theme.riskCritical }
                }
                opacity: 0.85
            }

            // Бегунок текущего значения
            Rectangle {
                width: 18
                height: 18
                radius: 9
                color: Theme.isDark ? "#ffffff" : "#0f172a"
                border.color: Theme.panel
                border.width: 2.5
                anchors.verticalCenter: track.verticalCenter
                x: Math.max(0, Math.min(track.width - width, (track.width * gauge.ratio) - (width / 2)))

                Behavior on x {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: qsTr("0 (Низкий)")
                color: Theme.muted
                font.pixelSize: Theme.fontMicro
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(gauge.maxScore / 2) + " " + qsTr("(Средний)")
                color: Theme.muted
                font.pixelSize: Theme.fontMicro
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(gauge.maxScore) + " " + qsTr("(Критический)")
                color: Theme.muted
                font.pixelSize: Theme.fontMicro
            }
        }
    }
}
