import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: card

    required property string label
    required property string value
    required property string note
    property color valueColor: Theme.text

    implicitHeight: 126
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
        anchors.margins: 18
        anchors.topMargin: 21
        spacing: 9
        Text {
            text: card.label
            color: Theme.muted
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        Text {
            text: card.value
            color: card.valueColor
            font.pixelSize: 27
            font.weight: Font.DemiBold
        }
        Text {
            text: card.note
            color: Theme.muted
            font.pixelSize: 11
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}
