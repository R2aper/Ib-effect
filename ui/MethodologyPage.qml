import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    clip: true
    padding: 24
    contentWidth: availableWidth

    ColumnLayout {
        width: parent.width
        spacing: 16
        SectionHeading {
            eyebrow: qsTr("МЕТОДИКА РАСЧЁТА")
            heading: qsTr("Методика")
            description: qsTr("Формулы и принципы, используемые в модели оценки ИБ.")
        }
        PlaceholderCard {
            glyph: "01"
            heading: qsTr("Формула расчёта риска")
            description: qsTr("Риск = Ущерб × Вероятность × Приоритет актива. Балльная оценка — от 1 до 64.")
        }
        PlaceholderCard {
            glyph: "02"
            heading: qsTr("Остаточный риск")
            description: qsTr("Ущерб с учётом снижения × вероятность с учётом снижения × приоритет актива.")
        }
        PlaceholderCard {
            glyph: "03"
            heading: qsTr("Ожидаемый ущерб")
            description: qsTr("Ожидаемый ущерб = Баллы риска × Стоимость одного балла риска.")
        }
        PlaceholderCard {
            glyph: "04"
            heading: qsTr("Net ROSI")
            description: qsTr("((Снижение потерь − Стоимость меры) / Стоимость меры) × 100%.")
        }
        PlaceholderCard {
            glyph: "05"
            heading: qsTr("Чистый экономический эффект")
            description: qsTr("(Ожидаемые потери до мер − Потери после мер) − Стоимость всех мер.")
        }
        PlaceholderCard {
            glyph: "06"
            heading: qsTr("Экономический эффект")
            description: qsTr("Сумма снижения ожидаемых потерь по всем рискам до вычета затрат на меры.")
        }
        Item { Layout.preferredHeight: 12 }
    }
}
