import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: card

    required property string label
    required property string value
    property string note: ""
    property string delta: ""
    property bool deltaIsGood: true
    property color valueColor: Theme.text
    property string glyph: ""
    property color accentColor: Theme.accent

    implicitHeight: 136
    Layout.fillWidth: true

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radiusMd
        color: mouseArea.containsMouse ? Theme.panelHover : Theme.panel
        border.color: mouseArea.containsMouse ? Theme.borderHighlight : Theme.border
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        // Тонкая верхняя акцентная окантовка
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 3
            radius: Theme.radiusXs
            color: card.accentColor
            opacity: mouseArea.containsMouse ? 0.9 : 0.4

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }

    MultiEffect {
        source: surface
        anchors.fill: surface
        shadowEnabled: true
        shadowColor: Theme.isDark ? "#40000000" : "#10000000"
        shadowBlur: 0.4
        shadowOpacity: mouseArea.containsMouse ? 0.4 : 0.15
        shadowVerticalOffset: mouseArea.containsMouse ? 3 : 1
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: card.label
                color: Theme.muted
                font.pixelSize: Theme.fontCaption
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: card.glyph.length > 0
                text: card.glyph
                color: card.accentColor
                font.pixelSize: 16
                font.bold: true
                opacity: 0.8
            }
        }

        RowLayout {
            spacing: 10
            Layout.alignment: Qt.AlignLeft

            Text {
                text: card.value
                color: card.valueColor
                font.pixelSize: Theme.fontMetricBig
                font.weight: Font.Bold
            }

            Rectangle {
                visible: card.delta.length > 0
                implicitHeight: 22
                implicitWidth: deltaText.implicitWidth + 12
                radius: Theme.radiusXs
                color: card.deltaIsGood ? Theme.badgeLowBg : Theme.badgeCriticalBg
                border.color: card.deltaIsGood ? Theme.badgeLowBorder : Theme.badgeCriticalBorder
                border.width: 1

                Text {
                    id: deltaText
                    anchors.centerIn: parent
                    text: card.delta
                    color: card.deltaIsGood ? Theme.green : Theme.riskCritical
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }
        }

        Text {
            visible: card.note.length > 0
            text: card.note
            color: Theme.muted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
