import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    // ---------- Справочники модели риска (соответствуют RiskModel::*) ----------
    readonly property var componentTypes: [
        { name: "Важные бизнес-процессы", weight: 0.55 },
        { name: "Межсетевые экраны / шлюзы", weight: 0.45 },
        { name: "Телеком-оборудование", weight: 0.40 },
        { name: "Серверы (ЦВУ)", weight: 0.35 },
        { name: "Рабочие станции (АРМ)", weight: 0.25 },
        { name: "СХД", weight: 0.20 },
        { name: "Другие компоненты", weight: 0.05 }
    ]
    readonly property var shareLevels: [
        { name: "Более 70%",     weight: 0.20 },
        { name: "От 50% до 70%", weight: 0.16 },
        { name: "От 10% до 50%", weight: 0.12 },
        { name: "Менее 10%",     weight: 0.10 }
    ]
    readonly property var perimeterLevels: [
        { name: "Доступно из Интернет",   weight: 0.33 },
        { name: "Недоступно из Интернет", weight: 0.18 }
    ]

    // ---------- Колонки таблицы ----------
    readonly property var columns: [
        { key: "primary",    title: "Основной актив",        min: 120, align: Text.AlignLeft,   mono: false },
        { key: "supporting", title: "Вспомогательный актив", min: 100, align: Text.AlignLeft,   mono: true  },
        { key: "sle",        title: "SLE",                   min: 80,  align: Text.AlignRight,  mono: true  },
        { key: "measures",   title: "Привязанные меры",      min: 100, align: Text.AlignLeft,   mono: false },
        { key: "iInfr",      title: "I_infr",                min: 50,  align: Text.AlignRight,  mono: true  },
        { key: "status",     title: "Статус",                min: 70,  align: Text.AlignHCenter, mono: false }
    ]
    readonly property var defaultColWidths: [300, 170, 120, 230, 70, 100]
    property var colWidths: [300, 170, 120, 230, 70, 100]
    readonly property real totalColsWidth: {
        var s = 0
        for (var i = 0; i < colWidths.length; ++i) s += colWidths[i]
        return s
    }
    readonly property int rowHeight: 30
    readonly property int headerHeight: 28
    readonly property int cardWidth: 430

    function setColWidth(i, w) {
        var a = colWidths.slice()
        a[i] = Math.max(columns[i].min, Math.round(w))
        colWidths = a
    }
    function resetColWidth(i) { setColWidth(i, defaultColWidths[i]) }

    // ---------- Данные из C++ RiskCalculator ----------
    property var assets: (typeof riskCalculator !== "undefined") ? riskCalculator.assets : []
    property var vulnerabilityItems: (typeof riskCalculator !== "undefined") ? riskCalculator.vulnerabilities : []
    property var measureItems: (typeof riskCalculator !== "undefined") ? riskCalculator.measures : []

    Connections {
        target: (typeof riskCalculator !== "undefined") ? riskCalculator : null
        function onAssetsChanged() {
            root.assets = riskCalculator.assets
            root.rebuild()
            if (root.selectedId !== "" && !root.dirty) {
                var a = root.assetById(root.selectedId)
                if (a) {
                    root.draft = JSON.parse(JSON.stringify(a))
                    root.updateSuggestedVulns()
                }
            }
        }
        function onVulnerabilitiesChanged() {
            root.vulnerabilityItems = riskCalculator.vulnerabilities
            root.updateSuggestedVulns()
        }
        function onMeasuresChanged() {
            root.measureItems = riskCalculator.measures
        }
    }

    property var suggestedVulns: []
    property string detectedSoftware: ""

    function extractSoftwareKeyword(str) {
        if (!str) return ""
        var matches = str.match(/(PostgreSQL|Postgres|GitLab|Nginx|Apache|Linux|Windows|SCADA|Docker|Kubernetes|Oracle|Redis|Node|Java|OpenSSL|SSH|1C|1С|IIS|Exchange|SharePoint)/i)
        if (matches && matches.length > 0) return matches[1]
        var clean = str.replace(/srv-|app-|ws-|db\d*|standby|server|core|node|АРМ|клиент|база|условия|ключи|исходный|код/gi, " ").trim()
        var parts = clean.split(/[\s\(\)\[\],]+/).filter(function(w) { return w.length > 2 })
        return parts.length > 0 ? parts[0] : ""
    }

    function updateSuggestedVulns() {
        if (typeof riskCalculator === "undefined" || !riskCalculator.isBduAvailable || !root.draft || !root.draft.id) {
            suggestedVulns = []
            detectedSoftware = ""
            return
        }
        var kw = extractSoftwareKeyword((root.draft.supportingAssetName || "") + " " + (root.draft.primaryAssetName || ""))
        detectedSoftware = kw
        if (!kw || kw.length < 2) {
            suggestedVulns = []
            return
        }
        var results = riskCalculator.searchBdu(kw, 3, 5) // Critical & High
        var currentVulns = root.draft.vulns || []
        var filtered = []
        for (var i = 0; i < results.length; ++i) {
            var item = results[i]
            if (currentVulns.indexOf(item.id) === -1 && currentVulns.indexOf(item.title) === -1) {
                filtered.push(item)
                if (filtered.length >= 2) break
            }
        }
        suggestedVulns = filtered
    }

    function getVulnDisplayInfo(idOrTitle) {
        if (typeof riskCalculator === "undefined") {
            return { id: idOrTitle, title: idOrTitle, cvss: "", color: Style.textSecondary, desc: "" }
        }
        var allV = riskCalculator.vulnerabilities
        for (var i = 0; i < allV.length; ++i) {
            if (allV[i].id === idOrTitle || allV[i].title === idOrTitle) {
                var v = allV[i]
                var lvlColor = Style.riskMedium
                if (v.level === "Критический" || v.cvss >= 9.0) lvlColor = Style.riskCritical
                else if (v.level === "Высокий" || v.cvss >= 7.0) lvlColor = Style.riskHigh
                else if (v.level === "Средний" || v.cvss >= 4.0) lvlColor = Style.riskMedium
                else lvlColor = Style.riskLow

                return {
                    id: v.id,
                    title: v.title,
                    cvss: (v.cvss !== undefined && v.cvss > 0) ? v.cvss.toFixed(1) : "",
                    level: v.level || "",
                    color: lvlColor,
                    desc: v.description || ""
                }
            }
        }
        if (typeof idOrTitle === "string" && idOrTitle.indexOf("BDU:") === 0) {
            var det = riskCalculator.getBduDetails(idOrTitle)
            if (det && det.id) {
                return {
                    id: det.id,
                    title: det.title,
                    cvss: (det.cvssScore !== undefined && det.cvssScore > 0) ? det.cvssScore.toFixed(1) : "",
                    level: det.severityLevel || "",
                    color: det.severityLevel === "Критический" ? Style.riskCritical : Style.riskHigh,
                    desc: det.description || ""
                }
            }
        }
        return { id: idOrTitle, title: idOrTitle, cvss: "", color: Style.textSecondary, desc: "" }
    }

    // ---------- Состояние ----------
    property string searchText: ""
    property int sortKeyIndex: 2          // по умолчанию SLE
    property bool sortDesc: true          // по убыванию
    property var viewAssets: []
    property string selectedId: ""
    property bool cardOpen: false
    property var draft: ({})
    property bool dirty: false

    // ---------- Расчёты ----------
    function sle(a)   { return (a.directRecoveryCost || 0) + (a.indirectBusinessLoss || 0) }
    function iInfr(a) {
        var cIdx = Math.min(Math.max(0, a.componentType || 0), componentTypes.length - 1)
        var sIdx = Math.min(Math.max(0, a.share || 0), shareLevels.length - 1)
        var pIdx = Math.min(Math.max(0, a.perimeter || 0), perimeterLevels.length - 1)
        return componentTypes[cIdx].weight
             + shareLevels[sIdx].weight
             + perimeterLevels[pIdx].weight
    }
    // Допущение: статус = SLE × I_infr. Пороги подправьте под методику.
    function statusOf(a) {
        var s = sle(a) * iInfr(a)
        if (s >= 10000000) return "Критический"
        if (s >= 5000000)  return "Высокий"
        if (s >= 1000000)  return "Средний"
        return "Низкий"
    }
    function statusRank(a) {
        return { "Критический": 3, "Высокий": 2, "Средний": 1, "Низкий": 0 }[statusOf(a)]
    }
    function fmtRub(n) {
        return Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, "\u00A0") + "\u00A0₽"
    }
    function parseRub(t) {
        var v = Number(String(t).replace(/[^\d.,]/g, "").replace(",", "."))
        return isNaN(v) ? 0 : v
    }
    function assetById(id) {
        for (var i = 0; i < assets.length; ++i)
            if (assets[i].id === id) return assets[i]
        return null
    }

    // Текст ячейки; isPlaceholder — «пустые» значения рисуем приглушённо
    function cellText(a, key) {
        switch (key) {
        case "primary":    return a.primaryAssetName
        case "supporting": return a.supportingAssetName === "" ? "-" : a.supportingAssetName
        case "sle":        return fmtRub(sle(a))
        case "measures":   return a.measures.length === 0 ? "Не привязано ни одной меры" : a.measures.join(", ")
        case "iInfr":      return iInfr(a).toFixed(2)
        case "status":     return statusOf(a)
        }
        return ""
    }
    function isPlaceholder(a, key) {
        return (key === "supporting" && a.supportingAssetName === "")
            || (key === "measures" && (!a.measures || a.measures.length === 0))
    }
    function sortValue(a, key) {
        switch (key) {
        case "primary":    return a.primaryAssetName.toLowerCase()
        case "supporting": return a.supportingAssetName.toLowerCase()
        case "sle":        return sle(a)
        case "measures":   return (a.measures ? a.measures.length : 0)
        case "iInfr":      return iInfr(a)
        case "status":     return statusRank(a)
        }
        return 0
    }

    function rebuild() {
        if (!assets) assets = []
        var q = searchText.trim().toLowerCase()
        var list = assets.filter(function (a) {
            if (q === "") return true
            var mStr = (a.measures && Array.isArray(a.measures)) ? a.measures.join(" ") : ""
            var vStr = (a.vulns && Array.isArray(a.vulns)) ? a.vulns.join(" ") : ""
            return (a.id + " " + a.primaryAssetName + " " + a.supportingAssetName + " "
                    + mStr + " " + vStr).toLowerCase().indexOf(q) !== -1
        })
        var key = columns[sortKeyIndex].key
        var dir = sortDesc ? -1 : 1
        list.sort(function (a, b) {
            var va = sortValue(a, key), vb = sortValue(b, key)
            var c = (typeof va === "string") ? va.localeCompare(vb) : (va - vb)
            if (c === 0) return a.id.localeCompare(b.id)
            return c * dir
        })
        viewAssets = list
    }

    // Клик по заголовку колонки: та же колонка — смена направления, другая — по возрастанию
    function toggleSort(i) {
        if (sortKeyIndex === i) {
            sortDesc = !sortDesc
        } else {
            sortDesc = false
            sortKeyIndex = i
        }
    }

    function selectAsset(id) {
        var changed = (id !== selectedId)
        selectedId = id
        cardOpen = true
        if (changed) resetDraft()
    }
    function resetDraft() {
        var a = assetById(selectedId)
        draft = a ? JSON.parse(JSON.stringify(a)) : ({})
        dirty = false
        formLoader.active = false      // пересоздаём форму, чтобы поля подхватили значения
        formLoader.active = (a !== null)
        root.updateSuggestedVulns()
    }
    function saveDraft() {
        if (typeof riskCalculator === "undefined") return

        var current = root.assetById(root.selectedId)
        if (!current) return
        var linkedKeys = ["vulns", "measures"]
        for (var k = 0; k < linkedKeys.length; ++k) {
            var key = linkedKeys[k]
            var before = current[key] || []
            var after = root.draft[key] || []
            var isMeasure = key === "measures"

            for (var i = 0; i < before.length; ++i) {
                if (after.indexOf(before[i]) === -1) {
                    if (isMeasure)
                        riskCalculator.unlinkMeasureFromAsset(root.selectedId, before[i])
                    else
                        riskCalculator.unlinkVulnerabilityFromAsset(root.selectedId, before[i])
                }
            }
            for (var j = 0; j < after.length; ++j) {
                if (before.indexOf(after[j]) !== -1) continue
                if (isMeasure) {
                    var measure = null
                    for (var m = 0; m < root.measureItems.length; ++m) {
                        if (root.measureItems[m].id === after[j] || root.measureItems[m].title === after[j]) {
                            measure = root.measureItems[m]
                            break
                        }
                    }
                    if (measure && measure.asset && measure.asset !== root.selectedId)
                        riskCalculator.updateMeasure({ id: measure.id, asset: root.selectedId })
                    else
                        riskCalculator.linkMeasureToAsset(root.selectedId, after[j])
                } else {
                    riskCalculator.linkVulnerabilityToAsset(root.selectedId, after[j])
                }
            }
        }

        riskCalculator.updateAsset(root.draft)
        var updated = root.assetById(root.selectedId)
        if (updated) root.draft = JSON.parse(JSON.stringify(updated))
        dirty = false
        root.updateSuggestedVulns()
    }
    function setDraft(key, value) {
        var d = draft
        d[key] = value
        draft = d
        dirty = true
    }
    function linkedEntities(key) {
        var ids = root.draft[key] || []
        var items = key === "vulns" ? root.vulnerabilityItems : root.measureItems
        var linked = []
        for (var i = 0; i < ids.length; ++i) {
            var found = null
            for (var j = 0; j < items.length; ++j) {
                if (items[j].id === ids[i] || items[j].title === ids[i]) {
                    found = items[j]
                    break
                }
            }
            linked.push(found || { id: ids[i], title: ids[i] })
        }
        return linked
    }
    function isDraftLinked(key, id) {
        var ids = root.draft[key] || []
        return ids.indexOf(id) !== -1
    }
    function addDraftLink(key, id) {
        if (!id || root.isDraftLinked(key, id)) return
        var ids = (root.draft[key] || []).slice()
        ids.push(id)
        root.setDraft(key, ids)
    }
    function removeDraftLink(key, id) {
        var ids = (root.draft[key] || []).slice()
        var index = ids.indexOf(id)
        if (index === -1) return
        ids.splice(index, 1)
        root.setDraft(key, ids)
    }

    onSearchTextChanged: rebuild()
    onSortKeyIndexChanged: rebuild()
    onSortDescChanged: rebuild()
    Component.onCompleted: rebuild()

    // =====================================================================
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ===================== Таблица =====================
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

                // --- Header: поиск, поле сортировки, направление, добавление ---
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
                            placeholderText: "Поиск по активу, хосту или мере..."
                            isMonospace: false
                            onTextChanged: root.searchText = text
                        }

                        Text {
                            text: "Сортировка:"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeBodySm
                            color: Style.textSecondary
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 170
                            model: root.columns.map(function (c) { return c.title })
                            currentIndex: root.sortKeyIndex
                            onCurrentIndexChanged: root.sortKeyIndex = currentIndex
                        }

                        CustomComboBox {
                            Layout.preferredWidth: 150
                            model: ["По возрастанию ↑", "По убыванию ↓"]
                            currentIndex: root.sortDesc ? 1 : 0
                            onCurrentIndexChanged: root.sortDesc = (currentIndex === 1)
                        }

                        AppButton {
                            isPrimary: true
                            text: "Актив"
                            iconText: "+"
                            onClicked: {
                                if (typeof riskCalculator !== "undefined") {
                                    var newA = riskCalculator.addAsset({ primaryAssetName: "Новый информационный актив" })
                                    root.selectAsset(newA.id)
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

                                    // клик по заголовку — сортировка
                                    MouseArea {
                                        id: hMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleSort(index)
                                    }

                                    // ручка изменения ширины (двойной клик — вернуть ширину по умолчанию)
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

                            // «хвост» заголовка до правого края
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
                            model: root.viewAssets
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

                                // горизонтальная линия сетки
                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: 1
                                    color: Style.hairlineBorder
                                }
                                // маркер выбранной строки
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

                                            // вертикальная линия сетки
                                            Rectangle {
                                                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                                                width: 1
                                                color: Style.hairlineBorder
                                            }

                                            Text {
                                                visible: cell.col.key !== "status"
                                                anchors {
                                                    left: parent.left; right: parent.right
                                                    leftMargin: 8; rightMargin: 8
                                                    verticalCenter: parent.verticalCenter
                                                }
                                                horizontalAlignment: cell.col.align
                                                elide: Text.ElideRight
                                                text: root.cellText(row.rowData, cell.col.key)
                                                font.family: cell.col.mono ? Style.fontMono : Style.fontSans
                                                font.pixelSize: cell.col.mono ? Style.fontSizeCodeSm : Style.fontSizeBodySm
                                                font.weight: (cell.col.key === "primary" || cell.col.key === "sle")
                                                             ? Font.DemiBold : Font.Normal
                                                font.italic: root.isPlaceholder(row.rowData, cell.col.key)
                                                color: root.isPlaceholder(row.rowData, cell.col.key)
                                                       ? Style.textMuted
                                                       : ((cell.col.key === "primary" || cell.col.key === "sle")
                                                          ? Style.textPrimary : Style.textSecondary)
                                            }

                                            RiskBadge {
                                                visible: cell.col.key === "status"
                                                anchors.centerIn: parent
                                                level: root.statusOf(row.rowData)
                                                compact: true
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectAsset(modelData.id)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.viewAssets.length === 0
                                text: root.assets.length === 0
                                      ? "Активы еще не добавлены. Нажмите «+ Актив», чтобы создать первый."
                                      : "Активы не найдены"
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
                            text: {
                                var t = 0
                                for (var i = 0; i < root.viewAssets.length; ++i) t += root.sle(root.viewAssets[i])
                                return "Суммарный SLE: " + root.fmtRub(t)
                            }
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Активов: " + root.viewAssets.length + " из " + root.assets.length
                            font.family: Style.fontMono
                            font.pixelSize: Style.fontSizeCodeSm
                            color: Style.textSecondary
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

        // ===================== Карточка актива (анимированная ширина) =====================
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

            // Содержимое имеет фиксированную ширину и «открывается» из-под правого края
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
                                Layout.fillWidth: true
                                text: root.draft.primaryAssetName || ""
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeHeadlineSm
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                                elide: Text.ElideRight
                            }


                        }
                    }

                    // --- Форма ---
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: availableWidth
                        contentHeight: formLoader.height
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        Loader {
                            id: formLoader
                            width: parent.width
                            height: item ? item.implicitHeight : 0
                            active: false
                            sourceComponent: formComponent
                        }
                    }

                    // --- Футер: I_infr + действия ---
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
                                text: "I_infr: " + (root.draft.id ? root.iInfr(root.draft).toFixed(2) : "-")
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeMd
                                font.weight: Font.Bold
                                color: Style.textPrimary
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
                                        riskCalculator.deleteAsset(root.selectedId)
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

    // ---------- Содержимое формы ----------
    Component {
        id: formComponent

        ColumnLayout {
            spacing: 12

            Item { Layout.preferredHeight: 2 }

            // 1. Идентификация
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: g1.implicitHeight + 20
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g1
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Text {
                        text: "ИДЕНТИФИКАЦИЯ"
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeHeadlineSm
                        font.weight: Font.DemiBold
                        color: Style.textPrimary
                    }
                    Text { text: "Основной актив:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                    CustomTextField {
                        Layout.fillWidth: true
                        isMonospace: false
                        text: root.draft.primaryAssetName || ""
                        onTextChanged: if (text !== root.draft.primaryAssetName) root.setDraft("primaryAssetName", text)
                    }
                    Text { text: "Вспомогательный актив (ИТ-компонент):"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        CustomTextField {
                            Layout.fillWidth: true
                            isMonospace: true
                            placeholderText: "Нажмите «Выбрать» или введите имя хоста..."
                            text: root.draft.supportingAssetName || ""
                            onTextChanged: if (text !== root.draft.supportingAssetName) {
                                root.setDraft("supportingAssetName", text)
                                root.updateSuggestedVulns()
                            }
                        }
                        AppButton {
                            text: "Выбрать"
                            onClicked: supportingAssetModal.isOpen = true
                        }
                    }
                }
            }

            // 2. Ущерб
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: g2.implicitHeight + 20
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g2
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "ЕДИНИЧНЫЙ УЩЕРБ (SLE)"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.DemiBold
                            color: Style.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "SLE = прямой + косвенный"
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
                            Text { text: "Прямое влияние, ₽:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            CustomTextField {
                                Layout.fillWidth: true
                                suffixText: "₽"
                                text: Math.round(root.draft.directRecoveryCost || 0).toString()
                                onTextChanged: {
                                    var v = root.parseRub(text)
                                    if (v !== root.draft.directRecoveryCost) root.setDraft("directRecoveryCost", v)
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { text: "Косвенное влияние, ₽:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                            CustomTextField {
                                Layout.fillWidth: true
                                suffixText: "₽"
                                text: Math.round(root.draft.indirectBusinessLoss || 0).toString()
                                onTextChanged: {
                                    var v = root.parseRub(text)
                                    if (v !== root.draft.indirectBusinessLoss) root.setDraft("indirectBusinessLoss", v)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        color: Style.surfaceContainerHighest
                        border.color: Style.hairlineBorder
                        border.width: 1
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text {
                                text: "Полная ценность (SLE):"
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodySm
                                color: Style.textSecondary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.fmtRub(root.sle(root.draft))
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeMetricDisplay
                                font.weight: Font.Bold
                                color: Style.textPrimary
                            }
                        }
                    }
                }
            }

            // 3. Параметры инфраструктуры
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: g3.implicitHeight + 20
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: g3
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Text {
                        text: "ПАРАМЕТРЫ ИНФРАСТРУКТУРЫ"
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeHeadlineSm
                        font.weight: Font.DemiBold
                        color: Style.textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Тип компонента:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "k = " + (root.componentTypes[root.draft.componentType || 0] ? root.componentTypes[root.draft.componentType || 0].weight.toFixed(2) : "0.55")
                            font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary
                        }
                    }
                    CustomComboBox {
                        Layout.fillWidth: true
                        model: root.componentTypes.map(function (c) { return c.name + " (" + c.weight.toFixed(2) + ")" })
                        currentIndex: Math.min(Math.max(0, root.draft.componentType || 0), root.componentTypes.length - 1)
                        onCurrentIndexChanged: if (currentIndex !== root.draft.componentType) root.setDraft("componentType", currentIndex)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Доля уязвимых компонентов:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "l = " + (root.shareLevels[root.draft.share || 0] ? root.shareLevels[root.draft.share || 0].weight.toFixed(2) : "0.16")
                            font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary
                        }
                    }
                    CustomComboBox {
                        Layout.fillWidth: true
                        model: root.shareLevels.map(function (s) { return s.name + " (" + s.weight.toFixed(2) + ")" })
                        currentIndex: Math.min(Math.max(0, root.draft.share || 0), root.shareLevels.length - 1)
                        onCurrentIndexChanged: if (currentIndex !== root.draft.share) root.setDraft("share", currentIndex)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Доступность из Интернет:"; font.family: Style.fontSans; font.pixelSize: Style.fontSizeBodySm; color: Style.textSecondary }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "p = " + (root.perimeterLevels[root.draft.perimeter || 0] ? root.perimeterLevels[root.draft.perimeter || 0].weight.toFixed(2) : "0.33")
                            font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; font.weight: Font.Bold; color: Style.textPrimary
                        }
                    }
                    SegmentedControl {
                        Layout.fillWidth: true
                        items: root.perimeterLevels.map(function (p) { return p.name + " (" + p.weight.toFixed(2) + ")" })
                        currentIndex: Math.min(Math.max(0, root.draft.perimeter || 0), root.perimeterLevels.length - 1)
                        onCurrentIndexChanged: if (currentIndex !== root.draft.perimeter) root.setDraft("perimeter", currentIndex)
                    }
                }
            }

            // 4. Привязанные уязвимости и меры защиты
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: linksColumn.implicitHeight + 20
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                ColumnLayout {
                    id: linksColumn
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: "СВЯЗАННЫЕ УЯЗВИМОСТИ И МЕРЫ"
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeHeadlineSm
                        font.weight: Font.DemiBold
                        color: Style.textPrimary
                    }

                    Text {
                        text: "Выберите записи для привязки к этому активу. Сведения о привязанных записях отображаются ниже."
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeBodySm
                        color: Style.textSecondary
                    }

                    Text {
                        text: "УЯЗВИМОСТИ"
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeBodySm
                        font.weight: Font.DemiBold
                        color: Style.textSecondary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        CustomComboBox {
                            id: vulnerabilityPicker
                            Layout.fillWidth: true
                            model: root.vulnerabilityItems.map(function(v) {
                                return (v.id || "") + " · " + (v.title || "Без названия")
                            })
                        }
                        AppButton {
                            text: "Привязать"
                            enabledState: vulnerabilityPicker.currentIndex >= 0
                                          && vulnerabilityPicker.currentIndex < root.vulnerabilityItems.length
                                          && !root.isDraftLinked("vulns", root.vulnerabilityItems[vulnerabilityPicker.currentIndex].id)
                            onClicked: {
                                if (vulnerabilityPicker.currentIndex >= 0)
                                    root.addDraftLink("vulns", root.vulnerabilityItems[vulnerabilityPicker.currentIndex].id)
                            }
                        }
                    }

                    Repeater {
                        model: root.linkedEntities("vulns")
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: vulnDetails.implicitHeight + 14
                            color: Style.panelSurface
                            border.color: Style.hairlineBorder
                            border.width: 1

                            RowLayout {
                                id: vulnDetails
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 8
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    Text {
                                        text: modelData.title || modelData.id
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Text {
                                        text: (modelData.id || "")
                                              + (modelData.level ? " · " + modelData.level : "")
                                              + (modelData.cvss ? " · CVSS " + Number(modelData.cvss).toFixed(1) : "")
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        font.family: Style.fontMono
                                        font.pixelSize: Style.fontSizeCodeSm
                                        color: Style.textSecondary
                                    }
                                    Text {
                                        text: modelData.desc || modelData.description || modelData.notes || ""
                                        visible: text !== ""
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textSecondary
                                    }
                                }
                                AppButton {
                                    text: "Убрать"
                                    onClicked: root.removeDraftLink("vulns", modelData.id)
                                }
                            }
                        }
                    }
                    Text {
                        visible: root.linkedEntities("vulns").length === 0
                        text: "К активу не привязаны уязвимости."
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeBodySm
                        color: Style.textMuted
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Style.hairlineBorder }

                    Text {
                        text: "МЕРЫ ЗАЩИТЫ"
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeBodySm
                        font.weight: Font.DemiBold
                        color: Style.textSecondary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        CustomComboBox {
                            id: measurePicker
                            Layout.fillWidth: true
                            model: root.measureItems.map(function(m) {
                                return (m.id || "") + " · " + (m.title || "Без названия")
                            })
                        }
                        AppButton {
                            text: "Привязать"
                            enabledState: measurePicker.currentIndex >= 0
                                          && measurePicker.currentIndex < root.measureItems.length
                                          && !root.isDraftLinked("measures", root.measureItems[measurePicker.currentIndex].id)
                            onClicked: {
                                if (measurePicker.currentIndex >= 0)
                                    root.addDraftLink("measures", root.measureItems[measurePicker.currentIndex].id)
                            }
                        }
                    }

                    Repeater {
                        model: root.linkedEntities("measures")
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: measureDetails.implicitHeight + 14
                            color: Style.panelSurface
                            border.color: Style.hairlineBorder
                            border.width: 1

                            RowLayout {
                                id: measureDetails
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 8
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    Text {
                                        text: modelData.title || modelData.id
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                    }
                                    Text {
                                        text: (modelData.id || "")
                                              + (modelData.measureType ? " · " + modelData.measureType : "")
                                              + (modelData.status ? " · " + modelData.status : "")
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        font.family: Style.fontMono
                                        font.pixelSize: Style.fontSizeCodeSm
                                        color: Style.textSecondary
                                    }
                                    Text {
                                        text: modelData.description || modelData.desc || modelData.fstecClass || ""
                                        visible: text !== ""
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        font.family: Style.fontSans
                                        font.pixelSize: Style.fontSizeBodySm
                                        color: Style.textSecondary
                                    }
                                }
                                AppButton {
                                    text: "Убрать"
                                    onClicked: root.removeDraftLink("measures", modelData.id)
                                }
                            }
                        }
                    }
                    Text {
                        visible: root.linkedEntities("measures").length === 0
                        text: "К активу не привязаны меры защиты."
                        font.family: Style.fontSans
                        font.pixelSize: Style.fontSizeBodySm
                        color: Style.textMuted
                    }
                }
            }


            Item { Layout.preferredHeight: 8 }
        }
    }

    SupportingAssetModal {
        id: supportingAssetModal
        onAssetSelected: function(assetName, compType) {
            root.setDraft("supportingAssetName", assetName)
            if (compType !== undefined) {
                root.setDraft("componentType", compType)
            }
            root.updateSuggestedVulns()
        }
    }
}
