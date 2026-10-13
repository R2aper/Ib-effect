cmake_minimum_required(VERSION 3.16)

project(Ib-effect VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.5)

set(IBE_UI_QML_FILES
    ui/Theme.qml
    ui/NavigationButton.qml
    ui/SectionHeading.qml
    ui/MetricCard.qml
    ui/PlaceholderCard.qml
    ui/AppSidebar.qml
    ui/AppHeader.qml
    ui/DashboardPage.qml
    ui/RiskModelPage.qml
    ui/AssetsPage.qml
    ui/RisksPage.qml
    ui/ProtectionMeasuresPage.qml
    ui/EconomicsPage.qml
    ui/MethodologyPage.qml
)

set_source_files_properties(ui/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
    QT_RESOURCE_ALIAS Theme.qml
)

foreach(qml_file IN LISTS IBE_UI_QML_FILES)
    if(NOT qml_file STREQUAL "ui/Theme.qml")
        get_filename_component(qml_name "${qml_file}" NAME)
        set_source_files_properties("${qml_file}" PROPERTIES
            QT_RESOURCE_ALIAS "${qml_name}"
        )
    endif()
endforeach()

qt_add_executable(Ibe
    main.cpp
)

qt_add_qml_module(Ibe
    URI Ibe
    QML_FILES
        Main.qml
        ${IBE_UI_QML_FILES}
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(Ibe PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.Ibe
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(Ibe
    PRIVATE Qt6::Quick Qt6::QuickControls2
)

install(TARGETS Ibe
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
