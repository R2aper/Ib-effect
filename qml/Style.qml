import QtQuick

pragma Singleton

QtObject {
    id: style

    // Functional Surfaces & Structural Lines (from Stitch DESIGN.md)
    readonly property color windowBackground: "#FAFAFA"
    readonly property color panelSurface: "#FFFFFF"
    readonly property color surfaceHover: "#F4F4F5"
    readonly property color surfaceActive: "#E4E4E7"
    readonly property color surfaceLow: "#F3F3F3"
    readonly property color surfaceContainer: "#EEEEEE"
    readonly property color surfaceContainerHigh: "#E8E8E8"
    readonly property color surfaceContainerHighest: "#E2E2E2"
    readonly property color hairlineBorder: "#E5E5E5"
    readonly property color borderDark: "#D4D4D8"

    // Typography Colors
    readonly property color textPrimary: "#0A0A0A"
    readonly property color textSecondary: "#737373"
    readonly property color textMuted: "#A1A1AA"
    readonly property color textOnDark: "#FFFFFF"

    // Brand & Accent
    readonly property color primary: "#0A0A0A"
    readonly property color primaryHover: "#262626"
    readonly property color primaryPressed: "#404040"
    readonly property color textOnPrimary: "#FFFFFF"

    // Risk Criticality Semantics (Exact values from Stitch DESIGN.md)
    // Low (Низкий)
    readonly property color riskLowText: "#16A34A"
    readonly property color riskLowBg: "#F0FDF4"
    readonly property color riskLowBorder: "#BBF7D0"

    // Medium (Средний)
    readonly property color riskMediumText: "#CA8A04"
    readonly property color riskMediumBg: "#FEFCE8"
    readonly property color riskMediumBorder: "#FEF08A"

    // High (Высокий)
    readonly property color riskHighText: "#EA580C"
    readonly property color riskHighBg: "#FFF7ED"
    readonly property color riskHighBorder: "#FFEDD5"

    // Critical (Критический)
    readonly property color riskCriticalText: "#DC2626"
    readonly property color riskCriticalBg: "#FEF2F2"
    readonly property color riskCriticalBorder: "#FECACA"

    // Typography Font Families
    readonly property string fontSans: "IBM Plex Sans, Segoe UI, -apple-system, sans-serif"
    readonly property string fontMono: "JetBrains Mono, Consolas, Courier New, monospace"

    // Font Sizes
    readonly property int fontSizeMetricDisplay: 22
    readonly property int fontSizeHeadlineLg: 18
    readonly property int fontSizeHeadlineMd: 15
    readonly property int fontSizeHeadlineSm: 13
    readonly property int fontSizeBodyLg: 13
    readonly property int fontSizeBodyMd: 12
    readonly property int fontSizeBodySm: 11
    readonly property int fontSizeCodeMd: 12
    readonly property int fontSizeCodeSm: 11
    readonly property int fontSizeBadge: 10

    // Helper functions for Risk Criticality
    function getRiskColor(level) {
        var l = (level || "").toLowerCase();
        if (l.indexOf("критич") !== -1 || l.indexOf("crit") !== -1) return riskCriticalText;
        if (l.indexOf("высок") !== -1 || l.indexOf("high") !== -1) return riskHighText;
        if (l.indexOf("средн") !== -1 || l.indexOf("med") !== -1) return riskMediumText;
        return riskLowText;
    }

    function getRiskBg(level) {
        var l = (level || "").toLowerCase();
        if (l.indexOf("критич") !== -1 || l.indexOf("crit") !== -1) return riskCriticalBg;
        if (l.indexOf("высок") !== -1 || l.indexOf("high") !== -1) return riskHighBg;
        if (l.indexOf("средн") !== -1 || l.indexOf("med") !== -1) return riskMediumBg;
        return riskLowBg;
    }

    function getRiskBorder(level) {
        var l = (level || "").toLowerCase();
        if (l.indexOf("критич") !== -1 || l.indexOf("crit") !== -1) return riskCriticalBorder;
        if (l.indexOf("высок") !== -1 || l.indexOf("high") !== -1) return riskHighBorder;
        if (l.indexOf("средн") !== -1 || l.indexOf("med") !== -1) return riskMediumBorder;
        return riskLowBorder;
    }
}
