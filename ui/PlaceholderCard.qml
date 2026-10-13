import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card

    required property string glyph
    required property string heading
    required property string description

    radius: 12
    color: Theme.panel
    border.color: Theme.border
    border.width: 1
    implicitHeight: 160
    Layout.fillWidth: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
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
