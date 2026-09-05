import QtQuick

Window {
    visible: true
    width: 560
    height: 720
    minimumWidth: 480
    minimumHeight: 560
    title: "MSI Linux Center — Phase 6 skeleton"
    color: "#181825"

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Text {
            text: "MSI Linux Center"
            color: "#cdd6f4"
            font.pointSize: 16
            font.bold: true
        }
        Text {
            text: "Phase 6 skeleton — read-only dashboard (2 s refresh)"
            color: "#a6adc8"
            font.pointSize: 9
        }
        Text {
            visible: center.lastError !== ""
            text: "Error: " + center.lastError
            color: "#f38ba8"
            font.pointSize: 9
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }

        SectionLabel { text: "Device" }
        KV { label: "Profile"; value: center.profileText }
        KV { label: "Support"; value: center.supportText }

        SectionLabel { text: "EC" }
        KV { label: "Firmware"; value: center.ecFirmware }
        KV { label: "Shift mode"; value: center.ecShift }
        KV { label: "Fan mode"; value: center.ecFanMode }
        KV { label: "Temps"; value: center.ecTemps }

        SectionLabel { text: "Fan RPM" }
        Text {
            text: center.fanText
            color: "#cdd6f4"
            font.pointSize: 10
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }

        SectionLabel { text: "Battery" }
        KV { label: "State"; value: center.batteryState }

        SectionLabel { text: "Capabilities (readable)" }
        Text {
            text: center.capsText
            color: "#cdd6f4"
            font.pointSize: 9
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }

        Item { width: 1; height: 6 }
        Rectangle {
            id: refreshButton
            width: 120
            height: 30
            radius: 6
            color: "#45475a"
            Text {
                anchors.centerIn: parent
                text: "Refresh now"
                color: "#cdd6f4"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: center.refreshNow()
            }
        }
    }
}
