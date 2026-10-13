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
            eyebrow: qsTr("РЕЕСТР РИСКОВ")
            heading: qsTr("Управление рисками")
            description: qsTr("Сценарии угроз, оценка приоритета и связь с активами и мерами защиты.")
        }
        GridLayout {
            columns: width >= 850 ? 4 : 2
            columnSpacing: 12
            rowSpacing: 12
            Layout.fillWidth: true
            MetricCard { label: qsTr("Всего рисков"); value: "—"; note: qsTr("В реестре"); valueColor: Theme.accent }
            MetricCard { label: qsTr("Высокий уровень"); value: "—"; note: qsTr("Требуют внимания"); valueColor: Theme.red }
            MetricCard { label: qsTr("Средний уровень"); value: "—"; note: qsTr("На контроле"); valueColor: Theme.amber }
            MetricCard { label: qsTr("Под контролем"); value: "—"; note: qsTr("Есть защитная мера"); valueColor: Theme.green }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            radius: 10
            color: Theme.panel
            border.color: Theme.border
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                Text {
                    text: "⌕"
                    color: Theme.muted
                    font.pixelSize: 20
                }
                Text {
                    text: qsTr("Поиск по угрозе, уязвимости или активу…")
                    color: "#6f829b"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
                Text {
                    text: qsTr("Все   Высокие   Средние   Низкие")
                    color: Theme.muted
                    font.pixelSize: 11
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 248
            radius: 14
            color: Theme.panel
            border.color: Theme.border
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                Text {
                    text: "△"
                    color: Theme.amber
                    font.pixelSize: 27
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: qsTr("Риски не добавлены")
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: qsTr("В реестре появятся описание угрозы, уязвимости, связанный актив и балльная оценка.")
                    color: Theme.muted
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.maximumWidth: 480
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
        Item { Layout.preferredHeight: 12 }
    }
}
