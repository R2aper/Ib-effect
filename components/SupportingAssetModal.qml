import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    property bool isOpen: false
    signal assetSelected(string assetName, int componentType)

    visible: isOpen
    anchors.fill: parent
    z: 1000

    property string searchKeyword: ""
    property int selectedCategoryIndex: 0

    readonly property var catalog: [
        // --- СУБД ---
        { category: "СУБД и базы данных", name: "srv-db01 (PostgreSQL Database)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Реляционная СУБД хранения транзакций и данных" },
        { category: "СУБД и базы данных", name: "srv-db02 (PostgreSQL Standby Cluster)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Отказоустойчивый резервный узел кластера СУБД" },
        { category: "СУБД и базы данных", name: "srv-db-mysql (MySQL / MariaDB Server)", compType: 3, compTypeName: "Сервер (0.35)", desc: "СУБД веб-портала и клиентских профилей" },
        { category: "СУБД и базы данных", name: "srv-db-mssql (Microsoft SQL Server)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Корпоративная СУБД учетных систем" },
        { category: "СУБД и базы данных", name: "srv-db-ora (Oracle Database Enterprise)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Высоконагруженная СУБД биллинга и ядра" },
        { category: "СУБД и базы данных", name: "srv-cache01 (Redis In-Memory Cache)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Кэш сессий пользователей и очередей задач" },

        // --- Веб-серверы и шлюзы ---
        { category: "Веб-серверы и шлюзы", name: "srv-web01 (Nginx Web Server / Reverse Proxy)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Входной фронтенд-сервер публикации интернет-ресурсов" },
        { category: "Веб-серверы и шлюзы", name: "srv-web02 (Apache HTTP Server)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Веб-сервер внутренних приложений и сервисов" },
        { category: "Веб-серверы и шлюзы", name: "gw-api01 (API Gateway / Ingress Controller)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Шлюз микросервисного API и мобильного приложения" },
        { category: "Веб-серверы и шлюзы", name: "app-node01 (Node.js / Express Backend)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Сервер бизнес-логики клиентского обслуживания" },

        // --- Корпоративное ПО ---
        { category: "Корпоративные сервисы", name: "srv-1c01 (Сервер 1С:Предприятие)", compType: 0, compTypeName: "Критический (0.55)", desc: "Центральный сервер бухгалтерского и складского учета" },
        { category: "Корпоративные сервисы", name: "srv-git01 (GitLab Server & CI/CD)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Репозиторий исходных кодов ядра системы и сборки" },
        { category: "Корпоративные сервисы", name: "dc-ad01 (Active Directory Domain Controller)", compType: 0, compTypeName: "Критический (0.55)", desc: "Контроллер домена, служба Kerberos и управление доступом" },
        { category: "Корпоративные сервисы", name: "srv-mail01 (Корпоративный почтовый сервер)", compType: 3, compTypeName: "Сервер (0.35)", desc: "Сервер обмена деловой корреспонденцией" },

        // --- Сеть и безопасность ---
        { category: "Сетевое оборудование и ИБ", name: "gw-fw01 (Межсетевой экран NGFW)", compType: 1, compTypeName: "Сетевое (0.40)", desc: "Шлюз фильтрации трафика и разграничения сетевых сегментов" },
        { category: "Сетевое оборудование и ИБ", name: "waf-node01 (Кластер Web Application Firewall)", compType: 1, compTypeName: "Сетевое (0.40)", desc: "Комплекс фильтрации атак уровня L7 на веб-сервисы" },
        { category: "Сетевое оборудование и ИБ", name: "vpn-gw01 (VPN-шлюз удаленного доступа сотрудников)", compType: 1, compTypeName: "Сетевое (0.40)", desc: "Криптографический шлюз защиты удаленных подключений" },

        // --- Рабочие станции ---
        { category: "Рабочие станции (АРМ)", name: "ws-acc01 (АРМ главного бухгалтера / Клиент-Банк)", compType: 4, compTypeName: "АРМ (0.25)", desc: "Рабочее место работы с платежами и ЭЦП" },
        { category: "Рабочие станции (АРМ)", name: "ws-sec01 (АРМ администратора ИБ / SIEM)", compType: 4, compTypeName: "АРМ (0.25)", desc: "Рабочая станция мониторинга и управления безопасностью" },
        { category: "Рабочие станции (АРМ)", name: "ws-dev01 (АРМ ведущего разработчика)", compType: 4, compTypeName: "АРМ (0.25)", desc: "Рабочая станция с доступом к кодовой базе и репозиториям" },

        // --- АСУ ТП / SCADA ---
        { category: "АСУ ТП и технологические сети", name: "scada-node01 (Сервер SCADA / Ядро диспетчеризации)", compType: 0, compTypeName: "Критический (0.55)", desc: "Сервер сбора телеметрии и управления технологическим процессом" },
        { category: "АСУ ТП и технологические сети", name: "plc-ctrl01 (Программируемый логический контроллер ПЛК)", compType: 0, compTypeName: "Критический (0.55)", desc: "Нижний уровень АСУ ТП, управление исполнительными механизмами" }
    ]

    readonly property var categories: [
        "Все категории",
        "СУБД и базы данных",
        "Веб-серверы и шлюзы",
        "Корпоративные сервисы",
        "Сетевое оборудование и ИБ",
        "Рабочие станции (АРМ)",
        "АСУ ТП и технологические сети"
    ]

    readonly property var filteredCatalog: {
        var q = searchKeyword.trim().toLowerCase()
        var selCat = categories[selectedCategoryIndex]
        return catalog.filter(function(item) {
            if (selCat !== "Все категории" && item.category !== selCat) return false
            if (q === "") return true
            return item.name.toLowerCase().indexOf(q) !== -1 ||
                   item.desc.toLowerCase().indexOf(q) !== -1 ||
                   item.category.toLowerCase().indexOf(q) !== -1
        })
    }

    // Затененный фон
    Rectangle {
        anchors.fill: parent
        color: "#90000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.isOpen = false
        }
    }

    // Модальное окно
    Rectangle {
        id: modalDialog
        width: Math.min(parent.width - 40, 820)
        height: Math.min(parent.height - 40, 620)
        anchors.centerIn: parent
        color: Style.panelSurface
        border.color: Style.borderDark
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Шапка
            Rectangle {
                Layout.fillWidth: true
                height: 52
                color: Style.surfaceContainer
                border.color: Style.hairlineBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Rectangle {
                        width: 28
                        height: 28
                        color: Style.primary
                        Text {
                            anchors.centerIn: parent
                            text: "ИТ"
                            font.family: Style.fontMono
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Style.textOnPrimary
                        }
                    }

                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: "Каталог вспомогательных активов (ИТ-компонентов)"
                            font.family: Style.fontSans
                            font.pixelSize: Style.fontSizeHeadlineSm
                            font.weight: Font.Bold
                            color: Style.textPrimary
                        }
                        Text {
                            text: "Выберите типовой компонент для автоматической привязки уязвимостей и параметров инфраструктуры"
                            font.family: Style.fontSans
                            font.pixelSize: 11
                            color: Style.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    AppButton {
                        text: "✕"
                        onClicked: root.isOpen = false
                    }
                }
            }

            // Поисковая панель и фильтр категорий
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: Style.surfaceLow
                border.color: Style.hairlineBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    CustomTextField {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: "Поиск компонента (например: PostgreSQL, Nginx, 1C, GitLab, SCADA)..."
                        text: root.searchKeyword
                        onTextChanged: root.searchKeyword = text
                    }

                    CustomComboBox {
                        Layout.preferredWidth: 240
                        model: root.categories
                        currentIndex: root.selectedCategoryIndex
                        onCurrentIndexChanged: root.selectedCategoryIndex = currentIndex
                    }
                }
            }

            // Список элементов
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.filteredCatalog

                delegate: Rectangle {
                    width: listView.width
                    height: 56
                    color: itemMouse.containsMouse ? Style.surfaceHover : (index % 2 === 0 ? Style.panelSurface : Style.surfaceLow)
                    border.color: Style.hairlineBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Rectangle {
                            implicitWidth: typeBadgeText.implicitWidth + 10
                            height: 22
                            color: Style.surfaceContainerHighest
                            radius: 2
                            Text {
                                id: typeBadgeText
                                anchors.centerIn: parent
                                text: modelData.compTypeName
                                font.family: Style.fontMono
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: Style.textPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.name
                                font.family: Style.fontSans
                                font.pixelSize: Style.fontSizeBodySm
                                font.weight: Font.Bold
                                color: Style.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.desc
                                font.family: Style.fontSans
                                font.pixelSize: 11
                                color: Style.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        AppButton {
                            text: "Выбрать"
                            isPrimary: true
                            onClicked: {
                                root.assetSelected(modelData.name, modelData.compType)
                                root.isOpen = false
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.assetSelected(modelData.name, modelData.compType)
                            root.isOpen = false
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.filteredCatalog.length === 0
                    text: "Компоненты по запросу не найдены"
                    font.family: Style.fontSans
                    font.pixelSize: Style.fontSizeBodyMd
                    color: Style.textMuted
                }
            }

            // Футер
            Rectangle {
                Layout.fillWidth: true
                height: 44
                color: Style.surfaceContainer
                border.color: Style.hairlineBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14

                    Text {
                        text: "Всего доступно типовых компонентов: " + root.catalog.length
                        font.family: Style.fontMono
                        font.pixelSize: 10
                        color: Style.textSecondary
                    }

                    Item { Layout.fillWidth: true }

                    AppButton {
                        text: "Закрыть"
                        onClicked: root.isOpen = false
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen
        onActivated: root.isOpen = false
    }
}
