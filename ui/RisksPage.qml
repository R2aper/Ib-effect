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
                eyebrow: qsTr("РЕЕСТР РИСКОВ И УГРОЗ")
                heading: qsTr("Управление информационными рисками")
                description: qsTr("Сценарии угроз, расчет баллов по ГОСТ Р ИСО/МЭК 27005-2010 и Методике ФСТЭК от 05.02.2021.")
            }

            WorkflowGuideBanner {
                stepNumber: "03"
                stepTitle: qsTr("Этап 3: Идентификация угроз и оценка величины рисков")
                purpose: qsTr("Оценка угроз безопасности информации с сопоставлением банку данных угроз БДУ ФСТЭК России и расчет начального риска Risk = I × P × A.")
                whatToDo: qsTr("Идентифицируйте сценарии угроз, выберите защищаемый актив, определите вероятность реализации P (1..4) и потенциальный ущерб I (1..4). Особое внимание уделите рискам с баллом выше порога (18 баллов).")
            }

            // --- ВЕРХНИЕ KPI-КАРТОЧКИ ---
            GridLayout {
                columns: width >= 1100 ? 4 : (width >= 650 ? 2 : 1)
                columnSpacing: 14
                rowSpacing: 14
                Layout.fillWidth: true

                KpiStatCard {
                    label: qsTr("ВСЕГО РИСКОВ")
                    value: DataStore.risksList.length.toString()
                    delta: "Реестр"
                    deltaIsGood: true
                    note: qsTr("Зарегистрировано в реестре СУИБ")
                    accentColor: Theme.accent
                }

                KpiStatCard {
                    label: qsTr("КРИТИЧЕСКИЕ РИСКИ")
                    value: DataStore.criticalRisksCount.toString()
                    delta: "Балл > 32"
                    deltaIsGood: false
                    note: qsTr("Требуют немедленной нейтрализации")
                    accentColor: Theme.riskCritical
                    valueColor: Theme.riskCritical
                }

                KpiStatCard {
                    label: qsTr("ВЫСОКИЙ УРОВЕНЬ")
                    value: DataStore.highRisksCount.toString()
                    delta: "Балл 17–32"
                    deltaIsGood: false
                    note: qsTr("Включены в план обработки рисков")
                    accentColor: Theme.riskHigh
                    valueColor: Theme.riskHigh
                }

                KpiStatCard {
                    label: qsTr("ПОД КОНТРОЛЕМ")
                    value: {
                        var cnt = 0;
                        for (var i = 0; i < DataStore.risksList.length; i++) {
                            if (DataStore.risksList[i].boundMeasureId) cnt++;
                        }
                        return cnt.toString();
                    }
                    delta: DataStore.risksList.length > 0 ? (Math.round((function(){
                        var cnt = 0;
                        for (var i = 0; i < DataStore.risksList.length; i++) {
                            if (DataStore.risksList[i].boundMeasureId) cnt++;
                        }
                        return (cnt / DataStore.risksList.length) * 100;
                    })()) + "% реестра") : "0%"
                    deltaIsGood: true
                    note: qsTr("Назначены компенсирующие меры")
                    accentColor: Theme.green
                    valueColor: Theme.green
                }
            }

            // --- СКРЫТЫЙ ПОЯСНЯЮЩИЙ БЛОК: НОРМАТИВНАЯ БАЗА РИСКОВ ---
            NormativeExplanationCard {
                title: qsTr("Нормативная база классификации угроз и оценки рисков")
                standard: "ГОСТ Р ИСО/МЭК 27005-2010 / ФСТЭК 05.02.2021"
                clause: qsTr("п. 8.2 ГОСТ 27005; Разд. 3–4 Методики ФСТЭК; Прил. А ГОСТ Р 57580.3-2022")
                quote: qsTr("«Идентификация рисков включает выявление источников угроз, уязвимостей и возможных последствий. Угрозы безопасности информации систематизируются с использованием Банка данных угроз (БДУ ФСТЭК) и классификатора инцидентов» (ГОСТ Р ИСО/МЭК 27005-2010, Методика ФСТЭК).")
                practicalNote: qsTr("Привязка защитной меры к риску снижает его остаточный балл до уровня ниже порога риск-аппетита, что соответствует требованию непрерывного управления рисками.")
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
                        id: searchRisk
                        Layout.fillWidth: true
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        selectByMouse: true
                        clip: true

                        Text {
                            visible: !searchRisk.text && !searchRisk.activeFocus
                            text: qsTr("Поиск по сценарию угрозы, уязвимости или связанному активу...")
                            color: Theme.subtle
                            font.pixelSize: Theme.fontBody
                        }
                    }

                    RowLayout {
                        spacing: 6
                        StatusBadge { text: qsTr("Все (") + DataStore.risksList.length + ")"; level: "info" }
                        StatusBadge { text: qsTr("Крит. (") + DataStore.criticalRisksCount + ")"; level: "critical" }
                        StatusBadge { text: qsTr("Выс. (") + DataStore.highRisksCount + ")"; level: "high" }
                    }

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            implicitWidth: importScenBtnText.implicitWidth + 24
                            implicitHeight: 34
                            radius: Theme.radiusSm
                            color: importScenMouse.containsMouse ? Theme.panelHover : "transparent"
                            border.color: Theme.accent
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "⚡"; color: Theme.accent; font.pixelSize: 12 }
                                Text {
                                    id: importScenBtnText
                                    text: qsTr("Сценарий ФСТЭК (С1–С3)")
                                    color: Theme.accent
                                    font.pixelSize: Theme.fontCaption
                                    font.weight: Font.Bold
                                }
                            }

                            MouseArea {
                                id: importScenMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: scenarioImportModal.openDialog()
                            }
                        }

                        Rectangle {
                            implicitWidth: addRiskBtn.implicitWidth + 24
                            implicitHeight: 34
                            radius: Theme.radiusSm
                            color: addRiskMouse.containsMouse ? Theme.accentGlow : Theme.accent

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                id: addRiskBtn
                                anchors.centerIn: parent
                                text: qsTr("+ Новый риск")
                                color: "#ffffff"
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: addRiskMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: riskDialog.openForAdd()
                            }
                        }
                    }
                }
            }

            // --- ТАБЛИЦА РЕЕСТРА РИСКОВ ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: riskTableLayout.implicitHeight + 20
                radius: Theme.radiusMd
                color: Theme.panel
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: riskTableLayout
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
                            Text { text: qsTr("СЦЕНАРИЙ УГРОЗЫ И УЯЗВИМОСТЬ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.fillWidth: true }
                            Text { text: qsTr("АКТИВ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 140 }
                            Text { text: qsTr("I × P × A"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                            Text { text: qsTr("БАЛЛ РИСКА"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 125 }
                            Text { text: qsTr("МЕРА ЗАЩИТЫ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 160 }
                            Text { text: qsTr("СТАТУС"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 95 }
                            Text { text: qsTr("ДЕЙСТВИЯ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                        }
                    }

                    // Строки таблицы
                    Repeater {
                        model: DataStore.risksList

                        delegate: Rectangle {
                            id: riskRow
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: 48
                            radius: Theme.radiusSm
                            color: riskRowMouse.containsMouse ? Theme.panelHover : (index % 2 === 0 ? "transparent" : (Theme.isDark ? "#171a21" : "#f8f9fb"))

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                Text {
                                    text: riskRow.modelData.id
                                    color: Theme.accent
                                    font.pixelSize: Theme.fontCaption
                                    font.weight: Font.Bold
                                    Layout.preferredWidth: 65
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: riskRow.modelData.threat
                                        color: Theme.text
                                        font.pixelSize: Theme.fontBody
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: riskRow.modelData.vuln ? ("Уязвимость: " + riskRow.modelData.vuln) : ""
                                        visible: riskRow.modelData.vuln !== ""
                                        color: Theme.subtle
                                        font.pixelSize: Theme.fontMicro
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: riskRow.modelData.assetName || "—"
                                    color: Theme.muted
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideRight
                                    Layout.preferredWidth: 140
                                }

                                Rectangle {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 24
                                    radius: Theme.radiusXs
                                    color: Theme.raised
                                    border.color: Theme.border
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: (riskRow.modelData.impact || 1) + " × " + (riskRow.modelData.probability || 1) + " × " + (riskRow.modelData.assetPriority || 1)
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontCaption
                                        font.weight: Font.DemiBold
                                    }
                                }

                                StatusBadge {
                                    text: riskRow.modelData.score + " · " + DataStore.getLevelName(riskRow.modelData.scoreLevel)
                                    level: riskRow.modelData.scoreLevel
                                    Layout.preferredWidth: 125
                                }

                                Text {
                                    text: riskRow.modelData.boundMeasureName || qsTr("Не назначена")
                                    color: riskRow.modelData.boundMeasureId ? (Theme.isDark ? Theme.tealLight : Theme.teal) : Theme.muted
                                    font.pixelSize: Theme.fontCaption
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.preferredWidth: 160
                                }

                                StatusBadge {
                                    text: riskRow.modelData.status || "В плане"
                                    level: riskRow.modelData.statusLevel || "high"
                                    Layout.preferredWidth: 95
                                }

                                // Кнопки действий
                                RowLayout {
                                    Layout.preferredWidth: 70
                                    spacing: 8

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: Theme.radiusXs
                                        color: editRiskMouse.containsMouse ? Theme.panelHover : "transparent"
                                        border.color: editRiskMouse.containsMouse ? Theme.borderHighlight : "transparent"
                                        border.width: 1

                                        AppIcon {
                                            anchors.centerIn: parent
                                            name: "edit"
                                            size: 15
                                            color: editRiskMouse.containsMouse ? Theme.accent : Theme.muted
                                        }

                                        MouseArea {
                                            id: editRiskMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: riskDialog.openForEdit(riskRow.index, riskRow.modelData)
                                        }

                                        ToolTip.visible: editRiskMouse.containsMouse
                                        ToolTip.text: qsTr("Редактировать риск")
                                    }

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: Theme.radiusXs
                                        color: delRiskMouse.containsMouse ? Theme.badgeCriticalBg : "transparent"
                                        border.color: delRiskMouse.containsMouse ? Theme.badgeCriticalBorder : "transparent"
                                        border.width: 1

                                        AppIcon {
                                            anchors.centerIn: parent
                                            name: "trash"
                                            size: 15
                                            color: delRiskMouse.containsMouse ? Theme.riskCritical : Theme.muted
                                        }

                                        MouseArea {
                                            id: delRiskMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: DataStore.deleteRisk(riskRow.index)
                                        }

                                        ToolTip.visible: delRiskMouse.containsMouse
                                        ToolTip.text: qsTr("Удалить риск")
                                    }
                                }
                            }

                            MouseArea {
                                id: riskRowMouse
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

    RiskDialog {
        id: riskDialog
        anchors.fill: parent
    }

    ScenarioImportDialog {
        id: scenarioImportModal
        anchors.fill: parent
    }
}
