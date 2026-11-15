import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Left Navigation Tree (28% width)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.28
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1
        //TODO:
        }
    }
}
