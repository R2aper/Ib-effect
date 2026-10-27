import QtQuick
import ".."

Rectangle {
    id: root

    property string text: ""
    property string iconText: ""
    property string shortcutText: ""
    property bool isPrimary: false
    property bool isDanger: false
    property bool isSubtle: false
    property bool enabledState: true

    signal clicked()

    implicitHeight: 26
    implicitWidth: contentRow.implicitWidth + 18
    radius: 0

    color: {
        if (!enabledState) return Style.surfaceContainer;
        if (isDanger) {
            if (mouseArea.pressed) return "#991B1B";
            if (mouseArea.containsMouse) return "#B91C1C";
            return Style.riskCriticalText;
        }
        if (isPrimary) {
            if (mouseArea.pressed) return Style.primaryPressed;
            if (mouseArea.containsMouse) return Style.primaryHover;
            return Style.primary;
        }
        if (isSubtle) {
            if (mouseArea.pressed) return Style.surfaceActive;
            if (mouseArea.containsMouse) return Style.surfaceHover;
            return "transparent";
        }
        // Secondary / Ghost Action
        if (mouseArea.pressed) return Style.surfaceActive;
        if (mouseArea.containsMouse) return Style.surfaceHover;
        return Style.panelSurface;
    }

    border.color: {
        if (!enabledState) return Style.hairlineBorder;
        if (isDanger) return Style.riskCriticalText;
        if (isPrimary) return Style.primary;
        if (isSubtle) return "transparent";
        return Style.hairlineBorder;
    }
    border.width: isSubtle ? 0 : 1

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.iconText !== ""
            text: root.iconText
            font.family: Style.fontMono
            font.pixelSize: Style.fontSizeCodeSm
            font.weight: Font.Bold
            color: root.textColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text
            font.family: Style.fontSans
            font.pixelSize: Style.fontSizeBodyMd
            font.weight: root.isPrimary ? Font.DemiBold : Font.Normal
            color: root.textColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.shortcutText !== ""
            text: root.shortcutText
            font.family: Style.fontMono
            font.pixelSize: 10
            opacity: 0.65
            color: root.textColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    readonly property color textColor: {
        if (!enabledState) return Style.textMuted;
        if (isDanger || isPrimary) return Style.textOnPrimary;
        return Style.textPrimary;
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabledState ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.enabledState
        onClicked: root.clicked()
    }
}
