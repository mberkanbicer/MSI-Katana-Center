import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth

    property int rgbZones: 15

    Column {
        width: page.availableWidth
        spacing: 14
        padding: 24

        Label {
            text: "Keyboard RGB"
            font.pixelSize: 22
            font.bold: true
            color: "#c0caf5"
        }

        Rectangle {
            width: parent.width
            radius: 10
            color: "#1f2335"
            border.color: "#2a2f45"
            border.width: 1
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12
                Label { text: "Controller"; color: "#565f89"; font.pixelSize: 11; font.bold: true }
                Label {
                    text: center.rgbControllerText
                    color: center.rgbControllerText === "not detected" ? "#f7768e" : "#c0caf5"
                    font.pixelSize: 14
                    font.bold: true
                }
                Label { text: "Zone"; color: "#565f89"; font.pixelSize: 11; font.bold: true }
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
            color: "#1f2335"
            border.color: "#2a2f45"
            border.width: 1
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12
                Label { text: "Steady color (non-persistent)"; color: "#565f89"; font.pixelSize: 11; font.bold: true }

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
                            color: modelData.hex === "000000" ? "#16161e" : ("#" + modelData.hex)
                            border.color: modelData.hex === "000000" ? "#565f89" : "#3b3b4a"
                            border.width: 1
                            Label {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: modelData.name === "Off" ? "#a9b1d6" : "#16161e"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: center.setRgbColorFromHex(page.rgbZones, modelData.hex)
                                onEntered: parent.border.color = "#7aa2f7"
                                onExited: parent.border.color = modelData.hex === "000000"
                                                          ? "#565f89" : "#3b3b4a"
                            }
                        }
                    }
                }
                Label {
                    text: "Effects (breathing, wave, cycle) and flash-save are available from the CLI: "
                          + "msicenter rgb-effect, msicenter rgb-save"
                    color: "#565f89"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    width: parent.width
                }
            }
            implicitHeight: 220
        }
    }
}
