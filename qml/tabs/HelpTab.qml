import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    property int activeSection: 0 // 0: Formuls, 1: FSTEC 2025, 2: ISO 27005, 3: Threats 2021, 4: 98-FZ, 5: Table 1, 6: Table 2, 7: Table 9.1

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Left Navigation Tree (28% width)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.28
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: "СПРАВОЧНИК И БАЗА ЗНАНИЙ"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                    }
                }

                // Tree Items ScrollView
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width

                    ColumnLayout {
                        width: parent.width - 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4

                        Item { height: 4 }

                        // Category 1: Математическая модель
                        Text {
                            text: "1. МАТЕМАТИЧЕСКАЯ МОДЕЛЬ"
                            font.family: Style.fontSans
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Style.textSecondary
                        }

                        Repeater {
                            model: [
                                { idx: 0, title: "1.1. Базовая система формул (V, ALE, ROSI)" }
                            ]
                            Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                color: (root.activeSection === modelData.idx) ? Style.surfaceActive : (mArea.containsMouse ? Style.surfaceHover : "transparent")
                                border.color: (root.activeSection === modelData.idx) ? Style.primary : "transparent"
                                border.width: 1

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    text: modelData.title
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    font.weight: (root.activeSection === modelData.idx) ? Font.DemiBold : Font.Normal
                                    color: (root.activeSection === modelData.idx) ? Style.textPrimary : Style.textSecondary
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    id: mArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeSection = modelData.idx
                                }
                            }
                        }

                        Item { height: 6 }

                        // Category 2: Нормативные документы
                        Text {
                            text: "2. НОРМАТИВНЫЕ ДОКУМЕНТЫ (5 ИСТОЧНИКОВ)"
                            font.family: Style.fontSans
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Style.textSecondary
                        }

                        Repeater {
                            model: [
                                { idx: 1, title: "2.1. Методика ФСТЭК России (30.06.2025)" },
                                { idx: 2, title: "2.2. ГОСТ Р ИСО/МЭК 27005-2010 (Риски ИБ)" },
                                { idx: 3, title: "2.3. Методика угроз ФСТЭК (05.02.2021)" },
                                { idx: 4, title: "2.4. Федеральный закон № 98-ФЗ (КТ, ст. 10)" }
                            ]
                            Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                color: (root.activeSection === modelData.idx) ? Style.surfaceActive : (mArea2.containsMouse ? Style.surfaceHover : "transparent")
                                border.color: (root.activeSection === modelData.idx) ? Style.primary : "transparent"
                                border.width: 1

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    text: modelData.title
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    font.weight: (root.activeSection === modelData.idx) ? Font.DemiBold : Font.Normal
                                    color: (root.activeSection === modelData.idx) ? Style.textPrimary : Style.textSecondary
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    id: mArea2
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeSection = modelData.idx
                                }
                            }
                        }

                        Item { height: 6 }

                        // Category 3: Нормативные таблицы
                        Text {
                            text: "3. ЭТАЛОННЫЕ ТАБЛИЦЫ ФСТЭК"
                            font.family: Style.fontSans
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Style.textSecondary
                        }

                        Repeater {
                            model: [
                                { idx: 5, title: "3.1. Таблица 1. Весовые коэффициенты (K,L,P,E,H)" },
                                { idx: 6, title: "3.2. Таблица 2. Уровни критичности V и SLA" },
                                { idx: 7, title: "3.3. Таблица 9.1. Нарушители (Н1-Н4) и ущерб (У1-У3)" }
                            ]
                            Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                color: (root.activeSection === modelData.idx) ? Style.surfaceActive : (mArea3.containsMouse ? Style.surfaceHover : "transparent")
                                border.color: (root.activeSection === modelData.idx) ? Style.primary : "transparent"
                                border.width: 1

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    text: modelData.title
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    font.weight: (root.activeSection === modelData.idx) ? Font.DemiBold : Font.Normal
                                    color: (root.activeSection === modelData.idx) ? Style.textPrimary : Style.textSecondary
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    id: mArea3
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeSection = modelData.idx
                                }
                            }
                        }
                    }
                }

                // Left Pane Footer
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    color: Style.surfaceContainer
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: "Версия методики: 2025.06"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "ФСТЭК России"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textPrimary
                        }
                    }
                }
            }
        }

        // Right Document Viewer Pane (72% width)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.72
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Top Banner
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14

                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: {
                                    switch (root.activeSection) {
                                    case 0: return "РАЗДЕЛ 1: МАТЕМАТИЧЕСКОЕ ЯДРО И СИСТЕМА РАСЧЕТНЫХ ФОРМУЛ";
                                    case 1: return "МЕТОДИКА ОЦЕНКИ КРИТИЧНОСТИ УЯЗВИМОСТЕЙ (ФСТЭК РОССИИ ОТ 30.06.2025)";
                                    case 2: return "ГОСТ Р ИСО/МЭК 27005-2010 «МЕНЕДЖМЕНТ РИСКА ИНФОРМАЦИОННОЙ БЕЗОПАСНОСТИ»";
                                    case 3: return "МЕТОДИКА ОЦЕНКИ УГРОЗ БЕЗОПАСНОСТИ ИНФОРМАЦИИ (ФСТЭК ОТ 05.02.2021)";
                                    case 4: return "ФЕДЕРАЛЬНЫЙ ЗАКОН ОТ 29.07.2004 № 98-ФЗ «О КОММЕРЧЕСКОЙ ТАЙНЕ»";
                                    case 5: return "ТАБЛИЦА 1. ЗНАЧЕНИЯ ВЕСОВЫХ КОЭФФИЦИЕНТОВ И ОЦЕНОК ПОКАЗАТЕЛЕЙ (ФСТЭК 2025)";
                                    case 6: return "ТАБЛИЦА 2. ИТОГОВАЯ ОЦЕНКА УРОВНЯ КРИТИЧНОСТИ V И РЕГЛАМЕНТНЫЕ СРОКИ";
                                    case 7: return "ТАБЛИЦА 9.1. АКТУАЛЬНЫЕ НАРУШИТЕЛИ (Н1–Н4) И ВИДЫ УЩЕРБА (У1, У2, У3)";
                                    default: return "СПРАВКА";
                                    }
                                }
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeHeadlineSm
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                            }
                            Text {
                                text: "Стандарт нормативной документации и регламенты регулятора"
                                font.family: Style.fontSans
                                font.pixelSize: 10
                                color: Style.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: 22
                            implicitWidth: certTag.implicitWidth + 12
                            color: Style.surfaceContainerHighest
                            radius: 2
                            Text {
                                id: certTag
                                anchors.centerIn: parent
                                text: "ОФИЦИАЛЬНАЯ МЕТОДИКА"
                                font.family: Style.fontMono
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Style.textPrimary
                            }
                        }
                    }
                }

                // Scrollable Content
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width

                    ColumnLayout {
                        width: parent.width - 28
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14

                        Item { height: 4 }

                        // SECTION 0: FORMULAS
                        ColumnLayout {
                            visible: root.activeSection === 0
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: fBox.implicitHeight + 20
                                color: Style.surfaceLow
                                border.color: Style.hairlineBorder
                                border.width: 1

                                ColumnLayout {
                                    id: fBox
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Text {
                                        text: "1. Полная ценность актива (SLE):"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.Bold
                                        color: Style.textPrimary
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 32
                                        color: Style.panelSurface
                                        border.color: Style.hairlineBorder
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: "SLE = D_direct + D_indirect"
                                            font.family: Style.fontMono
                                            font.pixelSize: Style.fontSizeCodeMd
                                            font.weight: Font.Bold
                                        }
                                    }
                                    Text {
                                        text: "• D_direct — прямой ущерб (восстановление, замена, форензика);\n• D_indirect — косвенный ущерб (упущенная выгода, штрафы NDA, У2 по ФСТЭК 2021)."
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textSecondary
                                    }

                                    Item { height: 4 }

                                    Text {
                                        text: "2. Уровень критичности уязвимости (V):"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.Bold
                                        color: Style.textPrimary
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 48
                                        color: Style.panelSurface
                                        border.color: Style.hairlineBorder
                                        border.width: 1
                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 2
                                            Text {
                                                text: "I_infr = k·K + l·L + p·P"
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeCodeMd
                                                font.weight: Font.Bold
                                            }
                                            Text {
                                                text: "V = I_cvss × I_infr × (I_at + I_imp)"
                                                font.family: Style.fontMono
                                                font.pixelSize: Style.fontSizeCodeMd
                                                font.weight: Font.Bold
                                            }
                                        }
                                    }

                                    Item { height: 4 }

                                    Text {
                                        text: "3. Непрерывная модель потерь (ALE) и окупаемости инвестиций (Net ROSI):"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.Bold
                                        color: Style.textPrimary
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 80
                                        color: Style.panelSurface
                                        border.color: Style.hairlineBorder
                                        border.width: 1
                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Text { text: "Prob = min(V / 8.0, 1.0)"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold }
                                            Text { text: "ALE = SLE × Prob"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold }
                                            Text { text: "Avoided Loss (ΔALE) = ALE_base - ALE_residual"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold }
                                            Text { text: "Net Benefit = Avoided Loss - Cost_TCO"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold }
                                            Text { text: "Net ROSI = (Net Benefit / Cost_TCO) × 100%"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.riskLowText }
                                        }
                                    }
                                }
                            }
                        }

                        // SECTION 1: FSTEC 2025
                        ColumnLayout {
                            visible: root.activeSection === 1
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: fstecCol.implicitHeight + 20
                                color: Style.surfaceLow
                                border.color: Style.hairlineBorder
                                border.width: 1

                                ColumnLayout {
                                    id: fstecCol
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Text {
                                        text: "Методика оценки уровня критичности уязвимостей (ФСТЭК России от 30 июня 2025 г.)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.Bold
                                        color: Style.textPrimary
                                    }
                                    Text {
                                        text: "Ключевые пункты методики:\n" +
                                              "• Раздел I (п. 1–6): Область применения, гармонизация с ГОСТ Р 50922-2006 и ГОСТ Р 56545-2015.\n" +
                                              "• Раздел II (п. 7–19): Порядок оценки уровня критичности V:\n" +
                                              "   - п. 8: Исходные данные из БДУ ФСТЭК (bdu.fstec.ru) и инвентаризации.\n" +
                                              "   - п. 11: 3 этапа оценки (перечень ПО, места установки, расчет показателя V).\n" +
                                              "   - п. 13: Расчет I_cvss по стандарту CVSS 3.1.\n" +
                                              "   - п. 14–15: Расчет инфраструктурного показателя I_infr.\n" +
                                              "   - п. 16: Эксплуатация уязвимости I_at = e·E.\n" +
                                              "   - п. 17: Последствия эксплуатации I_imp = h·H.\n" +
                                              "   - п. 18 и Таблица 2: Шкала критичности (Критический, Высокий, Средний, Низкий).\n" +
                                              "• Раздел III (п. 20–25): Регламентные сроки и компенсирующие меры:\n" +
                                              "   - п. 21: Сроки устранения (до 24 ч, до 7 дней, до 4 недель, до 4 месяцев);\n" +
                                              "   - п. 22–25: Обновление ПО, межсетевое экранирование, Endpoint DLP, отключение служб, резервирование."
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textPrimary
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }

                        // SECTION 5: TABLE 1
                        ColumnLayout {
                            visible: root.activeSection === 5
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: t1Col.implicitHeight + 20
                                color: Style.panelSurface
                                border.color: Style.hairlineBorder
                                border.width: 1

                                ColumnLayout {
                                    id: t1Col
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Text {
                                        text: "Таблица 1 (ФСТЭК 2025 г.) — Весовые коэффициенты показателей K, L, P, E, H"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.Bold
                                        color: Style.textPrimary
                                    }

                                    // Sub-table K
                                    Text { text: "1. Показатель типа компонента (K, вес k=0.5):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; font.weight: Font.Bold; color: Style.textPrimary }
                                    Text {
                                        text: "• Общесистемное ПО критических бизнес-процессов: k·K = 0.55\n" +
                                              "• Общесистемное ПО (ОС, СУБД): k·K = 0.45\n" +
                                              "• Прикладное ПО критических бизнес-процессов: k·K = 0.40\n" +
                                              "• Прикладное ПО общего назначения: k·K = 0.35\n" +
                                              "• ПО рабочих станций разработчиков и администраторов: k·K = 0.25\n" +
                                              "• Сетевое оборудование и серверы общего доступа: k·K = 0.20\n" +
                                              "• Вспомогательные изолированные узлы: k·K = 0.05"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textSecondary
                                    }

                                    // Sub-table L
                                    Text { text: "2. Доля уязвимых компонентов (L, вес l=0.2):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; font.weight: Font.Bold; color: Style.textPrimary }
                                    Text {
                                        text: "• Более 70% компонентов сегмента: l·L = 0.20\n" +
                                              "• От 50% до 70% компонентов: l·L = 0.16\n" +
                                              "• От 10% до 50% компонентов: l·L = 0.12\n" +
                                              "• Менее 10% компонентов сегмента: l·L = 0.10"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textSecondary
                                    }

                                    // Sub-table P
                                    Text { text: "3. Доступность из сети Интернет (P, вес p=0.3):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; font.weight: Font.Bold; color: Style.textPrimary }
                                    Text {
                                        text: "• Компонент доступен из сети Интернет: p·P = 0.33 (0.3 × 1.1)\n" +
                                              "• Компонент недоступен из сети Интернет (внутренний сегмент): p·P = 0.18 (0.3 × 0.6)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textSecondary
                                    }

                                    // Sub-table E
                                    Text { text: "4. Степень эксплуатации уязвимости (E, вес e=0.6):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; font.weight: Font.Bold; color: Style.textPrimary }
                                    Text {
                                        text: "• Зафиксированы реальные инциденты / атаки: e·E = 0.60\n" +
                                              "• Существует публичный эксплойт: e·E = 0.30\n" +
                                              "• Нет сведений о публичных эксплойтах: e·E = 0.10"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textSecondary
                                    }

                                    // Sub-table H
                                    Text { text: "5. Тяжесть последствий эксплуатации (H, вес h=0.5):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; font.weight: Font.Bold; color: Style.textPrimary }
                                    Text {
                                        text: "• H_01: Полное нарушение К, Ц, Д критических процессов: h·H = 0.50\n" +
                                              "• H_02: Существенный сбой сервисов обработки платежей: h·H = 0.40\n" +
                                              "• H_03: Локальное нарушение доступности второстепенных узлов: h·H = 0.34\n" +
                                              "• H_04: Утечка сведений коммерческой тайны и ноу-хау: h·H = 0.30\n" +
                                              "• H_05: Несанкционированная модификация конфигураций: h·H = 0.26\n" +
                                              "• H_06: Временная деградация производительности: h·H = 0.22\n" +
                                              "• H_07: Единичные отказы клиентских коннектов: h·H = 0.20\n" +
                                              "• H_08: Незначительное влияние без остановки функционала: h·H = 0.18\n" +
                                              "• H_09: Нарушение вспомогательных сервисов логирования: h·H = 0.12\n" +
                                              "• H_10: Минимальное локальное воздействие: h·H = 0.10"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textSecondary
                                    }
                                }
                            }
                        }

                        // SECTION 6: TABLE 2
                        ColumnLayout {
                            visible: root.activeSection === 6
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: t2Col.implicitHeight + 20
                                color: Style.panelSurface
                                border.color: Style.hairlineBorder
                                border.width: 1

                                ColumnLayout {
                                    id: t2Col
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Text {
                                        text: "Таблица 2 (ФСТЭК 2025 г.) — Шкала критичности V и регламентные сроки устранения (п. 21)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.Bold
                                        color: Style.textPrimary
                                    }

                                    Repeater {
                                        model: [
                                            { lvl: "Критический", range: "V > 8.0", sla: "До 24 часов", desc: "Немедленное устранение, изоляция сегмента или отключение службы." },
                                            { lvl: "Высокий", range: "5.0 ≤ V ≤ 8.0", sla: "До 7 дней", desc: "Приоритетное внедрение компенсирующих мер и патчей." },
                                            { lvl: "Средний", range: "2.0 ≤ V < 5.0", sla: "До 4 недель", desc: "Плановое обновление ПО в рамках регламентного окна." },
                                            { lvl: "Низкий", range: "V < 2.0", sla: "До 4 месяцев", desc: "Приемлемый уровень остаточного риска, плановый мониторинг." }
                                        ]

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 48
                                            color: Style.surfaceLow
                                            border.color: Style.hairlineBorder
                                            border.width: 1

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                spacing: 10

                                                RiskBadge {
                                                    Layout.preferredWidth: 90
                                                    level: modelData.lvl
                                                }

                                                Text {
                                                    text: modelData.range
                                                    font.family: Style.fontMono
                                                    font.pixelSize: Style.fontSizeCodeSm
                                                    font.weight: Font.Bold
                                                    color: Style.textPrimary
                                                    Layout.preferredWidth: 80
                                                }

                                                Text {
                                                    text: "Срок: " + modelData.sla
                                                    font.family: Style.fontMono
                                                    font.pixelSize: Style.fontSizeCodeSm
                                                    font.weight: Font.Bold
                                                    color: Style.primary
                                                    Layout.preferredWidth: 110
                                                }

                                                Text {
                                                    text: modelData.desc
                                                    font.family: Style.fontSans
                                                    font.pixelSize: Style.fontSizeBodySm
                                                    color: Style.textSecondary
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // DEFAULT / OTHER SECTIONS FALLBACK
                        ColumnLayout {
                            visible: root.activeSection !== 0 && root.activeSection !== 1 && root.activeSection !== 5 && root.activeSection !== 6
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 180
                                color: Style.surfaceLow
                                border.color: Style.hairlineBorder
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 8

                                    Text {
                                        text: "Нормативный раздел базы знаний"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeHeadlineSm
                                        font.weight: Font.Bold
                                        color: Style.textPrimary
                                    }

                                    Text {
                                        text: "Раздел содержит официальные выдержки нормативно-методической документации:\n" +
                                              "• ГОСТ Р ИСО/МЭК 27005-2010 «Менеджмент риска информационной безопасности»;\n" +
                                              "• Методика оценки угроз ФСТЭК России от 05.02.2021 г. (Таблица 9.1, нарушители Н1-Н4, ущерб У2);\n" +
                                              "• Федеральный закон от 29.07.2004 № 98-ФЗ «О коммерческой тайне» (ст. 10);\n" +
                                              "• Методология ENISA ROSI Framework."
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textPrimary
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }

                        Item { height: 10 }
                    }
                }
            }
        }
    }
}
