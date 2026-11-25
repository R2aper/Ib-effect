import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        Rectangle {
            width: root.width
            implicitHeight: contentColumn.implicitHeight + 48
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 16

                Text {
                    text: "СПРАВКА"
                    font.family: Style.fontSans
                    font.pixelSize: Style.fontSizeBodySm
                    font.weight: Font.DemiBold
                    color: Style.textSecondary
                }

                Text {
                    text: "Как ведется расчет"
                    font.family: Style.fontSans
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: Style.textPrimary
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    textFormat: Text.RichText
                    font.family: Style.fontSans
                    font.pixelSize: Style.fontSizeBodyLg
                    color: Style.textSecondary
                    text: "Калькулятор оценивает критичность уязвимости, вероятные годовые потери и экономическую эффективность мер защиты. Расчеты выполняются последовательно для исходного состояния актива и для состояния после применения защитных мер."
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: formulaColumn.implicitHeight + 28
                    radius: 2
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder

                    ColumnLayout {
                        id: formulaColumn
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Text {
                            text: "1. Критичность уязвимости"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineMd
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeMd
                            color: Style.textPrimary
                            text: "V = Icvss × Iinfr × (Iat + Iimp)"
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodyLg
                            color: Style.textSecondary
                            text: "Icvss берется из БДУ ФСТЭК либо рассчитывается по метрикам CVSS 3.1. Iinfr учитывает тип компонента, долю затронутых компонентов и доступ из сети. Iat отражает наличие эксплойта и реальную возможность эксплуатации, а Iimp — тяжесть последствий."
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodyLg
                            color: Style.textSecondary
                            text: "Уровень критичности: V > 8 — критический; 5 ≤ V ≤ 8 — высокий; 2 ≤ V < 5 — средний; V < 2 — низкий."
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: probabilityColumn.implicitHeight + 28
                    radius: 2
                    color: Style.panelSurface
                    border.color: Style.hairlineBorder

                    ColumnLayout {
                        id: probabilityColumn
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Text {
                            text: "2. Вероятность и годовой ущерб"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineMd
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeMd
                            color: Style.textPrimary
                            text: "P = min(V / 8, 1);  ALE = SLE × P"
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodyLg
                            color: Style.textSecondary
                            text: "SLE — разовая стоимость потерь актива: прямые затраты на восстановление плюс косвенные потери от утечки или недоступности. ALE показывает ожидаемый годовой ущерб при исходной и остаточной вероятности."
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: economicsColumn.implicitHeight + 28
                    radius: 2
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder

                    ColumnLayout {
                        id: economicsColumn
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Text {
                            text: "3. Экономический эффект меры"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineMd
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeMd
                            color: Style.textPrimary
                            text: "Предотвращенный ущерб = ALEдо − ALEпосле\nЧистая выгода = Предотвращенный ущерб − TCO\nNet ROSI = (Чистая выгода / TCO) × 100%"
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodyLg
                            color: Style.textSecondary
                            text: "TCO включает совокупные затраты на внедрение и сопровождение меры. Положительный Net ROSI означает, что расчетная предотвращенная часть убытков превышает TCO."
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sourcesColumn.implicitHeight + 28
                    radius: 2
                    color: Style.panelSurface
                    border.color: Style.hairlineBorder

                    ColumnLayout {
                        id: sourcesColumn
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "Нормативные источники"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineMd
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            textFormat: Text.RichText
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodyLg
                            color: Style.textSecondary
                            text: '<a href="https://fstec.ru/dokumenty/vse-dokumenty/spetsialnye-normativnye-dokumenty/metodicheskij-dokument-ot-5-fevralya-2021-g?ysclid=mww26usjsm986576824" style="color:#0A0A0A">Методический документ ФСТЭК России от 5 февраля 2021 г. — методика оценки угроз безопасности информации</a>'
                            onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            textFormat: Text.RichText
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodyLg
                            color: Style.textSecondary
                            text: '<a href="https://fstec.ru/dokumenty/vse-dokumenty/spetsialnye-normativnye-dokumenty/metodicheskij-dokument-ot-30-iyunya-2025-g?ysclid=mww270jil2823101463" style="color:#0A0A0A">Методический документ ФСТЭК России от 30 июня 2025 г. — методика оценки уровня критичности уязвимостей</a>'
                            onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodySm
                            color: Style.textMuted
                            text: "Методика 2025 г. определяет показатели критичности уязвимости и SLA устранения. Методика 2021 г. используется для описания сценариев угроз и негативных последствий."
                        }
                    }
                }

                Item { Layout.preferredHeight: 8 }
            }
        }
    }
}
