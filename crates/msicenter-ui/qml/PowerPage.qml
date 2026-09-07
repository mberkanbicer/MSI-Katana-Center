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
            title: "Power & Fans"
            subtitle: "Manage cooling, power saving and device controls."
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
                spacing: 6

                Switch {
                    text: "Cooler Boost"
                    checked: center.coolerBoostOn
                    enabled: center.coolerBoostValid
                    onToggled: {
                        if (checked === center.coolerBoostOn)
                            return
                        center.setCoolerBoost(checked)
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

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8
                ActionButton {
                    text: "Panic reset"
                    destructive: true
                    enabled: !center.sceneApplying
                    onClicked: center.panicReset()
                }
                Label {
                    text: "Cooler Boost off, Super Battery off, fan auto. "
                          + "Does not change shift/performance mode (now: "
                          + (center.ecShift !== "" ? center.ecShift : "unknown")
                          + "). Ctrl+Shift+P. Polkit + opt-ins still apply."
                    color: Theme.muted
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
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
