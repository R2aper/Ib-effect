import QtQuick
import ".."

Rectangle {
    id: root

    property string text: ""
    property int alignment: Text.AlignLeft
    property bool hasRightBorder: true

    implicitHeight: 24
    color: Style.windowBackground

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Style.hairlineBorder
    }

    Rectangle {
        visible: root.hasRightBorder
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Style.hairlineBorder
    }

    Text {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        text: root.text.toUpperCase()
        font.family: Style.fontSans
        font.pixelSize: Style.fontSizeBodySm
        font.weight: Font.DemiBold
        color: Style.textSecondary
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: root.alignment
        elide: Text.ElideRight
    }
}
