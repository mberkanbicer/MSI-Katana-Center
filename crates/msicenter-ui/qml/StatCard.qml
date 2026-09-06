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
    color: "#1f2335"
    border.color: "#2a2f45"
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        Label {
            text: card.title
            color: "#565f89"
            font.pixelSize: 11
            font.bold: true
        }
        Label {
            text: card.value
            color: "#c0caf5"
            font.pixelSize: 17
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Label {
            visible: card.footnote !== ""
            text: card.footnote
            color: "#565f89"
            font.pixelSize: 10
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
