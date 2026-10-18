import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property string eyebrow
    required property string heading
    required property string description

    spacing: 6

    Text {
        text: parent.eyebrow
        color: Theme.accent
        font.pixelSize: Theme.fontMicro
        font.weight: Font.Bold
        font.letterSpacing: 1.2
    }

    Text {
        text: parent.heading
        color: Theme.text
        font.pixelSize: Theme.fontH1
        font.weight: Font.Bold
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    Text {
        text: parent.description
        color: Theme.muted
        font.pixelSize: Theme.fontBody
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
