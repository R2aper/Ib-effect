import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Item {
    ScrollView {
        anchors.fill: parent
        clip: true
        padding: 24
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 20

        SectionHeading {
            eyebrow: qsTr("КАРТА АКТИВОВ")
            heading: qsTr("Инвентаризация и оценка активов")
            description: qsTr("Реестр информационных систем, баз данных и инфраструктуры, формирующих контур защиты.")
        }

        WorkflowGuideBanner {
            stepNumber: "02"
            stepTitle: qsTr("Этап 2: Инвентаризация и категорирование активов")
            purpose: qsTr("Формирование реестра защищаемых информационных активов и определение их категории ценности (A ∈ [1..4]) по ГОСТ Р ИСО/МЭК 27005-2010 и ГОСТ Р 57580.3-2022.")
            whatToDo: qsTr("Добавьте все критически важные системы, укажите балансовую стоимость, владельца актива и назначьте приоритет актива (1 - Низкий, 2 - Средний, 3 - Высокий, 4 - Критический).")
        }

        // --- ВЕРХНИЕ KPI-КАРТОЧКИ ---
        GridLayout {
            columns: width >= 900 ? 3 : 1
            columnSpacing: 14
            rowSpacing: 14
            Layout.fillWidth: true

            KpiStatCard {
                label: qsTr("ВСЕГО АКТИВОВ")
                value: DataStore.assetsList.length.toString()
                delta: "+1 нов."
                deltaIsGood: true
                note: qsTr("Зарегистрировано в реестре")
                glyph: "▣"
                accentColor: Theme.accent
            }

            KpiStatCard {
                label: qsTr("СУММАРНАЯ СТОИМОСТЬ АКТИВОВ")
                value: (DataStore.totalAssetsCost >= 1000000 ? (DataStore.totalAssetsCost / 1000000).toFixed(1) + "M ₽" : (DataStore.totalAssetsCost / 1000).toFixed(0) + "K ₽")
                delta: "Оценка"
                deltaIsGood: true
                note: qsTr("Балансовая и эксплуатационная ценность")
                glyph: "₽"
                accentColor: Theme.teal
                valueColor: Theme.isDark ? Theme.tealLight : Theme.teal
            }

            KpiStatCard {
                label: qsTr("КРИТИЧЕСКИЕ СИСТЕМЫ (КИИ)")
                value: {
                    var count = 0;
                    for (var i = 0; i < DataStore.assetsList.length; i++) {
                        if (DataStore.assetsList[i].prio === 4) count++;
                    }
                    return count.toString();
                }
                delta: "Приоритет 4"
                deltaIsGood: false
                note: qsTr("Объекты высшей категории значимости")
                glyph: "△"
                accentColor: Theme.riskCritical
                valueColor: Theme.riskCritical
            }
        }

        // --- СКРЫТЫЙ ПОЯСНЯЮЩИЙ БЛОК: НОРМАТИВНАЯ КЛАССИФИКАЦИЯ АКТИВОВ ---
        NormativeExplanationCard {
            title: qsTr("Нормативная база инвентаризации и категорирования активов")
            standard: "ГОСТ Р 57580.3-2022 / ГОСТ Р ИСО/МЭК 27005-2010"
            clause: qsTr("п. 6.3 ГОСТ Р 57580.3-2022; Приложение B ГОСТ Р ИСО/МЭК 27005-2010")
            quote: qsTr("«Выполнение процессов управления риском осуществляется применительно к совокупности критичных активов — объектов информатизации прикладного уровня (АБС, ДБО, веб-ресурсы) и инфраструктурного уровня (аппаратные средства, сети, СУБД, серверы приложений)» (ГОСТ Р 57580.3-2022, п. 6.3).")
            practicalNote: qsTr("Приоритет актива (1–4) отражает степень его критичности для операционной надежности бизнеса и допустимое время простоя технологических процессов (RTO).")
        }

        // --- ТУЛБАР ФИЛЬТРАЦИИ И ДЕЙСТВИЙ ---
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
                    id: searchAsset
                    Layout.fillWidth: true
                    color: Theme.text
                    font.pixelSize: Theme.fontBody
                    selectByMouse: true
                    clip: true

                    Text {
                        visible: !searchAsset.text && !searchAsset.activeFocus
                        text: qsTr("Поиск актива по названию, категории или ID...")
                        color: Theme.subtle
                        font.pixelSize: Theme.fontBody
                    }
                }

                RowLayout {
                    spacing: 6
                    StatusBadge { text: qsTr("Все (") + DataStore.assetsList.length + ")"; level: "info" }
                }

                Rectangle {
                    implicitWidth: addBtnText.implicitWidth + 24
                    implicitHeight: 34
                    radius: Theme.radiusSm
                    color: addBtnMouse.containsMouse ? Theme.accentGlow : Theme.accent

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: addBtnText
                        anchors.centerIn: parent
                        text: qsTr("+ Добавить актив")
                        color: "#ffffff"
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: addBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: assetDialog.openForAdd()
                    }
                }
            }
        }

        // --- ТАБЛИЦА РЕЕСТРА АКТИВОВ (DATA TABLE) ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tableLayout.implicitHeight + 20
            radius: Theme.radiusMd
            color: Theme.panel
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                id: tableLayout
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

                        Text { text: qsTr("ID"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 70 }
                        Text { text: qsTr("НАИМЕНОВАНИЕ АКТИВА"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.fillWidth: true }
                        Text { text: qsTr("КАТЕГОРИЯ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 150 }
                        Text { text: qsTr("СТОИМОСТЬ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 120 }
                        Text { text: qsTr("ПРИОРИТЕТ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 100 }
                        Text { text: qsTr("СТАТУС"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 95 }
                        Text { text: qsTr("ДЕЙСТВИЯ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                    }
                }

                // Строки таблицы
                Repeater {
                    model: DataStore.assetsList

                    delegate: Rectangle {
                        id: rowRect
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: Theme.radiusSm
                        color: rowMouse.containsMouse ? Theme.panelHover : (index % 2 === 0 ? "transparent" : (Theme.isDark ? "#171a21" : "#f8f9fb"))

                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Text {
                                text: rowRect.modelData.id
                                color: Theme.accent
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.Bold
                                Layout.preferredWidth: 70
                            }

                            Text {
                                text: rowRect.modelData.name
                                color: Theme.text
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: rowRect.modelData.cat
                                color: Theme.muted
                                font.pixelSize: Theme.fontCaption
                                Layout.preferredWidth: 150
                            }

                            Text {
                                text: (rowRect.modelData.cost ? (rowRect.modelData.cost).toLocaleString(Qt.locale(), 'f', 0) : "0") + " ₽"
                                color: Theme.isDark ? Theme.tealLight : Theme.teal
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.DemiBold
                                Layout.preferredWidth: 120
                            }

                            StatusBadge {
                                text: rowRect.modelData.prio + " · " + (rowRect.modelData.prio === 4 ? "КИИ" : (rowRect.modelData.prio === 3 ? "Высок." : (rowRect.modelData.prio === 2 ? "Сред." : "Низк.")))
                                level: rowRect.modelData.prio === 4 ? "critical" : (rowRect.modelData.prio === 3 ? "high" : (rowRect.modelData.prio === 2 ? "medium" : "low"))
                                Layout.preferredWidth: 100
                            }

                            StatusBadge {
                                text: rowRect.modelData.status || "На защите"
                                level: rowRect.modelData.statusLevel || "success"
                                Layout.preferredWidth: 95
                            }

                            // Кнопки редактирования и удаления
                            RowLayout {
                                Layout.preferredWidth: 70
                                spacing: 8

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.radiusXs
                                    color: editMouse.containsMouse ? Theme.panelHover : "transparent"
                                    border.color: editMouse.containsMouse ? Theme.borderHighlight : "transparent"
                                    border.width: 1

                                    AppIcon {
                                        anchors.centerIn: parent
                                        name: "edit"
                                        size: 15
                                        color: editMouse.containsMouse ? Theme.accent : Theme.muted
                                    }

                                    MouseArea {
                                        id: editMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: assetDialog.openForEdit(rowRect.index, rowRect.modelData)
                                    }

                                    ToolTip.visible: editMouse.containsMouse
                                    ToolTip.text: qsTr("Редактировать актив")
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.radiusXs
                                    color: delMouse.containsMouse ? Theme.badgeCriticalBg : "transparent"
                                    border.color: delMouse.containsMouse ? Theme.badgeCriticalBorder : "transparent"
                                    border.width: 1

                                    AppIcon {
                                        anchors.centerIn: parent
                                        name: "trash"
                                        size: 15
                                        color: delMouse.containsMouse ? Theme.riskCritical : Theme.muted
                                    }

                                    MouseArea {
                                        id: delMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: DataStore.deleteAsset(rowRect.index)
                                    }

                                    ToolTip.visible: delMouse.containsMouse
                                    ToolTip.text: qsTr("Удалить актив")
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
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

    AssetDialog {
        id: assetDialog
        anchors.fill: parent
    }
}
