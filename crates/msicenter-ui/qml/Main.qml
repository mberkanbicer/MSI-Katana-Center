import QtQuick

Window {
    visible: true
    width: 640
    height: 860
    minimumWidth: 520
    minimumHeight: 600
    title: "MSI Linux Center"
    color: "#181825"

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: column.implicitHeight + 32
        clip: true

        Column {
            id: column
            x: 16
            y: 16
            width: parent.parent.width - 32
            spacing: 8
            property int rgbZones: 15

            Text {
                text: "MSI Linux Center"
                color: "#cdd6f4"
                font.pointSize: 16
                font.bold: true
            }
            Text {
                text: "Hardware status and gated write controls — 2 s refresh"
                color: "#a6adc8"
                font.pointSize: 9
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: parent.width
            }
            Text {
                visible: center.lastError !== ""
                text: "Error: " + center.lastError
                color: "#f38ba8"
                font.pointSize: 9
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: parent.width
            }

            // ---- Device ----
            SectionLabel { text: "Device" }
            KV { label: "Profile"; value: center.profileText }
            KV { label: "Support"; value: center.supportText }

            // ---- EC ----
            SectionLabel { text: "EC" }
            KV { label: "Firmware"; value: center.ecFirmware }
            KV { label: "Shift mode"; value: center.ecShift }
            KV { label: "Fan mode"; value: center.ecFanMode }
            KV { label: "Temps"; value: center.ecTemps }

            // ---- Fan RPM ----
            SectionLabel { text: "Fan RPM" }
            Text {
                text: center.fanText
                color: "#cdd6f4"
                font.pointSize: 10
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: parent.width
            }

            // ---- Battery ----
            SectionLabel { text: "Battery" }
            KV { label: "State"; value: center.batteryState }

            // ---- Controls (write) ----
            SectionLabel { text: "Controls (write)" }
            Text {
                text: "Write controls call the daemon's Polkit-gated methods. If a feature is disabled in the daemon, the refusal message appears below."
                color: "#a6adc8"
                font.pointSize: 9
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: parent.width
            }

            KV { label: "Fan mode"; value: center.ecFanMode }
            Row {
                spacing: 8
                Repeater {
                    model: center.fanModes
                    ActionButton {
                        label: modelData
                        highlighted: modelData === center.ecFanMode
                        onClicked: center.setFanMode(modelData)
                    }
                }
            }

            ActionButton {
                label: !center.coolerBoostValid
                           ? "Cooler Boost: unavailable"
                           : (center.coolerBoostOn ? "Cooler Boost: turn off"
                                                   : "Cooler Boost: turn on")
                onClicked: center.setCoolerBoost(!center.coolerBoostOn)
            }
            ActionButton {
                label: !center.superBatteryValid
                           ? "Super Battery: unavailable"
                           : (center.superBatteryOn ? "Super Battery: turn off"
                                                    : "Super Battery: turn on")
                onClicked: center.setSuperBattery(!center.superBatteryOn)
            }

            Row {
                spacing: 8
                Rectangle {
                    width: 60
                    height: 28
                    radius: 4
                    color: "#313244"
                    border.color: "#585b70"
                    TextInput {
                        id: limitStart
                        anchors.fill: parent
                        anchors.margins: 6
                        color: "#cdd6f4"
                        font.pointSize: 10
                        inputMethodHints: Qt.ImhDigitsOnly
                        text: center.chargeStartPercent >= 0
                                  ? center.chargeStartPercent : ""
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Text {
                    text: "to"
                    color: "#a6adc8"
                    font.pointSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: 60
                    height: 28
                    radius: 4
                    color: "#313244"
                    border.color: "#585b70"
                    TextInput {
                        id: limitEnd
                        anchors.fill: parent
                        anchors.margins: 6
                        color: "#cdd6f4"
                        font.pointSize: 10
                        inputMethodHints: Qt.ImhDigitsOnly
                        text: center.chargeEndPercent >= 0
                                  ? center.chargeEndPercent : ""
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                ActionButton {
                    label: "Apply limits"
                    onClicked: center.setBatteryThresholds(
                                   parseInt(limitStart.text, 10),
                                   parseInt(limitEnd.text, 10))
                }
            }

            // ---- RGB (non-persistent) ----
            SectionLabel { text: "RGB keyboard" }
            KV { label: "Controller"; value: center.rgbControllerText }
            Row {
                spacing: 6
                ActionButton {
                    label: "All zones"
                    highlighted: column.rgbZones === 15
                    onClicked: column.rgbZones = 15
                }
                ActionButton {
                    label: "Zone 1"
                    highlighted: column.rgbZones === 1
                    onClicked: column.rgbZones = 1
                }
                ActionButton {
                    label: "Zone 2"
                    highlighted: column.rgbZones === 2
                    onClicked: column.rgbZones = 2
                }
                ActionButton {
                    label: "Zone 3"
                    highlighted: column.rgbZones === 4
                    onClicked: column.rgbZones = 4
                }
                ActionButton {
                    label: "Zone 4"
                    highlighted: column.rgbZones === 8
                    onClicked: column.rgbZones = 8
                }
            }
            Text {
                text: "Colors (steady, non-persistent)"
                color: "#a6adc8"
                font.pointSize: 9
            }
            Row {
                spacing: 6
                ActionButton {
                    label: "Red"
                    onClicked: center.setRgbColorFromHex(column.rgbZones, "ff0000")
                }
                ActionButton {
                    label: "Green"
                    onClicked: center.setRgbColorFromHex(column.rgbZones, "00ff00")
                }
                ActionButton {
                    label: "Blue"
                    onClicked: center.setRgbColorFromHex(column.rgbZones, "0000ff")
                }
                ActionButton {
                    label: "Yellow"
                    onClicked: center.setRgbColorFromHex(column.rgbZones, "ffff00")
                }
                ActionButton {
                    label: "White"
                    onClicked: center.setRgbColorFromHex(column.rgbZones, "ffffff")
                }
                ActionButton {
                    label: "Off"
                    onClicked: center.setRgbColorFromHex(column.rgbZones, "000000")
                }
            }
            Text {
                text: "Effects: use 'msicenter rgb-effect' in a terminal for now"
                color: "#585b70"
                font.pointSize: 8
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: parent.width
            }

            // ---- Scenes (Phase 8) ----
            SectionLabel { text: "Scenes" }
            Text {
                text: "From ~/.config/msi-linux-center/scenes.json — sequential gated writes"
                color: "#a6adc8"
                font.pointSize: 8
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: parent.width
            }
            Row {
                spacing: 6
                Repeater {
                    model: center.sceneNames
                    ActionButton {
                        label: modelData
                        onClicked: center.applyScene(modelData)
                    }
                }
                ActionButton {
                    label: "Reload"
                    onClicked: center.reloadScenes()
                }
            }
            Text {
                visible: center.sceneResultText !== ""
                text: center.sceneResultText
                color: "#a6e3a1"
                font.pointSize: 9
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: parent.width
            }

            // ---- Action result ----
            Text {
                visible: center.actionMessage !== ""
                text: center.actionError ? "✗ " + center.actionMessage
                                         : "✓ " + center.actionMessage
                color: center.actionError ? "#f38ba8" : "#a6e3a1"
                font.pointSize: 9
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: parent.width
            }

            Item { width: 1; height: 6 }
            Row {
                spacing: 8
                ActionButton { label: "Refresh now"; onClicked: center.refreshNow() }
            }
        }
    }
}
