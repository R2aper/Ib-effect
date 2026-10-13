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
        anchors.topMargin: 3
        radius: 12
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.panelRaised }
            GradientStop { position: 1.0; color: Theme.panel }
        }
        border.color: Theme.borderHighlight
        border.width: 1
    }

    MultiEffect {
        source: surface
        anchors.fill: surface
        shadowEnabled: true
        shadowColor: "#80000000"
        shadowBlur: 0.35
        shadowOpacity: 0.42
        shadowVerticalOffset: 5
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        anchors.topMargin: 23
        spacing: 10
        Text {
            text: card.glyph
            color: Theme.accent
            font.pixelSize: 21
            font.bold: true
        }
        Text {
            text: card.heading
            color: Theme.text
            font.pixelSize: 15
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        Text {
            text: card.description
            color: Theme.muted
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}
