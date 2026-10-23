import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "DocumentLinks.js" as DocumentLinks

Rectangle {
    id: root

    property string title: qsTr("Нормативное обоснование")
    property string standard: qsTr("ГОСТ Р ИСО/МЭК 27005-2010")
    property string clause: qsTr("п. 8.2")
    property string quote: ""
    property string practicalNote: ""
    property bool isExpanded: false

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight + (isExpanded ? 24 : 16)
    radius: Theme.radiusMd
    color: isExpanded
           ? (Theme.isDark ? "#172133" : "#f0f7ff")
           : (Theme.isDark ? "#161920" : "#f8fafc")
    border.color: isExpanded
                  ? (Theme.isDark ? "#28446e" : "#bcd7ff")
                  : (Theme.isDark ? "#2b303b" : "#e2e8f0")
    border.width: 1

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: root.isExpanded ? 16 : 12
        spacing: 10

        // Заголовок и кнопка сворачивания/разворачивания
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: Theme.radiusSm
                color: root.isExpanded
                       ? (Theme.isDark ? "#213f6b" : "#dbeafe")
                       : (Theme.isDark ? "#262b34" : "#e2e8f0")

                Text {
                    anchors.centerIn: parent
                    text: "§"
                    color: root.isExpanded ? Theme.accent : Theme.muted
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: 6
                    StatusBadge {
                        text: root.standard
                        level: "teal"
                    }
                    StatusBadge {
                        text: root.clause
                        level: "info"
                        visible: root.clause.length > 0
                    }
                }

                Text {
                    text: root.title
                    color: Theme.text
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Button {
                id: toggleBtn
                flat: true
                text: root.isExpanded ? qsTr("Скрыть ▴") : qsTr("ГОСТ-справка ▾")
                font.pixelSize: Theme.fontCaption
                font.weight: Font.Medium
                contentItem: Text {
                    text: toggleBtn.text
                    font: toggleBtn.font
                    color: root.isExpanded ? Theme.accent : Theme.muted
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: toggleBtn.hovered ? (Theme.isDark ? "#252b37" : "#e2e8f0") : "transparent"
                    radius: Theme.radiusSm
                }
                onClicked: root.isExpanded = !root.isExpanded
            }
        }

        // Раскрывающийся подробный блок с цитатой и нормативным правилом
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.isExpanded
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.isDark ? "#283e60" : "#dbeafe"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.quote.length > 0

                Rectangle {
                    Layout.preferredWidth: 3
                    Layout.fillHeight: true
                    color: Theme.teal
                    radius: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: DocumentLinks.linkify(root.quote)
                    textFormat: Text.RichText
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                    font.italic: true
                    wrapMode: Text.Wrap
                    lineHeight: 1.2
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: noteText.implicitHeight + 14
                radius: Theme.radiusSm
                color: Theme.isDark ? "#141d2b" : "#ffffff"
                border.color: Theme.isDark ? "#23334d" : "#e0e7ff"
                border.width: 1
                visible: root.practicalNote.length > 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 8

                    Text {
                        id: noteText
                        Layout.fillWidth: true
                        text: DocumentLinks.linkify(root.practicalNote)
                        textFormat: Text.RichText
                        color: Theme.isDark ? "#93c5fd" : "#1e40af"
                        font.pixelSize: Theme.fontCaption
                        wrapMode: Text.Wrap
                        lineHeight: 1.2
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.isExpanded
        cursorShape: Qt.PointingHandCursor
        onClicked: root.isExpanded = true
    }
}
