import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth

    Column {
        width: page.availableWidth
        spacing: 14
        padding: 24

        Label {
            text: "Diagnostics"
            font.pixelSize: 22
            font.bold: true
            color: "#E8DCCB"
        }

        Rectangle {
            width: parent.width
            radius: 10
            color: "#292420"
            border.color: "#3A332B"
            border.width: 1
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                Label { text: "Device identity"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                Label {
                    text: "Profile: " + (center.profileText !== "" ? center.profileText : "unmatched")
                          + "   ·   support: " + (center.supportText !== "" ? center.supportText : "unknown")
                          + "   ·   firmware: " + (center.ecFirmware !== "" ? center.ecFirmware : "?")
                    color: "#E8DCCB"
                    font.pixelSize: 13
                }
                Label { text: "RGB controller"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                Label {
                    text: center.rgbControllerText
                    color: "#E8DCCB"
                    font.pixelSize: 13
                }
                Label { text: "Last error"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                Label {
                    text: center.lastError !== "" ? center.lastError : "none"
                    color: center.lastError !== "" ? "#DD6B58" : "#A9BA7C"
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    width: parent.width
                }
            }
            implicitHeight: 200
        }

        Rectangle {
            width: parent.width
            Layout.preferredHeight: 200
            radius: 10
            color: "#292420"
            border.color: "#3A332B"
            border.width: 1
            clip: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                Label { text: "Runtime capabilities (readable)"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                ScrollView {
                    width: parent.width
                    height: 130
                    clip: true
                    Label {
                        text: center.capsText
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: 12
                        color: "#B5A896"
                        width: parent.width
                    }
                }
            }
        }
    }
}
