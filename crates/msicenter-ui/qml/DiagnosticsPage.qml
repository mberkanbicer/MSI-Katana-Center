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
            color: "#c0caf5"
        }

        Rectangle {
            width: parent.width
            radius: 10
            color: "#1f2335"
            border.color: "#2a2f45"
            border.width: 1
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                Label { text: "Device identity"; color: "#565f89"; font.pixelSize: 11; font.bold: true }
                Label {
                    text: "Profile: " + (center.profileText !== "" ? center.profileText : "unmatched")
                          + "   ·   support: " + (center.supportText !== "" ? center.supportText : "unknown")
                          + "   ·   firmware: " + (center.ecFirmware !== "" ? center.ecFirmware : "?")
                    color: "#c0caf5"
                    font.pixelSize: 13
                }
                Label { text: "RGB controller"; color: "#565f89"; font.pixelSize: 11; font.bold: true }
                Label {
                    text: center.rgbControllerText
                    color: "#c0caf5"
                    font.pixelSize: 13
                }
                Label { text: "Last error"; color: "#565f89"; font.pixelSize: 11; font.bold: true }
                Label {
                    text: center.lastError !== "" ? center.lastError : "none"
                    color: center.lastError !== "" ? "#f7768e" : "#9ece6a"
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
            color: "#1f2335"
            border.color: "#2a2f45"
            border.width: 1
            clip: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                Label { text: "Runtime capabilities (readable)"; color: "#565f89"; font.pixelSize: 11; font.bold: true }
                ScrollView {
                    width: parent.width
                    Layout.fillHeight: true
                    clip: true
                    TextArea {
                        text: center.capsText
                        readOnly: true
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: 12
                        color: "#a9b1d6"
                        background: null
                    }
                }
            }
        }
    }
}
