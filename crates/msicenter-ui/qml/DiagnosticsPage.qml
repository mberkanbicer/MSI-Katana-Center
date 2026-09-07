import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth

    Column {
        x: 24
        width: page.availableWidth - 48
        spacing: 14
        topPadding: 24
        bottomPadding: 24

        Label {
            text: "Diagnostics"
            font.pixelSize: 22
            font.bold: true
            color: "#E8DCCB"
        }

        Label {
            visible: center.profileText === ""
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: "No device profile matched. Copy the report below when asking for support on a new model. Serial numbers are not included."
            color: "#E2A35B"
            font.pixelSize: 12
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
                          + (center.ecFirmwareDate !== "" ? " (" + center.ecFirmwareDate + ")" : "")
                    color: "#E8DCCB"
                    font.pixelSize: 13
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
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
                    Layout.fillWidth: true
                }
            }
            implicitHeight: 210
        }

        Rectangle {
            width: parent.width
            radius: 10
            color: "#292420"
            border.color: "#3A332B"
            border.width: 1
            clip: true
            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                Label { text: "Runtime capabilities (readable)"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                Label {
                    width: parent.width - 32
                    text: center.capsText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font.pixelSize: 12
                    color: "#B5A896"
                }
            }
            implicitHeight: 160
        }

        Row {
            spacing: 10
            Button {
                text: "Copy report"
                enabled: center.diagnosticReport !== ""
                onClicked: center.copyDiagnosticReport()
            }
            Label {
                text: "CLI: msicenter report [--json]  ·  no serials (AGENTS §31)"
                color: "#8C7F6F"
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: parent.width
            radius: 10
            color: "#201C17"
            border.color: "#3A332B"
            border.width: 1
            clip: true
            ScrollView {
                anchors.fill: parent
                anchors.margins: 12
                TextArea {
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    text: center.diagnosticReport !== ""
                              ? center.diagnosticReport
                              : "connecting…"
                    color: "#B5A896"
                    font.family: "monospace"
                    font.pixelSize: 11
                    background: null
                }
            }
            implicitHeight: 280
        }
    }
}
