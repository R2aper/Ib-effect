import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    // ---------- Справочники модели мер ----------
    readonly property var fstecClassesList: [
        "ЗИС.2 — Межсетевое экранирование",
        "УПД.3 — Управление доступом",
        "ИАФ.1 — Аутентификация",
        "АНЗ.1 — Анализ защищенности"
    ]
    readonly property var statusList: ["В плане", "Внедрено", "Тест"]

    // ---------- Колонки таблицы ----------
    readonly property var columns: [
        { key: "id",          title: "Код",                 min: 60,  align: Text.AlignLeft,    mono: true  },
        { key: "title",       title: "Наименование меры",   min: 150, align: Text.AlignLeft,    mono: false },
        { key: "tco",         title: "TCO (₽)",             min: 90,  align: Text.AlignRight,   mono: true  },
        { key: "vDiff",       title: "V до → пос",          min: 80,  align: Text.AlignHCenter, mono: true  },
        { key: "deltaV",      title: "ΔV (%)",              min: 65,  align: Text.AlignRight,   mono: true  },
        { key: "status",      title: "Статус",              min: 75,  align: Text.AlignHCenter, mono: false }
    ]
    readonly property var defaultColWidths: [70, 220, 100, 85, 70, 85]
    property var colWidths: [70, 220, 100, 85, 70, 85]
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

    // ---------- Данные из C++ RiskCalculator ----------
    property var measuresModel: (typeof riskCalculator !== "undefined") ? riskCalculator.measures : []

    Connections {
        target: (typeof riskCalculator !== "undefined") ? riskCalculator : null
        function onMeasuresChanged() {
            root.measuresModel = riskCalculator.measures
            root.rebuild()
            if (root.selectedId !== "") {
                var m = root.measureById(root.selectedId)
                if (m) {
                    root.draft = JSON.parse(JSON.stringify(m))
                    root.dirty = false
                    root.activateForm(true)
                }
            }
        }
    }

    // ---------- Состояние ----------
    property string searchText: ""
    property string statusFilter: "Все статусы"
    property int sortKeyIndex: 0          // по умолчанию по коду
    property bool sortDesc: false         // по возрастанию
    property var viewMeasures: []
    property string selectedId: ""
    property bool cardOpen: false
    property var draft: ({})
    property bool dirty: false

    function activateForm(act) {
        formLoader.active = false
        formLoader.active = act
    }

    // ---------- Вспомогательные функции ----------
    function measureById(id) {
        for (var i = 0; i < measuresModel.length; ++i)
            if (measuresModel[i].id === id) return measuresModel[i]
        return null
    }

    function sortValue(m, key) {
        switch (key) {
        case "id":     return m.id.toLowerCase()
        case "title":  return m.title.toLowerCase()
        case "tco":    return m.tcoNum
        case "vDiff":  return parseFloat(m.vRes)
        case "deltaV": return parseFloat(m.deltaV)
        case "status": return m.status.toLowerCase()
        }
        return 0
    }

    function rebuild() {
        var q = searchText.trim().toLowerCase()
        var list = measuresModel.filter(function (m) {
            if (statusFilter !== "Все статусы" && m.status !== statusFilter) return false
            if (q === "") return true
            return (m.id + " " + m.title + " " + m.targetVuln + " " + m.fstecClass).toLowerCase().indexOf(q) !== -1
        })
        var key = columns[sortKeyIndex].key
        var dir = sortDesc ? -1 : 1
        list.sort(function (a, b) {
            var va = sortValue(a, key), vb = sortValue(b, key)
            var c = (typeof va === "string") ? va.localeCompare(vb) : (va - vb)
            if (c === 0) return a.id.localeCompare(b.id)
            return c * dir
        })
        viewMeasures = list
    }

    function toggleSort(i) {
        if (sortKeyIndex === i) {
            sortDesc = !sortDesc
        } else {
            sortDesc = false
            sortKeyIndex = i
        }
    }

    function selectMeasure(id) {
        selectedId = id
        cardOpen = true
        resetDraft()
    }

    function resetDraft() {
        var m = measureById(selectedId)
        draft = m ? JSON.parse(JSON.stringify(m)) : ({})
        dirty = false
        activateForm(m !== null)
    }

    function saveDraft() {
        if (typeof riskCalculator !== "undefined" && root.draft.id) {
            riskCalculator.updateMeasure(draft)
        }
        var copy = measuresModel.slice()
        for (var i = 0; i < copy.length; ++i) {
            if (copy[i].id === draft.id) {
                copy[i] = JSON.parse(JSON.stringify(draft))
                break
            }
        }
        measuresModel = copy
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
    Component.onCompleted: {
        rebuild()
        resetDraft()
    }

    // =====================================================================
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ===================== Таблица =====================
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: 320
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // --- Toolbar ---
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
                            placeholderText: "Поиск защитной меры или сценария..."
                            isMonospace: false
                            onTextChanged: root.searchText = text
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 130
                            model: ["Все статусы", "В плане", "Внедрено", "Тест"]
                            currentIndex: 0
                            onCurrentIndexChanged: {
                                var statuses = ["Все статусы", "В плане", "Внедрено", "Тест"]
                                root.statusFilter = statuses[currentIndex]
                            }
                        }

                        AppButton {
                            isPrimary: true
                            text: "+ Мера"
                            onClicked: {
                                if (typeof riskCalculator !== "undefined") {
                                    var newM = riskCalculator.addMeasure({ title: "Новая защитная мера", costTCO: 300000 })
                                    root.selectMeasure(newM.id)
                                }
                            }
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
                                        anchors.rightMargin: 10
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
                            model: root.viewMeasures
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                id: row
                                readonly property var rowData: modelData
                                readonly property bool selected: root.selectedId === modelData.id

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

                                            // Поведение ячеек по типу колонки
                                            Loader {
                                                anchors.fill: parent
                                                anchors.leftMargin: 6
                                                anchors.rightMargin: 6
                                                sourceComponent: {
                                                    if (cell.col.key === "id") return idComp;
                                                    if (cell.col.key === "title") return titleComp;
                                                    if (cell.col.key === "tco") return tcoComp;
                                                    if (cell.col.key === "vDiff") return vDiffComp;
                                                    if (cell.col.key === "deltaV") return deltaVComp;
                                                    if (cell.col.key === "status") return statusComp;
                                                    return null;
                                                }
                                            }

                                            Component {
                                                id: idComp
                                                Text {
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: row.rowData.id
                                                    font.family: Style.fontMono
                                                    font.pixelSize: Style.fontSizeCodeSm
                                                    font.weight: Font.DemiBold
                                                    color: Style.textPrimary
                                                }
                                            }

                                            Component {
                                                id: titleComp
                                                ColumnLayout {
                                                    anchors.verticalCenter: parent.verticalCenter
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
                                                        text: row.rowData.targetVuln
                                                        font.family: Style.fontSans
                                                        font.pixelSize: 10
                                                        color: Style.textSecondary
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }
                                                }
                                            }

                                            Component {
                                                id: tcoComp
                                                Text {
                                                    verticalAlignment: Text.AlignVCenter
                                                    horizontalAlignment: Text.AlignRight
                                                    text: row.rowData.tco
                                                    font.family: Style.fontMono
                                                    font.pixelSize: Style.fontSizeCodeSm
                                                    color: Style.textPrimary
                                                }
                                            }

                                            Component {
                                                id: vDiffComp
                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 2
                                                    Text {
                                                        text: row.rowData.vBase
                                                        font.family: Style.fontMono
                                                        font.pixelSize: Style.fontSizeCodeSm
                                                        color: Style.getRiskColor(row.rowData.levelOld)
                                                    }
                                                    Text {
                                                        text: "→"
                                                        font.family: Style.fontSans
                                                        font.pixelSize: 10
                                                        color: Style.textSecondary
                                                    }
                                                    Text {
                                                        text: row.rowData.vRes
                                                        font.family: Style.fontMono
                                                        font.pixelSize: Style.fontSizeCodeSm
                                                        font.weight: Font.Bold
                                                        color: Style.getRiskColor(row.rowData.levelNew)
                                                    }
                                                }
                                            }

                                            Component {
                                                id: deltaVComp
                                                Text {
                                                    verticalAlignment: Text.AlignVCenter
                                                    horizontalAlignment: Text.AlignRight
                                                    text: row.rowData.deltaV
                                                    font.family: Style.fontMono
                                                    font.pixelSize: Style.fontSizeCodeSm
                                                    font.weight: Font.DemiBold
                                                    color: Style.textPrimary
                                                }
                                            }



                                            Component {
                                                id: statusComp
 Text {
                                                    verticalAlignment: Text.AlignVCenter
                                                    horizontalAlignment: Text.AlignRight
                                                    text: row.rowData.status
                                                    font.family: Style.fontMono
                                                    font.pixelSize: Style.fontSizeCodeSm
                                                    font.weight: Font.DemiBold
                                                    color: Style.textPrimary
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectMeasure(modelData.id)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.viewMeasures.length === 0
                                text: root.measuresModel.length === 0
                                      ? "Меры защиты еще не добавлены. Нажмите «+ Добавить меру»."
                                      : "Меры не найдены"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodyMd
                                color: Style.textMuted
                            }
                        }
                    }
                }

                // --- Итоги ---
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
                            text: root.measuresModel.length > 0
                                  ? ("Всего мер: " + root.measuresModel.length + " • TCO: " + (typeof riskCalculator !== "undefined" ? riskCalculator.formatRub(riskCalculator.totalTco) : "—"))
                                  : "Меры защиты не добавлены"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Метод: п. 22, 25 ФСТЭК"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textPrimary
                        }
                    }
                }
            }
        }

        // ===================== Граница-переключатель таблица | карточка =====================
        Rectangle {
            id: edgeToggle
            visible: root.selectedId !== ""
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

        // ===================== Карточка инспектора (анимированная ширина) =====================
        Item {
            id: cardWrap
            Layout.fillHeight: true
            Layout.preferredWidth: root.cardOpen && root.selectedId !== "" ? root.cardWidth : 0
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

                            Rectangle {
                                height: 22
                                implicitWidth: badgeText.implicitWidth + 12
                                color: Style.primary
                                Text {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: root.draft.id || ""
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeCodeSm
                                    font.weight: Font.Bold
                                    color: Style.textOnPrimary
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.draft.title || ""
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeHeadlineSm
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                                elide: Text.ElideRight
                            }

                            RiskBadge {
                                level: root.draft.levelOld || "Высокий"
                                text: (root.draft.levelOld ? root.draft.levelOld.toUpperCase() : "") + " ДО"
                                compact: true
                            }
                            Text { text: "→"; font.family: Style.fontSans; color: Style.textSecondary }
                            RiskBadge {
                                level: root.draft.levelNew || "Низкий"
                                text: (root.draft.levelNew ? root.draft.levelNew.toUpperCase() : "") + " ПОСЛЕ"
                                compact: true
                            }
                        }
                    }

                    // --- Форма инспектора ---
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

                    // --- Футер: ROSI + действия ---
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
                                text: "ROSI: " + (root.draft.rosi || "-")
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeMd
                                font.weight: Font.Bold
                                color: Style.riskLowText
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
                                    if (typeof riskCalculator !== "undefined" && root.selectedId !== "") {
                                        riskCalculator.deleteMeasure(root.selectedId)
                                        root.selectedId = ""
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
                                text: "Сохранить меру"
                                iconText: "✓"
                                shortcutText: "Ctrl+S"
                                enabled: root.selectedId !== ""
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
        enabled: root.cardOpen && root.selectedId !== ""
        onActivated: root.saveDraft()
    }

    // ---------- Содержимое формы ----------
    Component {
        id: formComponent

        ColumnLayout {
            spacing: 12

            Item { Layout.preferredHeight: 2 }

            // Group 1: Общие параметры и стоимость владения
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
                            text: "1. ОБЩИЕ ПАРАМЕТРЫ И TCO"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Формуляр СЗИ"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    Text { text: "Защищаемый актив:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                    CustomComboBox {
                        Layout.fillWidth: true
                        model: {
                            if (typeof riskCalculator === "undefined") return []
                            var arr = []
                            var allA = riskCalculator.assets
                            for (var i = 0; i < allA.length; ++i) {
                                arr.push(allA[i].id + " — " + allA[i].primaryAssetName)
                            }
                            return arr.length > 0 ? arr : ["(Нет активов)"]
                        }
                        currentIndex: {
                            if (typeof riskCalculator === "undefined") return 0
                            var allA = riskCalculator.assets
                            for (var i = 0; i < allA.length; ++i) {
                                if (allA[i].id === root.draft.asset || allA[i].primaryAssetName === root.draft.asset) return i
                            }
                            return 0
                        }
                        onCurrentIndexChanged: {
                            if (typeof riskCalculator !== "undefined") {
                                var allA = riskCalculator.assets
                                if (currentIndex >= 0 && currentIndex < allA.length) {
                                    if (root.draft.asset !== allA[currentIndex].id) {
                                        root.setDraft("asset", allA[currentIndex].id)
                                    }
                                }
                            }
                        }
                    }

                    Text { text: "Целевая уязвимость / сценарий угрозы:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                    CustomComboBox {
                        Layout.fillWidth: true
                        model: {
                            if (typeof riskCalculator === "undefined") return []
                            var arr = []
                            var allV = riskCalculator.vulnerabilities
                            for (var i = 0; i < allV.length; ++i) {
                                arr.push(allV[i].id + " — " + allV[i].title)
                            }
                            return arr.length > 0 ? arr : ["(Нет угроз)"]
                        }
                        currentIndex: {
                            if (typeof riskCalculator === "undefined") return 0
                            var allV = riskCalculator.vulnerabilities
                            for (var i = 0; i < allV.length; ++i) {
                                if (allV[i].id === root.draft.targetVuln || allV[i].title === root.draft.targetVuln) return i
                            }
                            return 0
                        }
                        onCurrentIndexChanged: {
                            if (typeof riskCalculator !== "undefined") {
                                var allV = riskCalculator.vulnerabilities
                                if (currentIndex >= 0 && currentIndex < allV.length) {
                                    if (root.draft.targetVuln !== allV[currentIndex].id) {
                                        root.setDraft("targetVuln", allV[currentIndex].id)
                                    }
                                }
                            }
                        }
                    }

                    Text { text: "Наименование меры защиты (п. 22, 25 ФСТЭК 2025):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                    CustomTextField {
                        Layout.fillWidth: true
                        text: root.draft.title || ""
                        isMonospace: false
                        onTextChanged: if (text !== root.draft.title) root.setDraft("title", text)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { text: "Класс меры по ФСТЭК №239:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            CustomComboBox {
                                Layout.fillWidth: true
                                model: root.fstecClassesList
                                currentIndex: Math.max(0, root.fstecClassesList.indexOf(root.draft.fstecClass))
                                onCurrentIndexChanged: {
                                    if (currentIndex >= 0 && root.fstecClassesList[currentIndex] !== root.draft.fstecClass)
                                        root.setDraft("fstecClass", root.fstecClassesList[currentIndex])
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.preferredWidth: 125
                            Text { text: "Статус меры:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            CustomComboBox {
                                Layout.fillWidth: true
                                model: root.statusList
                                currentIndex: Math.max(0, root.statusList.indexOf(root.draft.status))
                                onCurrentIndexChanged: {
                                    if (currentIndex >= 0 && root.statusList[currentIndex] !== root.draft.status)
                                        root.setDraft("status", root.statusList[currentIndex])
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.preferredWidth: 140
                            Text { text: "TCO в год (₽):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            CustomTextField {
                                Layout.fillWidth: true
                                suffixText: "₽"
                                text: root.draft.costTCO !== undefined ? Math.round(root.draft.costTCO).toString() : (root.draft.tcoNum !== undefined ? Math.round(root.draft.tcoNum).toString() : (root.draft.tco || "300000"))
                                onTextChanged: {
                                    var num = parseFloat(text.replace(/[^\d.-]/g, "")) || 0
                                    if (num !== root.draft.costTCO) {
                                        root.setDraft("costTCO", num)
                                        root.setDraft("tcoNum", num)
                                        root.setDraft("tco", text)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Group 2: Объективное изменение параметров по Таблице 1 ФСТЭК 2025
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
                            text: "2. СНИЖЕНИЕ ПАРАМЕТРОВ ИНФРАСТРУКТУРЫ"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Таблица 1 ФСТЭК 2025"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            color: Style.textSecondary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Новая доля уязвимых узлов (NewShare):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                        Item { Layout.fillWidth: true }
                        Text { text: "Было: " + (root.draft.oldShare || "не задано"); font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                    }
                    CustomComboBox {
                        Layout.fillWidth: true
                        model: [
                            "Более 70% компонентов (l·L = 0.20)",
                            "От 50% до 70% компонентов (l·L = 0.16)",
                            "От 10% до 50% компонентов (l·L = 0.12)",
                            "Менее 10% компонентов (l·L = 0.10) [Патчинг / изоляция]"
                        ]
                        currentIndex: root.draft.newShare !== undefined ? root.draft.newShare : 3
                        onCurrentIndexChanged: {
                            if (currentIndex !== root.draft.newShare) {
                                root.setDraft("newShare", currentIndex)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Защищенность периметра (NewPerimeter):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                        Item { Layout.fillWidth: true }
                        Text { text: "Было: " + (root.draft.oldPerimeter || "не задано"); font.family: Style.fontMono; font.pixelSize: 10; color: Style.textSecondary }
                    }
                    SegmentedControl {
                        Layout.fillWidth: true
                        items: [
                            "Доступно из Интернет (0.33)",
                            "Недоступно из Интернет (0.18)"
                        ]
                        currentIndex: root.draft.newPerimeter !== undefined ? root.draft.newPerimeter : 1
                        onCurrentIndexChanged: {
                            if (currentIndex !== root.draft.newPerimeter) {
                                root.setDraft("newPerimeter", currentIndex)
                            }
                        }
                    }
                }
            }

            // Group 3: Экономический прогноз (ROSI Framework)
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
                            text: "3. ЭФФЕКТИВНОСТЬ МЕРЫ (ROSI FRAMEWORK)"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "ENISA / ISO 27005"
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
                            height: 54
                            color: Style.panelSurface
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text { text: "Предотвращенный ущерб:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                Text {
                                    text: root.draft.deltaAle || ""
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeBodySm
                                    font.weight: Font.Bold
                                    color: Style.textPrimary
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 54
                            color: Style.panelSurface
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text { text: "Чистая выгода:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                Text {
                                    text: root.draft.netBenefit || ""
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeBodySm
                                    font.weight: Font.Bold
                                    color: Style.textPrimary
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 54
                            color: Style.panelSurface
                            border.color: Style.hairlineBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text { text: "Net ROSI:"; font.family: Style.fontSans; font.pixelSize: 10; color: Style.textSecondary }
                                Text {
                                    text: root.draft.rosi || ""
                                    font.family: Style.fontMono
                                    font.pixelSize: Style.fontSizeHeadlineSm
                                    font.weight: Font.Bold
                                    color: Style.riskLowText
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
