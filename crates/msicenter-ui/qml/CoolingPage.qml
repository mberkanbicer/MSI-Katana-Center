import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    property bool alertOpen: false

    Column {
        x: Math.max(28, (page.availableWidth - 1120) / 2)
        width: Math.min(1120, page.availableWidth - 56)
        spacing: 18
        topPadding: 28
        bottomPadding: 24

        PageHeading {
            title: "Cooling"
            subtitle: "Tame heat and noise."
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 4
                        Label { text: "Cooler Boost"; color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                        Label {
                            text: !center.coolerBoostValid ? "Unavailable on this device"
                                                          : center.coolerBoostOn ? "On · maximum fan speed" : "Off"
                            color: Theme.muted
                            font.pixelSize: 12
                        }
                    }
                    Switch {
                        checked: center.coolerBoostOn
                        enabled: center.coolerBoostValid
                        implicitHeight: 48
                        Accessible.name: "Cooler Boost"
                        onToggled: {
                            if (checked === center.coolerBoostOn)
                                return
                            center.setCoolerBoost(checked)
                        }
                    }
                }
                Label {
                    text: "Maximum fan speed on request. Polkit prompt follows."
                    color: Theme.muted; font.pixelSize: 12
                }
                Row {
                    spacing: 10
                    Label {
                        text: "Auto-off"
                        color: Theme.muted
                        font.pixelSize: 12
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    ComboBox {
                        id: autoOffBox
                        implicitWidth: 180
                        textRole: "label"
                        model: ListModel {
                            ListElement { label: "Off (manual only)"; seconds: 0 }
                            ListElement { label: "30 seconds"; seconds: 30 }
                            ListElement { label: "1 minute"; seconds: 60 }
                            ListElement { label: "2 minutes"; seconds: 120 }
                            ListElement { label: "5 minutes"; seconds: 300 }
                            ListElement { label: "10 minutes"; seconds: 600 }
                            ListElement { label: "15 minutes"; seconds: 900 }
                        }
                        Component.onCompleted: {
                            const current = center.coolerBoostAutoOffSeconds
                            for (let i = 0; i < count; i++) {
                                if (Number(model.get(i).seconds) === current) {
                                    currentIndex = i
                                    break
                                }
                            }
                        }
                        onActivated: (index) =>
                            center.setCoolerBoostAutoOffSeconds(
                                Number(model.get(index).seconds))
                    }
                }
                Label {
                    visible: center.coolerBoostRemainingSeconds > 0
                    text: {
                        const s = center.coolerBoostRemainingSeconds
                        const m = Math.floor(s / 60)
                        const r = s % 60
                        const clock = m > 0
                            ? (m + ":" + (r < 10 ? "0" : "") + r)
                            : (s + "s")
                        return "Turns off in " + clock + " (while this app is running)."
                    }
                    color: Theme.accent
                    font.pixelSize: 12
                }
            }
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Label { text: "Fan mode"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Row {
                    spacing: 8
                    ButtonGroup { id: fanGroup }
                    Repeater {
                        model: center.fanModes
                        ActionButton {
                            required property string modelData
                            text: modelData
                            checkable: true
                            implicitHeight: 48
                            checked: modelData === center.ecFanMode
                            ButtonGroup.group: fanGroup
                            onClicked: center.setFanMode(modelData)
                        }
                    }
                }
                Label {
                    text: "Currently: " + (center.ecFanMode !== "" ? center.ecFanMode
                                                                  : "unavailable")
                    color: Theme.secondary
                    font.pixelSize: 12
                }
            }
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 4
                Label { text: "Fan speed"; color: Theme.muted; font.pixelSize: 12; font.bold: true }
                Label {
                    visible: center.fanEntries.length === 0
                    text: "Unavailable"
                    color: Theme.muted
                    font.pixelSize: 12
                }
                Repeater {
                    model: center.fanEntries
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 8
                        Label {
                            text: modelData.channel
                            color: Theme.muted
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            elide: Text.ElideRight
                        }
                        Label {
                            text: modelData.rpm + " RPM"
                            color: Theme.text
                            font.pixelSize: 13
                            font.family: "monospace"
                        }
                    }
                }
                Label {
                    text: "Read-only · channels unmapped"
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Label {
                        text: "Temperature alerts"
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }
                    ToolButton {
                        implicitWidth: 48; implicitHeight: 48
                        Accessible.name: page.alertOpen ? "Hide temperature alerts" : "Show temperature alerts"
                        text: page.alertOpen ? "−" : "+"
                        font.pixelSize: 20
                        onClicked: page.alertOpen = !page.alertOpen
                    }
                }
                ColumnLayout {
                    visible: page.alertOpen
                    spacing: 10
                    Switch {
                        text: "CPU temperature alert"
                        checked: center.tempAlert
                        onToggled: {
                            if (checked === center.tempAlert)
                                return
                            center.setTempAlert(checked)
                        }
                    }
                    RowLayout {
                        spacing: 8
                        Label { text: "Above"; color: Theme.muted; font.pixelSize: 12 }
                        SpinBox {
                            from: 70
                            to: 100
                            value: center.tempAlertCelsius
                            enabled: center.tempAlert
                            onValueModified: center.setTempAlertCelsius(value)
                        }
                        Label { text: "°C for"; color: Theme.muted; font.pixelSize: 12 }
                        SpinBox {
                            from: 5
                            to: 60
                            value: center.tempAlertHoldSeconds
                            enabled: center.tempAlert
                            onValueModified: center.setTempAlertHoldSeconds(value)
                        }
                        Label { text: "s"; color: Theme.muted; font.pixelSize: 12 }
                    }
                    RowLayout {
                        spacing: 8
                        Label { text: "Cooldown"; color: Theme.muted; font.pixelSize: 12 }
                        SpinBox {
                            from: 30
                            to: 600
                            stepSize: 30
                            value: center.tempAlertCooldownSeconds
                            enabled: center.tempAlert
                            onValueModified: center.setTempAlertCooldownSeconds(value)
                        }
                        Label { text: "s between alerts"; color: Theme.muted; font.pixelSize: 12 }
                    }
                    Label {
                        text: "OSD only, no hardware write. Needs this app running. Current CPU: "
                              + (center.ecTemps !== "" ? center.ecTemps : "n/a")
                        color: Theme.muted
                        font.pixelSize: 12
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        Layout.fillWidth: true
                    }
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
