cmake_minimum_required(VERSION 3.21)
project(msicenter-ui VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick DBus QuickControls2 Widgets)

qt_standard_project_setup()

qt_add_executable(msicenter-ui
    src/main.cpp
    src/centerclient.cpp
    src/centerclient.h
)

qt_add_resources(msicenter-ui "qml"
    PREFIX "/"
    FILES
        qml/Main.qml
        qml/StatCard.qml
        qml/OverviewPage.qml
        qml/PowerPage.qml
        qml/BatteryPage.qml
        qml/RgbPage.qml
        qml/ScenesPage.qml
        qml/DiagnosticsPage.qml
        qml/OSD.qml
)

target_link_libraries(msicenter-ui PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::DBus
    Qt6::QuickControls2
    Qt6::Widgets
)
