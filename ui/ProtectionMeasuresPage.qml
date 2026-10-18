import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: root

    ScrollView {
        anchors.fill: parent
        clip: true
        padding: 24
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 20

            SectionHeading {
                eyebrow: qsTr("ПОРТФЕЛЬ МЕР ЗАЩИТЫ")
                heading: qsTr("Каталог защитных мероприятий")
                description: qsTr("Технические и организационные меры, их стоимость (CAPEX/OPEX) и ожидаемая эффективность.")
            }

            WorkflowGuideBanner {
                stepNumber: "04"
                stepTitle: qsTr("Этап 4: Выбор мер защиты и привязка к рискам")
                purpose: qsTr("Планирование обработки рисков (п. 9 ГОСТ Р ИСО/МЭК 27005-2010): выбор мер нейтрализации, расчет затрат (TCO = CAPEX + OPEX) и привязка к рискам.")
                whatToDo: qsTr("Сформируйте каталог компенсирующих мер (MFA, SIEM, WAF, Резервирование). Откройте диалог привязки меры к рискам и укажите степень снижения вероятности (ΔP) и ущерба (ΔI).")
            }

            // --- ВЕРХНИЕ KPI-КАРТОЧКИ ---
            GridLayout {
                columns: width >= 900 ? 3 : 1
                columnSpacing: 14
                rowSpacing: 14
                Layout.fillWidth: true

                KpiStatCard {
                    label: qsTr("МЕР В ПОРТФЕЛЕ")
                    value: DataStore.measuresList.length.toString()
                    delta: "Реестр"
                    deltaIsGood: true
                    note: qsTr("Зарегистрировано защитных мероприятий")
                    glyph: "◉"
                    accentColor: Theme.accent
                }

                KpiStatCard {
                    label: qsTr("ОБЩИЕ ИНВЕСТИЦИИ В ИБ")
                    value: (DataStore.totalMeasuresCost >= 1000000 ? (DataStore.totalMeasuresCost / 1000000).toFixed(1) + "M ₽" : (DataStore.totalMeasuresCost / 1000).toFixed(0) + "K ₽")
                    delta: "CAPEX+OPEX"
                    deltaIsGood: true
                    note: qsTr("Суммарные затраты на внедрение и лицензии")
                    glyph: "₽"
                    accentColor: Theme.teal
                    valueColor: Theme.isDark ? Theme.tealLight : Theme.teal
                }

                KpiStatCard {
                    label: qsTr("СРЕДНЕЕ СНИЖЕНИЕ РИСКА")
                    value: DataStore.measuresList.length > 0 ? ("-" + Math.round((function(){
                        var s = 0;
                        for (var i = 0; i < DataStore.measuresList.length; i++) {
                            s += ((DataStore.measuresList[i].dmgRed || 0) + (DataStore.measuresList[i].probRed || 0)) / 2.0;
                        }
                        return s / DataStore.measuresList.length;
                    })()) + "%") : "0%"
                    delta: "Эффект"
                    deltaIsGood: true
                    note: qsTr("Прогнозное падение ущерба и вероятности")
                    glyph: "↓"
                    accentColor: Theme.green
                    valueColor: Theme.green
                }
            }

            // --- СКРЫТЫЙ ПОЯСНЯЮЩИЙ БЛОК: НОРМАТИВНАЯ БАЗА МЕР ЗАЩИТЫ ---
            NormativeExplanationCard {
                title: qsTr("Нормативная база планирования и выбора защитных мер")
                standard: "ГОСТ Р 57580.3-2022 / ГОСТ Р 59339-2021"
                clause: qsTr("Таблицы 13–16 ГОСТ Р 57580.3-2022; Таблица Г.1 ГОСТ Р 59339-2021")
                quote: qsTr("«Разработка мероприятий направлена на снижение степени возможности реализации (СВР) инцидентов и ограничение степени тяжести последствий (СТП). Превентивные меры воздействуют на уязвимости, а компенсирующие меры — на предотвращение катастрофических потерь» (ГОСТ Р 57580.3-2022, п. 8.3.1).")
                practicalNote: qsTr("Каталог защитных мер гармонизируется с требованиями Приказа ФСТЭК России № 21 (ИАФ, УПД, РСБ, АНЗ) и комплекса стандартов ГОСТ Р 57580.1 / ГОСТ Р 57580.4.")
            }

            // --- ТУЛБАР ПОИСКА И ФИЛЬТРАЦИИ ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                radius: Theme.radiusMd
                color: Theme.panel
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: "⌕"
                        color: Theme.muted
                        font.pixelSize: 16
                    }

                    TextInput {
                        id: searchMeasure
                        Layout.fillWidth: true
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        selectByMouse: true
                        clip: true

                        Text {
                            visible: !searchMeasure.text && !searchMeasure.activeFocus
                            text: qsTr("Поиск меры по названию, классу или статусу...")
                            color: Theme.subtle
                            font.pixelSize: Theme.fontBody
                        }
                    }

                    RowLayout {
                        spacing: 6
                        StatusBadge { text: qsTr("Все (") + DataStore.measuresList.length + ")"; level: "info" }
                    }

                    Rectangle {
                        implicitWidth: addMeasureBtn.implicitWidth + 24
                        implicitHeight: 34
                        radius: Theme.radiusSm
                        color: addMeasureMouse.containsMouse ? Theme.accentGlow : Theme.accent

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: addMeasureBtn
                            anchors.centerIn: parent
                            text: qsTr("+ Новая мера")
                            color: "#ffffff"
                            font.pixelSize: Theme.fontCaption
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            id: addMeasureMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: measureDialog.openForAdd()
                        }
                    }
                }
            }

            // --- ТАБЛИЦА РЕЕСТРА МЕР ЗАЩИТЫ ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: measureTableLayout.implicitHeight + 20
                radius: Theme.radiusMd
                color: Theme.panel
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: measureTableLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    // Шапка таблицы
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Theme.radiusSm
                        color: Theme.raised
                        border.color: Theme.border
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Text { text: qsTr("ID"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 65 }
                            Text { text: qsTr("НАИМЕНОВАНИЕ МЕРЫ ЗАЩИТЫ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.fillWidth: true }
                            Text { text: qsTr("КЛАСС"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 110 }
                            Text { text: qsTr("СТОИМОСТЬ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 110 }
                            Text { text: qsTr("СНИЖ. УЩЕРБА"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 95 }
                            Text { text: qsTr("СНИЖ. ВЕРОЯТН."); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 95 }
                            Text { text: qsTr("СВЯЗАННЫЙ РИСК"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 125 }
                            Text { text: qsTr("СТАТУС"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 95 }
                            Text { text: qsTr("ДЕЙСТВИЯ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 105; horizontalAlignment: Text.AlignHCenter }
                        }
                    }

                    // Строки таблицы
                    Repeater {
                        model: DataStore.measuresList

                        delegate: Rectangle {
                            id: measureRow
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: 48
                            radius: Theme.radiusSm
                            color: measureRowMouse.containsMouse ? Theme.panelHover : (index % 2 === 0 ? "transparent" : (Theme.isDark ? "#171a21" : "#f8f9fb"))

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                Text {
                                    text: measureRow.modelData.id
                                    color: Theme.accent
                                    font.pixelSize: Theme.fontCaption
                                    font.weight: Font.Bold
                                    Layout.preferredWidth: 65
                                }

                                Text {
                                    text: measureRow.modelData.name
                                    color: Theme.text
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: measureRow.modelData.type
                                    color: Theme.muted
                                    font.pixelSize: Theme.fontCaption
                                    Layout.preferredWidth: 110
                                }

                                Text {
                                    text: (measureRow.modelData.cost ? measureRow.modelData.cost.toLocaleString(Qt.locale(), 'f', 0) : "0") + " ₽"
                                    color: Theme.isDark ? Theme.tealLight : Theme.teal
                                    font.pixelSize: Theme.fontCaption
                                    font.weight: Font.DemiBold
                                    Layout.preferredWidth: 110
                                }

                                StatusBadge {
                                    text: "-" + (measureRow.modelData.dmgRed || 0) + "%"
                                    level: "success"
                                    showDot: false
                                    Layout.preferredWidth: 95
                                }

                                StatusBadge {
                                    text: "-" + (measureRow.modelData.probRed || 0) + "%"
                                    level: "success"
                                    showDot: false
                                    Layout.preferredWidth: 95
                                }

                                StatusBadge {
                                    text: measureRow.modelData.boundRiskId ? measureRow.modelData.boundRiskId : qsTr("Не привязана")
                                    level: measureRow.modelData.boundRiskId ? "teal" : "low"
                                    Layout.preferredWidth: 125
                                }

                                StatusBadge {
                                    text: measureRow.modelData.status || "В плане"
                                    level: measureRow.modelData.statusLevel || "info"
                                    Layout.preferredWidth: 95
                                }

                                // Кнопки действий
                                RowLayout {
                                    Layout.preferredWidth: 105
                                    spacing: 6

                                    // Кнопка привязки/отвязки
                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: Theme.radiusXs
                                        color: linkActionMouse.containsMouse ? (measureRow.modelData.boundRiskId ? Theme.panelHover : Theme.badgeTealBg) : "transparent"
                                        border.color: linkActionMouse.containsMouse ? Theme.accent : "transparent"
                                        border.width: 1

                                        AppIcon {
                                            anchors.centerIn: parent
                                            name: measureRow.modelData.boundRiskId ? "unlink" : "link"
                                            size: 15
                                            color: measureRow.modelData.boundRiskId ? (linkActionMouse.containsMouse ? Theme.riskHigh : Theme.muted) : Theme.teal
                                        }

                                        MouseArea {
                                            id: linkActionMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (measureRow.modelData.boundRiskId) {
                                                    DataStore.unbindMeasure(measureRow.index);
                                                } else {
                                                    linkRiskDialog.openForLink(measureRow.index, measureRow.modelData);
                                                }
                                            }
                                        }

                                        ToolTip.visible: linkActionMouse.containsMouse
                                        ToolTip.text: measureRow.modelData.boundRiskId ? qsTr("Отвязать меру от риска") : qsTr("Привязать меру к риску")
                                    }

                                    // Редактирование
                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: Theme.radiusXs
                                        color: editMeasureMouse.containsMouse ? Theme.panelHover : "transparent"
                                        border.color: editMeasureMouse.containsMouse ? Theme.borderHighlight : "transparent"
                                        border.width: 1

                                        AppIcon {
                                            anchors.centerIn: parent
                                            name: "edit"
                                            size: 15
                                            color: editMeasureMouse.containsMouse ? Theme.accent : Theme.muted
                                        }

                                        MouseArea {
                                            id: editMeasureMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: measureDialog.openForEdit(measureRow.index, measureRow.modelData)
                                        }

                                        ToolTip.visible: editMeasureMouse.containsMouse
                                        ToolTip.text: qsTr("Редактировать меру")
                                    }

                                    // Удаление
                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: Theme.radiusXs
                                        color: delMeasureMouse.containsMouse ? Theme.badgeCriticalBg : "transparent"
                                        border.color: delMeasureMouse.containsMouse ? Theme.badgeCriticalBorder : "transparent"
                                        border.width: 1

                                        AppIcon {
                                            anchors.centerIn: parent
                                            name: "trash"
                                            size: 15
                                            color: delMeasureMouse.containsMouse ? Theme.riskCritical : Theme.muted
                                        }

                                        MouseArea {
                                            id: delMeasureMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: DataStore.deleteMeasure(measureRow.index)
                                        }

                                        ToolTip.visible: delMeasureMouse.containsMouse
                                        ToolTip.text: qsTr("Удалить меру")
                                    }
                                }
                            }

                            MouseArea {
                                id: measureRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                propagateComposedEvents: true
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 12 }
        }
    }

    MeasureDialog {
        id: measureDialog
        anchors.fill: parent
    }

    LinkRiskDialog {
        id: linkRiskDialog
        anchors.fill: parent
    }
}
