import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: guideRoot

    property string stepNumber: "01"
    property string stepTitle: qsTr("Текущий этап процесса")
    property string purpose: qsTr("Что здесь происходит:")
    property string whatToDo: qsTr("Что необходимо сделать:")
    property string nextStepText: ""
    property string nextTabName: ""
    property bool isDismissible: true

    signal nextClicked()

    Layout.fillWidth: true
    implicitHeight: guideCol.implicitHeight + 24
    radius: Theme.radiusMd
    color: Theme.isDark ? "#141c28" : "#f1f5f9"
    border.color: Theme.isDark ? "#23334d" : "#cbd5e1"
    border.width: 1

    ColumnLayout {
        id: guideCol
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.radiusSm
                color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: guideRoot.stepNumber
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: guideRoot.stepTitle.toUpperCase()
                    color: Theme.accent
                    font.pixelSize: Theme.fontMicro
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }

                Text {
                    text: guideRoot.purpose
                    color: Theme.text
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            Button {
                visible: guideRoot.nextStepText.length > 0
                flat: true
                text: guideRoot.nextStepText
                font.pixelSize: Theme.fontCaption
                font.weight: Font.Bold
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: Theme.accent
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? (Theme.isDark ? "#1e293b" : "#e2e8f0") : "transparent"
                    radius: Theme.radiusSm
                }
                onClicked: guideRoot.nextClicked()
            }
        }

        Rectangle {
            visible: guideRoot.whatToDo.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.isDark ? "#23334d" : "#e2e8f0"
        }

        RowLayout {
            visible: guideRoot.whatToDo.length > 0
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "👉"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignTop
            }

            Text {
                Layout.fillWidth: true
                text: guideRoot.whatToDo
                color: Theme.textSecondary
                font.pixelSize: Theme.fontCaption
                wrapMode: Text.Wrap
                lineHeight: 1.2
            }
        }
    }
}
