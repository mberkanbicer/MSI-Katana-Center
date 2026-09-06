import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Rectangle {
    id: card
    property string title: ""
    property string value: ""
    property string footnote: ""

    Layout.fillWidth: true
    implicitHeight: 96
    radius: 10
    color: "#292420"
    border.color: "#3A332B"
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        Label {
            text: card.title
            color: "#8C7F6F"
            font.pixelSize: 11
            font.bold: true
            Layout.minimumWidth: 0
        }
        Label {
            text: card.value
            color: "#E8DCCB"
            font.pixelSize: 17
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
        Label {
            visible: card.footnote !== ""
            text: card.footnote
            color: "#8C7F6F"
            font.pixelSize: 10
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }
}
