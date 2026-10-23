import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "DocumentLinks.js" as DocumentLinks

ScrollView {
    clip: true
    padding: 24
    contentWidth: availableWidth
    contentHeight: pageContent.implicitHeight

    ColumnLayout {
        id: pageContent
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
            purpose: qsTr("Финансовое сопоставление предотвращенного ущерба (ΔLoss) с совокупной стоимостью владения мерами (TCO).")
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
                value: (EconomicsService.summary.initialLosses >= 1000000 ? (EconomicsService.summary.initialLosses / 1000000).toFixed(1) + "M ₽" : (EconomicsService.summary.initialLosses / 1000).toFixed(0) + "K ₽")
                delta: "Базовый риск"
                deltaIsGood: false
                note: qsTr("Суммарный вероятный ущерб без защиты")
                accentColor: Theme.riskCritical
                valueColor: Theme.riskCritical
            }

            KpiStatCard {
                label: qsTr("ОСТАТОЧНЫЕ ПОТЕРИ")
                value: (EconomicsService.summary.residualLosses >= 1000000 ? (EconomicsService.summary.residualLosses / 1000000).toFixed(1) + "M ₽" : (EconomicsService.summary.residualLosses / 1000).toFixed(0) + "K ₽")
                delta: EconomicsService.summary.initialLosses > 0 ? ("-" + Math.round(((EconomicsService.summary.initialLosses - EconomicsService.summary.residualLosses) / EconomicsService.summary.initialLosses) * 100) + "% ↓") : "0%"
                deltaIsGood: true
                note: qsTr("Остаточный риск после внедрения мер")
                accentColor: Theme.green
                valueColor: Theme.green
            }

            KpiStatCard {
                label: qsTr("ИНВЕСТИЦИИ В ЗАЩИТУ")
                value: (EconomicsService.summary.totalMeasuresCost >= 1000000 ? (EconomicsService.summary.totalMeasuresCost / 1000000).toFixed(1) + "M ₽" : (EconomicsService.summary.totalMeasuresCost / 1000).toFixed(0) + "K ₽")
                delta: "CAPEX+OPEX"
                deltaIsGood: true
                note: qsTr("Совокупная стоимость владения (TCO)")
                accentColor: Theme.accent
                valueColor: Theme.isDark ? Theme.accentLight : Theme.accent
            }

            KpiStatCard {
                label: qsTr("КОЭФФИЦИЕНТ ROSI")
                value: (EconomicsService.summary.rosi >= 0 ? "+" : "") + EconomicsService.summary.rosi + "%"
                delta: EconomicsService.summary.rosi >= 0 ? "Окупаем" : "Неокупаем"
                deltaIsGood: EconomicsService.summary.rosi >= 0
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
            color: Theme.isDark ? (EconomicsService.summary.netBenefit >= 0 ? "#14251d" : "#2a1515") : (EconomicsService.summary.netBenefit >= 0 ? "#f0fdf4" : "#fef2f2")
            border.color: Theme.isDark ? (EconomicsService.summary.netBenefit >= 0 ? "#1d4b38" : "#592020") : (EconomicsService.summary.netBenefit >= 0 ? "#bbf7d0" : "#fecaca")
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
                            text: EconomicsService.summary.netBenefit >= 0 ? qsTr("ПОЛОЖИТЕЛЬНЫЙ ЭФФЕКТ") : qsTr("ОТРИЦАТЕЛЬНЫЙ ЭФФЕКТ")
                            level: EconomicsService.summary.netBenefit >= 0 ? "success" : "critical"
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
                            text: (EconomicsService.summary.netBenefit >= 0 ? "+" : "") + (EconomicsService.summary.netBenefit).toLocaleString(Qt.locale(), 'f', 0) + " ₽"
                            color: EconomicsService.summary.netBenefit >= 0 ? (Theme.isDark ? "#4ade80" : "#15803d") : (Theme.isDark ? "#f87171" : "#b91c1c")
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
                            (EconomicsService.summary.avoidedDamage >= 1000000 ? (EconomicsService.summary.avoidedDamage / 1000000).toFixed(1) + "M ₽" : (EconomicsService.summary.avoidedDamage / 1000).toFixed(0) + "K ₽")
                        ).arg(
                            (EconomicsService.summary.totalMeasuresCost >= 1000000 ? (EconomicsService.summary.totalMeasuresCost / 1000000).toFixed(1) + "M ₽" : (EconomicsService.summary.totalMeasuresCost / 1000).toFixed(0) + "K ₽")
                        )
                        color: EconomicsService.summary.netBenefit >= 0 ? (Theme.isDark ? "#86efac" : "#166534") : (Theme.isDark ? "#fca5a5" : "#991b1b")
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
                            text: EconomicsService.summary.multiplier
                            color: EconomicsService.summary.netBenefit >= 0 ? (Theme.isDark ? "#34d399" : "#15803d") : (Theme.isDark ? "#f87171" : "#b91c1c")
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
                            text: qsTr("Оценка предотвращенного косвенного ущерба от остановки оборудования")
                            color: Theme.muted
                            font.pixelSize: Theme.fontCaption
                        }
                    }

                    StatusBadge {
                        text: AssetService.industrialMode ? qsTr("Промышленный контур АСУ ТП") : qsTr("Корпоративный IT-контур")
                        level: AssetService.industrialMode ? "teal" : "info"
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: qsTr("Стоимость часа простоя линии (₽/ч):"); color: Theme.muted; font.pixelSize: Theme.fontCaption }
                        Text { text: (EconomicsService.summary.downtimeHourlyCost).toLocaleString(Qt.locale(), 'f', 0) + " ₽/ч"; color: Theme.text; font.pixelSize: Theme.fontH2; font.weight: Font.Bold }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: qsTr("Время восстановления (MTTR):"); color: Theme.muted; font.pixelSize: Theme.fontCaption }
                        Text { text: EconomicsService.summary.mttrHours + " " + qsTr("часов"); color: Theme.text; font.pixelSize: Theme.fontH2; font.weight: Font.Bold }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: qsTr("Предотвращенный ущерб от простоя:"); color: Theme.muted; font.pixelSize: Theme.fontCaption }
                        Text { text: ((EconomicsService.summary.downtimeHourlyCost * EconomicsService.summary.mttrHours) / 1000000).toFixed(1) + "M ₽"; color: Theme.green; font.pixelSize: Theme.fontH2; font.weight: Font.Bold }
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
            border.color: statusMsg ? (reportBox.exportSucceeded ? Theme.green : Theme.riskCritical) : Theme.accent
            property bool exportSucceeded: false
            border.width: 1

            function getLevelName(level) {
                if (level === "critical") return qsTr("Критический");
                if (level === "high") return qsTr("Высокий");
                if (level === "medium") return qsTr("Средний");
                return qsTr("Низкий");
            }

            function buildReportMarkdown() {
                var md = "";
                var now = new Date();
                var dateStr = now.toLocaleDateString() + " " + now.toLocaleTimeString();

                md += "# МОДЕЛЬ УГРОЗ БЕЗОПАСНОСТИ ИНФОРМАЦИИ И РАСЧЕТ ЭКОНОМИЧЕСКОГО ЭФФЕКТА СУИБ\n\n";
                md += "**Организация:** " + (AuthService.user.org || "СибГУТИ / Промышленное предприятие") + "\n";
                md += "**Ответственный исполнитель:** " + (AuthService.user.name || "Иван Остренко") + " (" + (AuthService.user.role || "Специалист ИБ") + ")\n";
                md += "**Дата формирования:** " + dateStr + "\n";
                md += "**Нормативная основа:** ГОСТ 19.505-79 (Руководство оператора), Методика моделирования угроз ФСТЭК России от 05.02.2021, ГОСТ Р ИСО/МЭК 27005-2010, ГОСТ Р 57580.3-2022, Приказ ФСТЭК России № 239.\n\n";
                md += "---\n\n";

                md += "## 1. ПЕРЕЧЕНЬ И КАТЕГОРИРОВАНИЕ ЗАЩИЩАЕМЫХ АКТИВОВ\n\n";
                md += "| ID | Наименование актива | Тип объекта ФСТЭК | Категория | Стоимость (₽) | Приоритет A (1..4) | Статус |\n";
                md += "| :--- | :--- | :--- | :--- | :---: | :---: | :---: |\n";
                var assets = EconomicsService.summary.assets;
                for (var a = 0; a < assets.length; a++) {
                    var ast = assets[a];
                    md += "| " + ast.id + " | " + ast.name + " | " + (ast.oaCode ? (ast.oaCode + " (" + ast.oaTitle + ")") : "Общий IT") + " | " + ast.cat + " | " + (ast.cost ? ast.cost.toLocaleString() : "0") + " | " + ast.prio + " | " + (ast.status || "На защите") + " |\n";
                }
                md += "\n**Суммарная балансовая стоимость активов:** " + EconomicsService.summary.totalAssetsCost.toLocaleString() + " ₽\n\n";
                md += "---\n\n";

                md += "## 2. ИДЕНТИФИЦИРОВАННЫЕ УГРОЗЫ БЕЗОПАСНОСТИ И РАСЧЕТ РИСКОВ\n\n";
                md += "| ID | Код/Угроза (БДУ ФСТЭК) | Уязвимость / Способ атак (СПА) | Связанный актив | I (1..4) | P (1..4) | A (1..4) | Начальный балл | Уровень риска | Остаточный балл | Риск-аппетит |\n";
                md += "| :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |\n";
                var risks = EconomicsService.summary.risks;
                for (var r = 0; r < risks.length; r++) {
                    var rsk = risks[r];
                    md += "| " + rsk.id + " | " + rsk.threat + " | " + rsk.vuln + " | " + rsk.assetName + " | " + rsk.impact + " | " + rsk.probability + " | " + rsk.assetPriority + " | " + rsk.score + " | " + reportBox.getLevelName(rsk.scoreLevel) + " | " + rsk.residualScore + " | " + (rsk.appetiteExceeded ? "Выше порога" : "В пределах") + " |\n";
                }
                md += "\n**Критерии риск-аппетита:** Порог допустимого остаточного риска = " + EconomicsService.riskAppetite + " баллов. Остаточный балл не выше порога находится в пределах аппетита; превышение требует обработки или документированного принятия. Стоимость балла = " + EconomicsService.pointCost.toLocaleString() + " ₽.\n\n";
                md += "---\n\n";

                md += "## 3. ПОРТФЕЛЬ КОМПЕНСИРУЮЩИХ МЕР (ПРИКАЗ ФСТЭК № 239 / ГОСТ Р 57580.3-2022)\n\n";
                md += "| ID | Наименование мероприятия / СЗИ | Тип | Затраты TCO (₽) | Снижение ΔI (%) | Снижение ΔP (%) | Связанный риск | Статус |\n";
                md += "| :--- | :--- | :--- | :---: | :---: | :---: | :--- | :---: |\n";
                var measures = EconomicsService.summary.measures;
                for (var m = 0; m < measures.length; m++) {
                    var msr = measures[m];
                    md += "| " + msr.id + " | " + msr.name + " | " + msr.type + " | " + (msr.cost ? msr.cost.toLocaleString() : "0") + " | " + msr.dmgRed + "% | " + msr.probRed + "% | " + (msr.boundRiskId || "Не привязана") + " | " + msr.status + " |\n";
                }
                md += "\n**Совокупный бюджет мероприятий по защите:** " + EconomicsService.summary.totalMeasuresCost.toLocaleString() + " ₽\n\n";
                md += "---\n\n";

                md += "## 4. ФИНАНСОВО-ЭКОНОМИЧЕСКОЕ ОБОСНОВАНИЕ (NET ROSI)\n\n";
                md += "* **Потенциальный ущерб до внедрения мер:** " + EconomicsService.summary.initialLosses.toLocaleString() + " ₽\n";
                md += "* **Остаточный ущерб после реализации мер:** " + EconomicsService.summary.residualLosses.toLocaleString() + " ₽\n";
                md += "* **Предотвращенный финансовый ущерб (ΔLoss):** " + EconomicsService.summary.avoidedDamage.toLocaleString() + " ₽\n";
                md += "* **Инвестиции в системы защиты информации (TCO):** " + EconomicsService.summary.totalMeasuresCost.toLocaleString() + " ₽\n";
                md += "* **Чистый экономический эффект (Net Benefit):** " + (EconomicsService.summary.netBenefit >= 0 ? "+" : "") + EconomicsService.summary.netBenefit.toLocaleString() + " ₽\n";
                md += "* **Коэффициент окупаемости Net ROSI:** **" + (EconomicsService.summary.rosi >= 0 ? "+" : "") + EconomicsService.summary.rosi + "%**\n";
                md += "* **Мультипликатор возврата инвестиций:** **" + EconomicsService.summary.multiplier + "**\n\n";

                if (AssetService.industrialMode) {
                    md += "### Экономика простоя технологического процесса (Downtime Economics):\n";
                    md += "* Стоимость 1 часа аварийного останова производственной линии: " + EconomicsService.summary.downtimeHourlyCost.toLocaleString() + " ₽/час\n";
                    md += "* Среднее расчетное время восстановления АСУ ТП (MTTR): " + EconomicsService.summary.mttrHours + " часов\n";
                    md += "* Предотвращенный косвенный технологический ущерб: " + (EconomicsService.summary.downtimeHourlyCost * EconomicsService.summary.mttrHours).toLocaleString() + " ₽\n\n";
                }

                md += "---\n\n";
                md += "*Документ сгенерирован в Системе автоматизации оценки рисков и эффективности ИБ («ИБ-Эффект»). Соответствует требованиям ГОСТ 19.505-79 и ГОСТ 7.32.*\n";
                return DocumentLinks.linkifyMarkdown(md);
            }

            ColumnLayout {
                id: reportCol
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

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
                            text: DocumentLinks.linkify(qsTr("Экспорт структурированного отчета"))
                            textFormat: Text.RichText
                            color: Theme.muted
                            font.pixelSize: Theme.fontCaption
                            onLinkActivated: link => Qt.openUrlExternally(link)
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
                                reportBox.exportSucceeded = ReportExporter.saveReport(fileName, content);
                                reportBox.statusMsg = reportBox.exportSucceeded
                                        ? qsTr("Отчет успешно сформирован и сохранен в файл «%1».").arg(fileName)
                                        : qsTr("Не удалось сохранить отчет в файл «%1». Проверьте доступ к папке приложения.").arg(fileName);
                            }
                        }
                    }
                }

                Text {
                    visible: reportBox.statusMsg !== ""
                    text: reportBox.statusMsg
                    color: reportBox.exportSucceeded ? Theme.green : Theme.riskCritical
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
                    model: EconomicsService.summary.measureBreakdown

                    delegate: Rectangle {
                        id: econRow
                        required property var modelData
                        required property int index

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
                                text: econRow.modelData.hasRisk
                                      ? econRow.modelData.avoidedDamage.toLocaleString(Qt.locale(), 'f', 0) + " ₽"
                                      : qsTr("Не привязана")
                                color: Theme.isDark ? Theme.tealLight : Theme.teal
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.DemiBold
                                Layout.preferredWidth: 170
                            }

                            Text {
                                text: econRow.modelData.hasRisk
                                      ? (econRow.modelData.netBenefit >= 0 ? "+" : "") + econRow.modelData.netBenefit.toLocaleString(Qt.locale(), 'f', 0) + " ₽"
                                      : "—"
                                color: !econRow.modelData.hasRisk ? Theme.muted
                                      : (econRow.modelData.netBenefit >= 0 ? Theme.green : (Theme.isDark ? "#f87171" : "#b91c1c"))
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.Bold
                                Layout.preferredWidth: 130
                            }

                            StatusBadge {
                                text: econRow.modelData.hasRisk
                                      ? (econRow.modelData.rosi >= 0 ? "+" : "") + econRow.modelData.rosi + "%"
                                      : "—"
                                level: econRow.modelData.hasRisk
                                       ? (econRow.modelData.netBenefit >= 0 ? "success" : "critical")
                                       : "low"
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
