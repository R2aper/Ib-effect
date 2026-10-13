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
    Layout.fillWidth: true

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
        gradient: control.checked ? activeGradient
               : control.hovered ? hoverGradient : null
        color: control.checked ? "#1d3555"
              : control.hovered ? "#19283d" : "transparent"
        border.width: control.checked ? 1 : 0
        border.color: control.checked ? "#345d89" : "transparent"

        Gradient {
            id: activeGradient
            GradientStop { position: 0.0; color: "#24466e" }
            GradientStop { position: 1.0; color: "#1a304c" }
        }
        Gradient {
            id: hoverGradient
            GradientStop { position: 0.0; color: "#1e3048" }
            GradientStop { position: 1.0; color: "#17263a" }
        }

        Rectangle {
            visible: control.checked
            width: 3
            radius: 2
            color: Theme.accent
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 8
        }
    }
}
