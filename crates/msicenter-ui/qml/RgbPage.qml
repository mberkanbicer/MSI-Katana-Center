import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

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
    function effectLabel() {
        return ["", "Steady", "Breathing", "Cycle", "Wave"][page.modeIndex] || "";
    }
    function refreshSticky() {
        const w = ApplicationWindow.window;
        if (!w)
            return;
        if (page.visible) {
            w.stickyAction = {
                owner: page,
                text: "Apply effect",
                detail: effectLabel() + " \u00b7 #" + page.colorHex,
                enabled: true,
                handler: () => center.setRgbEffectPreset(page.rgbZones, page.modeIndex,
                                                         page.speedSeconds, page.colorHex,
                                                         page.waveDirection)
            };
        } else if (w.stickyAction && w.stickyAction.owner === page) {
            w.stickyAction = null;
        }
    }
    onVisibleChanged: refreshSticky()
    onRgbZonesChanged: refreshSticky()
    onColorHexChanged: refreshSticky()
    onModeIndexChanged: refreshSticky()
    onSpeedSecondsChanged: refreshSticky()
    onWaveDirectionChanged: refreshSticky()
    Component.onCompleted: refreshSticky()

    Column {
        x: Math.max(28, (page.availableWidth - 1120) / 2)
        width: Math.min(1120, page.availableWidth - 56)
        spacing: 18
        topPadding: 28
        bottomPadding: 24

        PageHeading {
            title: "Keyboard RGB"
            subtitle: "Choose your palette. Make your keyboard your own."
        }

        // ---- Controller & zones ----
        Panel {
            width: parent.width
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                Label { text: "Controller"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Label {
                    text: center.rgbControllerText
                    color: center.rgbControllerText === "not detected" ? Theme.danger : Theme.text
                    font.pixelSize: 14
                    font.bold: true
                }
                RowLayout {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            height: 76
                            radius: 10
                            color: Theme.background
                            border.color: (page.rgbZones & (1 << index)) ? hexToColor(page.colorHex) : Theme.border
                            Grid {
                                anchors.fill: parent
                                anchors.margins: 10
                                columns: 4
                                spacing: 4
                                Repeater {
                                    model: 12
                                    Rectangle {
                                        width: (parent.width - 12) / 4
                                        height: (parent.height - 8) / 3
                                        radius: 3
                                        color: (page.rgbZones & (1 << parent.parent.index))
                                               ? hexToColor(page.colorHex) : Theme.elevated
                                        opacity: 0.75
                                    }
                                }
                            }
                        }
                    }
                }
                Label {
                    text: "Selected color preview · apply below to update your keyboard"
                    color: Theme.muted
                    font.pixelSize: 12
                    width: parent.width
                    wrapMode: Text.WordWrap
                }
                Label { text: "Zone"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Row {
                    spacing: 8
                    ButtonGroup { id: zoneGroup }
                    Repeater {
                        model: [{ label: "All", mask: 15 },
                                { label: "Zone 1", mask: 1 },
                                { label: "Zone 2", mask: 2 },
                                { label: "Zone 3", mask: 4 },
                                { label: "Zone 4", mask: 8 }]
                        ActionButton {
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
        }

        // ---- Color & effect ----
        Panel {
            width: parent.width
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Label { text: "Color & effect (non-persistent)"; color: Theme.muted; font.pixelSize: 12; font.bold: true }

                    Flow {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: [{ name: "Red", hex: "ff0000" },
                                    { name: "Green", hex: "00ff00" },
                                    { name: "Blue", hex: "0000ff" },
                                    { name: "Yellow", hex: "ffff00" },
                                    { name: "Cyan", hex: "00ffff" },
                                    { name: "White", hex: "ffffff" }]
                            AbstractButton {
                                id: swatch
                                required property var modelData
                                width: 80
                                height: 42
                                text: modelData.name
                                Accessible.name: modelData.name + " color"
                                checked: page.colorHex === modelData.hex
                                hoverEnabled: true
                                onClicked: page.colorHex = modelData.hex
                                contentItem: Row {
                                    spacing: 7
                                    leftPadding: 8
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 12; height: 12; radius: 6
                                        color: "#" + swatch.modelData.hex
                                        border.color: Qt.lighter(color, 1.5)
                                    }
                                    Label {
                                        height: parent.height
                                        verticalAlignment: Text.AlignVCenter
                                        text: swatch.text
                                        color: Theme.text
                                        font.pixelSize: 12
                                    }
                                }
                                background: Rectangle {
                                    radius: 9
                                    color: swatch.checked ? Theme.accentSoft : swatch.hovered ? Theme.elevated : Theme.surface
                                    border.color: swatch.checked || swatch.visualFocus ? Theme.accent : Theme.border
                                    border.width: swatch.visualFocus ? 2 : 1
                                }
                            }
                        }
                    }
                Row {
                    spacing: 10
                    Label { text: "Effect"; color: Theme.muted; font.pixelSize: 12; font.bold: true
                            anchors.verticalCenter: parent.verticalCenter }
                    ButtonGroup { id: effectGroup }
                    Repeater {
                        model: [{ label: "Steady", mode: 1 },
                                { label: "Breathing", mode: 2 },
                                { label: "Cycle", mode: 3 },
                                { label: "Wave", mode: 4 }]
                        ActionButton {
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
                        color: Theme.secondary
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
                    Label { text: "Direction"; color: Theme.muted; font.pixelSize: 12
                            font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    ButtonGroup { id: directionGroup }
                    Repeater {
                        model: [{ label: "Left → Right", value: 1 },
                                { label: "Right → Left", value: 0 }]
                        ActionButton {
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
                    ActionButton {
                        text: "Turn off"
                        onClicked: center.setRgbColorFromHex(page.rgbZones, "000000")
                    }
                }
                Label {
                    text: page.modeIndex === 3
                              ? "Cycle and wave derive companion colors from your selection."
                              : "Breathing fades your selected color; steady lights it."
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
        }

        // ---- Custom color picker ----
        Panel {
            width: parent.width
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Label { text: "Custom color"; color: Theme.muted; font.pixelSize: 12; font.bold: true }

                Row {
                    spacing: 14
                    Rectangle {
                        id: preview
                        width: 72
                        height: 44
                        radius: 8
                        border.color: Theme.border
                        border.width: 1
                        color: validHex(hexField.text) ? hexToColor(hexField.text) : Theme.border
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
                                onAccepted: {
                                    if (validHex(text))
                                        page.colorHex = text.toLowerCase()
                                }
                                Accessible.name: "Custom color, six hexadecimal digits"
                            }
                            ActionButton {
                                text: "Use this color"
                                enabled: validHex(hexField.text)
                                onClicked: page.colorHex = hexField.text.toLowerCase()
                            }
                        }
                        Label {
                            text: "Enter or 'Use this color', then Apply effect below"
                            color: Theme.muted
                            font.pixelSize: 12
                        }
                    }
                }

                Row {
                    spacing: 14
                    width: parent.width
                    Label { text: "Hue"; width: 44; color: Theme.secondary; font.pixelSize: 12 }
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
                    Label { text: "Sat"; width: 44; color: Theme.secondary; font.pixelSize: 12 }
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
                    Label { text: "Light"; width: 44; color: Theme.secondary; font.pixelSize: 12 }
                    Slider {
                        id: pickLight
                        from: 0.15
                        to: 0.9
                        value: 0.62
                        width: parent.width - 58
                    }
                }
            }
        }
    }
}
