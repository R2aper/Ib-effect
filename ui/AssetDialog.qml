import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "DocumentLinks.js" as DocumentLinks
import QtQuick.Effects

Rectangle {
    id: assetDialog

    property bool isEditMode: false
    property string editId: ""
    property string initialName: ""
    property string initialCategory: "Информ. система"
    property real initialCost: 1000000
    property int initialPriority: 3

    readonly property var oaList: [
        { code: "", title: qsTr("Без привязки к ОА (Общий IT-актив)"), cat: "Информ. система", defPrio: 3, hint: "" },
        { code: "ОА.001", title: qsTr("ОА.001 · АРМ оператора (диспетчера)"), cat: "АРМ диспетчера", defPrio: 3, hint: qsTr("АРМ отображает мнемосхемы техпроцесса. Угроза искажения данных телеметрии.") },
        { code: "ОА.002", title: qsTr("ОА.002 · АРМ инженера (инженерная станция)"), cat: "АРМ инженера", defPrio: 4, hint: qsTr("Инженерная станция имеет прямой доступ к компиляции и прошивке ПЛК. Рекомендуется приоритет 4.") },
        { code: "ОА.003", title: qsTr("ОА.003 · Промышленный сервер (SCADA/DCS)"), cat: "Промышленный сервер", defPrio: 4, hint: qsTr("Центральный узел управления АСУ ТП. Сбой ведет к потере контроля над производством.") },
        { code: "ОА.004", title: qsTr("ОА.004 · Сервер архивов (SCADA Historian)"), cat: "Сервер архивов", defPrio: 3, hint: qsTr("База технологических параметров и аварийных событий. Важна целостность логов.") },
        { code: "ОА.005", title: qsTr("ОА.005 · Сенсорная панель оператора (HMI)"), cat: "Панель оператора", defPrio: 3, hint: qsTr("Локальный пульт управления установкой. Угроза несанкционированного ввода команд.") },
        { code: "ОА.006", title: qsTr("ОА.006 · Программируемый логический контроллер (ПЛК / PLC)"), cat: "Контроллер (ПЛК)", defPrio: 4, hint: qsTr("Внимание: ПЛК выполняет логику реального времени. Сбой/подмена прошивки ведет к аварии. Рекомендуется приоритет 4.") },
        { code: "ОА.007", title: qsTr("ОА.007 · ПЛК противоаварийной защиты (ПАЗ / SIS)"), cat: "Система ПАЗ / SIS", defPrio: 4, hint: qsTr("Внимание: критический контур безопасности жизни людей и оборудования при ЧС. Высший приоритет 4.") },
        { code: "ОА.008", title: qsTr("ОА.008 · Датчики и исполнительные механизмы"), cat: "Полевое оборудование", defPrio: 2, hint: qsTr("Клапаны, насосы, термометры полевого уровня. Уязвимы к перехвату 4-20mA / HART сигналов.") },
        { code: "ОА.009", title: qsTr("ОА.009 · Съемный носитель информации (USB, flash)"), cat: "Съемный носитель", defPrio: 4, hint: qsTr("Внимание: основной вектор проникновения в закрытые технологические сети (Air Gap, пример Stuxnet). Рекомендуется приоритет 4.") },
        { code: "ОА.010", title: qsTr("ОА.010 · Устройство промышленного интернета вещей (IIoT)"), cat: "Устройство IIoT", defPrio: 2, hint: qsTr("Беспроводные датчики мониторинга вибрации/давления. Риск компрометации шлюза.") },
        { code: "ОА.011", title: qsTr("ОА.011 · Активное сетевое оборудование (коммутаторы/маршрутизаторы)"), cat: "Сетевое оборудование", defPrio: 3, hint: qsTr("Промышленные коммутаторы технологической сети. Угроза нарушения доступности и MITM.") },
        { code: "ОА.012", title: qsTr("ОА.012 · Средства защиты информации (МЭ, диоды данных)"), cat: "Средство защиты", defPrio: 4, hint: qsTr("Межсетевые экраны и однонаправленные шлюзы. Защищают границу контуров IT и OT.") },
        { code: "ОА.013", title: qsTr("ОА.013 · Мобильное устройство (планшет обходчика)"), cat: "Мобильное устройство", defPrio: 2, hint: qsTr("Планшеты инженеров ТОиР. Риск несанкционированного подключения к беспроводной сети АСУ ТП.") },
        { code: "ОА.014", title: qsTr("ОА.014 · Оборудование беспроводной связи (Wi-Fi/Zigbee/LoRa)"), cat: "Беспроводная связь", defPrio: 3, hint: qsTr("Точки доступа и модемы. Вектор атак на периметр без физического доступа.") }
    ]

    anchors.fill: parent
    color: Theme.isDark ? "#aa000000" : "#66000000"
    visible: false
    z: 999

    function openForAdd() {
        isEditMode = false;
        editId = "";
        nameInput.text = "";
        costInput.text = AssetService.industrialMode ? "15000000" : "5000000";
        prioSelector.selectedPrio = AssetService.industrialMode ? 4 : 3;
        categoryBox.currentIndex = 0;
        oaBox.currentIndex = AssetService.industrialMode ? 6 : 0;
        updateOaHint();
        errorText.text = "";
        visible = true;
    }

    function openForEdit(item) {
        isEditMode = true;
        editId = String(item.id || "");
        nameInput.text = item.name || "";
        costInput.text = item.cost ? item.cost.toString() : "0";
        prioSelector.selectedPrio = item.prio || 3;
        for (var i = 0; i < categoryBox.model.length; i++) {
            if (categoryBox.model[i] === item.cat) {
                categoryBox.currentIndex = i;
                break;
            }
        }
        var foundOa = false;
        if (item.oaCode) {
            for (var k = 0; k < oaList.length; k++) {
                if (oaList[k].code === item.oaCode) {
                    oaBox.currentIndex = k;
                    foundOa = true;
                    break;
                }
            }
        }
        if (!foundOa) oaBox.currentIndex = 0;
        updateOaHint();
        errorText.text = "";
        visible = true;
    }

    function updateOaHint() {
        var sel = oaList[oaBox.currentIndex];
        if (sel && sel.hint) {
            oaHintBox.visible = true;
            oaHintText.text = sel.hint;
            if (!isEditMode && sel.defPrio) {
                prioSelector.selectedPrio = sel.defPrio;
            }
        } else {
            oaHintBox.visible = false;
            oaHintText.text = "";
        }
    }

    MouseArea { anchors.fill: parent }

    Rectangle {
        id: card
        width: 520
        height: dialogCol.implicitHeight + 48
        implicitHeight: height
        anchors.centerIn: parent
        radius: Theme.radiusLg
        color: Theme.panel
        border.color: Theme.border
        border.width: 1

        MultiEffect {
            source: card
            anchors.fill: card
            shadowEnabled: true
            shadowColor: Theme.isDark ? "#80000000" : "#20000000"
            shadowBlur: 0.5
            shadowOpacity: 0.3
            shadowVerticalOffset: 4
            z: -1
        }

        ColumnLayout {
            id: dialogCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: assetDialog.isEditMode ? qsTr("Редактирование актива") : qsTr("Добавление защищаемого актива")
                    color: Theme.text
                    font.pixelSize: Theme.fontH2
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }
                Text {
                    text: "✕"
                    color: Theme.muted
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: assetDialog.visible = false
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // Выбор типа объекта воздействия по ФСТЭК (ОА.001 - ОА.014)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                RowLayout {
                    Text { text: qsTr("Тип объекта по ФСТЭК (БДУ АСУ ТП):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }
                    StatusBadge {
                        text: oaBox.currentIndex > 0 ? qsTr("Промышленный актив АСУ ТП") : qsTr("Общий IT-контур")
                        level: oaBox.currentIndex > 0 ? "teal" : "info"
                    }
                }
                ComboBox {
                    id: oaBox
                    Layout.fillWidth: true
                    model: {
                        var titles = [];
                        for (var i = 0; i < oaList.length; i++) titles.push(oaList[i].title);
                        return titles;
                    }
                    onActivated: assetDialog.updateOaHint()
                }
            }

            // Подсказка / Особенность выбранного ОА
            Rectangle {
                id: oaHintBox
                Layout.fillWidth: true
                implicitHeight: oaHintText.implicitHeight + 16
                radius: Theme.radiusSm
                color: Theme.isDark ? "#172533" : "#eff6ff"
                border.color: Theme.isDark ? "#243c5a" : "#bfdbfe"
                border.width: 1
                visible: false

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    Text {
                        id: oaHintText
                        color: Theme.isDark ? "#93c5fd" : "#1d4ed8"
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Наименование
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: qsTr("Наименование актива:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: nameInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: nameInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        clip: true
                    }
                }
            }

            // Категория
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: qsTr("Категория оборудования:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                ComboBox {
                    id: categoryBox
                    Layout.fillWidth: true
                    model: ["Контроллер (ПЛК)", "Съемный носитель", "АРМ инженера", "АРМ диспетчера", "Промышленный сервер", "Панель оператора", "Система ПАЗ / SIS", "Сетевое оборудование", "Информ. система", "База данных", "Инфраструктура", "Служба каталога"]
                }
            }

            // Стоимость в рублях
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: qsTr("Балансовая / эксплуатационная стоимость актива (₽):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: costInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: costInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        validator: DoubleValidator { bottom: 0 }
                        clip: true
                    }
                }
            }

            // Приоритет актива (1..4)
            ColumnLayout {
                id: prioSelector
                property int selectedPrio: 3
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: DocumentLinks.linkify(qsTr("Приоритет актива A ∈ [1..4] (ГОСТ 27005 / Приказ № 239):"))
                    textFormat: Text.RichText
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                RowLayout {
                    spacing: 8
                    Repeater {
                        model: [
                            { prio: 1, label: "1 · Низкий" },
                            { prio: 2, label: "2 · Средний" },
                            { prio: 3, label: "3 · Высокий" },
                            { prio: 4, label: "4 · КИИ" }
                        ]
                        delegate: Rectangle {
                            id: prioBtn
                            required property var modelData
                            implicitWidth: (card.width - 48 - 24) / 4
                            implicitHeight: 34
                            radius: Theme.radiusSm
                            color: prioSelector.selectedPrio === modelData.prio ? (Theme.isDark ? "#1d293d" : "#eff6ff") : Theme.panelHover
                            border.color: prioSelector.selectedPrio === modelData.prio ? Theme.accent : Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: prioBtn.modelData.label
                                color: prioSelector.selectedPrio === prioBtn.modelData.prio ? Theme.accent : Theme.text
                                font.pixelSize: 11
                                font.weight: prioSelector.selectedPrio === prioBtn.modelData.prio ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: prioSelector.selectedPrio = prioBtn.modelData.prio
                            }
                        }
                    }
                }
            }

            Text {
                id: errorText
                color: Theme.riskCritical
                font.pixelSize: Theme.fontCaption
                visible: text !== ""
            }

            // Кнопки Сохранить / Отмена
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 12

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: cancelText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: cancelMouse.containsMouse ? Theme.panelHover : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        id: cancelText
                        anchors.centerIn: parent
                        text: qsTr("Отмена")
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: assetDialog.visible = false
                    }
                }

                Rectangle {
                    implicitWidth: saveBtnText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: saveMouse.containsMouse ? Theme.accentGlow : Theme.accent

                    Text {
                        id: saveBtnText
                        anchors.centerIn: parent
                        text: assetDialog.isEditMode ? qsTr("Сохранить") : qsTr("Добавить актив")
                        color: "#ffffff"
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!nameInput.text.trim()) {
                                errorText.text = qsTr("Укажите наименование актива");
                                return;
                            }
                            var costVal = parseFloat(costInput.text) || 0;
                            var selOa = oaBox.currentIndex > 0 ? oaList[oaBox.currentIndex] : null;
                            var oaCode = selOa ? selOa.code : "";
                            var oaTitle = selOa ? selOa.title : "";
                            var domain = selOa ? "OT" : (AssetService.industrialMode ? "OT" : "IT");

                            var asset = {
                                name: nameInput.text.trim(),
                                cat: categoryBox.currentText,
                                cost: costVal,
                                prio: prioSelector.selectedPrio,
                                oaCode: oaCode,
                                oaTitle: oaTitle,
                                domain: domain
                            };
                            if (assetDialog.isEditMode) {
                                AssetService.update(assetDialog.editId, asset);
                            } else {
                                AssetService.create(asset);
                            }
                            assetDialog.visible = false;
                        }
                    }
                }
            }
        }
    }
}
