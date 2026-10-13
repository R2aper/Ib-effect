import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    clip: true
    padding: 24
    contentWidth: availableWidth

    ColumnLayout {
        width: parent.width
        spacing: 20
        SectionHeading {
            eyebrow: qsTr("ПОРТФЕЛЬ ЗАЩИТЫ")
            heading: qsTr("Меры защиты")
            description: qsTr("Каталог мер, их стоимость, влияние на ущерб и вероятность сценария.")
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 260
            radius: 14
            color: Theme.panel
            border.color: Theme.border
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                Text {
                    text: "◉"
                    color: Theme.green
                    font.pixelSize: 27
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: qsTr("Каталог мер защиты пока пуст")
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: qsTr("Карточки мер будут содержать стоимость и ожидаемое снижение ущерба и вероятности.")
                    color: Theme.muted
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.maximumWidth: 460
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
        Text {
            text: qsTr("Параметры меры")
            color: Theme.text
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
        GridLayout {
            columns: width >= 850 ? 3 : 1
            columnSpacing: 12
            rowSpacing: 12
            Layout.fillWidth: true
            PlaceholderCard { glyph: "₽"; heading: qsTr("Стоимость"); description: qsTr("Затраты на внедрение меры") }
            PlaceholderCard { glyph: "↓"; heading: qsTr("Снижение ущерба"); description: qsTr("Ожидаемое снижение в процентах") }
            PlaceholderCard { glyph: "↘"; heading: qsTr("Снижение вероятности"); description: qsTr("Ожидаемое снижение в процентах") }
        }
        Item { Layout.preferredHeight: 12 }
    }
}
