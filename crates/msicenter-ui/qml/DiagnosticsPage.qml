import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    Column {
        x: Math.max(28, (page.availableWidth - 1120) / 2)
        width: Math.min(1120, page.availableWidth - 56)
        spacing: 18
        topPadding: 28
        bottomPadding: 24

        PageHeading {
            title: "Diagnostics"
            subtitle: "Device details, activity and a shareable support report."
        }

        Label {
            visible: center.profileText === ""
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: "No device profile matched. Copy the report below when asking for support on a new model. Serial numbers are not included."
            color: Theme.accent
            font.pixelSize: 12
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Label { text: "Device identity"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Label {
                    text: "Profile: " + (center.profileText !== "" ? center.profileText : "unmatched")
                          + "   ·   support: " + (center.supportText !== "" ? center.supportText : "unknown")
                          + "   ·   firmware: " + (center.ecFirmware !== "" ? center.ecFirmware : "?")
                          + (center.ecFirmwareDate !== "" ? " (" + center.ecFirmwareDate + ")" : "")
                    color: Theme.text
                    font.pixelSize: 13
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
                Label { text: "RGB controller"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Label {
                    text: center.rgbControllerText
                    color: Theme.text
                    font.pixelSize: 13
                }
                Label { text: "Last error"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Label {
                    text: center.lastError !== "" ? center.lastError : "none"
                    color: center.lastError !== "" ? Theme.danger : Theme.success
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
        }

        Panel {
            width: parent.width
            clip: true
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8
                Label { text: "Runtime capabilities (readable)"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Label {
                    width: parent.width - 32
                    text: center.capsText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font.pixelSize: 12
                    color: Theme.secondary
                }
            }
        }

        Panel {
            width: parent.width
            clip: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8
                RowLayout {
                    Label {
                        text: "Client write log"
                        color: Theme.muted
                        font.pixelSize: 12
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    ActionButton {
                        text: "Copy log"
                        enabled: center.writeLogText !== ""
                        onClicked: center.copyWriteLog()
                    }
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: center.writeLogText !== "" ? 180 : 48
                    clip: true
                    TextArea {
                        text: center.writeLogText || "No hardware writes recorded."
                        readOnly: true
                        selectByMouse: true
                        color: Theme.secondary
                        font.family: "monospace"
                        font.pixelSize: 12
                        wrapMode: TextEdit.Wrap
                        background: null
                    }
                }
                Label {
                    text: "Last 200 writes · stored locally · no raw EC data"
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
        }

        Row {
            spacing: 10
            ActionButton {
                text: "Copy report"
                primary: true
                enabled: center.diagnosticReport !== ""
                onClicked: center.copyDiagnosticReport()
            }
            Label {
                text: "Serial numbers are excluded."
                color: Theme.muted
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: parent.width
            radius: 10
            color: Theme.sidebar
            border.color: Theme.border
            border.width: 1
            clip: true
            ScrollView {
                anchors.fill: parent
                anchors.margins: 12
                TextArea {
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    text: center.diagnosticReport !== ""
                              ? center.diagnosticReport
                              : "connecting…"
                    color: Theme.secondary
                    font.family: "monospace"
                    font.pixelSize: 12
                    background: null
                }
            }
            implicitHeight: 280
        }
    }
}
