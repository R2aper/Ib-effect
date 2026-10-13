import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sidebar

    property int currentTab: 0
    signal tabSelected(int index)

    color: Theme.sidebar
    border.color: Theme.border
    border.width: 1
    Layout.preferredWidth: 252
    Layout.fillHeight: true

    readonly property var items: [
        { glyph: "⌂", label: qsTr("Панель эффективности") },
        { glyph: "◈", label: qsTr("Модель риска") },
        { glyph: "▣", label: qsTr("Активы") },
        { glyph: "△", label: qsTr("Риски") },
        { glyph: "◉", label: qsTr("Меры защиты") },
        { glyph: "₽", label: qsTr("Экономика") },
        { glyph: "∑", label: qsTr("Методика") }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 7
            Layout.bottomMargin: 24
            spacing: 11
            Rectangle {
                width: 38
                height: 38
                radius: 11
                color: "#1c3a5e"
                Text {
                    anchors.centerIn: parent
                    text: "ИБ"
                    color: "#83bdff"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }
            ColumnLayout {
                spacing: 2
                Text {
                    text: qsTr("ИБ-Эффект")
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
                Text {
                    text: qsTr("Платформа оценки ИБ")
                    color: Theme.muted
                    font.pixelSize: 10
                }
            }
        }

        Text {
            text: qsTr("РАБОЧЕЕ ПРОСТРАНСТВО")
            color: "#6f829b"
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            Layout.leftMargin: 9
            Layout.bottomMargin: 10
        }

        Repeater {
            model: sidebar.items
            delegate: NavigationButton {
                required property int index
                required property var modelData
                tabIndex: index
                glyph: modelData.glyph
                label: modelData.label
                checked: sidebar.currentTab === index
                onClicked: sidebar.tabSelected(index)
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 74
            radius: 10
            color: "#14243a"
            border.color: Theme.border
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 5
                Text {
                    text: qsTr("Локальный проект")
                    color: Theme.text
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Text {
                    text: qsTr("Черновик · данные не подключены")
                    color: Theme.muted
                    font.pixelSize: 10
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
