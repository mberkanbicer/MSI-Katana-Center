import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

Panel {
    id: card
    property string title: ""
    property string value: ""
    property string footnote: ""
    property var valueLines: []
    property bool loading: false
    property color accent: Theme.accent
    property real progress: -1
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.minimumWidth: 0
    implicitHeight: card.valueLines.length > 0 ? 86 + card.valueLines.length * 26 : 138
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 8
        Label { text: card.title; color: Theme.muted; font.pixelSize: 11; font.weight: Font.Medium; font.letterSpacing: 0.6 }
        Label {
            visible: card.valueLines.length === 0 && !card.loading
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
            visible: card.loading && card.valueLines.length === 0
            Layout.fillWidth: true
            height: 28
            radius: 6
            color: Theme.elevated
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.35; to: 1; duration: 700; easing.type: Easing.InOutQuad }
            }
        }
        ColumnLayout {
            visible: card.valueLines.length > 0
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 4
            Repeater {
                model: card.valueLines
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 8
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: card.accent
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Label {
                        text: modelData.channel
                        color: Theme.muted
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        elide: Text.ElideRight
                    }
                    Label {
                        text: modelData.rpm + " RPM"
                        color: Theme.text
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                }
            }
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
