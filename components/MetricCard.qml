import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string title: ""
    property string iconText: ""
    property string value: ""
    property string unitText: ""
    property string badgeText: ""
    property color badgeColor: Style.primary
    property color badgeTextColor: Style.textOnPrimary
    property string footerLeft: ""
    property string footerRight: ""
    property color valueColor: Style.textPrimary

    color: Style.panelSurface
    border.color: Style.hairlineBorder
    border.width: 1
    implicitHeight: 110
    implicitWidth: 240

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // Header Row
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.title
                font.family: Style.fontSans
                font.pixelSize: Style.fontSizeHeadlineSm
                font.weight: Font.DemiBold
                color: Style.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root.iconText !== ""
                height: 20
                implicitWidth: Math.max(20, iconLabel.implicitWidth + 8)
                // опционально ограничить максимальную ширину, чтобы не раздувало карточку
                // Layout.maximumWidth: 48

                color: Style.surfaceLow
                radius: 2
                border.color: Style.hairlineBorder
                border.width: 1
                clip: true

                Text {
                    id: iconLabel
                    anchors.centerIn: parent
                    text: root.iconText
                    font.family: Style.fontMono
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Style.textSecondary
                    elide: Text.ElideRight
                    // если хочешь жёстко ограничить:
                    // width: Math.min(implicitWidth, 40)
                }
            }
        }

        // Value & Subtitle Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            baselineOffset: valText.baselineOffset

            Text {
                id: valText
                text: root.value
                font.family: Style.fontMono
                font.pixelSize: Style.fontSizeMetricDisplay
                font.weight: Font.DemiBold
                color: root.valueColor
            }

            Text {
                visible: root.unitText !== ""
                text: root.unitText
                font.family: Style.fontSans
                font.pixelSize: Style.fontSizeCodeSm
                color: Style.textSecondary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                visible: root.badgeText !== ""
                height: 18
                implicitWidth: badgeLabel.implicitWidth + 8
                color: root.badgeColor
                radius: 2

                Text {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: root.badgeText
                    font.family: Style.fontMono
                    font.pixelSize: Style.fontSizeBadge
                    font.weight: Font.Bold
                    color: root.badgeTextColor
                }
            }
        }

        // Footer Row
        Rectangle {
            Layout.fillWidth: true
            height: 22
            color: Style.surfaceLow
            border.color: Style.hairlineBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6

                Text {
                    text: root.footerLeft
                    font.family: Style.fontMono
                    font.pixelSize: Style.fontSizeCodeSm
                    color: Style.textSecondary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: root.footerRight
                    font.family: Style.fontMono
                    font.pixelSize: Style.fontSizeCodeSm
                    font.weight: Font.DemiBold
                    color: Style.textPrimary
                    visible: root.footerRight !== ""
                }
            }
        }
    }
}
