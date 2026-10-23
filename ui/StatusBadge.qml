import QtQuick
import QtQuick.Layouts
import "DocumentLinks.js" as DocumentLinks

Rectangle {
    id: badge

    property string text: ""
    property string level: "info" // "critical" | "high" | "medium" | "low" | "info" | "success" | "teal"
    property bool showDot: true

    readonly property color fgColor: {
        switch (level) {
        case "critical": return Theme.riskCritical
        case "high": return Theme.riskHigh
        case "medium": return Theme.riskMedium
        case "low": return Theme.riskLow
        case "success": return Theme.green
        case "teal": return Theme.isDark ? Theme.tealLight : Theme.teal
        default: return Theme.isDark ? Theme.accentLight : Theme.accent
        }
    }

    readonly property color bgColor: {
        switch (level) {
        case "critical": return Theme.badgeCriticalBg
        case "high": return Theme.badgeHighBg
        case "medium": return Theme.badgeMediumBg
        case "low": return Theme.badgeLowBg
        case "success": return Theme.badgeLowBg
        case "teal": return Theme.isDark ? "#132b29" : "#f0fdfa"
        default: return Theme.badgeInfoBg
        }
    }

    readonly property color borderColor: {
        switch (level) {
        case "critical": return Theme.badgeCriticalBorder
        case "high": return Theme.badgeHighBorder
        case "medium": return Theme.badgeMediumBorder
        case "low": return Theme.badgeLowBorder
        case "success": return Theme.badgeLowBorder
        case "teal": return Theme.isDark ? "#1e544e" : "#ccfbf1"
        default: return Theme.badgeInfoBorder
        }
    }

    implicitWidth: layout.implicitWidth + 18
    implicitHeight: 26
    radius: Theme.radiusSm
    color: bgColor
    border.color: borderColor
    border.width: 1

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            visible: badge.showDot
            width: 7
            height: 7
            radius: 3.5
            color: badge.fgColor
        }

        Text {
            text: DocumentLinks.linkify(badge.text)
            textFormat: Text.RichText
            color: badge.fgColor
            font.pixelSize: Theme.fontCaption
            font.weight: Font.Bold
            verticalAlignment: Text.AlignVCenter
            onLinkActivated: link => Qt.openUrlExternally(link)
        }
    }
}
