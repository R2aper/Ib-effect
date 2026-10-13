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
            eyebrow: qsTr("ЭКОНОМИЧЕСКАЯ МОДЕЛЬ")
            heading: qsTr("Экономика")
            description: qsTr("Перевод снижения ожидаемых потерь в финансовый эффект и ROSI.")
        }
        Text {
            text: qsTr("Экономическая эффективность внедрения ИБ")
            color: Theme.text
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }
        GridLayout {
            columns: width >= 850 ? 3 : 1
            columnSpacing: 12
            rowSpacing: 12
            Layout.fillWidth: true
            MetricCard {
                label: qsTr("Ожидаемые потери до мер")
                value: "— ₽"
                note: qsTr("Сумма ожидаемых потерь по рискам")
                valueColor: Theme.red
            }
            MetricCard {
                label: qsTr("Ожидаемые потери после мер")
                value: "— ₽"
                note: qsTr("Остаточные потери после защиты")
                valueColor: Theme.green
            }
            MetricCard {
                label: qsTr("Инвестиции в защиту")
                value: "— ₽"
                note: qsTr("Суммарная стоимость мер")
                valueColor: Theme.accent
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 136
            radius: 14
            color: "#142a25"
            border.color: "#286044"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 8
                Text {
                    text: qsTr("ЧИСТЫЙ ЭКОНОМИЧЕСКИЙ ЭФФЕКТ")
                    color: "#8bd9ad"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1
                }
                Text {
                    text: "— ₽"
                    color: Theme.text
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                }
                Text {
                    text: qsTr("(Потери до мер − Потери после мер) − Стоимость мер")
                    color: "#a8c9b7"
                    font.pixelSize: 12
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 78
            radius: 10
            color: Theme.panel
            border.color: Theme.border
            Text {
                anchors.fill: parent
                anchors.margins: 17
                text: qsTr("Анализ ROSI появится после добавления рисков и связанных с ними мер защиты.")
                color: Theme.muted
                font.pixelSize: 12
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item { Layout.preferredHeight: 12 }
    }
}
