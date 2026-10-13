import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

ScrollView {
    clip: true
    padding: 24
    contentWidth: availableWidth

    ColumnLayout {
        width: parent.width
        spacing: 22
        Item { Layout.preferredHeight: 2 }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 286
            Rectangle {
                id: heroSurface
                anchors.fill: parent
                radius: 18
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1a3b5e" }
                    GradientStop { position: 0.52; color: "#142b45" }
                    GradientStop { position: 1.0; color: "#132338" }
                }
                border.color: "#31577e"
            }
            MultiEffect {
                source: heroSurface
                anchors.fill: heroSurface
                shadowEnabled: true
                shadowColor: "#a0000000"
                shadowBlur: 0.55
                shadowOpacity: 0.55
                shadowVerticalOffset: 8
                z: -1
            }
            RowLayout {
                anchors.fill: parent
                anchors.margins: 32
                spacing: 24
                ColumnLayout {
                    spacing: 13
                    Layout.fillWidth: true
                    Text {
                        text: qsTr("ПЛАТФОРМА УПРАВЛЕНИЯ ЭФФЕКТИВНОСТЬЮ ИБ")
                        color: "#82b9f7"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                        wrapMode: Text.Wrap
                    }
                    Text {
                        text: qsTr("Управляйте рисками.\nДоказывайте ценность ИБ.")
                        color: Theme.text
                        font.pixelSize: 29
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    Text {
                        text: qsTr("Единая модель связывает активы, риски, защитные меры и экономический результат — от первой оценки до обоснования инвестиций.")
                        color: "#b4c4d8"
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.maximumWidth: 620
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        spacing: 8
                        Repeater {
                            model: [
                                qsTr("Активы  →"),
                                qsTr("Риски  →"),
                                qsTr("Меры  →"),
                                qsTr("Экономика")
                            ]
                            delegate: Text {
                                required property string modelData
                                text: modelData
                                color: "#d2e1f3"
                                font.pixelSize: 10
                                Layout.rightMargin: 3
                            }
                        }
                    }
                }
                Item {
                    Layout.preferredWidth: 224
                    Layout.preferredHeight: 204
                    Rectangle {
                        id: brandSurface
                        anchors.fill: parent
                        radius: 18
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#244b74" }
                            GradientStop { position: 1.0; color: "#19324e" }
                        }
                        border.color: "#416b95"
                    }
                    MultiEffect {
                        source: brandSurface
                        anchors.fill: brandSurface
                        shadowEnabled: true
                        shadowColor: "#90000000"
                        shadowBlur: 0.45
                        shadowOpacity: 0.5
                        shadowVerticalOffset: 6
                        z: -1
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 7
                        Text {
                            text: "ИБ"
                            color: "#8fc6ff"
                            font.pixelSize: 41
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: qsTr("ЭФФЕКТ")
                            color: "#c9ddf4"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 3
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 7
                            width: 86
                            height: 2
                            color: Theme.accent
                        }
                        Text {
                            text: qsTr("Риск → защита → результат")
                            color: "#a9bdd4"
                            font.pixelSize: 9
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        SectionHeading {
            eyebrow: qsTr("КАК РАБОТАЕТ ИБ-ЭФФЕКТ")
            heading: qsTr("От вопроса «что защищать?» к решению «во что инвестировать?»")
            description: qsTr("Последовательно пройдите модель — от карты активов до оценки экономического эффекта.")
        }

        GridLayout {
            columns: width >= 880 ? 4 : 2
            columnSpacing: 12
            rowSpacing: 12
            Layout.fillWidth: true
            PlaceholderCard {
                glyph: "01  ▣"
                heading: qsTr("Определите активы")
                description: qsTr("Что защищаем и насколько это важно?")
            }
            PlaceholderCard {
                glyph: "02  △"
                heading: qsTr("Оцените риски")
                description: qsTr("Какой ущерб и вероятность сценария?")
            }
            PlaceholderCard {
                glyph: "03  ◉"
                heading: qsTr("Выберите меры")
                description: qsTr("Что снизит риск и сколько это стоит?")
            }
            PlaceholderCard {
                glyph: "04  ₽"
                heading: qsTr("Посчитайте эффект")
                description: qsTr("Как снижение риска превращается в деньги?")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 84
            radius: 12
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.panelRaised }
                GradientStop { position: 1.0; color: Theme.panel }
            }
            border.color: Theme.borderHighlight
            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14
                Text {
                    text: qsTr("ЕДИНАЯ МОДЕЛЬ")
                    color: Theme.accent
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
                Text {
                    text: qsTr("Риск   →   Мера   →   Снижение   →   Экономический эффект   →   ROSI")
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }
        Item { Layout.preferredHeight: 18 }
    }
}
