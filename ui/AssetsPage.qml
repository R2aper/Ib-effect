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
            eyebrow: qsTr("КАРТА АКТИВОВ")
            heading: qsTr("Активы")
            description: qsTr("Объекты, данные и системы, ценность которых формирует приоритет защиты.")
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 250
            radius: 14
            color: Theme.panel
            border.color: Theme.border
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                Text {
                    text: "▣"
                    color: Theme.accent
                    font.pixelSize: 27
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: qsTr("Реестр активов пока пуст")
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: qsTr("Здесь будут отображаться название, стоимость и приоритет каждого актива.")
                    color: Theme.muted
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.maximumWidth: 440
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
        Text {
            text: qsTr("Поля реестра")
            color: Theme.text
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
        GridLayout {
            columns: width >= 800 ? 3 : 1
            columnSpacing: 12
            rowSpacing: 12
            Layout.fillWidth: true
            PlaceholderCard { glyph: "01"; heading: qsTr("Название актива"); description: qsTr("Система, данные или бизнес-процесс") }
            PlaceholderCard { glyph: "02"; heading: qsTr("Стоимость"); description: qsTr("Оценка ценности актива в рублях") }
            PlaceholderCard { glyph: "03"; heading: qsTr("Приоритет"); description: qsTr("Шкала критичности от 1 до 4") }
        }
        Item { Layout.preferredHeight: 12 }
    }
}
