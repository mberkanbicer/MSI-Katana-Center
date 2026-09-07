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
            text: "Battery"
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

                Label {
                    text: center.batteryState !== "" ? center.batteryState : "unavailable"
                    color: "#E8DCCB"
                    font.pixelSize: 15
                    font.bold: true
                }
                ProgressBar {
                    width: parent.width
                    from: 0
                    to: 100
                    value: center.capacityPercent >= 0 ? center.capacityPercent : 0
                    indeterminate: center.capacityPercent < 0
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
                spacing: 14

                Label { text: "Charge limits"; color: "#8C7F6F"; font.pixelSize: 11; font.bold: true }

                RowLayout {
                    width: parent.width
                    spacing: 10

                    SpinBox {
                        id: startBox
                        from: 0
                        to: endBox.value - 1
                        value: center.chargeStartPercent >= 0 ? center.chargeStartPercent : 80
                        editable: true
                    }
                    Label { text: "to"; color: "#8C7F6F" }
                    SpinBox {
                        id: endBox
                        from: startBox.value + 1
                        to: 100
                        value: center.chargeEndPercent >= 0 ? center.chargeEndPercent : 90
                        editable: true
                    }
                    Button {
                        text: "Apply limits"
                        onClicked: center.setBatteryThresholds(startBox.value, endBox.value)
                    }
                }
                Label {
                    text: "Daemon-reported limits: "
                          + (center.chargeStartPercent >= 0
                                 ? center.chargeStartPercent
                                 : "?")
                          + "% – "
                          + (center.chargeEndPercent >= 0
                                 ? center.chargeEndPercent
                                 : "?")
                          + "%"
                    color: "#B5A896"
                    font.pixelSize: 12
                }
                Row {
                    spacing: 8
                    Button {
                        text: "50–60%"
                        onClicked: center.setBatteryThresholds(50, 60)
                    }
                    Button {
                        text: "70–80%"
                        onClicked: center.setBatteryThresholds(70, 80)
                    }
                    Button {
                        text: "90–100%"
                        onClicked: center.setBatteryThresholds(90, 100)
                    }
                }
                Label {
                    text: "Presets write start and end together (Linux charge thresholds), not a single GhostDeck-style stop limit."
                    color: "#8C7F6F"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
            implicitHeight: 230
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

                Label {
                    text: "Travel (charge to 100%)"
                    color: "#8C7F6F"
                    font.pixelSize: 11
                    font.bold: true
                }
                Row {
                    spacing: 10
                    ComboBox {
                        id: travelBox
                        implicitWidth: 140
                        textRole: "label"
                        model: ListModel {
                            ListElement { label: "3 days"; days: 3 }
                            ListElement { label: "7 days"; days: 7 }
                            ListElement { label: "14 days"; days: 14 }
                            ListElement { label: "30 days"; days: 30 }
                        }
                        Component.onCompleted: {
                            const current = center.travelDays
                            for (let i = 0; i < count; i++) {
                                if (Number(model.get(i).days) === current) {
                                    currentIndex = i
                                    break
                                }
                            }
                        }
                        onActivated: (index) =>
                            center.setTravelDays(Number(model.get(index).days))
                    }
                    Button {
                        text: center.travelActive ? "Extend trip" : "Start travel"
                        enabled: center.chargeStartPercent >= 0
                                 && center.chargeEndPercent > center.chargeStartPercent
                        onClicked: center.startTravel(
                                       Number(travelBox.model.get(travelBox.currentIndex).days))
                    }
                    Button {
                        text: "Restore now"
                        visible: center.travelActive
                        onClicked: center.cancelTravel()
                    }
                }
                Label {
                    visible: center.travelActive
                    text: center.travelRestoreText
                    color: "#E2A35B"
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
                Label {
                    text: "Saves the current start/end pair, sets end to 100%, then restores that pair after N days while this app is running — or on the next launch after the date. Needs the battery write opt-in and Polkit. No extra EC register."
                    color: "#8C7F6F"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
            implicitHeight: 210
        }
    }
}
