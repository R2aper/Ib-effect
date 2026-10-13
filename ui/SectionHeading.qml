import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property string eyebrow
    required property string heading
    required property string description

    spacing: 7

    Text {
        text: parent.eyebrow
        color: Theme.accent
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 1.5
    }
    Text {
        text: parent.heading
        color: Theme.text
        font.pixelSize: 26
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    Text {
        text: parent.description
        color: Theme.muted
        font.pixelSize: 13
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
