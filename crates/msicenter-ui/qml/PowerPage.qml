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
            title: "Power"
            subtitle: "Battery preservation and device switches."
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 6

                Label { text: "Battery & privacy"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Switch {
                    text: "Super Battery"
                    checked: center.superBatteryOn
                    enabled: center.superBatteryValid
                    onToggled: center.setSuperBattery(checked)
                }
                Label {
                    text: "Battery preservation mode. Polkit prompt follows."
                    color: Theme.muted; font.pixelSize: 12
                }
                Switch {
                    text: "Webcam"
                    checked: center.webcamOn
                    enabled: center.webcamValid
                    onToggled: center.setWebcam(checked)
                }
                Switch {
                    text: "Webcam block"
                    checked: center.webcamBlockOn
                    enabled: center.webcamBlockValid
                    onToggled: center.setWebcamBlock(checked)
                }
                Label {
                    text: "Block is a hardware kill: the Fn webcam key cannot re-enable it."
                    color: Theme.muted; font.pixelSize: 12
                }
                Label { text: "Fn key position"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Row {
                    spacing: 8
                    ButtonGroup { id: fnGroup }
                    ActionButton {
                        text: "Fn left"
                        checkable: true
                        checked: center.fnKey === "left"
                        enabled: center.fnKey !== ""
                        ButtonGroup.group: fnGroup
                        onClicked: center.setFnKey("left")
                    }
                    ActionButton {
                        text: "Fn right"
                        checkable: true
                        checked: center.fnKey === "right"
                        enabled: center.fnKey !== ""
                        ButtonGroup.group: fnGroup
                        onClicked: center.setFnKey("right")
                    }
                }
                Label {
                    text: center.fnWinText + "  ·  Polkit + per-feature opt-in."
                    color: Theme.muted; font.pixelSize: 12
                }
            }
        }

        Label {
            text: "Every write is gated daemon-side: per-feature opt-in, exact verified firmware and Polkit. "
                  + "When an opt-in is off, the refusal appears in the banner above."
            color: Theme.muted
            font.pixelSize: 12
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }
    }
}
