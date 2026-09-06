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
            text: "Overview"
            font.pixelSize: 22
            font.bold: true
            color: "#E8DCCB"
        }

        // Device card
        Rectangle {
            width: parent.width
            radius: 10
            color: "#292420"
            border.color: "#3A332B"
            border.width: 1
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 4
                Label { text: "Device"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                Label {
                    text: center.profileText !== ""
                              ? "Matched: " + center.profileText
                              : "No device profile matched"
                    color: "#E8DCCB"; font.pixelSize: 14; font.bold: true
                }
                Label {
                    text: "EC firmware: " + (center.ecFirmware !== ""
                                             ? center.ecFirmware
                                             : "unavailable")
                          + (center.ecShift !== "" ? "   ·   shift: " + center.ecShift : "")
                    color: "#B5A896"; font.pixelSize: 12
                }
            }
            implicitHeight: 92
        }

        GridLayout {
            columns: page.availableWidth > 520 ? 2 : 1
            columnSpacing: 14
            rowSpacing: 14
            width: parent.width
            StatCard {
                title: "TEMPERATURE (CPU / GPU)"
                value: center.ecTemps
            }
            StatCard {
                title: "FAN MODE"
                value: center.ecFanMode !== "" ? center.ecFanMode : "unavailable"
                footnote: "msi-ec"
            }
            StatCard {
                title: "FANS (RPM)"
                value: center.fanText
                footnote: "msi_wmi_platform · channels unmapped"
            }
            StatCard {
                title: "BATTERY"
                value: center.batteryState
                footnote: "limits from power_supply"
            }
            StatCard {
                title: "COOLER BOOST"
                value: !center.coolerBoostValid
                           ? "unavailable"
                           : (center.coolerBoostOn ? "ON" : "off")
            }
            StatCard {
                title: "SUPER BATTERY"
                value: !center.superBatteryValid
                           ? "unavailable"
                           : (center.superBatteryOn ? "ON" : "off")
            }
            StatCard {
                title: "RGB CONTROLLER"
                value: center.rgbControllerText
            }
            StatCard {
                title: "SNAPSHOT"
                value: center.capsText
                footnote: "readable features"
            }
        }
    }
}
