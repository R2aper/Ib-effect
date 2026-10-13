import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card

    required property string label
    required property string value
    required property string note
    property color valueColor: Theme.text

    radius: 12
    color: Theme.panel
    border.color: Theme.border
    border.width: 1
    implicitHeight: 126
    Layout.fillWidth: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
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
