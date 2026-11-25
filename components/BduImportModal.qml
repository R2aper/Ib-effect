import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    property bool isOpen: false
    property string targetAssetId: ""
    property string targetAssetName: ""
    signal vulnerabilityImported(var vulnMap)

    function openDefault() {
        targetAssetId = ""
        targetAssetName = ""
        isOpen = true
    }

    function openForAsset(assetId, assetName, defaultKeyword) {
        targetAssetId = assetId || ""
        targetAssetName = assetName || ""
        isOpen = true
        if (defaultKeyword && defaultKeyword.trim().length > 0) {
            searchKeyword = defaultKeyword.trim()
            searchField.text = defaultKeyword.trim()
            doSearch()
        }
    }

    visible: isOpen
    anchors.fill: parent
    z: 1000

    property var searchResults: []
    property int selectedResultIndex: 0
    readonly property var currentItem: (searchResults.length > 0 && selectedResultIndex >= 0 && selectedResultIndex < searchResults.length)
                                        ? searchResults[selectedResultIndex]
                                        : null

    property string searchKeyword: ""
    property int severityFilterIndex: 0 // 0: Все, 1: Критический, 2: Высокий, 3: Средний, 4: Низкий
    property int sortOrderIndex: 0
    property bool exploitOnly: false
    property bool fixOnly: false
    property string statusMessage: ""

    function getSeverityLevel() {
        switch (severityFilterIndex) {
        case 1: return 4 // Критический
        case 2: return 3 // Высокий
        case 3: return 2 // Средний
        case 4: return 1 // Низкий
        default: return 0
        }
    }

    function doSearch() {
        if (typeof riskCalculator === "undefined" || !riskCalculator.isBduAvailable) {
            searchResults = []
            return
        }
        var sev = getSeverityLevel()
        var res = riskCalculator.searchBdu(searchKeyword, sev, 60,
                                           sortOrderIndex, exploitOnly, fixOnly)
        searchResults = res
        selectedResultIndex = 0
        statusMessage = ""
    }

    function importCurrent(bduId) {
        if (typeof riskCalculator === "undefined") return
        var targetId = bduId || (currentItem ? currentItem.id : "")
        if (!targetId) return

        var imported = riskCalculator.importFromBdu(targetId)
        if (imported && imported.id) {
            if (targetAssetId !== "") {
                riskCalculator.linkVulnerabilityToAsset(targetAssetId, targetId)
                statusMessage = "Уязвимость " + targetId + " привязана к активу: " + targetAssetName
            } else {
                statusMessage = "Уязвимость " + targetId + " успешно импортирована в проект!"
            }
            // Обновляем статус в текущем списке
            var list = searchResults.slice()
            for (var i = 0; i < list.length; ++i) {
                if (list[i].id === targetId) {
                    list[i].alreadyImported = true
                }
            }
            searchResults = list
            root.vulnerabilityImported(imported)
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            if (targetAssetId === "") {
                searchField.text = ""
                searchKeyword = ""
            }
            severityFilterIndex = 0
            sortOrderIndex = 0
            exploitOnly = false
            fixOnly = false
            doSearch()
            searchField.forceActiveFocus()
        }
    }

    Timer {
        id: debounceTimer
        interval: 220
        repeat: false
        onTriggered: root.doSearch()
    }

    // Затененный фон
    Rectangle {
        anchors.fill: parent
        color: "#90000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.isOpen = false
        }
    }

    // Модальное окно
    Rectangle {
        id: modalDialog
        width: Math.min(parent.width - 40, 1020)
        height: Math.min(parent.height - 40, 720)
        anchors.centerIn: parent
        color: Style.panelSurface
        border.color: Style.borderDark
        border.width: 1
        clip: true

        // Предотвращаем клик сквозь окно
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ==================== Шапка ====================
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: Style.surfaceContainer
                border.color: Style.hairlineBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Rectangle {
                        width: 28
                        height: 28
                        color: Style.primary
                        Text {
                            anchors.centerIn: parent
                            text: "БДУ"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Style.textOnPrimary
                        }
                    }

                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: root.targetAssetId !== ""
                                  ? ("БДУ ФСТЭК России → Привязка к активу: " + root.targetAssetName)
                                  : "Каталог уязвимостей БДУ ФСТЭК России"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.Bold
                            color: Style.textPrimary
                        }
                        Text {
                            text: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable)
                                  ? ("База данных подключена: " + riskCalculator.formatNumber(riskCalculator.bduTotalCount, 0) + " уязвимостей • bdu.sqlite")
                                  : "База данных БДУ не найдена (проверьте наличие bdu.sqlite)"
                            font.family: Style.fontSans
                            font.pixelSize: 11
                            color: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable)
                                   ? Style.riskLowText : Style.riskCriticalText
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 28
                        height: 28
                        color: closeMouse.containsMouse ? Style.surfaceHover : "transparent"
                        border.color: Style.hairlineBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: Style.fontSans
                            font.pixelSize: 14
                            color: Style.textSecondary
                        }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isOpen = false
                        }
                    }
                }
            }

            // ==================== Панель поиска и фильтров ====================
            Rectangle {
                Layout.fillWidth: true
                height: 78
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        CustomTextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "BDU ID, CVE, название, ПО или вендор — например CVE-2024, PostgreSQL, Linux"
                            isMonospace: false
                            onTextChanged: {
                                root.searchKeyword = text
                                debounceTimer.restart()
                            }
                            Keys.onReturnPressed: root.doSearch()
                        }

                        AppButton {
                            visible: searchField.text.length > 0
                            text: "Очистить"
                            onClicked: {
                                searchField.text = ""
                                searchField.forceActiveFocus()
                            }
                        }

                        AppButton {
                            isPrimary: true
                            text: "Найти"
                            iconText: "🔍"
                            onClicked: root.doSearch()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Уровень"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodySm
                            color: Style.textSecondary
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 154
                            model: [
                                "Все уровни",
                                "Критический (≥9.0)",
                                "Высокий (7.0–8.9)",
                                "Средний (4.0–6.9)",
                                "Низкий (<4.0)"
                            ]
                            currentIndex: root.severityFilterIndex
                            onCurrentIndexChanged: {
                                if (root.severityFilterIndex !== currentIndex) {
                                    root.severityFilterIndex = currentIndex
                                    root.doSearch()
                                }
                            }
                        }

                        Text {
                            text: "Сортировка"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodySm
                            color: Style.textSecondary
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 165
                            model: ["По релевантности", "CVSS: сначала выше", "Сначала новые", "По BDU ID"]
                            currentIndex: root.sortOrderIndex
                            onCurrentIndexChanged: {
                                if (root.sortOrderIndex !== currentIndex) {
                                    root.sortOrderIndex = currentIndex
                                    root.doSearch()
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        AppButton {
                            text: "Есть эксплойт"
                            isPrimary: root.exploitOnly
                            onClicked: {
                                root.exploitOnly = !root.exploitOnly
                                root.doSearch()
                            }
                        }

                        AppButton {
                            text: "Есть исправление"
                            isPrimary: root.fixOnly
                            onClicked: {
                                root.fixOnly = !root.fixOnly
                                root.doSearch()
                            }
                        }
                    }
                }
            }

            // ==================== Основной контент: Список + Инспектор ====================
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // ----- Левая колонка: Таблица результатов -----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 520
                    color: Style.panelSurface
                    border.color: Style.hairlineBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Шапка таблицы результатов
                        Rectangle {
                            Layout.fillWidth: true
                            height: 26
                            color: Style.surfaceContainerHigh
                            border.color: Style.hairlineBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Text { text: "Код BDU"; font.family: Style.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textSecondary; Layout.preferredWidth: 95 }
                                Text { text: "CVE"; font.family: Style.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textSecondary; Layout.preferredWidth: 95 }
                                Text { text: "CVSS"; font.family: Style.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textSecondary; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignHCenter }
                                Text { text: "Уровень"; font.family: Style.fontSans; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textSecondary; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter }
                                Text { text: "Наименование / ПО"; font.family: Style.fontSans; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textSecondary; Layout.fillWidth: true }
                                Text { text: "Статус"; font.family: Style.fontSans; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textSecondary; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                            }
                        }

                        // Список
                        ListView {
                            id: bduListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: root.searchResults
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                id: bduRow
                                width: bduListView.width
                                height: 36
                                color: {
                                    if (root.selectedResultIndex === index) return Style.surfaceActive
                                    if (rowArea.containsMouse) return Style.surfaceHover
                                    return (index % 2 === 0) ? Style.panelSurface : Style.surfaceLow
                                }

                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: 1
                                    color: Style.hairlineBorder
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 6

                                    Text {
                                        text: modelData.id
                                        font.family: Style.fontMono
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                        Layout.preferredWidth: 95
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.cve || "—"
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                        Layout.preferredWidth: 95
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 42
                                        height: 18
                                        color: Style.getRiskColor(modelData.level)
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.cvss > 0 ? Number(modelData.cvss).toFixed(1) : "—"
                                            font.family: Style.fontMono
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                            color: Style.textOnDark
                                        }
                                    }

                                    RiskBadge {
                                        Layout.preferredWidth: 80
                                        level: modelData.level
                                    }

                                    Text {
                                        text: modelData.title
                                        font.family: Style.fontSans
                                        font.pixelSize: 11
                                        color: Style.textPrimary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Бейдж наличия в проекте
                                    Rectangle {
                                        Layout.preferredWidth: 70
                                        height: 18
                                        color: modelData.alreadyImported ? Style.riskLowBg : "transparent"
                                        border.color: modelData.alreadyImported ? Style.riskLowBorder : Style.hairlineBorder
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.alreadyImported ? "✓ В проекте" : "+ Добавить"
                                            font.family: Style.fontSans
                                            font.pixelSize: 9
                                            font.weight: modelData.alreadyImported ? Font.DemiBold : Font.Normal
                                            color: modelData.alreadyImported ? Style.riskLowText : Style.textSecondary
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedResultIndex = index
                                    }
                                    onDoubleClicked: {
                                        root.selectedResultIndex = index
                                        if (!modelData.alreadyImported) {
                                            root.importCurrent(modelData.id)
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.searchResults.length === 0
                                text: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable)
                                      ? (root.searchKeyword.length > 0 || root.severityFilterIndex > 0
                                         || root.exploitOnly || root.fixOnly
                                         ? "По заданным условиям ничего не найдено"
                                         : "Уязвимости не найдены")
                                      : "База данных БДУ недоступна"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodyMd
                                color: Style.textMuted
                            }
                        }

                        // Футер списка
                        Rectangle {
                            Layout.fillWidth: true
                            height: 24
                            color: Style.surfaceContainer
                            border.color: Style.hairlineBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                Text {
                                    text: root.statusMessage || ("Показано записей: " + root.searchResults.length)
                                    font.family: Style.fontMono
                                    font.pixelSize: 10
                                    color: Style.textSecondary
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "Двойной клик по строке для быстрого импорта"
                                    font.family: Style.fontSans
                                    font.pixelSize: 10
                                    color: Style.textMuted
                                }
                            }
                        }
                    }
                }

                // ----- Правая колонка: Детальная карточка выбранной уязвимости -----
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 420
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Шапка инспектора
                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            color: Style.surfaceContainerHigh
                            border.color: Style.hairlineBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "СВЕДЕНИЯ ИЗ БДУ ФСТЭК"
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeHeadlineSm
                                    font.weight: Font.Bold
                                    color: Style.textPrimary
                                }
                                Item { Layout.fillWidth: true }
                                RiskBadge {
                                    level: root.currentItem ? root.currentItem.level : "Низкий"
                                }
                            }
                        }

                        // Содержимое карточки с прокруткой
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth

                            ColumnLayout {
                                width: parent.width
                                spacing: 12
                                anchors.margins: 10

                                Item { Layout.preferredHeight: 2 }

                                // Идентификаторы
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    color: Style.panelSurface
                                    border.color: Style.hairlineBorder
                                    border.width: 1
                                    implicitHeight: idCol.implicitHeight + 16

                                    ColumnLayout {
                                        id: idCol
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Идентификатор BDU:"; font.family: Style.fontSans; font.pixelSize: 11; color: Style.textSecondary }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: root.currentItem ? root.currentItem.id : "—"
                                                font.family: Style.fontMono
                                                font.pixelSize: 12
                                                font.weight: Font.Bold
                                                color: Style.textPrimary
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Связанные CVE:"; font.family: Style.fontSans; font.pixelSize: 11; color: Style.textSecondary }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: root.currentItem ? (root.currentItem.cve || "—") : "—"
                                                font.family: Style.fontMono
                                                font.pixelSize: 11
                                                color: Style.primary
                                                elide: Text.ElideRight
                                                Layout.maximumWidth: 220
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Дата выявления:"; font.family: Style.fontSans; font.pixelSize: 11; color: Style.textSecondary }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: root.currentItem ? (root.currentItem.identifyDate || "—") : "—"
                                                font.family: Style.fontMono
                                                font.pixelSize: 11
                                                color: Style.textSecondary
                                            }
                                        }
                                    }
                                }

                                // CVSS Оценка
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    color: Style.surfaceContainerHighest
                                    border.color: Style.hairlineBorder
                                    border.width: 1
                                    height: 52

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 10

                                        Rectangle {
                                            width: 36
                                            height: 36
                                            color: Style.getRiskColor(root.currentItem ? root.currentItem.level : "")
                                            Text {
                                                anchors.centerIn: parent
                                                text: root.currentItem && root.currentItem.cvss > 0 ? Number(root.currentItem.cvss).toFixed(1) : "—"
                                                font.family: Style.fontMono
                                                font.pixelSize: 13
                                                font.weight: Font.Bold
                                                color: Style.textOnDark
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                text: "Базовый балл CVSS v3.1 / 2.0"
                                                font.family: Style.fontSans
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                color: Style.textPrimary
                                            }
                                            Text {
                                                text: root.currentItem ? (root.currentItem.cvssVector || "Вектор не указан в источнике") : ""
                                                font.family: Style.fontMono
                                                font.pixelSize: 10
                                                color: Style.textSecondary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }
                                }

                                // Название и описание
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    color: Style.panelSurface
                                    border.color: Style.hairlineBorder
                                    border.width: 1
                                    implicitHeight: descCol.implicitHeight + 16

                                    ColumnLayout {
                                        id: descCol
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6

                                        Text {
                                            text: "Наименование уязвимости:"
                                            font.family: Style.fontSans
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                            color: Style.textSecondary
                                        }
                                        Text {
                                            text: root.currentItem ? root.currentItem.title : "—"
                                            font.family: Style.fontSans
                                            font.pixelSize: 11
                                            color: Style.textPrimary
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }

                                        Item { Layout.preferredHeight: 4 }

                                        Text {
                                            text: "Подробное описание:"
                                            font.family: Style.fontSans
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                            color: Style.textSecondary
                                        }
                                        Text {
                                            text: root.currentItem && root.currentItem.description ? root.currentItem.description : "Описание отсутствует"
                                            font.family: Style.fontSans
                                            font.pixelSize: 11
                                            color: Style.textPrimary
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                // Затронутое ПО и вендоры
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    color: Style.panelSurface
                                    border.color: Style.hairlineBorder
                                    border.width: 1
                                    implicitHeight: softCol.implicitHeight + 16

                                    ColumnLayout {
                                        id: softCol
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4

                                        Text {
                                            text: "Затронутое ПО / Вендоры:"
                                            font.family: Style.fontSans
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                            color: Style.textSecondary
                                        }
                                        Text {
                                            text: root.currentItem && (root.currentItem.software || root.currentItem.vendor)
                                                  ? (root.currentItem.vendor ? (root.currentItem.vendor + " — ") : "") + root.currentItem.software
                                                  : "Информация отсутствует"
                                            font.family: Style.fontMono
                                            font.pixelSize: 10
                                            color: Style.textPrimary
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                // Рекомендации по устранению
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    color: Style.panelSurface
                                    border.color: Style.hairlineBorder
                                    border.width: 1
                                    implicitHeight: solCol.implicitHeight + 16

                                    ColumnLayout {
                                        id: solCol
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4

                                        Text {
                                            text: "Рекомендации ФСТЭК по нейтрализации:"
                                            font.family: Style.fontSans
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                            color: Style.textSecondary
                                        }
                                        Text {
                                            text: root.currentItem && root.currentItem.solution ? root.currentItem.solution : "Информация об устранении не представлена"
                                            font.family: Style.fontSans
                                            font.pixelSize: 11
                                            color: Style.textPrimary
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                Item { Layout.preferredHeight: 6 }
                            }
                        }

                        // Футер с кнопкой импорта
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            color: Style.surfaceContainer
                            border.color: Style.hairlineBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Item { Layout.fillWidth: true }

                                AppButton {
                                    text: "Закрыть"
                                    onClicked: root.isOpen = false
                                }

                                AppButton {
                                    isPrimary: true
                                    enabled: root.currentItem !== null && !root.currentItem.alreadyImported
                                    text: {
                                        if (root.currentItem && root.currentItem.alreadyImported) {
                                            return "✓ Уже в проекте"
                                        }
                                        if (root.targetAssetId !== "") {
                                            return "+ Импортировать и привязать"
                                        }
                                        return "+ Импортировать в проект"
                                    }
                                    iconText: "↓"
                                    onClicked: root.importCurrent()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen
        onActivated: root.isOpen = false
    }
}
