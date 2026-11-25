import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "."
import "tabs"
import "components"

ApplicationWindow {
    id: window
    width: 1366
    height: 840
    minimumWidth: 1200
    minimumHeight: 800
    visible: true
    title: "Net ROSI Calculator — КТ / ФСТЭК / ГОСТ Р ИСО/МЭК 27005"
    color: Style.windowBackground

    property int currentTabIndex: 0

    // Main App Body
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar Navigation
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 210
            color: Style.panelSurface
            border.color: Style.hairlineBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Sidebar Section Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: "МОДУЛИ"
                        font.family: Style.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Style.textSecondary
                    }
                }

                // Nav Items List
                ListView {
                    id: navList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    interactive: false
                    currentIndex: window.currentTabIndex

                    model: [
                        { icon: "assets/icons/dashboard.svg",   label: "Dashboard" },
                        { icon: "assets/icons/assets.svg",      label: "Активы" },
                        { icon: "assets/icons/risks.svg",       label: "Уязвимости" },
                        { icon: "assets/icons/measures.svg",    label: "Меры" },
                        { icon: "assets/icons/criteria.svg",    label: "CVSS 3.1" },
                        { icon: "assets/icons/economics.svg",   label: "Экономика" },
                        { icon: "assets/icons/methodology.svg", label: "Справка" }
                    ]

                    delegate: Rectangle {
                        width: navList.width
                            height: 34
                            color: (window.currentTabIndex === index)
                                   ? Style.surfaceActive
                                   : (navMouse.containsMouse ? Style.surfaceHover : "transparent")

                            // Active Indicator Bar
                            Rectangle {
                                visible: window.currentTabIndex === index
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 3
                                color: Style.primary
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Item {
                                    width: 16
                                    height: 16

                                    Image {
                                        id: iconImg
                                        anchors.fill: parent
                                        source: modelData.icon
                                        sourceSize.width: 16
                                        sourceSize.height: 16
                                        fillMode: Image.PreserveAspectFit
                                        visible: false
                                    }

                                    ColorOverlay {
                                        anchors.fill: iconImg
                                        source: iconImg
                                        color: (window.currentTabIndex === index)
                                               ? Style.textPrimary
                                               : Style.textSecondary
                                    }
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Style.fontSans
                                    font.pixelSize: Style.fontSizeBodyMd
                                    font.weight: (window.currentTabIndex === index) ? Font.DemiBold : Font.Normal
                                    color: (window.currentTabIndex === index) ? Style.textPrimary : Style.textSecondary
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.currentTabIndex = index
                            }
                    }
                }

                // BDU Database Indicator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    color: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable) ? Style.riskLowBg : Style.surfaceLow
                    border.color: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable) ? Style.riskLowBorder : Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable) ? "●" : "○"
                            font.pixelSize: 10
                            color: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable) ? Style.riskLowText : Style.textMuted
                        }
                        Text {
                            text: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable)
                                  ? ("БДУ: " + riskCalculator.formatNumber(riskCalculator.bduTotalCount, 0) + " зап.")
                                  : "БДУ: база не найдена"
                            font.family: Style.fontMono
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: (typeof riskCalculator !== "undefined" && riskCalculator.isBduAvailable) ? Style.riskLowText : Style.textSecondary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }

                // Sidebar Bottom Telemetry
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: Style.surfaceLow
                    border.color: Style.hairlineBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Всего мер:"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: (typeof riskCalculator !== "undefined") ? riskCalculator.totalMeasuresCount.toString() : "4"
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.Bold
                                color: Style.textPrimary
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "ROSI:"; font.family: Style.fontMono; font.pixelSize: Style.fontSizeCodeSm; color: Style.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: (typeof riskCalculator !== "undefined" && riskCalculator.hasValidRosi)
                                      ? ((riskCalculator.netRosiPercent >= 0 ? "+" : "") + riskCalculator.formatNumber(riskCalculator.netRosiPercent, 1) + "%")
                                      : "ROSI: —"
                                font.family: Style.fontMono
                                font.pixelSize: Style.fontSizeCodeSm
                                font.weight: Font.Bold
                                color: (typeof riskCalculator !== "undefined" && riskCalculator.netBenefit >= 0) ? Style.riskLowText : Style.riskCriticalText
                            }
                        }
                    }
                }
            }
        }

        // Main Tab Content Workspace
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Style.windowBackground

            StackLayout {
                id: stackLayout
                anchors.fill: parent
                anchors.margins: 8
                currentIndex: window.currentTabIndex

                DashboardTab {}
                AssetsTab {}
                VulnerabilitiesTab {
                    onOpenCvssCalculator: function(id, vector, score) {
                        cvssTab.openWithVector(id, vector, score)
                        window.currentTabIndex = 4; // Switch to CVSS tab
                    }
                }
                MeasuresTab {}
                CvssCalcTab {
                    id: cvssTab
                }
                EconomicsTab {}
                HelpTab {}
            }
        }
    }

    BduImportModal {
        id: globalBduModal
        anchors.fill: parent
        z: 9999
    }

    function openBdu() {
        globalBduModal.openDefault()
    }

    function openBduForAsset(assetId, assetName, keyword) {
        globalBduModal.openForAsset(assetId, assetName, keyword)
    }

}
