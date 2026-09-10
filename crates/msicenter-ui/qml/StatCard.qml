import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

Panel {
    id: card
    property string title: ""
    property string value: ""
    property string footnote: ""
    property color accent: Theme.accent
    property real progress: -1
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.minimumWidth: 0
    implicitHeight: 138
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 8
        Label { text: card.title; color: Theme.muted; font.pixelSize: 11; font.weight: Font.Medium; font.letterSpacing: 0.6 }
        Label {
            text: card.value || "Unavailable"
            color: Theme.text
            font.pixelSize: 28
            font.weight: Font.DemiBold
            font.letterSpacing: -0.6
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            ToolTip.visible: valueHover.hovered
            ToolTip.text: text
            HoverHandler { id: valueHover }
        }
        Rectangle {
            visible: card.progress >= 0
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: Theme.chartGrid
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, card.progress))
                height: parent.height
                radius: 2
                color: card.accent
            }
        }
        Label {
            visible: card.footnote !== ""
            text: card.footnote
            color: Theme.muted
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }
}
