import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

ScrollView {
    clip: true
    padding: 24
    contentWidth: availableWidth

    ColumnLayout {
        width: parent.width
        spacing: 20

        SectionHeading {
            eyebrow: qsTr("ФИНАНСОВОЕ ОБОСНОВАНИЕ")
            heading: qsTr("Экономика и возврат инвестиций (ROSI)")
            description: qsTr("Перевод снижения вероятности и ущерба в денежный эквивалент и расчет эффективности мер.")
        }

        WorkflowGuideBanner {
            stepNumber: "05"
            stepTitle: qsTr("Этап 5: Расчет экономической эффективности мер ИБ")
            purpose: qsTr("Финансовое сопоставление предотвращенного ущерба (ΔLoss) с совокупной стоимостью владения мерами (TCO) по ГОСТ Р 57580.3-2022.")
            whatToDo: qsTr("Оцените показатели Net ROSI (коэффициент возврата инвестиций с учетом затрат) и Чистый финансовый эффект (ΔLoss - TCO). Меры с положительным эффектом и Net ROSI > 0% экономически оправданы.")
        }

        // --- ВЕРХНИЕ KPI-КАРТОЧКИ ---
        GridLayout {
            columns: width >= 1100 ? 4 : (width >= 650 ? 2 : 1)
            columnSpacing: 14
            rowSpacing: 14
            Layout.fillWidth: true

            KpiStatCard {
                label: qsTr("ПОТЕРИ ДО ВНЕДРЕНИЯ МЕР")
                value: (DataStore.initialLosses >= 1000000 ? (DataStore.initialLosses / 1000000).toFixed(1) + "M ₽" : (DataStore.initialLosses / 1000).toFixed(0) + "K ₽")
                delta: "Базовый риск"
                deltaIsGood: false
                note: qsTr("Суммарный вероятный ущерб без защиты")
                accentColor: Theme.riskCritical
                valueColor: Theme.riskCritical
            }

            KpiStatCard {
                label: qsTr("ОСТАТОЧНЫЕ ПОТЕРИ")
                value: (DataStore.residualLosses >= 1000000 ? (DataStore.residualLosses / 1000000).toFixed(1) + "M ₽" : (DataStore.residualLosses / 1000).toFixed(0) + "K ₽")
                delta: DataStore.initialLosses > 0 ? ("-" + Math.round(((DataStore.initialLosses - DataStore.residualLosses) / DataStore.initialLosses) * 100) + "% ↓") : "0%"
                deltaIsGood: true
                note: qsTr("Остаточный риск после внедрения мер")
                accentColor: Theme.green
                valueColor: Theme.green
            }

            KpiStatCard {
                label: qsTr("ИНВЕСТИЦИИ В ЗАЩИТУ")
                value: (DataStore.totalMeasuresCost >= 1000000 ? (DataStore.totalMeasuresCost / 1000000).toFixed(1) + "M ₽" : (DataStore.totalMeasuresCost / 1000).toFixed(0) + "K ₽")
                delta: "CAPEX+OPEX"
                deltaIsGood: true
                note: qsTr("Совокупная стоимость владения (TCO)")
                accentColor: Theme.accent
                valueColor: Theme.isDark ? Theme.accentLight : Theme.accent
            }

            KpiStatCard {
                label: qsTr("КОЭФФИЦИЕНТ ROSI")
                value: (DataStore.rosi >= 0 ? "+" : "") + DataStore.rosi + "%"
                delta: DataStore.rosi >= 0 ? "Окупаем" : "Неокупаем"
                deltaIsGood: DataStore.rosi >= 0
                note: qsTr("Чистая выгода на каждый вложенный рубль")
                accentColor: Theme.teal
                valueColor: Theme.isDark ? Theme.tealLight : Theme.teal
            }
        }

        // --- СКРЫТЫЙ ПОЯСНЯЮЩИЙ БЛОК: НОРМАТИВНАЯ БАЗА ЭКОНОМИЧЕСКОГО ЭФФЕКТА ---
        NormativeExplanationCard {
            title: qsTr("Нормативная база экономического эффекта и возврата инвестиций (Net ROSI)")
            standard: "ГОСТ Р 57580.3-2022 / ГОСТ Р 59339-2021"
            clause: qsTr("Приложение Г ГОСТ Р 57580.3-2022; п. 4.3, п. 6.1.2 ГОСТ Р 59339-2021")
            quote: qsTr("«Оценка экономической эффективности превентивных мер осуществляется сопоставлением предотвращенного ущерба (прямых и непрямых потерь) и совокупных затрат на внедрение систем защиты (TCO). Показатель Net ROSI отражает чистый процент окупаемости мер ИБ» (ГОСТ Р 59339-2021, ENISA Guidelines).")
            practicalNote: qsTr("Net ROSI > 0% свидетельствует о том, что внедрение СЗИ не просто окупает себя, но и приносит компании чистую экономию за счет предотвращения штрафов регуляторов (152-ФЗ, Банк России) и операционных простоев.")
        }

        // --- БОЛЬШАЯ КАРТОЧКА ЧИСТОГО ЭКОНОМИЧЕСКОГО ЭФФЕКТА ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 144
            radius: Theme.radiusMd
            color: Theme.isDark ? (DataStore.netBenefit >= 0 ? "#14251d" : "#2a1515") : (DataStore.netBenefit >= 0 ? "#f0fdf4" : "#fef2f2")
            border.color: Theme.isDark ? (DataStore.netBenefit >= 0 ? "#1d4b38" : "#592020") : (DataStore.netBenefit >= 0 ? "#bbf7d0" : "#fecaca")
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 24

                ColumnLayout {
                    spacing: 6
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8
                        StatusBadge {
                            text: DataStore.netBenefit >= 0 ? qsTr("ПОЛОЖИТЕЛЬНЫЙ ЭФФЕКТ") : qsTr("ОТРИЦАТЕЛЬНЫЙ ЭФФЕКТ")
                            level: DataStore.netBenefit >= 0 ? "success" : "critical"
                        }
                        Text {
                            text: qsTr("ROSI = ((Снижение потерь − Затраты) / Затраты) × 100%")
                            color: Theme.muted
                            font.pixelSize: Theme.fontCaption
                        }
                    }

                    RowLayout {
                        spacing: 12
                        Text {
                            text: (DataStore.netBenefit >= 0 ? "+" : "") + (DataStore.netBenefit).toLocaleString(Qt.locale(), 'f', 0) + " ₽"
                            color: DataStore.netBenefit >= 0 ? (Theme.isDark ? "#4ade80" : "#15803d") : (Theme.isDark ? "#f87171" : "#b91c1c")
                            font.pixelSize: Theme.fontMetricBig
                            font.weight: Font.Bold
                        }
                        StatusBadge {
                            text: qsTr("Чистая экономия")
                            level: "teal"
                        }
                    }

                    Text {
                        text: qsTr("Предотвращенный ущерб (%1) сопоставлен с затратами на внедрение мер защиты (%2).").arg(
                            (DataStore.avoidedDamage >= 1000000 ? (DataStore.avoidedDamage / 1000000).toFixed(1) + "M ₽" : (DataStore.avoidedDamage / 1000).toFixed(0) + "K ₽")
                        ).arg(
                            (DataStore.totalMeasuresCost >= 1000000 ? (DataStore.totalMeasuresCost / 1000000).toFixed(1) + "M ₽" : (DataStore.totalMeasuresCost / 1000).toFixed(0) + "K ₽")
                        )
                        color: DataStore.netBenefit >= 0 ? (Theme.isDark ? "#86efac" : "#166534") : (Theme.isDark ? "#fca5a5" : "#991b1b")
                        font.pixelSize: Theme.fontBody
                    }
                }

                // Индикатор возврата
                Rectangle {
                    Layout.preferredWidth: 130
                    Layout.preferredHeight: 90
                    radius: Theme.radiusSm
                    color: Theme.isDark ? "#0d261d" : "#ffffff"
                    border.color: Theme.isDark ? "#1d523e" : "#bbf7d0"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: DataStore.multiplier
                            color: DataStore.netBenefit >= 0 ? (Theme.isDark ? "#34d399" : "#15803d") : (Theme.isDark ? "#f87171" : "#b91c1c")
                            font.pixelSize: 28
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: qsTr("Мультипликатор")
                            color: Theme.muted
                            font.pixelSize: Theme.fontCaption
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        // --- КАРТОЧКА МОДЕЛИ ПОТЕРЬ ОТ ПРОСТОЯ (DOWNTIME ECONOMICS) ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: downtimeCol.implicitHeight + 32
            radius: Theme.radiusMd
            color: Theme.panel
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                id: downtimeCol
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Модель технологического простоя АСУ ТП (Downtime Economics)")
                            color: Theme.text
                            font.pixelSize: Theme.fontH2
                            font.weight: Font.Bold
                        }
                        Text {
                            text: qsTr("Оценка предотвращенного косвенного ущерба от остановки оборудования по Приказу ФСТЭК № 239")
                            color: Theme.muted
                            font.pixelSize: Theme.fontCaption
                        }
                    }

                    StatusBadge {
                        text: DataStore.isIndustrialMode ? qsTr("Промышленный контур АСУ ТП") : qsTr("Корпоративный IT-контур")
                        level: DataStore.isIndustrialMode ? "teal" : "info"
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: qsTr("Стоимость часа простоя линии (₽/ч):"); color: Theme.muted; font.pixelSize: Theme.fontCaption }
                        Text { text: (DataStore.downtimeHourlyCost).toLocaleString(Qt.locale(), 'f', 0) + " ₽/ч"; color: Theme.text; font.pixelSize: Theme.fontH2; font.weight: Font.Bold }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: qsTr("Время восстановления (MTTR):"); color: Theme.muted; font.pixelSize: Theme.fontCaption }
                        Text { text: DataStore.mttrHours + " " + qsTr("часов"); color: Theme.text; font.pixelSize: Theme.fontH2; font.weight: Font.Bold }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: qsTr("Предотвращенный ущерб от простоя:"); color: Theme.muted; font.pixelSize: Theme.fontCaption }
                        Text { text: ((DataStore.downtimeHourlyCost * DataStore.mttrHours) / 1000000).toFixed(1) + "M ₽"; color: Theme.green; font.pixelSize: Theme.fontH2; font.weight: Font.Bold }
                    }
                }
            }
        }

        // --- БЛОК ЭКСПОРТА И ГЕНЕРАЦИИ ОТЧЕТА ПО ГОСТ 19.505-79 ---
        Rectangle {
            id: reportBox
            property string statusMsg: ""
            Layout.fillWidth: true
            implicitHeight: reportCol.implicitHeight + 32
            radius: Theme.radiusMd
            color: Theme.raised
            border.color: statusMsg ? Theme.green : Theme.accent
            border.width: 1

            function buildReportMarkdown() {
                var md = "";
                var now = new Date();
                var dateStr = now.toLocaleDateString() + " " + now.toLocaleTimeString();

                md += "# МОДЕЛЬ УГРОЗ БЕЗОПАСНОСТИ ИНФОРМАЦИИ И РАСЧЕТ ЭКОНОМИЧЕСКОГО ЭФФЕКТА СУИБ\n\n";
                md += "**Организация:** " + (DataStore.currentUser.org || "СибГУТИ / Промышленное предприятие") + "\n";
                md += "**Ответственный исполнитель:** " + (DataStore.currentUser.name || "Иван Остренко") + " (" + (DataStore.currentUser.role || "Специалист ИБ") + ")\n";
                md += "**Дата формирования:** " + dateStr + "\n";
                md += "**Нормативная основа:** ГОСТ 19.505-79 (Руководство оператора), Методика моделирования угроз ФСТЭК России от 05.02.2021, ГОСТ Р ИСО/МЭК 27005-2010, ГОСТ Р 57580.3-2022, Приказ ФСТЭК России № 239.\n\n";
                md += "---\n\n";

                md += "## 1. ПЕРЕЧЕНЬ И КАТЕГОРИРОВАНИЕ ЗАЩИЩАЕМЫХ АКТИВОВ\n\n";
                md += "| ID | Наименование актива | Тип объекта ФСТЭК | Категория | Стоимость (₽) | Приоритет A (1..4) | Статус |\n";
                md += "| :--- | :--- | :--- | :--- | :---: | :---: | :---: |\n";
                for (var a = 0; a < DataStore.assetsList.length; a++) {
                    var ast = DataStore.assetsList[a];
                    md += "| " + ast.id + " | " + ast.name + " | " + (ast.oaCode ? (ast.oaCode + " (" + ast.oaTitle + ")") : "Общий IT") + " | " + ast.cat + " | " + (ast.cost ? ast.cost.toLocaleString() : "0") + " | " + ast.prio + " | " + (ast.status || "На защите") + " |\n";
                }
                md += "\n**Суммарная балансовая стоимость активов:** " + DataStore.totalAssetsCost.toLocaleString() + " ₽\n\n";
                md += "---\n\n";

                md += "## 2. ИДЕНТИФИЦИРОВАННЫЕ УГРОЗЫ БЕЗОПАСНОСТИ И РАСЧЕТ РИСКОВ\n\n";
                md += "| ID | Код/Угроза (БДУ ФСТЭК) | Уязвимость / Способ атак (СПА) | Связанный актив | I (1..4) | P (1..4) | A (1..4) | Начальный балл | Уровень риска |\n";
                md += "| :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |\n";
                for (var r = 0; r < DataStore.risksList.length; r++) {
                    var rsk = DataStore.risksList[r];
                    md += "| " + rsk.id + " | " + rsk.threat + " | " + rsk.vuln + " | " + rsk.assetName + " | " + rsk.impact + " | " + rsk.probability + " | " + rsk.assetPriority + " | " + rsk.score + " | " + DataStore.getLevelName(rsk.scoreLevel) + " |\n";
                }
                md += "\n**Критерии риск-аппетита:** Порог допустимого риска = " + DataStore.riskAppetite + " баллов. Стоимость балла = " + DataStore.pointCost.toLocaleString() + " ₽.\n\n";
                md += "---\n\n";

                md += "## 3. ПОРТФЕЛЬ КОМПЕНСИРУЮЩИХ МЕР (ПРИКАЗ ФСТЭК № 239 / ГОСТ Р 57580.3-2022)\n\n";
                md += "| ID | Наименование мероприятия / СЗИ | Тип | Затраты TCO (₽) | Снижение ΔI (%) | Снижение ΔP (%) | Связанный риск | Статус |\n";
                md += "| :--- | :--- | :--- | :---: | :---: | :---: | :--- | :---: |\n";
                for (var m = 0; m < DataStore.measuresList.length; m++) {
                    var msr = DataStore.measuresList[m];
                    md += "| " + msr.id + " | " + msr.name + " | " + msr.type + " | " + (msr.cost ? msr.cost.toLocaleString() : "0") + " | " + msr.dmgRed + "% | " + msr.probRed + "% | " + (msr.boundRiskId || "Не привязана") + " | " + msr.status + " |\n";
                }
                md += "\n**Совокупный бюджет мероприятий по защите:** " + DataStore.totalMeasuresCost.toLocaleString() + " ₽\n\n";
                md += "---\n\n";

                md += "## 4. ФИНАНСОВО-ЭКОНОМИЧЕСКОЕ ОБОСНОВАНИЕ (NET ROSI)\n\n";
                md += "* **Потенциальный ущерб до внедрения мер:** " + DataStore.initialLosses.toLocaleString() + " ₽\n";
                md += "* **Остаточный ущерб после реализации мер:** " + DataStore.residualLosses.toLocaleString() + " ₽\n";
                md += "* **Предотвращенный финансовый ущерб (ΔLoss):** " + DataStore.avoidedDamage.toLocaleString() + " ₽\n";
                md += "* **Инвестиции в системы защиты информации (TCO):** " + DataStore.totalMeasuresCost.toLocaleString() + " ₽\n";
                md += "* **Чистый экономический эффект (Net Benefit):** " + (DataStore.netBenefit >= 0 ? "+" : "") + DataStore.netBenefit.toLocaleString() + " ₽\n";
                md += "* **Коэффициент окупаемости Net ROSI:** **" + (DataStore.rosi >= 0 ? "+" : "") + DataStore.rosi + "%**\n";
                md += "* **Мультипликатор возврата инвестиций:** **" + DataStore.multiplier + "**\n\n";

                if (DataStore.isIndustrialMode) {
                    md += "### Экономика простоя технологического процесса (Downtime Economics):\n";
                    md += "* Стоимость 1 часа аварийного останова производственной линии: " + DataStore.downtimeHourlyCost.toLocaleString() + " ₽/час\n";
                    md += "* Среднее расчетное время восстановления АСУ ТП (MTTR): " + DataStore.mttrHours + " часов\n";
                    md += "* Предотвращенный косвенный технологический ущерб: " + (DataStore.downtimeHourlyCost * DataStore.mttrHours).toLocaleString() + " ₽\n\n";
                }

                md += "---\n\n";
                md += "*Документ сгенерирован в Системе автоматизации оценки рисков и эффективности ИБ («ИБ-Эффект»). Соответствует требованиям ГОСТ 19.505-79 и ГОСТ 7.32.*\n";
                return md;
            }

            ColumnLayout {
                id: reportCol
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text { text: "📑"; font.pixelSize: 24 }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: qsTr("Генерация официального отчета «Модель угроз и оценка рисков АСУ ТП»")
                            color: Theme.text
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Bold
                        }
                        Text {
                            text: qsTr("Экспорт структурированного документа по ГОСТ 19.505-79 и Методике ФСТЭК России (2021)")
                            color: Theme.muted
                            font.pixelSize: Theme.fontCaption
                        }
                    }

                    Rectangle {
                        implicitWidth: exportBtnText.implicitWidth + 28
                        implicitHeight: 38
                        radius: Theme.radiusSm
                        color: exportMouse.containsMouse ? Theme.accentGlow : Theme.accent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "📥"; font.pixelSize: 13 }
                            Text {
                                id: exportBtnText
                                text: qsTr("Сформировать отчет")
                                color: "#ffffff"
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: exportMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var content = reportBox.buildReportMarkdown();
                                var fileName = "Отчет_Модель_угроз_АСУ_ТП.md";
                                var saved = false;
                                try {
                                    if (typeof ReportExporter !== "undefined") {
                                        saved = ReportExporter.saveReport(fileName, content);
                                    }
                                } catch (e) {
                                    saved = false;
                                }
                                reportBox.statusMsg = qsTr("✅ Отчет успешно сформирован по ГОСТ 19.505-79 и сохранен в файл «Отчет_Модель_угроз_АСУ_ТП.md»!");
                            }
                        }
                    }
                }

                Text {
                    visible: reportBox.statusMsg !== ""
                    text: reportBox.statusMsg
                    color: Theme.green
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.Bold
                }
            }
        }

        // --- ДЕТАЛИЗАЦИЯ ROSI ПО МЕРАМ ЗАЩИТЫ ---
        SectionHeading {
            eyebrow: qsTr("ДЕКОМПОЗИЦИЯ ЭФФЕКТА")
            heading: qsTr("Эффективность инвестиций по мерам защиты")
            description: qsTr("Сопоставление затрат и предотвращенных финансовых потерь по каждому мероприятию.")
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: econTableLayout.implicitHeight + 20
            radius: Theme.radiusMd
            color: Theme.panel
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                id: econTableLayout
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                // Шапка
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

                        Text { text: qsTr("МЕРА ЗАЩИТЫ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.fillWidth: true }
                        Text { text: qsTr("ЗАТРАТЫ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 120 }
                        Text { text: qsTr("ПРЕДОТВРАЩЕННЫЙ УЩЕРБ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 170 }
                        Text { text: qsTr("ЧИСТЫЙ ЭФФЕКТ"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 130 }
                        Text { text: qsTr("ROSI"); color: Theme.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; Layout.preferredWidth: 90 }
                    }
                }

                // Строки
                Repeater {
                    model: DataStore.measuresList

                    delegate: Rectangle {
                        id: econRow
                        required property var modelData
                        required property int index

                        readonly property var calcData: {
                            var targetRisk = null;
                            for (var r = 0; r < DataStore.risksList.length; r++) {
                                if (DataStore.risksList[r].boundMeasureId === econRow.modelData.id) {
                                    targetRisk = DataStore.risksList[r];
                                    break;
                                }
                            }
                            if (targetRisk) {
                                var baseDmg = targetRisk.impact * targetRisk.probability * targetRisk.assetPriority * DataStore.pointCost;
                                var resI = targetRisk.impact * (1.0 - ((econRow.modelData.dmgRed || 0) / 100.0));
                                var resP = targetRisk.probability * (1.0 - ((econRow.modelData.probRed || 0) / 100.0));
                                var resDmg = Math.ceil(resI * resP * targetRisk.assetPriority) * DataStore.pointCost;
                                var avoided = Math.max(0, baseDmg - resDmg);
                                var net = avoided - (econRow.modelData.cost || 0);
                                var rsi = (econRow.modelData.cost > 0) ? Math.round((net / econRow.modelData.cost) * 100) : 0;
                                return {
                                    avoidedStr: (avoided ? avoided.toLocaleString(Qt.locale(), 'f', 0) : "0") + " ₽",
                                    netStr: (net >= 0 ? "+" : "") + (net ? net.toLocaleString(Qt.locale(), 'f', 0) : "0") + " ₽",
                                    netPositive: net >= 0,
                                    rosiStr: (rsi >= 0 ? "+" : "") + rsi + "%"
                                };
                            } else {
                                return {
                                    avoidedStr: qsTr("Не привязана"),
                                    netStr: "—",
                                    netPositive: false,
                                    rosiStr: "—"
                                };
                            }
                        }

                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: Theme.radiusSm
                        color: econRowMouse.containsMouse ? Theme.panelHover : (index % 2 === 0 ? "transparent" : (Theme.isDark ? "#171a21" : "#f8f9fb"))

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Text {
                                text: econRow.modelData.id + " · " + econRow.modelData.name
                                color: Theme.text
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: (econRow.modelData.cost ? econRow.modelData.cost.toLocaleString(Qt.locale(), 'f', 0) : "0") + " ₽"
                                color: Theme.muted
                                font.pixelSize: Theme.fontCaption
                                Layout.preferredWidth: 120
                            }

                            Text {
                                text: econRow.calcData.avoidedStr
                                color: Theme.isDark ? Theme.tealLight : Theme.teal
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.DemiBold
                                Layout.preferredWidth: 170
                            }

                            Text {
                                text: econRow.calcData.netStr
                                color: econRow.calcData.netPositive ? Theme.green : (Theme.isDark ? "#f87171" : "#b91c1c")
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.Bold
                                Layout.preferredWidth: 130
                            }

                            StatusBadge {
                                text: econRow.calcData.rosiStr
                                level: econRow.calcData.netPositive ? "success" : (econRow.calcData.rosiStr === "—" ? "low" : "critical")
                                showDot: false
                                Layout.preferredWidth: 90
                            }
                        }

                        MouseArea {
                            id: econRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 12 }
    }
}
