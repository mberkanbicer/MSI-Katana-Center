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
                    onToggled: {
                        if (checked === center.coolerBoostOn)
                            return
                        center.setCoolerBoost(checked)
                    }
                }
                Label {
                    text: "Maximum fan speed on request. Polkit prompt follows."
                    color: "#8C7F6F"; font.pixelSize: 10
                }
                Row {
                    spacing: 10
                    Label {
                        text: "Auto-off"
                        color: "#8C7F6F"
                        font.pixelSize: 11
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
                    color: "#E2A35B"
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
                    color: "#8C7F6F"; font.pixelSize: 10
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
                    color: "#8C7F6F"; font.pixelSize: 10
                }
                Label { text: "Fn key position"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }
                Row {
                    spacing: 8
                    ButtonGroup { id: fnGroup }
                    Button {
                        text: "Fn left"
                        checkable: true
                        checked: center.fnKey === "left"
                        enabled: center.fnKey !== ""
                        ButtonGroup.group: fnGroup
                        onClicked: center.setFnKey("left")
                    }
                    Button {
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
                    color: "#8C7F6F"; font.pixelSize: 10
                }
            }
            implicitHeight: 450
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
                spacing: 8
                Button {
                    text: "Panic reset"
                    enabled: !center.sceneApplying
                    onClicked: center.panicReset()
                }
                Label {
                    text: "Cooler Boost off, Super Battery off, fan auto. "
                          + "Does not change shift/performance mode (now: "
                          + (center.ecShift !== "" ? center.ecShift : "unknown")
                          + "). Ctrl+Shift+P. Polkit + opt-ins still apply."
                    color: "#8C7F6F"
                    font.pixelSize: 11
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
            implicitHeight: 110
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
                    Label { text: "Above"; color: "#8C7F6F"; font.pixelSize: 11 }
                    SpinBox {
                        from: 70
                        to: 100
                        value: center.tempAlertCelsius
                        enabled: center.tempAlert
                        onValueModified: center.setTempAlertCelsius(value)
                    }
                    Label { text: "°C for"; color: "#8C7F6F"; font.pixelSize: 11 }
                    SpinBox {
                        from: 5
                        to: 60
                        value: center.tempAlertHoldSeconds
                        enabled: center.tempAlert
                        onValueModified: center.setTempAlertHoldSeconds(value)
                    }
                    Label { text: "s"; color: "#8C7F6F"; font.pixelSize: 11 }
                }
                RowLayout {
                    spacing: 8
                    Label { text: "Cooldown"; color: "#8C7F6F"; font.pixelSize: 11 }
                    SpinBox {
                        from: 30
                        to: 600
                        stepSize: 30
                        value: center.tempAlertCooldownSeconds
                        enabled: center.tempAlert
                        onValueModified: center.setTempAlertCooldownSeconds(value)
                    }
                    Label { text: "s between alerts"; color: "#8C7F6F"; font.pixelSize: 11 }
                }
                Label {
                    text: "OSD only, no hardware write. Needs this app running. Current CPU: "
                          + (center.ecTemps !== "" ? center.ecTemps : "n/a")
                    color: "#8C7F6F"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
            implicitHeight: 190
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
