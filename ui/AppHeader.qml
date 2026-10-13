import QtQuick
import QtQuick.Layouts

Rectangle {
    id: header

    required property string currentTitle

    color: Theme.background
    border.color: Theme.border
    border.width: 1
    Layout.fillWidth: true
    Layout.preferredHeight: 64

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        Text {
            text: qsTr("Рабочее пространство")
            color: Theme.muted
            font.pixelSize: 12
        }
        Text {
            text: " / "
            color: "#53657b"
            font.pixelSize: 12
        }
        Text {
            text: header.currentTitle
            color: Theme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }
        Rectangle {
            radius: 14
            color: "#142a25"
            border.color: "#245440"
            implicitWidth: 106
            implicitHeight: 28
            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.green
                }
                Text {
                    text: qsTr("Интерфейс")
                    color: "#9ce2bf"
                    font.pixelSize: 10
                }
            }
        }
    }
}
