import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

// Collapsible automation section: one open at a time (the page owns
// `openSection`). The header always shows title + live summary so closed
// sections still communicate state (Slice 4).
Panel {
    id: root
    property string title: ""
    property string summary: ""
    property bool open: false
    signal toggled()
    default property alias content: contentSlot.children
    width: parent.width
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 2
                Label {
                    text: root.title
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Label {
                    visible: root.summary !== ""
                    text: root.summary
                    color: Theme.muted
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            ToolButton {
                implicitWidth: 48; implicitHeight: 48
                Accessible.name: (root.open ? "Collapse " : "Expand ") + root.title
                text: root.open ? "−" : "+"
                font.pixelSize: 20
                onClicked: root.toggled()
            }
        }
        ColumnLayout {
            id: contentSlot
            visible: root.open
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 10
        }
    }
}
