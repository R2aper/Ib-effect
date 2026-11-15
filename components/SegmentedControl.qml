import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property var items: [] // Array of string labels or objects { label, value }
    property int currentIndex: 0
    signal indexChanged(int index)

    implicitHeight: 26
    color: Style.surfaceContainer
    border.color: Style.hairlineBorder
    border.width: 1
    radius: 0

    RowLayout {
        anchors.fill: parent
        anchors.margins: 1
        spacing: 1

        Repeater {
            model: root.items

            Rectangle {
                id: itemRect
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property bool isSelected: root.currentIndex === index
                readonly property string itemText: (typeof modelData === "string") ? modelData : modelData.label

                color: isSelected ? Style.primary : (mouseArea.containsMouse ? Style.surfaceHover : Style.panelSurface)

                Text {
                    anchors.centerIn: parent
                    text: itemRect.itemText
                    font.family: Style.fontSans
                    font.pixelSize: Style.fontSizeBodyMd
                    font.weight: itemRect.isSelected ? Font.DemiBold : Font.Normal
                    color: itemRect.isSelected ? Style.textOnPrimary : (mouseArea.containsMouse ? Style.textPrimary : Style.textSecondary)
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index;
                        root.indexChanged(index);
                    }
                }
            }
        }
    }
}
