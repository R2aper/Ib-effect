import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control

    required property int tabIndex
    required property string glyph
    required property string label

    checkable: true
    implicitHeight: 46

    contentItem: RowLayout {
        spacing: 12
        Text {
            text: control.glyph
            color: control.checked ? Theme.accent : Theme.muted
            font.pixelSize: 17
            font.bold: true
            Layout.preferredWidth: 22
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            text: control.label
            color: control.checked ? Theme.text : Theme.muted
            font.pixelSize: 13
            font.weight: control.checked ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    background: Rectangle {
        radius: 9
        color: control.checked ? "#1d3555"
              : control.hovered ? "#19283d" : "transparent"
        border.width: control.checked ? 1 : 0
        border.color: "#29486d"
    }
}
