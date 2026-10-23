import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

ScrollView {
    clip: true
    padding: 24
    contentWidth: availableWidth
    contentHeight: pageContent.implicitHeight

    ColumnLayout {
        id: pageContent
        width: parent.width
        spacing: 20

        SectionHeading {
            eyebrow: qsTr("МОДЕЛЬ ОЦЕНКИ И БАЛЛЬНЫЕ ШКАЛЫ")
            heading: qsTr("Математическая модель рисков ИБ")
            description: qsTr("Критерии, шкалы и базовые параметры расчета уровней риска.")
        }

        WorkflowGuideBanner {
            stepNumber: "01"
            stepTitle: qsTr("Этап 1: Настройка модели и порога риск-аппетита")
            purpose: qsTr("Определение правил математического моделирования: порога допустимого риска (аппетита к риску) и стоимости балла потерь.")
            whatToDo: qsTr("Убедитесь, что порог риск-аппетита (по умолчанию 16 баллов) и стоимость балла риска (250 000 ₽) соответствуют политике безопасности вашей организации. Порог применяется к остаточному риску и не меняет границы уровней.")
        }

        // --- БАННЕР ФОРМУЛЫ ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 136
            radius: Theme.radiusMd
            color: Theme.isDark ? "#172133" : "#eff6ff"
            border.color: Theme.isDark ? "#283e60" : "#bfdbfe"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 8

                RowLayout {
                    spacing: 8
                    StatusBadge {
                        text: qsTr("Диапазон: 1–64 баллов")
                        level: "success"
                    }
                }

                Text {
                    text: qsTr("Риск = Ущерб (I) × Вероятность (P) × Приоритет актива (A)")
                    color: Theme.text
                    font.pixelSize: Theme.fontH1
                    font.weight: Font.Bold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Каждый фактор оценивается по 4-балльной шкале экспертным или аналитическим методом.")
                    color: Theme.muted
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        // --- СКРЫТЫЙ ПОЯСНЯЮЩИЙ БЛОК: ФОРМУЛА РИСКА ---
        NormativeExplanationCard {
            title: qsTr("Нормативное обоснование формулы и оценки рисков")
            standard: "ГОСТ Р ИСО/МЭК 27005-2010"
            clause: qsTr("п. 8.2, Приложение E; ГОСТ Р 59339-2021 п. 6.3.1")
            quote: qsTr("«Уровень риска оценивается как сочетание вероятности возникновения события инцидента информационной безопасности и его последствий. При оценке последствий учитывается ценность активов, ущерб бизнесу и затраты на восстановление» (ГОСТ Р ИСО/МЭК 27005, п. 8.2).")
            practicalNote: qsTr("В калькуляторе ценность актива (приоритет A) калибрует тяжесть ущерба. Применение шкал 1–4 соответствует матричному методу оценки рисков (Risk Matrix) по ГОСТ Р 58771-2019 / ГОСТ Р ИСО/МЭК 31010.")
        }

        // --- ПАРАМЕТРЫ ШКАЛ (3 КОЛОНКИ) ---
        Text {
            text: qsTr("Базовые факторы оценки")
            color: Theme.text
            font.pixelSize: Theme.fontH2
            font.weight: Font.Bold
        }

        GridLayout {
            columns: width >= 900 ? 3 : 1
            columnSpacing: 14
            rowSpacing: 14
            Layout.fillWidth: true

            KpiStatCard {
                label: qsTr("ПОТЕНЦИАЛЬНЫЙ УЩЕРБ (I)")
                value: "1 – 4"
                delta: "Шкала"
                deltaIsGood: true
                note: qsTr("1: Незначит., 2: Умерен., 3: Существ., 4: Катастроф.")
                accentColor: Theme.accent
            }

            KpiStatCard {
                label: qsTr("ВЕРОЯТНОСТЬ УГРОЗЫ (P)")
                value: "1 – 4"
                delta: "Шкала"
                deltaIsGood: true
                note: qsTr("1: Редкая, 2: Возможная, 3: Вероятная, 4: Постоянная")
                accentColor: Theme.amber
                valueColor: Theme.amber
            }

            KpiStatCard {
                label: qsTr("ПРИОРИТЕТ АКТИВА (A)")
                value: "1 – 4"
                delta: "Шкала"
                deltaIsGood: true
                note: qsTr("1: Низкий, 2: Средний, 3: Высокий, 4: Критич. (КИИ)")
                accentColor: Theme.green
                valueColor: Theme.green
            }
        }

        // --- СКРЫТЫЙ ПОЯСНЯЮЩИЙ БЛОК: ФАКТОРЫ ОЦЕНКИ И БДУ ФСТЭК ---
        NormativeExplanationCard {
            title: qsTr("Обоснование шкал ущерба, вероятности и модели нарушителя")
            standard: "Методика ФСТЭК от 05.02.2021"
            clause: qsTr("Разд. 3–4; Приложение Б ГОСТ Р 59339-2021")
            quote: qsTr("«Оценка возможности реализации угроз безопасности информации осуществляется на основе сопоставления потенциала нарушителя и уровня защищенности объекта (уязвимостей интерфейсов). Сценарии угроз формируются с использованием Банка данных угроз (БДУ ФСТЭК)» (Методика ФСТЭК от 05.02.2021).")
            practicalNote: qsTr("Калькулятор использует 4-балльные шкалы для гармонизации экспертных оценок с классификатором Банка России (ГОСТ Р 57580.3-2022) и методиками ФСТЭК.")
        }

        // --- МОДЕЛЬ УПРАВЛЕНИЯ: НАСТРОЙКА КРИТЕРИЕВ ---
        Text {
            text: qsTr("Параметры риск-аппетита и стоимости балла")
            color: Theme.text
            font.pixelSize: Theme.fontH2
            font.weight: Font.Bold
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: criteriaCol.implicitHeight + 36
            radius: Theme.radiusMd
            color: Theme.panel
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                id: criteriaCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 24

                    // Риск-аппетит
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: qsTr("Порог риск-аппетита:")
                                color: Theme.text
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                            StatusBadge {
                                text: Math.round(appetiteSlider.value) + qsTr(" баллов")
                                level: appetiteSlider.value <= 16 ? "success" : "high"
                            }
                        }

                        Text {
                            text: qsTr("С порогом сравнивается остаточный балл: без меры он равен исходному, с мерой учитывает снижение ущерба и вероятности. Балл не выше порога — в пределах аппетита; выше порога — требуется обработка или документированное принятие риска.")
                            color: Theme.muted
                            font.pixelSize: Theme.fontCaption
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        Slider {
                            id: appetiteSlider
                            Layout.fillWidth: true
                            from: 1
                            to: 64
                            stepSize: 1
                            value: EconomicsService.riskAppetite
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: Theme.border
                    }

                    // Стоимость одного балла
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: qsTr("Стоимость одного балла риска:")
                            color: Theme.text
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: qsTr("Финансовый эквивалент для перевода баллов ущерба в рублевые потери организации.")
                            color: Theme.muted
                            font.pixelSize: Theme.fontCaption
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: Theme.radiusSm
                            color: Theme.isDark ? Theme.panelHover : "#ffffff"
                            border.color: pCostInput.activeFocus ? Theme.accent : Theme.border
                            border.width: 1

                            TextInput {
                                id: pCostInput
                                anchors.fill: parent
                                anchors.margins: 10
                                text: EconomicsService.pointCost.toString()
                                color: Theme.text
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                                validator: DoubleValidator { bottom: 1000 }
                                clip: true
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item { Layout.fillWidth: true }

                    Text {
                        id: saveStatusText
                        text: ""
                        color: Theme.green
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        implicitWidth: saveCriteriaBtn.implicitWidth + 24
                        implicitHeight: 36
                        radius: Theme.radiusSm
                        color: saveCriteriaMouse.containsMouse ? Theme.accentGlow : Theme.accent

                        Text {
                            id: saveCriteriaBtn
                            anchors.centerIn: parent
                            text: qsTr("Применить параметры модели")
                            color: "#ffffff"
                            font.pixelSize: Theme.fontCaption
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            id: saveCriteriaMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var cost = parseFloat(pCostInput.text) || 250000;
                                EconomicsService.saveCriteria(Math.round(appetiteSlider.value), cost);
                                saveStatusText.text = qsTr("✓ Параметры сохранены и пересчитаны");
                                saveTimer.restart();
                            }
                        }
                    }

                    Timer {
                        id: saveTimer
                        interval: 3000
                        onTriggered: saveStatusText.text = ""
                    }
                }
            }
        }

        // --- СКРЫТЫЙ ПОЯСНЯЮЩИЙ БЛОК: РИСК-АППЕТИТ И ФИНАНСОВЫЕ ПОТЕРИ ---
        NormativeExplanationCard {
            title: qsTr("Обоснование порога риск-аппетита и оценки финансовых потерь")
            standard: "ГОСТ Р 59339-2021"
            clause: qsTr("Приложение Д; Приложение Г ГОСТ Р 57580.3-2022")
            quote: qsTr("«Определение допустимых рисков осуществляется на основе прецедентного принципа либо ориентации на систему-эталон. Потери классифицируются на прямые балансовые убытки и непрямые потери» (ГОСТ Р 59339-2021 п. 6.3, ГОСТ Р 57580.3-2022 Приложение Г).")
            practicalNote: qsTr("Риск-аппетит — отдельный критерий приемлемости: остаточный балл не выше порога находится в пределах аппетита, а превышение требует обработки либо документированного принятия. Порог не меняет уровень тяжести риска и сам по себе не означает автоматическое внедрение меры.")
        }

        // --- КАРТА ГРАДАЦИИ УРОВНЕЙ РИСКА ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 104
            radius: Theme.radiusMd
            color: Theme.panel
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    text: qsTr("ГРАДАЦИЯ ИТОГОВЫХ УРОВНЕЙ РИСКА")
                    color: Theme.muted
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    StatusBadge { text: qsTr("1–8: Низкий"); level: "low"; Layout.fillWidth: true }
                    StatusBadge { text: qsTr("9–16: Средний"); level: "medium"; Layout.fillWidth: true }
                    StatusBadge { text: qsTr("17–32: Высокий"); level: "high"; Layout.fillWidth: true }
                    StatusBadge { text: qsTr("33–64: Критический"); level: "critical"; Layout.fillWidth: true }
                }
            }
        }

        Item { Layout.preferredHeight: 12 }
    }
}
