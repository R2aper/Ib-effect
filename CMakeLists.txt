cmake_minimum_required(VERSION 3.16)

project(New VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql)

qt_standard_project_setup(REQUIRES 6.5)

set_source_files_properties(Style.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

# Content of downloaded design from Figma to Qt or similar
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

qt_add_executable(appNew
    main.cpp
    RiskCalculator.cpp
    RiskCalculator.h
    BduDatabase.cpp
    BduDatabase.h
    RiskStorage.h
    RiskStorage.cpp
)

qt_add_qml_module(appNew
    URI New
    SOURCES
        Cvsscalculator.cpp
        Cvsscalculator.h
        RiskStorage.h
        RiskStorage.cpp
    QML_FILES
        Main.qml
        Style.qml
        tabs/AssetsTab.qml
        tabs/CvssCalcTab.qml
        tabs/DashboardTab.qml
        tabs/EconomicsTab.qml
        tabs/HelpTab.qml
        tabs/MeasuresTab.qml
        tabs/VulnerabilitiesTab.qml
        components/AppButton.qml
        components/CustomComboBox.qml
        components/CustomTextField.qml
        components/MetricCard.qml
        components/RiskBadge.qml
        components/SegmentedControl.qml
        components/TableHeaderCell.qml
        components/BduImportModal.qml
        components/SupportingAssetModal.qml
        assets/icons/dashboard.svg
        assets/icons/assets.svg
        assets/icons/risks.svg
        assets/icons/measures.svg
        assets/icons/criteria.svg
        assets/icons/economics.svg
        assets/icons/methodology.svg
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appNew PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appNew
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appNew
    PRIVATE Qt6::Quick Qt6::Sql
)

include(GNUInstallDirs)

install(TARGETS appNew
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/bdu.sqlite")
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/bdu.sqlite"
        DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
endif()

if(COMMAND qt_generate_deploy_qml_app_script)
    qt_generate_deploy_qml_app_script(
        TARGET appNew
        OUTPUT_SCRIPT deploy_script
    )
    install(SCRIPT ${deploy_script})
endif()
