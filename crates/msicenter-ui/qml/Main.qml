import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 1000
    height: 680
    minimumWidth: 860
    minimumHeight: 580
    title: "MSI Linux Center"

    // Closing hides to the system tray when one is available; Quit lives
    // in the tray menu.
    onClosing: (close) => {
        if (trayAvailable) {
            close.accepted = false
            root.hide()
        }
    }
    Material.theme: Material.Dark
    Material.primary: "#E2A35B"
    Material.accent: "#E2A35B"
    Material.background: "#1B1815"

    property int currentPage: 0

    // ---- Top bar ----
    header: ToolBar {
        Material.background: "#201C17"
        implicitHeight: 56
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 12
            spacing: 12

            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: center.lastError !== ""
                           ? "#DD6B58"
                           : (center.profileText !== ""
                                  ? "#A9BA7C"
                                  : "#8C7F6F")
            }
            Label {
                text: "MSI Linux Center"
                font.pixelSize: 16
                font.bold: true
                color: "#E8DCCB"
            }
            Label {
                text: "hardware management"
                color: "#8C7F6F"
                font.pixelSize: 11
                visible: root.width > 900
            }
            Item { Layout.fillWidth: true }

            Rectangle {
                visible: center.supportText !== ""
                radius: 9
                color: "#E2A35B"
                implicitHeight: 20
                implicitWidth: supportLabel.implicitWidth + 18
                Label {
                    id: supportLabel
                    anchors.centerIn: parent
                    text: center.supportText
                    font.pixelSize: 11
                    font.bold: true
                    color: "#1B1815"
                }
            }
            Button {
                text: qsTr("Refresh")
                onClicked: center.refreshNow()
            }
        }
    }

    // ---- Global action banner ----
    Rectangle {
        id: banner
        visible: center.actionMessage !== ""
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: visible ? 34 : 0
        color: center.actionError ? "#3B241D" : "#2C3220"
        Label {
            anchors.fill: parent
            anchors.margins: 8
            text: (center.actionError ? "✗ " : "✓ ") + center.actionMessage
            color: center.actionError ? "#DD6B58" : "#A9BA7C"
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    // ---- Body ----
    RowLayout {
        anchors.fill: parent
        anchors.topMargin: banner.height
        spacing: 0

        // Sidebar
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 190
            color: "#201C17"
            ListView {
                id: nav
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                model: ["Overview", "Power & Fans", "Battery",
                        "Keyboard RGB", "Scenes", "Diagnostics"]
                currentIndex: root.currentPage
                onCurrentIndexChanged: root.currentPage = currentIndex
                delegate: ItemDelegate {
                    required property string modelData
                    required property int index
                    width: nav.width - 12
                    height: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    highlighted: ListView.isCurrentItem
                    text: modelData
                    onClicked: nav.currentIndex = index
                    contentItem: Label {
                        text: parent.text
                        color: parent.highlighted ? "#E2A35B" : "#B5A896"
                        font.pixelSize: 13
                        font.bold: parent.highlighted
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 14
                    }
                    background: Rectangle {
                        radius: 6
                        color: parent.highlighted ? "#332D26" : "transparent"
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: "#4A4237"
        }

        // Pages
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Material.background
            StackLayout {
                anchors.fill: parent
                currentIndex: root.currentPage
                OverviewPage {}
                PowerPage {}
                BatteryPage {}
                RgbPage {}
                ScenesPage {}
                DiagnosticsPage {}
            }
        }
    }

    // ---- OSD toast (separate top-level window) ----
    OSD {
        id: osd
    }
    Connections {
        target: center
        function onActionDone(ok, title, detail) {
            osd.showMessage(title, detail, !ok)
        }
    }
}
