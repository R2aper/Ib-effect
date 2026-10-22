import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "BduData.js" as BduData

Rectangle {
    id: riskDialog

    property bool isEditMode: false
    property int editIndex: -1
    property string editRiskId: ""
    property var currentSuggestedThreats: []
    property string selectedThreatCode: ""
    property string pendingRequestId: ""

    anchors.fill: parent
    color: Theme.isDark ? "#aa000000" : "#66000000"
    visible: false
    z: 999

    function openForAdd() {
        isEditMode = false;
        editIndex = -1;
        threatInput.text = "";
        vulnInput.text = "";
        selectedThreatCode = "";
        impactSelector.selectedVal = 3;
        probSelector.selectedVal = 3;
        populateAssets();
        updateThreatSuggestions();
        errorText.text = "";
        visible = true;
    }

    function openForEdit(index, item) {
        isEditMode = true;
        editIndex = index;
        editRiskId = item.id;
        threatInput.text = item.threat || "";
        vulnInput.text = item.vuln || "";
        selectedThreatCode = item.threatCode || "";
        impactSelector.selectedVal = item.impact || 3;
        probSelector.selectedVal = item.probability || 3;
        populateAssets();
        for (var i = 0; i < AssetService.items.length; i++) {
            if (AssetService.items[i].id === item.assetId) {
                assetBox.currentIndex = i;
                break;
            }
        }
        updateThreatSuggestions();
        errorText.text = "";
        visible = true;
    }

    function populateAssets() {
        var names = [];
        for (var a = 0; a < AssetService.items.length; a++) {
            var ast = AssetService.items[a];
            var oaTag = ast.oaCode ? ("[" + ast.oaCode + "] ") : "";
            names.push(oaTag + ast.id + " · " + ast.name + " (Приоритет: " + ast.prio + ")");
        }
        assetBox.model = names;
        if (names.length > 0 && assetBox.currentIndex < 0) assetBox.currentIndex = 0;
    }

    function updateThreatSuggestions() {
        var aIdx = assetBox.currentIndex;
        var asset = AssetService.items[aIdx];
        var suggestions = [];
        var titles = [qsTr("— Выбрать угрозу из классификатора ФСТЭК —")];

        if (asset && asset.oaCode) {
            // АСУ ТП актив с кодом ОА
            var threats = BduData.getThreatsForObject(asset.oaCode);
            for (var i = 0; i < threats.length; i++) {
                var th = threats[i];
                suggestions.push({
                    code: th.code,
                    title: th.code + ": " + th.title,
                    vuln: qsTr("Уязвимость конфигурации и разграничения доступа компонента ") + asset.oaCode,
                    defImpact: (asset.prio >= 4 ? 4 : 3),
                    defProb: 3
                });
                titles.push(th.code + " · " + th.title);
            }
        } else {
            // Корпоративный IT актив -> выборка из 227 УБИ
            var itTh = BduData.getItThreats();
            var sampleCount = Math.min(25, itTh.length);
            for (var j = 0; j < sampleCount; j++) {
                var it = itTh[j];
                suggestions.push({
                    code: it.id,
                    title: it.id + ": " + it.name,
                    vuln: it.description ? it.description.slice(0, 100) + "..." : qsTr("Уязвимость контура защиты"),
                    defImpact: 3,
                    defProb: 3
                });
                titles.push(it.id + " · " + it.name);
            }

        }
        currentSuggestedThreats = suggestions;
        threatPickerBox.model = titles;
        threatPickerBox.currentIndex = 0;
    }

    function levelByScore(score) {
        if (score > 32) return "critical";
        if (score > 16) return "high";
        if (score > 8) return "medium";
        return "low";
    }

    function levelName(level) {
        if (level === "critical") return qsTr("Критический");
        if (level === "high") return qsTr("Высокий");
        if (level === "medium") return qsTr("Средний");
        return qsTr("Низкий");
    }

    Connections {
        target: RiskService
        function onOperationFinished(requestId, operation, success, data, error) {
            if (requestId !== riskDialog.pendingRequestId)
                return;
            riskDialog.pendingRequestId = "";
            if (success) {
                riskDialog.visible = false;
            } else {
                errorText.text = error;
            }
        }
    }

    MouseArea { anchors.fill: parent }

    Rectangle {
        id: card
        width: 540
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
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: riskDialog.isEditMode ? qsTr("Редактирование риска") : qsTr("Регистрация и оценка риска")
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
                        onClicked: riskDialog.visible = false
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // Связанный актив (выбирается первым)
            ColumnLayout {
                visible: !riskDialog.isEditMode
                Layout.fillWidth: true
                spacing: 5
                Text { text: qsTr("Атакуемый актив:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                ComboBox {
                    id: assetBox
                    Layout.fillWidth: true
                    onActivated: riskDialog.updateThreatSuggestions()
                }
            }

            // Быстрый выбор из классификатора ФСТЭК (УТП / УБИ)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                RowLayout {
                    Text { text: qsTr("Классификатор угроз ФСТЭК (автоподбор):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: qsTr("БДУ АСУ ТП / БДУ ФСТЭК")
                        color: Theme.accent
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
                ComboBox {
                    id: threatPickerBox
                    Layout.fillWidth: true
                    onActivated: {
                        if (currentIndex > 0 && currentSuggestedThreats.length >= currentIndex) {
                            var sel = currentSuggestedThreats[currentIndex - 1];
                            riskDialog.selectedThreatCode = sel.code;
                            threatInput.text = sel.title;
                            vulnInput.text = sel.vuln;
                            impactSelector.selectedVal = sel.defImpact;
                            probSelector.selectedVal = sel.defProb;
                        }
                    }
                }
            }

            // Сценарий угрозы
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text { text: qsTr("Наименование и сценарий угрозы:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: threatInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: threatInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        clip: true
                    }
                }
            }

            // Уязвимость
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text { text: qsTr("Уязвимость / способ реализации (СПА):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: Theme.isDark ? Theme.panelHover : "#ffffff"
                    border.color: vulnInput.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    TextInput {
                        id: vulnInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        clip: true
                    }
                }
            }

            // Шкала ущерба I (1..4)
            ColumnLayout {
                id: impactSelector
                property int selectedVal: 3
                Layout.fillWidth: true
                spacing: 5

                Text { text: qsTr("Потенциальный ущерб I (1..4):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                RowLayout {
                    spacing: 8
                    Repeater {
                        model: [
                            { val: 1, label: "1 · Незнач." },
                            { val: 2, label: "2 · Умерен." },
                            { val: 3, label: "3 · Сущест." },
                            { val: 4, label: "4 · Катастр." }
                        ]
                        delegate: Rectangle {
                            id: iBtn
                            required property var modelData
                            implicitWidth: (card.width - 48 - 24) / 4
                            implicitHeight: 32
                            radius: Theme.radiusSm
                            color: impactSelector.selectedVal === modelData.val ? (Theme.isDark ? "#1d293d" : "#eff6ff") : Theme.panelHover
                            border.color: impactSelector.selectedVal === modelData.val ? Theme.accent : Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: iBtn.modelData.label
                                color: impactSelector.selectedVal === iBtn.modelData.val ? Theme.accent : Theme.text
                                font.pixelSize: 11
                                font.weight: impactSelector.selectedVal === iBtn.modelData.val ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: impactSelector.selectedVal = iBtn.modelData.val
                            }
                        }
                    }
                }
            }

            // Шкала вероятности P (1..4)
            ColumnLayout {
                id: probSelector
                property int selectedVal: 3
                Layout.fillWidth: true
                spacing: 5

                Text { text: qsTr("Вероятность реализации P (1..4):"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold }
                RowLayout {
                    spacing: 8
                    Repeater {
                        model: [
                            { val: 1, label: "1 · Редкая" },
                            { val: 2, label: "2 · Возмож." },
                            { val: 3, label: "3 · Вероят." },
                            { val: 4, label: "4 · Постоян." }
                        ]
                        delegate: Rectangle {
                            id: pBtn
                            required property var modelData
                            implicitWidth: (card.width - 48 - 24) / 4
                            implicitHeight: 32
                            radius: Theme.radiusSm
                            color: probSelector.selectedVal === modelData.val ? (Theme.isDark ? "#1d293d" : "#eff6ff") : Theme.panelHover
                            border.color: probSelector.selectedVal === modelData.val ? Theme.accent : Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: pBtn.modelData.label
                                color: probSelector.selectedVal === pBtn.modelData.val ? Theme.accent : Theme.text
                                font.pixelSize: 11
                                font.weight: probSelector.selectedVal === pBtn.modelData.val ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: probSelector.selectedVal = pBtn.modelData.val
                            }
                        }
                    }
                }
            }

            // Превью балла
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Theme.radiusSm
                color: Theme.raised
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text {
                        text: qsTr("Расчетный балл: ") + (impactSelector.selectedVal * probSelector.selectedVal * (AssetService.items[assetBox.currentIndex] ? AssetService.items[assetBox.currentIndex].prio : 3))
                        color: Theme.text
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }
                    StatusBadge {
                        text: riskDialog.levelName(riskDialog.levelByScore(impactSelector.selectedVal * probSelector.selectedVal * (AssetService.items[assetBox.currentIndex] ? AssetService.items[assetBox.currentIndex].prio : 3)))
                        level: riskDialog.levelByScore(impactSelector.selectedVal * probSelector.selectedVal * (AssetService.items[assetBox.currentIndex] ? AssetService.items[assetBox.currentIndex].prio : 3))
                    }
                }
            }

            Text {
                id: errorText
                color: Theme.riskCritical
                font.pixelSize: Theme.fontCaption
                visible: text !== ""
            }

            // Кнопки
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
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
                        onClicked: riskDialog.visible = false
                    }
                }

                Rectangle {
                    implicitWidth: saveRiskBtnText.implicitWidth + 32
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: saveRiskMouse.containsMouse ? Theme.accentGlow : Theme.accent

                    Text {
                        id: saveRiskBtnText
                        anchors.centerIn: parent
                        text: riskDialog.isEditMode ? qsTr("Сохранить") : qsTr("Добавить риск")
                        color: "#ffffff"
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: saveRiskMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!threatInput.text.trim()) {
                                errorText.text = qsTr("Укажите сценарий угрозы");
                                return;
                            }
                            if (!riskDialog.isEditMode && !AssetService.items[assetBox.currentIndex]) {
                                errorText.text = qsTr("Сначала загрузите или создайте актив");
                                return;
                            }
                            var requestId;
                            if (riskDialog.isEditMode) {
                                requestId = RiskService.update(riskDialog.editRiskId, {
                                    threat: threatInput.text.trim(),
                                    threatCode: riskDialog.selectedThreatCode,
                                    vuln: vulnInput.text.trim(),
                                    impact: impactSelector.selectedVal,
                                    probability: probSelector.selectedVal
                                });
                            } else {
                                var asset = AssetService.items[assetBox.currentIndex];
                                requestId = RiskService.create({
                                    threat: threatInput.text.trim(),
                                    threatCode: riskDialog.selectedThreatCode,
                                    vuln: vulnInput.text.trim(),
                                    assetId: asset.id,
                                    assetName: asset.name,
                                    assetPriority: asset.prio,
                                    impact: impactSelector.selectedVal,
                                    probability: probSelector.selectedVal,
                                    riskAppetite: EconomicsService.riskAppetite
                                });
                            }
                            riskDialog.pendingRequestId = requestId;
                        }
                    }
                }
            }
        }
    }
}
