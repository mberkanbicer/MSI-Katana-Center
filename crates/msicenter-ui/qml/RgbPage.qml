import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth

    property int rgbZones: 15

    function hslToHex(h, s, l) {
        const c = Qt.hsla(h, s, l, 1)
        const ch = (v) => Math.round(v * 255).toString(16).padStart(2, "0")
        return ch(c.r) + ch(c.g) + ch(c.b)
    }
    function validHex(text) {
        return /^[0-9a-fA-F]{6}$/.test(text)
    }
    function hexToColor(text) {
        const v = parseInt(text, 16)
        return Qt.rgba(((v >> 16) & 0xff) / 255, ((v >> 8) & 0xff) / 255,
                       (v & 0xff) / 255, 1)
    }

    Column {
        x: 24
        width: page.availableWidth - 48
        spacing: 14
        topPadding: 24
        bottomPadding: 24

        Label {
            text: "Keyboard RGB"
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
                spacing: 12
                Label { text: "Controller"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                Label {
                    text: center.rgbControllerText
                    color: center.rgbControllerText === "not detected" ? "#DD6B58" : "#E8DCCB"
                    font.pixelSize: 14
                    font.bold: true
                }
                Label { text: "Zone"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                Row {
                    spacing: 8
                    ButtonGroup { id: zoneGroup }
                    Repeater {
                        model: [{ label: "All", mask: 15 },
                                { label: "Zone 1", mask: 1 },
                                { label: "Zone 2", mask: 2 },
                                { label: "Zone 3", mask: 4 },
                                { label: "Zone 4", mask: 8 }]
                        Button {
                            required property var modelData
                            text: modelData.label
                            checkable: true
                            checked: page.rgbZones === modelData.mask
                            ButtonGroup.group: zoneGroup
                            onClicked: page.rgbZones = modelData.mask
                        }
                    }
                }
            }
            implicitHeight: 190
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
                spacing: 12
                Label { text: "Steady color (non-persistent)"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }

                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: [{ name: "Red", hex: "ff0000" },
                                { name: "Green", hex: "00ff00" },
                                { name: "Blue", hex: "0000ff" },
                                { name: "Yellow", hex: "ffff00" },
                                { name: "Cyan", hex: "00ffff" },
                                { name: "White", hex: "ffffff" },
                                { name: "Off", hex: "000000" }]
                        Rectangle {
                            required property var modelData
                            width: 64
                            height: 44
                            radius: 8
                            color: modelData.hex === "000000" ? "#1B1815" : ("#" + modelData.hex)
                            border.color: modelData.hex === "000000" ? "#8C7F6F" : "#4A4237"
                            border.width: 1
                            Label {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: modelData.name === "Off" ? "#B5A896" : "#1B1815"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: center.setRgbColorFromHex(page.rgbZones, modelData.hex)
                                onEntered: parent.border.color = "#E2A35B"
                                onExited: parent.border.color = modelData.hex === "000000"
                                                          ? "#8C7F6F" : "#4A4237"
                            }
                        }
                    }
                }
                Label {
                    text: "Effects (breathing, wave, cycle) and flash-save are available from the CLI: "
                          + "msicenter rgb-effect, msicenter rgb-save"
                    color: "#8C7F6F"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    width: parent.width
                }
            }
            implicitHeight: 220
        }

        // ---- Custom color picker ----
        Rectangle {
            width: parent.width
            radius: 10
            color: "#292420"
            border.color: "#3A332B"
            border.width: 1
            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Label { text: "Custom color"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }

                Row {
                    spacing: 14
                    Rectangle {
                        id: preview
                        width: 72
                        height: 48
                        radius: 8
                        border.color: "#4A4237"
                        border.width: 1
                        color: validHex(hexField.text)
                                   ? hexToColor(hexField.text)
                                   : "#3A332B"
                        Label {
                            anchors.centerIn: parent
                            visible: !validHex(hexField.text)
                            text: "?"
                            color: "#8C7F6F"
                        }
                    }
                    Column {
                        spacing: 8
                        Row {
                            spacing: 8
                            TextField {
                                id: hexField
                                width: 130
                                text: hslToHex(pickHue.value, pickSat.value, pickLight.value)
                                placeholderText: "RRGGBB"
                                maximumLength: 6
                                font.family: "monospace"
                                onAccepted: center.setRgbColorFromHex(page.rgbZones, text)
                            }
                            Button {
                                text: "Apply to zone"
                                onClicked: center.setRgbColorFromHex(page.rgbZones, hexField.text)
                            }
                        }
                        Label {
                            text: "press Enter in the hex field, or use Apply"
                            color: "#8C7F6F"
                            font.pixelSize: 10
                        }
                    }
                }

                Row {
                    spacing: 14
                    width: parent.width
                    Label { text: "Hue"; width: 44; color: "#B5A896"; font.pixelSize: 12 }
                    Slider {
                        id: pickHue
                        from: 0
                        to: 1
                        value: 0.097
                        width: parent.width - 58
                    }
                }
                Row {
                    spacing: 14
                    width: parent.width
                    Label { text: "Sat"; width: 44; color: "#B5A896"; font.pixelSize: 12 }
                    Slider {
                        id: pickSat
                        from: 0
                        to: 1
                        value: 0.72
                        width: parent.width - 58
                    }
                }
                Row {
                    spacing: 14
                    width: parent.width
                    Label { text: "Light"; width: 44; color: "#B5A896"; font.pixelSize: 12 }
                    Slider {
                        id: pickLight
                        from: 0.15
                        to: 0.9
                        value: 0.62
                        width: parent.width - 58
                    }
                }
            }
            implicitHeight: 280
        }

    }
}
