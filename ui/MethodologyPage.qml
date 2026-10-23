import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "DocumentLinks.js" as DocumentLinks

ScrollView {
    clip: true
    padding: 24
    contentWidth: availableWidth

    ColumnLayout {
        width: parent.width
        spacing: 18

        SectionHeading {
            eyebrow: qsTr("МЕТОДОЛОГИЧЕСКИЙ БАЗИС")
            heading: qsTr("Методика расчета эффективности ИБ")
            description: qsTr("Математический аппарат, формулы и алгоритмы оценки рисков и экономической целесообразности инвестиций.")
        }

        WorkflowGuideBanner {
            stepNumber: "INFO"
            stepTitle: qsTr("Справочник методологии и математического аппарата")
            purpose: qsTr("Теоретическое и нормативное обоснование формул расчета рисков, предотвращенного ущерба и экономической эффективности.")
            whatToDo: qsTr("Изучите используемые математические соотношения, пояснения и практические комментарии. Нормативные основания доступны в справке к каждой формуле.")
        }

        Repeater {
            model: [
                {
                    num: "01",
                    title: qsTr("Формула базовой оценки риска"),
                    formula: qsTr("Риск = Ущерб (I) × Вероятность (P) × Приоритет актива (A)"),
                    desc: qsTr("Балльная оценка принимает дискретные значения от 1 до 64. Позволяет ранжировать сценарии угроз по степени тяжести последствий."),
                    tag: qsTr("Базовый риск"),
                    tagLevel: "teal",
                    standard: "ГОСТ Р ИСО/МЭК 27005-2010",
                    clause: "п. 8.2, Приложение E",
                    normativeQuote: qsTr("«Уровень риска оценивается как сочетание вероятности возникновения события инцидента информационной безопасности и его последствий. При оценке последствий учитывается ценность активов, ущерб бизнесу и затраты на восстановление» (ГОСТ Р ИСО/МЭК 27005-2010, п. 8.2)."),
                    practicalNote: qsTr("Ценность актива (приоритет A) калибрует шкалу ущерба. Применение матричного метода соответствует ГОСТ Р 58771-2019 / ГОСТ Р ИСО/МЭК 31010-2011.")
                },
                {
                    num: "02",
                    title: qsTr("Расчет остаточного риска"),
                    formula: qsTr("Остаточный риск = (Ущерб × (1 − Снижение_I)) × (Вероятность × (1 − Снижение_P)) × Приоритет"),
                    desc: qsTr("Отражает фактический уровень защищенности после внедрения технических и организационных мер нейтрализации."),
                    tag: qsTr("Остаточный риск"),
                    tagLevel: "info",
                    standard: "ГОСТ Р 59339-2021",
                    clause: "п. 6.3.1, Таблица Г.1",
                    normativeQuote: qsTr("«Частные показатели риска реализации угроз безопасности информации определяются в условиях применения мер защиты (показатели остаточного риска)» (ГОСТ Р 59339-2021, п. 6.3.1)."),
                    practicalNote: qsTr("Превентивные меры снижают вероятность инцидента, а компенсирующие меры и планы аварийного восстановления ограничивают тяжесть последствий.")
                },
                {
                    num: "03",
                    title: qsTr("Перевод баллов риска в денежные потери"),
                    formula: qsTr("Ожидаемые финансовые потери = Баллы риска × Стоимость 1 балла риска"),
                    desc: qsTr("Монетизация рисков для предоставления обоснованных отчетов совету директоров и финансовой службе организации."),
                    tag: qsTr("Монетизация"),
                    tagLevel: "high",
                    standard: "ГОСТ Р 57580.3-2022",
                    clause: "Приложение Г, пп. Г.1–Г.4",
                    normativeQuote: qsTr("«Потери от реализации риска классифицируются на прямые потери (отраженные на счетах бухгалтерского учета) и непрямые потери (косвенные расчетные, качественные экспертные и потенциальные)» (ГОСТ Р 57580.3-2022, Приложение Г)."),
                    practicalNote: qsTr("В калькуляторе стоимость одного балла служит базовым финансовым эквивалентом для перевода интегрального балла риска в рублевую оценку возможных убытков.")
                },
                {
                    num: "04",
                    title: qsTr("Коэффициент чистой окупаемости инвестиций (Net ROSI)"),
                    formula: qsTr("Net ROSI = ((Предотвращенный ущерб − Затраты на меры) / Затраты на меры) × 100%"),
                    desc: qsTr("Ключевая финансовая метрика окупаемости портфеля мер защиты. Положительный показатель подтверждает целесообразность инвестиций."),
                    tag: "Net ROSI",
                    tagLevel: "success",
                    standard: "Методология ROSI (ENISA)",
                    clause: "ГОСТ Р 59339-2021 п. 4.3",
                    normativeQuote: qsTr("«Net Return on Security Investment (Net ROSI) оценивает чистую окупаемость затрат на ИБ с учетом вычета капитальных и операционных расходов на меры защиты (TCO)» (Методология ENISA / NIST SP 800-30)."),
                    practicalNote: qsTr("Термин Net означает «чистый» (с вычетом затрат на СЗИ, аналогично Net Present Value), а не «сетевой». Значение > 0% свидетельствует об экономической эффективности.")
                },
                {
                    num: "05",
                    title: qsTr("Чистый экономический эффект программы ИБ"),
                    formula: qsTr("Чистый эффект = Предотвращенные потери − Совокупная стоимость мер (TCO)"),
                    desc: qsTr("Абсолютная рублевая выгода от реализации программы информационной безопасности."),
                    tag: qsTr("Экономический эффект"),
                    tagLevel: "success",
                    standard: "ГОСТ Р 59339-2021",
                    clause: "п. 6.1.2, Таблица Г.1",
                    normativeQuote: qsTr("«Результатами процесса управления рисками являются достигаемые эффекты от реализации предупреждающих мер по снижению рисков или их удержанию в допустимых пределах» (ГОСТ Р 59339-2021, п. 6.1.2)."),
                    practicalNote: qsTr("Показывает сумму сохраненных средств компании за вычетом прямых затрат на лицензии, внедрение и сопровождение мер безопасности.")
                },
                {
                    num: "06",
                    title: qsTr("Классификация событий риска и операционная надежность"),
                    formula: qsTr("Источники: Процессы + Персонал + Сбои ИТ + Внешние факторы"),
                    desc: qsTr("Комплексный учет источников угроз и времени допустимого простоя бизнес-процессов (RTO)."),
                    tag: "Операционная надежность",
                    tagLevel: "teal",
                    standard: "ГОСТ Р 57580.3-2022",
                    clause: "Приложения А, Б, Таблица Б.1",
                    normativeQuote: qsTr("«Финансовая организация классифицирует события риска реализации информационных угроз по четырем категориям источников риска и типам событий, включая простой и деградацию бизнес-процессов» (ГОСТ Р 57580.3-2022)."),
                    practicalNote: qsTr("Обеспечивает гармонизацию процессов управления инцидентами с требованиями Положений Банка России № 716-П и № 787-П.")
                }
            ]

            delegate: Rectangle {
                id: methCard
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: cardCol.implicitHeight + 32
                radius: Theme.radiusMd
                color: Theme.panel
                border.color: cardMouse.containsMouse ? Theme.borderHighlight : Theme.border
                border.width: 1

                Behavior on border.color {
                    ColorAnimation { duration: 120 }
                }

                MultiEffect {
                    source: methCard
                    anchors.fill: methCard
                    shadowEnabled: true
                    shadowColor: Theme.isDark ? "#40000000" : "#12000000"
                    shadowBlur: 0.35
                    shadowOpacity: 0.25
                    shadowVerticalOffset: 2
                    z: -1
                }

                RowLayout {
                    id: cardCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 18

                    // Номер блока
                    Rectangle {
                        width: 44
                        height: 44
                        radius: Theme.radiusSm
                        color: Theme.raised
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: methCard.modelData.num
                            color: Theme.accent
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                    }

                    ColumnLayout {
                        spacing: 8
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: 10
                            Text {
                                text: methCard.modelData.title
                                color: Theme.text
                                font.pixelSize: Theme.fontH3
                                font.weight: Font.Bold
                            }
                            StatusBadge {
                                text: methCard.modelData.tag
                                level: methCard.modelData.tagLevel
                                showDot: false
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: formulaText.implicitHeight + 16
                            radius: Theme.radiusSm
                            color: Theme.isDark ? "#171a22" : "#f8f9fb"
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                id: formulaText
                                anchors.centerIn: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                text: DocumentLinks.linkify(methCard.modelData.formula)
                                textFormat: Text.RichText
                                color: Theme.isDark ? Theme.accentLight : Theme.accent
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width - 28
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                        }

                        Text {
                            text: methCard.modelData.desc
                            color: Theme.muted
                            font.pixelSize: Theme.fontBody
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        NormativeExplanationCard {
                            title: qsTr("Нормативная база формулы")
                            standard: methCard.modelData.standard
                            clause: methCard.modelData.clause
                            quote: methCard.modelData.normativeQuote
                            practicalNote: methCard.modelData.practicalNote
                            Layout.fillWidth: true
                        }
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onPressed: mouse.accepted = false
                }
            }
        }

        Item { Layout.preferredHeight: 12 }
    }
}
