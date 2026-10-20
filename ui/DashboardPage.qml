import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

ScrollView {
    function getLevelByScore(score) {
        if (score > 32) return "critical";
        if (score > 16) return "high";
        if (score > 8) return "medium";
        return "low";
    }

    function getLevelName(level) {
        if (level === "critical") return qsTr("Критический");
        if (level === "high") return qsTr("Высокий");
        if (level === "medium") return qsTr("Средний");
        return qsTr("Низкий");
    }

    Component.onCompleted: DashboardService.refresh()

    clip: true
    padding: 24
    contentWidth: availableWidth

    ColumnLayout {
        width: parent.width
        spacing: 24
        Item { Layout.preferredHeight: 2 }
        Text {
            visible: DashboardService.loading || DashboardService.error !== ""
            text: DashboardService.loading ? qsTr("Загрузка сводки…") : DashboardService.error
            color: DashboardService.error !== "" ? Theme.riskCritical : Theme.muted
            font.pixelSize: Theme.fontCaption
            Layout.fillWidth: true
        }

        // --- ВЕРХНИЙ ПРЕДСТАВИТЕЛЬСКИЙ БАННЕР (ЧИСТЫЙ ENTERPRISE B2B, БЕЗ КИБЕРПАНКА) ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 210

            Rectangle {
                id: heroSurface
                anchors.fill: parent
                radius: Theme.radiusLg
                color: Theme.panel
                border.color: Theme.border
                border.width: 1

                Behavior on color { ColorAnimation { duration: 180 } }
                Behavior on border.color { ColorAnimation { duration: 180 } }

                // Тонкая акцентная полоса сверху
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 3
                    radius: Theme.radiusXs
                    color: Theme.accent
                }
            }

            MultiEffect {
                source: heroSurface
                anchors.fill: heroSurface
                shadowEnabled: true
                shadowColor: Theme.isDark ? "#40000000" : "#12000000"
                shadowBlur: 0.4
                shadowOpacity: Theme.isDark ? 0.35 : 0.1
                shadowVerticalOffset: 2
                z: -1
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 26
                spacing: 24

                ColumnLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8
                        StatusBadge {
                            text: qsTr("СУИБ · ГОСТ Р ИСО/МЭК 27005-2010")
                            level: "teal"
                        }
                        StatusBadge {
                            text: qsTr("ГОСТ Р 59339-2021")
                            level: "info"
                        }
                        StatusBadge {
                            text: qsTr("Версия 0.1 · Корпоративный релиз")
                            level: "success"
                        }
                    }

                    Text {
                        text: qsTr("Управляйте рисками. Доказывайте ценность ИБ.")
                        color: Theme.text
                        font.pixelSize: Theme.fontHero
                        font.weight: Font.Bold
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: qsTr("Единая модель связывает активы, угрозы, защитные меры и финансовый результат — от оценки ущерба до возврата инвестиций (ROSI).")
                        color: Theme.muted
                        font.pixelSize: Theme.fontBody
                        wrapMode: Text.Wrap
                        Layout.maximumWidth: 680
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 12
                        Layout.topMargin: 4
                        Repeater {
                            model: [
                                qsTr("01. Активы  →"),
                                qsTr("02. Риски  →"),
                                qsTr("03. Меры  →"),
                                qsTr("04. Экономика (ROSI)")
                            ]
                            delegate: Text {
                                required property string modelData
                                text: modelData
                                color: Theme.accent
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                // Правый информационный блок бренда
                Rectangle {
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 156
                    radius: Theme.radiusMd
                    color: Theme.isDark ? Theme.sidebarRaised : "#f8f9fb"
                    border.color: Theme.border
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "ИБ"
                            color: Theme.accent
                            font.pixelSize: 34
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: qsTr("ЭФФЕКТ")
                            color: Theme.text
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 4
                            width: 48
                            height: 2
                            color: Theme.accent
                        }

                        Text {
                            text: qsTr("Риск → Мера → ROSI")
                            color: Theme.muted
                            font.pixelSize: Theme.fontMicro
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        WorkflowGuideBanner {
            stepNumber: "00"
            stepTitle: qsTr("Сводная панель управления (Dashboard)")
            purpose: qsTr("Интегральный мониторинг состояния системы управления рисками информационной безопасности (СУИБ).")
            whatToDo: qsTr("Отслеживайте динамику остаточного риска по отношению к порогу риск-аппетита организации, финансовую отдачу от портфеля мер (Net ROSI) и контролируйте критические риски, требующие немедленной реакции.")
        }

        // --- СКРЫТЫЙ ПОЯСНЯЮЩИЙ БЛОК: СВОДНАЯ НОРМАТИВНАЯ БАЗА ---
        NormativeExplanationCard {
            title: qsTr("Нормативная база функционирования программного комплекса «ИБ-Эффект»")
            standard: "ГОСТ Р ИСО/МЭК 27005-2010 / ГОСТ Р 59339-2021 / ГОСТ Р 57580.3-2022"
            clause: qsTr("Комплекс национальных стандартов РФ в области защиты информации и оценки рисков")
            quote: qsTr("«Система управления рисками информационной безопасности обеспечивает своевременную идентификацию угроз, расчет вероятного ущерба, обоснование превентивных мер защиты и оценку их экономической эффективности» (ГОСТ Р ИСО/МЭК 27005-2010, ГОСТ Р 59339-2021, ГОСТ Р 57580.3-2022).")
            practicalNote: qsTr("Программа реализует сквозной процесс СУИБ: Каталог критичных активов → Модель угроз (БДУ ФСТЭК) → Оценка рисков → Формирование защитных мер → Расчет возврата инвестиций (Net ROSI).")
        }

        // --- БЛОК 1: СВОДНЫЕ KPI-МЕТРИКИ (КРУПНЫЙ ТЕКСТ, ЧИТАЕМЫЙ С РАССТОЯНИЯ) ---
        SectionHeading {
            eyebrow: qsTr("СВОДКА СОСТОЯНИЯ")
            heading: qsTr("Ключевые показатели эффективности")
            description: qsTr("Оперативные метрики защищенности активов и прогнозируемой финансовой отдачи.")
        }

        GridLayout {
            columns: width >= 1100 ? 4 : (width >= 650 ? 2 : 1)
            columnSpacing: 16
            rowSpacing: 16
            Layout.fillWidth: true

            KpiStatCard {
                label: qsTr("АКТИВЫ НА ЗАЩИТЕ")
                value: (DashboardService.summary.assetCount || 0).toString()
                delta: "Реестр"
                deltaIsGood: true
                note: qsTr("Критические системы и СУБД")
                accentColor: Theme.accent
            }

            KpiStatCard {
                label: qsTr("ВЫЯВЛЕННЫЕ РИСКИ")
                value: (DashboardService.summary.riskCount || 0).toString()
                delta: (DashboardService.summary.criticalRisksCount || 0) + " крит."
                deltaIsGood: false
                note: (DashboardService.summary.criticalRisksCount || 0) + qsTr(" критических требуют нейтрализации")
                accentColor: Theme.riskCritical
                valueColor: Theme.riskCritical
            }

            KpiStatCard {
                label: qsTr("ПОРТФЕЛЬ МЕР ЗАЩИТЫ")
                value: (DashboardService.summary.measureCount || 0).toString()
                delta: ((DashboardService.summary.totalMeasuresCost || 0) >= 1000000 ? ((DashboardService.summary.totalMeasuresCost || 0) / 1000000).toFixed(1) + "M ₽" : ((DashboardService.summary.totalMeasuresCost || 0) / 1000).toFixed(0) + "K ₽")
                deltaIsGood: true
                note: qsTr("Инвестиции в безопасность")
                accentColor: Theme.green
                valueColor: Theme.green
            }

            KpiStatCard {
                label: qsTr("ПРОГНОЗНЫЙ ROSI")
                value: ((DashboardService.summary.rosi || 0) >= 0 ? "+" : "") + (DashboardService.summary.rosi || 0) + "%"
                delta: (DashboardService.summary.rosi || 0) >= 0 ? "Окупаем" : "Неокупаем"
                deltaIsGood: (DashboardService.summary.rosi || 0) >= 0
                note: qsTr("Чистый эффект: ") + ((DashboardService.summary.netBenefit || 0) >= 1000000 ? ((DashboardService.summary.netBenefit || 0) / 1000000).toFixed(1) + "M ₽" : ((DashboardService.summary.netBenefit || 0) / 1000).toFixed(0) + "K ₽")
                accentColor: Theme.teal
                valueColor: Theme.isDark ? Theme.tealLight : Theme.teal
            }
        }

        // --- БЛОК 2: ГЛУБОКАЯ АНАЛИТИКА (РИСК-ШКАЛА И РАСПРЕДЕЛЕНИЕ) ---
        GridLayout {
            columns: width >= 900 ? 2 : 1
            columnSpacing: 16
            rowSpacing: 16
            Layout.fillWidth: true

            RiskGauge {
                title: qsTr("Интегральный уровень риска")
                score: Math.round(DashboardService.summary.averageScore || 0)
                maxScore: 64
                statusText: getLevelName(getLevelByScore(DashboardService.summary.averageScore || 0))
                statusLevel: getLevelByScore(DashboardService.summary.averageScore || 0)
            }

            DistributionBar {
                title: qsTr("Распределение рисков по критичности")
                criticalCount: DashboardService.summary.criticalRisksCount || 0
                highCount: DashboardService.summary.highRisksCount || 0
                mediumCount: DashboardService.summary.mediumRisksCount || 0
                lowCount: DashboardService.summary.lowRisksCount || 0
            }
        }

        // --- БЛОК 3: ЦЕПОЧКА АРХИТЕКТУРЫ МОДЕЛИ ---
        SectionHeading {
            eyebrow: qsTr("АРХИТЕКТУРА МОДЕЛИ")
            heading: qsTr("От вопроса «что защищать?» к решению «во что инвестировать?»")
            description: qsTr("Последовательное движение по контуру оценки эффективности информационной безопасности.")
        }

        GridLayout {
            columns: width >= 880 ? 4 : (width >= 500 ? 2 : 1)
            columnSpacing: 14
            rowSpacing: 14
            Layout.fillWidth: true

            PlaceholderCard {
                glyph: "01"
                heading: qsTr("Определите активы")
                description: qsTr("Что защищаем и какова стоимость простоя и утечки данных?")
            }
            PlaceholderCard {
                glyph: "02"
                heading: qsTr("Оцените риски")
                description: qsTr("Сценарии угроз, матрица ущерба и вероятность реализации.")
            }
            PlaceholderCard {
                glyph: "03"
                heading: qsTr("Выберите меры")
                description: qsTr("Каталог мер, стоимость внедрения и коэффициент снижения риска.")
            }
            PlaceholderCard {
                glyph: "04"
                heading: qsTr("Посчитайте эффект")
                description: qsTr("Финансовая оценка предотвращенных потерь и коэффициент ROSI.")
            }
        }

        // --- БЛОК 4: ИНФОРМАЦИОННЫЙ БАННЕР ПАЙПЛАЙНА ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 74
            radius: Theme.radiusMd
            color: Theme.panel
            border.color: Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16

                StatusBadge {
                    text: qsTr("ЕДИНАЯ МОДЕЛЬ")
                    level: "teal"
                }

                Text {
                    text: qsTr("Риск   →   Мера защиты   →   Снижение потерь   →   Экономический эффект   →   ROSI")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.Medium
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.preferredHeight: 18 }
    }
}
