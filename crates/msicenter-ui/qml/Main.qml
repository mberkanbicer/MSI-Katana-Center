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
    Material.theme: Material.Dark
    Material.accent: "#7aa2f7"
    Material.background: "#16161e"

    property int currentPage: 0

    // ---- Top bar ----
    header: ToolBar {
        Material.background: "#1a1b26"
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
                           ? "#f7768e"
                           : (center.profileText !== ""
                                  ? "#9ece6a"
                                  : "#565f89")
            }
            Label {
                text: "MSI Linux Center"
                font.pixelSize: 16
                font.bold: true
                color: "#c0caf5"
            }
            Label {
                text: "hardware management"
                color: "#565f89"
                font.pixelSize: 11
                visible: root.width > 900
            }
            Item { Layout.fillWidth: true }

            Rectangle {
                visible: center.supportText !== ""
                radius: 9
                color: "#7aa2f7"
                implicitHeight: 20
                implicitWidth: supportLabel.implicitWidth + 18
                Label {
                    id: supportLabel
                    anchors.centerIn: parent
                    text: center.supportText
                    font.pixelSize: 11
                    font.bold: true
                    color: "#16161e"
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
        color: center.actionError ? "#3b1d24" : "#1c3526"
        Label {
            anchors.fill: parent
            anchors.margins: 8
            text: (center.actionError ? "✗ " : "✓ ") + center.actionMessage
            color: center.actionError ? "#f7768e" : "#9ece6a"
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
            Layout.preferredWidth: 210
            color: "#1a1b26"
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
                        color: parent.highlighted ? "#7aa2f7" : "#a9b1d6"
                        font.pixelSize: 13
                        font.bold: parent.highlighted
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 14
                    }
                    background: Rectangle {
                        radius: 6
                        color: parent.highlighted ? "#24283b" : "transparent"
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: "#3b3b4a"
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
}
