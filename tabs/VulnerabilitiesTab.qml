import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    property int selectedIndex: 0
    signal openCvssCalculator(string id, string vector, double score)

    // ---------- Данные из C++ RiskCalculator ----------
    property var vulnModel: (typeof riskCalculator !== "undefined") ? riskCalculator.vulnerabilities : []

    Connections {
        target: (typeof riskCalculator !== "undefined") ? riskCalculator : null
        function onVulnerabilitiesChanged() {
            root.vulnModel = riskCalculator.vulnerabilities
            root.rebuild()
            root.resetDraft()
        }
    }

    readonly property var currentVuln: vulnModel[selectedIndex] !== undefined ? vulnModel[selectedIndex] : ({})

    // ---------- Конфигурация колонок таблицы (как в AssetsTab) ----------
    readonly property var columns: [
        { key: "id",     title: "Код / BDU",       min: 90,  align: Text.AlignLeft,   mono: true  },
        { key: "title",  title: "Сценарий угрозы", min: 180, align: Text.AlignLeft,   mono: false },
        { key: "cvss",   title: "CVSS",            min: 50,  align: Text.AlignHCenter,mono: true  },
        { key: "eVal",   title: "I_at",            min: 50,  align: Text.AlignRight,  mono: true  },
        { key: "hVal",   title: "I_imp",           min: 50,  align: Text.AlignRight,  mono: true  },
        { key: "vBase",  title: "V_base",          min: 60,  align: Text.AlignRight,  mono: true  },
        { key: "level",  title: "Критичность",     min: 90,  align: Text.AlignHCenter,mono: false },
        { key: "status", title: "Статус",          min: 70,  align: Text.AlignHCenter,mono: false }
    ]
    readonly property var defaultColWidths: [110, 260, 60, 60, 60, 70, 100, 80]
    property var colWidths: [110, 260, 60, 60, 60, 70, 100, 80]
    readonly property real totalColsWidth: {
        var s = 0
        for (var i = 0; i < colWidths.length; ++i) s += colWidths[i]
        return s
    }
    readonly property int rowHeight: 34
    readonly property int headerHeight: 28
    readonly property int cardWidth: 460

    function setColWidth(i, w) {
        var a = colWidths.slice()
        a[i] = Math.max(columns[i].min, Math.round(w))
        colWidths = a
    }
    function resetColWidth(i) { setColWidth(i, defaultColWidths[i]) }

    // ---------- Состояние интерфейса ----------
    property string searchText: ""
    property string statusFilter: "Все статусы"
    property int sortKeyIndex: 5          // По умолчанию V_base
    property bool sortDesc: true          // По убыванию
    property var viewVulns: []
    property bool cardOpen: true
    property var draft: ({})
    property bool dirty: false

    // Вспомогательные ранги для сортировки уровней рисков
    function riskRank(level) {
        return { "Критический": 3, "Высокий": 2, "Средний": 1, "Низкий": 0 }[level] || 0
    }

    function cellText(v, key) {
        switch (key) {
        case "id":     return v.id
        case "title":  return v.title
        case "cvss":   return v.cvss
        case "eVal":   return v.eVal
        case "hVal":   return v.hVal
        case "vBase":  return v.vBase
        case "level":  return v.level
        case "status": return v.status
        }
        return ""
    }

    function sortValue(v, key) {
        switch (key) {
        case "id":     return v.id.toLowerCase()
        case "title":  return v.title.toLowerCase()
        case "cvss":   return parseFloat(v.cvss) || 0
        case "eVal":   return parseFloat(v.eVal) || 0
        case "hVal":   return parseFloat(v.hVal) || 0
        case "vBase":  return parseFloat(v.vBase) || 0
        case "level":  return riskRank(v.level)
        case "status": return v.status.toLowerCase()
        }
        return 0
    }

    function rebuild() {
        var q = searchText.trim().toLowerCase()
        var list = vulnModel.filter(function (v) {
            // Фильтр по статусу/критичности из комбобокса
            if (statusFilter === "Открыта" && v.status !== "Открыта") return false
            if (statusFilter === "В работе" && v.status !== "В работе") return false
            if (statusFilter === "Критические" && v.level !== "Критический") return false
            if (statusFilter === "Высокие" && v.level !== "Высокий") return false

            if (q === "") return true
            return (v.id + " " + v.cve + " " + v.title + " " + v.desc).toLowerCase().indexOf(q) !== -1
        })

        var key = columns[sortKeyIndex].key
        var dir = sortDesc ? -1 : 1
        list.sort(function (a, b) {
            var va = sortValue(a, key), vb = sortValue(b, key)
            var c = (typeof va === "string") ? va.localeCompare(vb) : (va - vb)
            if (c === 0) return a.id.localeCompare(b.id)
            return c * dir
        })
        viewVulns = list
    }

    function toggleSort(i) {
        if (sortKeyIndex === i) {
            sortDesc = !sortDesc
        } else {
            sortDesc = false
            sortKeyIndex = i
        }
    }

    function selectVuln(indexInModel) {
        var changed = (indexInModel !== root.selectedIndex)
        root.selectedIndex = indexInModel
        cardOpen = true
        if (changed) resetDraft()
    }

    function resetDraft() {
        var v = root.currentVuln
        draft = v ? JSON.parse(JSON.stringify(v)) : ({})
        dirty = false
        formLoader.active = false
        formLoader.active = (v !== null && root.vulnModel.length > 0)
    }

    function saveDraft() {
        if (typeof riskCalculator !== "undefined" && root.draft.id) {
            riskCalculator.updateVulnerability(draft)
        }
        var copy = vulnModel.slice()
        if (root.selectedIndex >= 0 && root.selectedIndex < copy.length) {
            copy[root.selectedIndex] = JSON.parse(JSON.stringify(draft))
        }
        vulnModel = copy
        rebuild()
        dirty = false
    }

    function setDraft(key, value) {
        var d = draft
        d[key] = value
        draft = d
        dirty = true
    }

    onSearchTextChanged: rebuild()
    onStatusFilterChanged: rebuild()
    onSortKeyIndexChanged: rebuild()
    onSortDescChanged: rebuild()
    onSelectedIndexChanged: resetDraft()
    Component.onCompleted: {
        rebuild()
        resetDraft()
    }

    // =====================================================================
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ===================== Таблица (Master Pane) =====================
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: 300
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // --- Header Toolbar ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        CustomTextField {
                            Layout.fillWidth: true
                            placeholderText: "Поиск BDU, CVE или тактики..."
                            isMonospace: false
                            onTextChanged: root.searchText = text
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 130
                            model: ["Все статусы", "Открыта", "В работе", "Критические", "Высокие"]
                            onCurrentIndexChanged: root.statusFilter = model[currentIndex]
                        }

                        Text {
                            text: "Сортировка:"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodySm
                            color: Style.textSecondary
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 140
                            model: root.columns.map(function (c) { return c.title })
                            currentIndex: root.sortKeyIndex
                            onCurrentIndexChanged: root.sortKeyIndex = currentIndex
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 140
                            model: ["По возрастанию ↑", "По убыванию ↓"]
                            currentIndex: root.sortDesc ? 1 : 0
                            onCurrentIndexChanged: root.sortDesc = (currentIndex === 1)
                        }

                        AppButton {
                            isPrimary: true
                            text: "+ Угроза"
                            onClicked: {
                                if (typeof riskCalculator !== "undefined") {
                                    var newV = riskCalculator.addVulnerability({ title: "Новый сценарий угрозы безопасности", cvss: 7.5 })
                                    root.selectedIndex = root.vulnModel.length - 1
                                    root.selectVuln(root.selectedIndex)
                                }
                            }
                        }

                        AppButton {
                            text: "Импорт БДУ"
                            iconText: "↓"
                            onClicked: window.openBdu()
                        }
                    }
                }

                // --- Сетка: заголовок + строки, горизонтальная прокрутка ---
                Flickable {
                    id: hFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: Math.max(width, root.totalColsWidth)
                    contentHeight: height
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                    Item {
                        width: hFlick.contentWidth
                        height: hFlick.height

                        // ----- Заголовок колонок -----
                        Row {
                            id: headerRow
                            height: root.headerHeight
                            z: 2

                            Repeater {
                                model: root.columns
                                delegate: Rectangle {
                                    id: hCell
                                    width: root.colWidths[index]
                                    height: root.headerHeight
                                    color: hMouse.containsMouse ? Style.surfaceHover : Style.surfaceContainer
                                    border.color: Style.hairlineBorder
                                    border.width: 1

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 6
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: modelData.align
                                        elide: Text.ElideRight
                                        text: modelData.title + (root.sortKeyIndex === index
                                                                 ? (root.sortDesc ? "  ▼" : "  ▲") : "")
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }

                                    MouseArea {
                                        id: hMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleSort(index)
                                    }

                                    // Ручка изменения ширины
                                    Item {
                                        id: grip
                                        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                                        width: 8
                                        z: 5
                                        property real pressX: 0
                                        property real pressW: 0

                                        Rectangle {
                                            anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                                            width: gripMouse.containsMouse || gripMouse.pressed ? 3 : 0
                                            color: Style.primary
                                        }
                                        MouseArea {
                                            id: gripMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.SizeHorCursor
                                            preventStealing: true
                                            onPressed: function (m) {
                                                grip.pressX = mapToItem(headerRow, m.x, 0).x
                                                grip.pressW = root.colWidths[index]
                                            }
                                            onPositionChanged: function (m) {
                                                if (!pressed) return
                                                var x = mapToItem(headerRow, m.x, 0).x
                                                root.setColWidth(index, grip.pressW + (x - grip.pressX))
                                            }
                                            onDoubleClicked: root.resetColWidth(index)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: Math.max(0, hFlick.contentWidth - root.totalColsWidth)
                                height: root.headerHeight
                                color: Style.surfaceContainer
                                border.color: Style.hairlineBorder
                                border.width: 1
                                visible: width > 0
                            }
                        }

                        // ----- Строки -----
                        ListView {
                            id: listView
                            anchors { top: headerRow.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
                            clip: true
                            model: root.viewVulns
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                id: row
                                readonly property var rowData: modelData
                                // Поиск оригинального индекса в vulnModel
                                readonly property int origIndex: {
                                    for (var i = 0; i < root.vulnModel.length; ++i) {
                                        if (root.vulnModel[i].id === modelData.id) return i
                                    }
                                    return -1
                                }
                                readonly property bool selected: root.selectedIndex === origIndex

                                width: listView.width
                                height: root.rowHeight
                                color: {
                                    if (selected) return Style.surfaceActive
                                    if (rowMouse.containsMouse) return Style.surfaceHover
                                    return (index % 2 === 0) ? Style.panelSurface : Style.surfaceLow
                                }

                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: 1
                                    color: Style.hairlineBorder
                                }

                                Rectangle {
                                    visible: row.selected
                                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                    width: 3
                                    color: Style.primary
                                    z: 3
                                }

                                Row {
                                    anchors { top: parent.top; bottom: parent.bottom }

                                    Repeater {
                                        model: root.columns
                                        delegate: Item {
                                            id: cell
                                            readonly property var col: modelData
                                            width: root.colWidths[index]
                                            height: root.rowHeight

                                            Rectangle {
                                                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                                                width: 1
                                                color: Style.hairlineBorder
                                            }

                                            // Если сценарий (title), выводим название + CVE в две строки
                                            ColumnLayout {
                                                visible: cell.col.key === "title"
                                                anchors.fill: parent
                                                anchors.leftMargin: 6; anchors.rightMargin: 6
                                                spacing: 0

                                                Text {
                                                    text: row.rowData.title
                                                    font.family: Style.fontSans
                                                    font.pixelSize: Style.fontSizeBodySm
                                                    font.weight: Font.DemiBold
                                                    color: Style.textPrimary
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Text {
                                                    text: row.rowData.cve
                                                    font.family: Style.fontMono
                                                    font.pixelSize: 10
                                                    color: Style.textSecondary
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            // Текстовая ячейка для обычных данных
                                            Text {
                                                visible: cell.col.key !== "title" && cell.col.key !== "level" && cell.col.key !== "status"
                                                anchors {
                                                    left: parent.left; right: parent.right
                                                    leftMargin: 6; rightMargin: 6
                                                    verticalCenter: parent.verticalCenter
                                                }
                                                horizontalAlignment: cell.col.align
                                                elide: Text.ElideRight
                                                text: root.cellText(row.rowData, cell.col.key)
                                                font.family: cell.col.mono ? Style.fontMono : Style.fontSans
                                                font.pixelSize: cell.col.mono ? Style.fontSizeCodeSm : Style.fontSizeBodySm
                                                font.weight: (cell.col.key === "id" || cell.col.key === "cvss" || cell.col.key === "vBase")
                                                             ? Font.Bold : Font.Normal
                                                color: cell.col.key === "vBase" ? Style.getRiskColor(row.rowData.level) : Style.textPrimary
                                            }

                                            // Бейдж критичности
                                            RiskBadge {
                                                visible: cell.col.key === "level"
                                                anchors.centerIn: parent
                                                level: row.rowData.level
                                                compact: true
                                            }

                                            // Статус
                                            Text {
                                                visible: cell.col.key === "status"
                                                anchors.centerIn: parent
                                                text: row.rowData.status
                                                font.family: Style.fontSans
                                                font.pixelSize: 10
                                                color: (row.rowData.status === "Открыта") ? Style.riskCriticalText : Style.textSecondary
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectVuln(row.origIndex)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.viewVulns.length === 0
                                text: root.vulnModel.length === 0
                                      ? "Уязвимости еще не добавлены. Нажмите «Импорт БДУ» или «+ Уязвимость»."
                                      : "Уязвимости не найдены"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodyMd
                                color: Style.textMuted
                            }
                        }
                    }
                }

                // --- Итоги таблицы ---
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
                            text: "Формула: V = I_cvss × I_infr × (I_at + I_imp) • Методика ФСТЭК 2025"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Уязвимостей: " + root.viewVulns.length + " из " + root.vulnModel.length
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textPrimary
                        }
                    }
                }
            }
        }

        // ===================== Переключатель видимости инспектора =====================
        Rectangle {
            id: edgeToggle
            visible: root.vulnModel.length > 0
            Layout.fillHeight: true
            Layout.preferredWidth: 16
            color: edgeMouse.containsMouse ? Style.surfaceHover : Style.surfaceContainer
            border.color: Style.hairlineBorder
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: root.cardOpen ? "›" : "‹"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: edgeMouse.containsMouse ? Style.textPrimary : Style.textSecondary
            }
            MouseArea {
                id: edgeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cardOpen = !root.cardOpen
            }
        }

        // ===================== Карточка инспектора уязвимостей =====================
        Item {
            id: cardWrap
            Layout.fillHeight: true
            Layout.preferredWidth: root.cardOpen && root.vulnModel.length > 0 ? root.cardWidth : 0
            visible: Layout.preferredWidth > 0 || cardAnim.running
            clip: true

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    id: cardAnim
                    duration: 260
                    easing.type: Easing.InOutCubic
                }
            }

            Rectangle {
                id: card
                width: root.cardWidth
                anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                color: Style.panelSurface
                border.color: Style.hairlineBorder
                border.width: 1
                opacity: Math.min(1, cardWrap.width / (root.cardWidth * 0.6))

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // --- Шапка карточки ---
                    Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        color: Style.surfaceContainer
                        border.color: Style.hairlineBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8


                            Text {
                                text: root.draft.title || ""
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeHeadlineSm
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RiskBadge {
                                level: root.draft.level || "Низкий"
                            }
                        }
                    }

                    // --- Выпадающая форма / Лоадер ---
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: availableWidth

                        Loader {
                            id: formLoader
                            width: parent.width
                            active: false
                            sourceComponent: formComponent
                        }
                    }

                    // --- Футер действия ---
                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        color: Style.surfaceContainer
                        border.color: Style.hairlineBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "V_base: " + (root.draft.vBase || "-") + " (" + (root.draft.level || "") + ")"
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeMd
                                font.weight: Font.Bold
                                color: Style.getRiskColor(root.draft.level || "")
                            }

                            Text {
                                visible: root.dirty
                                text: "● не сохранено"
                                font.family: Style.fontSans
                                font.pixelSize: 10
                                color: Style.textSecondary
                            }

                            Item { Layout.fillWidth: true }

                            AppButton {
                                text: "Удалить"
                                onClicked: {
                                    if (typeof riskCalculator !== "undefined" && root.draft.id) {
                                        riskCalculator.deleteVulnerability(root.draft.id)
                                        root.selectedIndex = 0
                                        root.cardOpen = false
                                    }
                                }
                            }

                            AppButton {
                                text: "Отмена"
                                enabled: root.dirty
                                onClicked: root.resetDraft()
                            }

                            AppButton {
                                isPrimary: true
                                text: "Сохранить"
                                iconText: "✓"
                                shortcutText: "Ctrl+S"
                                enabled: root.dirty
                                onClicked: root.saveDraft()
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+S"
        enabled: root.cardOpen && root.dirty
        onActivated: root.saveDraft()
    }

    // ---------- Форма инспектора уязвимости ----------
    Component {
        id: formComponent

        ColumnLayout {
            spacing: 12

            Item { Layout.preferredHeight: 2 }

            // Переключатель источника
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                height: 32
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                SegmentedControl {
                    anchors.fill: parent
                    anchors.margins: 2
                    items: [
                        "Найдено в БДУ ФСТЭК",
                        "Собственный сценарий УБИ (п. 5.3.3)"
                    ]
                    currentIndex: root.draft.fromBdu ? 0 : 1
                    onCurrentIndexChanged: {
                        var b = (currentIndex === 0)
                        if (b !== root.draft.fromBdu) root.setDraft("fromBdu", b)
                    }
                }
            }

            // Group 1: Основные атрибуты
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: g1Col.implicitHeight + 20
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g1Col
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "1. ОСНОВНЫЕ АТРИБУТЫ СЦЕНАРИЯ"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Спецификация БДУ"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { text: "Код в БДУ ФСТЭК:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            CustomTextField {
                                Layout.fillWidth: true
                                text: root.draft.id || ""
                                isMonospace: true
                                onTextChanged: if (text !== root.draft.id) root.setDraft("id", text)
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { text: "Связанный CVE / Тактика:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            CustomTextField {
                                Layout.fillWidth: true
                                text: root.draft.cve || ""
                                isMonospace: true
                                onTextChanged: if (text !== root.draft.cve) root.setDraft("cve", text)
                            }
                        }
                    }

                    Text { text: "Описание механизма реализации угрозы:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 56
                        color: Style.panelSurface
                        border.color: Style.hairlineBorder
                        border.width: 1

                        TextEdit {
                            anchors.fill: parent
                            anchors.margins: 6
                            text: root.draft.desc || ""
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodySm
                            color: Style.textPrimary
                            wrapMode: TextEdit.WordWrap
                            selectByMouse: true
                            onTextChanged: if (text !== root.draft.desc) root.setDraft("desc", text)
                        }
                    }

                    // CVSS v3.1 Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: !root.draft.fromBdu ? 92 : 50
                        color: Style.surfaceContainerHighest
                        border.color: Style.hairlineBorder
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 34
                                    height: 34
                                    color: Style.primary
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.draft.cvss !== undefined && root.draft.cvss !== null
                                              ? Number(root.draft.cvss).toFixed(1) : "-"
                                        font.family: Style.fontMono
                                        font.pixelSize: Style.fontSizeCodeMd
                                        font.weight: Font.Bold
                                        color: Style.textOnPrimary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Базовый балл CVSS v3.1 (I_cvss)"
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Text {
                                        text: root.draft.vector || ""
                                        font.family: Style.fontMono
                                        font.pixelSize: 10
                                        color: Style.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                AppButton {
                                    visible: !root.draft.fromBdu
                                    text: "Калькулятор"
                                    iconText: "↗"
                                    onClicked: root.openCvssCalculator(
                                        root.draft.id || "",
                                        root.draft.vector || "",
                                        Number(root.draft.cvss || 0)
                                    )
                                }
                            }

                            RowLayout {
                                visible: !root.draft.fromBdu
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: "Балл:"
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodySm
                                    color: Style.textSecondary
                                }
                                CustomTextField {
                                    Layout.preferredWidth: 90
                                    text: root.draft.cvss !== undefined && root.draft.cvss !== null
                                          ? String(root.draft.cvss) : ""
                                    isMonospace: true
                                    onTextChanged: {
                                        var v = parseFloat(text)
                                        if (!isNaN(v) && v >= 0 && v <= 10) {
                                            if (v !== root.draft.cvss) root.setDraft("cvss", v)
                                        }
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }

            // Group 2: Факторы методики ФСТЭК 2025
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: g2Col.implicitHeight + 20
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g2Col
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "2. ФАКТОРЫ МЕТОДИКИ ФСТЭК 2025"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Таблица 1 ФСТЭК"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Статус эксплуатации (E → I_at):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                        Item { Layout.fillWidth: true }
                        Text { text: "I_at = " + (root.draft.eVal || ""); font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                    }
                    SegmentedControl {
                        Layout.fillWidth: true
                        items: [
                            "Реальные атаки (0.60)",
                            "Есть эксплойт (0.30)",
                            "Нет сведений (0.10)"
                        ]
                        currentIndex: (root.draft.eVal === "0.60") ? 0 : ((root.draft.eVal === "0.30") ? 1 : 2)
                        onCurrentIndexChanged: {
                            var vals = ["0.60", "0.30", "0.10"]
                            var statuses = ["Реальные атаки (0.60)", "Есть эксплойт (0.30)", "Нет сведений (0.10)"]
                            if (vals[currentIndex] !== root.draft.eVal) {
                                root.setDraft("eVal", vals[currentIndex])
                                root.setDraft("eStatus", statuses[currentIndex])
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Тяжесть последствий (H → I_imp):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                        Item { Layout.fillWidth: true }
                        Text { text: "I_imp = " + (root.draft.hVal || ""); font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary }
                    }
                    CustomComboBox {
                        Layout.fillWidth: true
                        model: [
                            "H_01: Полное нарушение К, Ц, Д критических процессов (0.50)",
                            "H_02: Существенный сбой сервисов обработки платежей (0.40)",
                            "H_03: Локальное нарушение доступности второстепенных узлов (0.34)",
                            "H_04: Утечка сведений коммерческой тайны и ноу-хау (0.30)",
                            "H_05: Несанкционированная модификация конфигураций (0.26)",
                            "H_06: Временная деградация производительности кластера (0.22)",
                            "H_07: Единичные сбои и отказы клиентских коннектов (0.20)",
                            "H_08: Незначительное влияние без остановки функционала (0.18)",
                            "H_09: Нарушение вспомогательных сервисов логирования (0.12)",
                            "H_10: Минимальное локальное воздействие (0.10)"
                        ]
                        currentIndex: {
                            var h = root.draft.hVal
                            if (h === "0.50") return 0
                            if (h === "0.40") return 1
                            if (h === "0.34") return 2
                            if (h === "0.30") return 3
                            if (h === "0.26") return 4
                            if (h === "0.22") return 5
                            if (h === "0.20") return 6
                            if (h === "0.18") return 7
                            if (h === "0.12") return 8
                            if (h === "0.10") return 9
                            return 0
                        }
                        onCurrentIndexChanged: {
                            var hVals = ["0.50", "0.40", "0.34", "0.30", "0.26", "0.22", "0.20", "0.18", "0.12", "0.10"]
                            if (hVals[currentIndex] !== root.draft.hVal) {
                                root.setDraft("hVal", hVals[currentIndex])
                                root.setDraft("hStatus", model[currentIndex])
                            }
                        }
                    }
                }
            }

            // Group 3: Итоговый индекс
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: g3Col.implicitHeight + 20
                color: Style.surfaceContainerHighest
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g3Col
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "3. ИТОГОВЫЙ ИНДЕКС КРИТИЧНОСТИ V И СРОК УСТРАНЕНИЯ"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "п. 18, 21 ФСТЭК"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            color: Style.panelSurface
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text { text: "Базовый индекс V:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                Text {
                                    text: root.draft.vBase || ""
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeMetricDisplay
                                    font.weight: Font.Bold
                                    color: Style.getRiskColor(root.draft.level || "")
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            color: Style.panelSurface
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text { text: "Уровень Таблицы 2:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                RiskBadge {
                                    level: root.draft.level || "Низкий"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            color: Style.panelSurface
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text { text: "Нормативный SLA:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                Text {
                                    text: root.draft.sla || ""
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeHeadlineSm
                                    font.weight: Font.Bold
                                    color: Style.textPrimary
                                }
                            }
                        }
                    }
                }
            }

            // Group 4: Сведения из БДУ ФСТЭК (если FromBDU=true)
            Rectangle {
                visible: !!root.draft.fromBdu && (!!root.draft.software || !!root.draft.solution || !!root.draft.vendor)
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: g4Col.implicitHeight + 20
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g4Col
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "4. КАРТОЧКА БДУ ФСТЭК РОССИИ"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Реестр ФСТЭК РФ"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.riskLowText
                        }
                    }

                    ColumnLayout {
                        visible: !!root.draft.software || !!root.draft.vendor
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Затронутое ПО / Вендоры:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                        Text {
                            text: (root.draft.vendor ? (root.draft.vendor + " — ") : "") + (root.draft.software || "")
                            font.family: Style.fontMono
                            font.pixelSize: 11
                            color: Style.textPrimary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    ColumnLayout {
                        visible: !!root.draft.solution
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Рекомендации ФСТЭК по устранению:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                        Text {
                            text: root.draft.solution || ""
                            font.family: Style.fontSans
                            font.pixelSize: 11
                            color: Style.textPrimary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Group 5: Заметки
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: g5Col.implicitHeight + 20
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g5Col
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: "5. ЗАМЕТКИ"
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeHeadlineSm
                        font.weight: Font.DemiBold
                        color: Style.textPrimary
                    }

                    Text {
                        text: "Контекст, источники и решения для этого сценария:"
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeBodySm
                        color: Style.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 82
                        color: Style.panelSurface
                        border.color: Style.hairlineBorder
                        border.width: 1

                        TextEdit {
                            anchors.fill: parent
                            anchors.margins: 6
                            text: root.draft.notes || ""
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodySm
                            color: Style.textPrimary
                            wrapMode: TextEdit.WordWrap
                            selectByMouse: true
                            onTextChanged: if (text !== root.draft.notes) root.setDraft("notes", text)
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }

}
