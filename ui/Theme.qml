pragma Singleton

import QtQuick

QtObject {
    // --- ПЕРЕКЛЮЧАТЕЛЬ ТЕМЫ (ПО УМОЛЧАНИЮ СВЕТЛАЯ КОРПОРАТИВНАЯ ТЕМА) ---
    property bool isDark: false

    // Функция переключения темы
    function toggleTheme() {
        isDark = !isDark;
    }

    // --- ФОНОВЫЕ ПОВЕРХНОСТИ (Светлая: бежево-серый / Тёмная: спокойный графит) ---
    readonly property color background: isDark ? "#121418" : "#f4f5f8"
    readonly property color backgroundRaised: isDark ? "#181a20" : "#ffffff"
    readonly property color sidebar: isDark ? "#15181e" : "#ffffff"
    readonly property color sidebarRaised: isDark ? "#1b1f26" : "#f8f9fb"
    readonly property color panel: isDark ? "#1a1d24" : "#ffffff"
    readonly property color panelRaised: isDark ? "#20242c" : "#fafbfe"
    readonly property color panelHover: isDark ? "#262b34" : "#f1f4f9"
    readonly property color raised: isDark ? "#22262f" : "#edf0f5"

    // --- ГРАНИЦЫ И РАЗДЕЛИТЕЛИ ---
    readonly property color border: isDark ? "#2b303b" : "#e2e6ed"
    readonly property color borderHighlight: isDark ? "#3c4352" : "#cbd3e1"

    // --- ТЕКСТ (Глубокий угольный в светлой теме для чтения с расстояния) ---
    readonly property color text: isDark ? "#f8fafc" : "#0f172a"
    readonly property color textSecondary: isDark ? "#cbd5e1" : "#334155"
    readonly property color muted: isDark ? "#94a3b8" : "#556477"
    readonly property color subtle: isDark ? "#64748b" : "#8896a8"

    // --- БЛАГОРОДНЫЕ АКЦЕНТЫ (Строгий Royal Blue & Шалфейный Teal, без неона) ---
    readonly property color accent: isDark ? "#38bdf8" : "#2563eb"
    readonly property color accentLight: isDark ? "#7dd3fc" : "#3b82f6"
    readonly property color accentGlow: isDark ? "#0284c7" : "#1d4ed8"
    readonly property color teal: isDark ? "#2dd4bf" : "#0d9488"
    readonly property color tealLight: isDark ? "#5eead4" : "#14b8a6"
    readonly property color indigo: isDark ? "#818cf8" : "#4f46e5"

    // --- БАЗОВЫЕ ЦВЕТА СТАТУСОВ (Мягкие, сдержанные тона) ---
    readonly property color green: isDark ? "#34d399" : "#15803d"
    readonly property color amber: isDark ? "#fbbf24" : "#b45309"
    readonly property color red: isDark ? "#f87171" : "#b91c1c"

    // --- СЕМАНТИЧЕСКАЯ ШКАЛА РИСКОВ (Четкая градация без ядовитых цветов) ---
    readonly property color riskCritical: isDark ? "#f87171" : "#b91c1c"
    readonly property color riskHigh: isDark ? "#fb923c" : "#c2410c"
    readonly property color riskMedium: isDark ? "#fbbf24" : "#b45309"
    readonly property color riskLow: isDark ? "#34d399" : "#15803d"
    readonly property color riskInfo: isDark ? "#60a5fa" : "#2563eb"

    // --- ПОДЛОЖКИ И ОБВОДКИ БЕЙДЖЕЙ (Пастельные, высокая контрастность текста) ---
    readonly property color badgeCriticalBg: isDark ? "#33161a" : "#fef2f2"
    readonly property color badgeCriticalBorder: isDark ? "#542128" : "#fecaca"

    readonly property color badgeHighBg: isDark ? "#331f13" : "#fff7ed"
    readonly property color badgeHighBorder: isDark ? "#57301c" : "#fed7aa"

    readonly property color badgeMediumBg: isDark ? "#332b12" : "#fefce8"
    readonly property color badgeMediumBorder: isDark ? "#54441b" : "#fef08a"

    readonly property color badgeLowBg: isDark ? "#122e20" : "#f0fdf4"
    readonly property color badgeLowBorder: isDark ? "#1b4d35" : "#bbf7d0"

    readonly property color badgeInfoBg: isDark ? "#14253e" : "#eff6ff"
    readonly property color badgeInfoBorder: isDark ? "#213f6b" : "#bfdbfe"

    // --- ТИПОГРАФИКА (Увеличенная для легкого чтения даже с расстояния) ---
    readonly property int fontMetricBig: 34
    readonly property int fontHero: 28
    readonly property int fontH1: 24
    readonly property int fontTitle: 20
    readonly property int fontH2: 19
    readonly property int fontH3: 16
    readonly property int fontSubtitle: 16
    readonly property int fontBody: 14
    readonly property int fontCaption: 12
    readonly property int fontMicro: 10

    // --- РАДИУСЫ СКРУГЛЕНИЯ ---
    readonly property int radiusXs: 4
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 14
    readonly property int radiusXl: 18

    // --- ГАБАРИТЫ МАКЕТА ---
    readonly property int sidebarWidthExpanded: 252
    readonly property int sidebarWidthCompact: 68
    readonly property int headerHeight: 64
}