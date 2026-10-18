import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control

    required property int tabIndex
    property string iconName: ""
    property string glyph: ""
    required property string label
    property bool compact: false

    checkable: true
    implicitHeight: 46
    Layout.fillWidth: true

    ToolTip.visible: control.compact && control.hovered
    ToolTip.delay: 300
    ToolTip.text: control.label

    contentItem: RowLayout {
        spacing: 12
        anchors.fill: parent
        anchors.leftMargin: control.compact ? 0 : 14
        anchors.rightMargin: control.compact ? 0 : 14

        AppIcon {
            visible: control.iconName !== ""
            name: control.iconName
            size: 20
            color: control.checked ? Theme.accent : (control.hovered ? Theme.text : Theme.muted)
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: control.compact ? Qt.AlignCenter : Qt.AlignVCenter
        }

        Text {
            visible: control.iconName === ""
            text: control.glyph
            color: control.checked ? Theme.accent : (control.hovered ? Theme.text : Theme.muted)
            font.pixelSize: 17
            font.bold: true
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: control.compact ? Qt.AlignCenter : Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: !control.compact
            text: control.label
            color: control.checked ? (Theme.isDark ? Theme.accentLight : Theme.accent) : (control.hovered ? Theme.text : Theme.textSecondary)
            font.pixelSize: Theme.fontBody
            font.weight: control.checked ? Font.Bold : Font.Normal
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    background: Rectangle {
        radius: Theme.radiusSm
        color: control.checked 
               ? (Theme.isDark ? "#1d293d" : "#eff6ff") 
               : (control.hovered ? Theme.panelHover : "transparent")
        border.width: control.checked ? 1 : 0
        border.color: control.checked 
               ? (Theme.isDark ? "#2d4263" : "#bfdbfe") 
               : "transparent"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        // Индикатор активного пункта (вертикальная плашка слева)
        Rectangle {
            visible: control.checked
            width: 3
            radius: 2
            color: Theme.accent
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 6
        }
    }
}
