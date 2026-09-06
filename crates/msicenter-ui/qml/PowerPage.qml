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
            text: "Power & Fans"
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
                spacing: 14

                Label { text: "Fan mode"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                Row {
                    spacing: 8
                    ButtonGroup { id: fanGroup }
                    Repeater {
                        model: center.fanModes
                        Button {
                            required property string modelData
                            text: modelData
                            checkable: true
                            checked: modelData === center.ecFanMode
                            ButtonGroup.group: fanGroup
                            onClicked: center.setFanMode(modelData)
                        }
                    }
                }
                Label {
                    text: "Currently: " + (center.ecFanMode !== "" ? center.ecFanMode
                                                                  : "unavailable")
                    color: "#B5A896"
                    font.pixelSize: 12
                }
            }
            implicitHeight: 140
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
                spacing: 6

                Switch {
                    text: "Cooler Boost"
                    checked: center.coolerBoostOn
                    enabled: center.coolerBoostValid
                    onToggled: center.setCoolerBoost(checked)
                }
                Label {
                    text: "Maximum fan speed on request. Polkit prompt follows."
                    color: "#8C7F6F"; font.pixelSize: 10
                }
                Switch {
                    text: "Super Battery"
                    checked: center.superBatteryOn
                    enabled: center.superBatteryValid
                    onToggled: center.setSuperBattery(checked)
                }
                Label {
                    text: "Battery preservation mode. Polkit prompt follows."
                    color: "#8C7F6F"; font.pixelSize: 10
                }
            }
            implicitHeight: 170
        }

        Label {
            text: "Every write is gated daemon-side: per-feature opt-in, exact verified firmware and Polkit. "
                  + "When an opt-in is off, the refusal appears in the banner above."
            color: "#8C7F6F"
            font.pixelSize: 11
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }
    }
}
