import QtQuick
import ".."

Rectangle {
    id: root

    property string level: "Критический"
    property string text: level.toUpperCase()
    property bool compact: false

    height: compact ? 18 : 22
    width: label.implicitWidth + (compact ? 12 : 16)
    radius: 2

    color: Style.getRiskBg(level)
    border.color: Style.getRiskBorder(level)
    border.width: 1

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.family: Style.fontMono
        font.pixelSize: root.compact ? Style.fontSizeBadge : Style.fontSizeCodeSm
        font.weight: Font.DemiBold
        color: Style.getRiskColor(root.level)
    }
}
