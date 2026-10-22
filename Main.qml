import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: window

    width: 1440
    height: 900
    minimumWidth: 980
    minimumHeight: 680
    visible: true
    title: qsTr("IB-effect")
    color: Theme.background

    property int currentTab: 0

    Component.onCompleted: {
        AssetService.load();
        RiskService.load();
        MeasureService.load();
        EconomicsService.refresh();
    }

    readonly property var sectionNames: [
        qsTr("Панель эффективности"),
        qsTr("Модель риска"),
        qsTr("Активы"),
        qsTr("Риски"),
        qsTr("Меры защиты"),
        qsTr("Экономика"),
        qsTr("Методика")
    ]

    RowLayout {
        anchors.fill: parent
        spacing: 0

        AppSidebar {
            currentTab: window.currentTab
            compactMode: window.width < 1200
            onTabSelected: index => window.currentTab = index
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            AppHeader {
                currentTitle: window.sectionNames[window.currentTab]
            }

            StackLayout {
                currentIndex: window.currentTab
                Layout.fillWidth: true
                Layout.fillHeight: true

                DashboardPage {}
                RiskModelPage {}
                AssetsPage {}
                RisksPage {}
                ProtectionMeasuresPage {}
                EconomicsPage {}
                MethodologyPage {}
            }
        }
    }

    AuthModal {
        id: authModal
    }

    Connections {
        target: AssetService
        function onOperationFinished(requestId, operation, success) {
            if (success && operation !== "assets.list")
                DashboardService.refresh();
        }
    }

    Connections {
        target: RiskService
        function onOperationFinished(requestId, operation, success) {
            if (success && operation !== "risks.list")
                DashboardService.refresh();
        }
    }

    Connections {
        target: MeasureService
        function onOperationFinished(requestId, operation, success) {
            if (success && operation !== "measures.list")
                DashboardService.refresh();
        }
    }
}
