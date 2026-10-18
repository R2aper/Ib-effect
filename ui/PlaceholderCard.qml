import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: card

    required property string glyph
    required property string heading
    required property string description

    implicitHeight: 160
    Layout.fillWidth: true

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radiusMd
        color: mouseArea.containsMouse ? Theme.panelHover : Theme.panel
        border.color: mouseArea.containsMouse ? Theme.borderHighlight : Theme.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    MultiEffect {
        source: surface
        anchors.fill: surface
        shadowEnabled: true
        shadowColor: Theme.isDark ? "#40000000" : "#10000000"
        shadowBlur: 0.35
        shadowOpacity: Theme.isDark ? 0.35 : 0.1
        shadowVerticalOffset: 1
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        Text {
            text: card.glyph
            color: Theme.accent
            font.pixelSize: 22
            font.bold: true
        }

        Text {
            text: card.heading
            color: Theme.text
            font.pixelSize: Theme.fontH3
            font.weight: Font.Bold
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Text {
            text: card.description
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
    }
}
