import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

// Bottom-docked primary call-to-action for control pages.
// Hidden until Main.stickyAction is assigned ({text, detail, enabled,
// handler}); Status/Support leave it null so the bar never appears there.
// Pages claim it in later slices; this file is shell only.
Rectangle {
    id: bar
    property string actionText: ""
    property string actionDetail: ""
    property bool actionEnabled: true
    signal triggered()
    Layout.fillWidth: true
    implicitHeight: visible ? 76 : 0
    visible: actionText !== ""
    Behavior on implicitHeight { NumberAnimation { duration: 140 } }
    color: Theme.sidebar
    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 12
        Label {
            text: bar.actionDetail
            visible: bar.actionDetail !== ""
            color: Theme.muted
            font.pixelSize: 12
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            elide: Text.ElideRight
        }
        Item { visible: bar.actionDetail === ""; Layout.fillWidth: true }
        ActionButton {
            text: bar.actionText
            primary: true
            enabled: bar.actionEnabled
            implicitHeight: 48
            Layout.minimumWidth: 200
            onClicked: bar.triggered()
        }
    }
}
