import QtQuick
import QtQuick.Controls
import ".."

Rectangle {
    id: root

    property alias text: input.text
    property alias placeholderText: input.placeholderText
    property alias readOnly: input.readOnly
    property string suffixText: ""
    property bool isMonospace: true

    implicitHeight: 26
    implicitWidth: 160
    color: input.readOnly ? Style.surfaceLow : Style.panelSurface
    border.color: input.activeFocus ? Style.primary : Style.hairlineBorder
    border.width: 1

    Row {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 4

        TextInput {
            id: input
            width: root.suffixText !== "" ? parent.width - suffixLabel.implicitWidth - 8 : parent.width
            height: parent.height
            verticalAlignment: TextInput.AlignVCenter
            font.family: root.isMonospace ? Style.fontMono : Style.fontSans
            font.pixelSize: Style.fontSizeBodyMd
            color: Style.textPrimary
            selectByMouse: true
            selectionColor: Style.surfaceActive
            selectedTextColor: Style.textPrimary

            property string placeholderText: ""
            Text {
                text: input.placeholderText
                visible: input.text === "" && !input.activeFocus
                color: Style.textMuted
                font: input.font
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            id: suffixLabel
            visible: root.suffixText !== ""
            text: root.suffixText
            font.family: Style.fontMono
            font.pixelSize: Style.fontSizeCodeSm
            color: Style.textSecondary
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
