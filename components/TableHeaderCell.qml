import QtQuick
import ".."

Rectangle {
    id: root

    property string text: ""
    property int alignment: Text.AlignLeft
    property bool hasRightBorder: true
    property bool resizable: false

    signal resizeStarted()
    signal resizeDelta(real delta)

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
        anchors.rightMargin: root.resizable ? 10 : 6
        text: root.text.toUpperCase()
        font.family: Style.fontSans
        font.pixelSize: Style.fontSizeBodySm
        font.weight: Font.DemiBold
        color: Style.textSecondary
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: root.alignment
        elide: Text.ElideRight
    }

    Rectangle {
        visible: root.resizable && resizeArea.containsMouse
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 3
        color: Style.primary
    }

    MouseArea {
        id: resizeArea
        visible: root.resizable
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 8
        hoverEnabled: true
        cursorShape: Qt.SplitHCursor
        property real pressX: 0

        onPressed: function(mouse) {
            pressX = mouse.x
            root.resizeStarted()
        }
        onPositionChanged: function(mouse) {
            if (pressed)
                root.resizeDelta(mouse.x - pressX)
        }
    }
}
