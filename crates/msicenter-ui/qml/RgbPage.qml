import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth

    property int rgbZones: 15
    property string colorHex: "ff0000"
    property int modeIndex: 1          // 1 steady, 2 breathing, 3 cycle, 4 wave
    property int speedSeconds: 3
    property int waveDirection: 1      // 1 left-to-right, 0 right-to-left

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
    function applyColor(color) {
        page.colorHex = color
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

        // ---- Controller & zones ----
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

        // ---- Color & effect ----
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

                Label { text: "Color & effect (non-persistent)"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }

                Row {
                    spacing: 10
                    Rectangle {
                        id: selectedSwatch
                        width: 46
                        height: 34
                        radius: 6
                        color: hexToColor(page.colorHex)
                        border.color: "#E2A35B"
                        border.width: 2
                        Label {
                            anchors.centerIn: parent
                            text: "selected"
                            color: page.colorHex === "ffffff" || page.colorHex === "00ffff"
                                       || page.colorHex === "ffff00" ? "#1B1815" : "#E8DCCB"
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }
                    Flow {
                        width: parent.parent.width - 62
                        spacing: 8
                        Repeater {
                            model: [{ name: "Red", hex: "ff0000" },
                                    { name: "Green", hex: "00ff00" },
                                    { name: "Blue", hex: "0000ff" },
                                    { name: "Yellow", hex: "ffff00" },
                                    { name: "Cyan", hex: "00ffff" },
                                    { name: "White", hex: "ffffff" }]
                            Rectangle {
                                required property var modelData
                                width: 46
                                height: 34
                                radius: 6
                                color: "#" + modelData.hex
                                border.color: page.colorHex === modelData.hex
                                                 ? "#E2A35B" : "#3A332B"
                                border.width: page.colorHex === modelData.hex ? 2 : 1
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: modelData.hex === "ffffff" || modelData.hex === "00ffff"
                                           || modelData.hex === "ffff00" ? "#1B1815" : "#E8DCCB"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: page.colorHex = modelData.hex
                                    onEntered: parent.border.color = "#E2A35B"
                                    onExited: parent.border.color =
                                        page.colorHex === modelData.hex ? "#E2A35B" : "#3A332B"
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: 10
                    Label { text: "Effect"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true
                            anchors.verticalCenter: parent.verticalCenter }
                    ButtonGroup { id: effectGroup }
                    Repeater {
                        model: [{ label: "Steady", mode: 1 },
                                { label: "Breathing", mode: 2 },
                                { label: "Cycle", mode: 3 },
                                { label: "Wave", mode: 4 }]
                        Button {
                            required property var modelData
                            text: modelData.label
                            checkable: true
                            checked: page.modeIndex === modelData.mode
                            ButtonGroup.group: effectGroup
                            onClicked: page.modeIndex = modelData.mode
                        }
                    }
                }

                Row {
                    visible: page.modeIndex !== 1
                    spacing: 10
                    width: parent.width
                    Label {
                        text: "Speed: " + page.speedSeconds + " s"
                        width: 110
                        color: "#B5A896"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Slider {
                        id: speedSlider
                        from: 3
                        to: 12
                        stepSize: 1
                        value: page.speedSeconds
                        width: parent.width - 130
                        onMoved: page.speedSeconds = Math.round(value)
                    }
                }

                Row {
                    visible: page.modeIndex === 4
                    spacing: 10
                    Label { text: "Direction"; color: "#8C7F6F"; font.pixelSize: 11
                            font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    ButtonGroup { id: directionGroup }
                    Repeater {
                        model: [{ label: "Left → Right", value: 1 },
                                { label: "Right → Left", value: 0 }]
                        Button {
                            required property var modelData
                            text: modelData.label
                            checkable: true
                            checked: page.waveDirection === modelData.value
                            ButtonGroup.group: directionGroup
                            onClicked: page.waveDirection = modelData.value
                        }
                    }
                }

                Row {
                    spacing: 10
                    Button {
                        text: "Apply effect"
                        onClicked: center.setRgbEffectPreset(page.rgbZones, page.modeIndex,
                                                             page.speedSeconds, page.colorHex,
                                                             page.waveDirection)
                    }
                    Button {
                        text: "Turn off"
                        onClicked: center.setRgbColorFromHex(page.rgbZones, "000000")
                    }
                }
                Label {
                    text: page.modeIndex === 3
                              ? "Cycle and wave derive companion colors from your selection."
                              : "Breathing fades your selected color; steady lights it."
                    color: "#8C7F6F"
                    font.pixelSize: 10
                }
            }
            implicitHeight: 330
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
                        height: 44
                        radius: 8
                        border.color: "#4A4237"
                        border.width: 1
                        color: validHex(hexField.text) ? hexToColor(hexField.text) : "#3A332B"
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
                                onAccepted: page.colorHex = text
                            }
                            Button {
                                text: "Use this color"
                                onClicked: page.colorHex = hexField.text
                            }
                        }
                        Label {
                            text: "Enter or 'Use this color', then Apply effect above"
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
            implicitHeight: 300
        }
    }
}
