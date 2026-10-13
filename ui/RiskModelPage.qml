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
            eyebrow: qsTr("МОДЕЛЬ ОЦЕНКИ")
            heading: qsTr("Модель риска")
            description: qsTr("Критерии и параметры, которые задают основу оценки информационных рисков.")
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 132
            radius: 14
            color: "#142943"
            border.color: "#254669"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 9
                Text {
                    text: qsTr("ФОРМУЛА ОЦЕНКИ")
                    color: "#82b9f7"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1
                }
                Text {
                    text: qsTr("Риск = Ущерб × Вероятность × Приоритет актива")
                    color: Theme.text
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                Text {
                    text: qsTr("Шкалы оценки: от 1 до 4 баллов для каждого параметра")
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
        }
        Text {
            text: qsTr("Параметры модели")
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
                label: qsTr("Максимальный ущерб")
                value: "1–4"
                note: qsTr("Балльная шкала")
                valueColor: Theme.accent
            }
            MetricCard {
                label: qsTr("Вероятность события")
                value: "1–4"
                note: qsTr("Балльная шкала")
                valueColor: Theme.amber
            }
            MetricCard {
                label: qsTr("Приоритет актива")
                value: "1–4"
                note: qsTr("Балльная шкала")
                valueColor: Theme.green
            }
        }
        GridLayout {
            columns: width >= 850 ? 2 : 1
            columnSpacing: 12
            rowSpacing: 12
            Layout.fillWidth: true
            MetricCard {
                label: qsTr("Риск-аппетит")
                value: qsTr("Не задан")
                note: qsTr("Максимально допустимый балл риска")
                valueColor: Theme.green
            }
            MetricCard {
                label: qsTr("Стоимость одного балла риска")
                value: qsTr("Не задана")
                note: qsTr("Используется для перевода оценки в денежный эквивалент")
                valueColor: Theme.accent
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 72
            radius: 10
            color: Theme.panel
            border.color: Theme.border
            Text {
                anchors.fill: parent
                anchors.margins: 17
                text: qsTr("Методологическая основа: ГОСТ Р ИСО/МЭК 27000-2021 — менеджмент риска информационной безопасности.")
                color: Theme.muted
                font.pixelSize: 12
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item { Layout.preferredHeight: 12 }
    }
}
