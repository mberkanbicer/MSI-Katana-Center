import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    function refreshSticky() {
        const w = ApplicationWindow.window;
        if (!w)
            return;
        if (page.visible) {
            w.stickyAction = {
                owner: page,
                text: "Apply limits",
                detail: startBox.value + "% \u2013 " + endBox.value + "%",
                enabled: true,
                handler: () => center.setBatteryThresholds(startBox.value, endBox.value)
            };
        } else if (w.stickyAction && w.stickyAction.owner === page) {
            w.stickyAction = null;
        }
    }
    onVisibleChanged: refreshSticky()
    Component.onCompleted: refreshSticky()

    Column {
        x: Math.max(28, (page.availableWidth - 1120) / 2)
        width: Math.min(1120, page.availableWidth - 56)
        spacing: 18
        topPadding: 28
        bottomPadding: 24

        PageHeading {
            title: "Battery"
            subtitle: "Balance everyday battery care with time away from your desk."
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Label {
                    text: center.batteryState !== "" ? center.batteryState : "unavailable"
                    color: Theme.text
                    font.pixelSize: 15
                    font.bold: true
                }
                ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: center.capacityPercent >= 0 ? center.capacityPercent : 0
                    indeterminate: center.capacityPercent < 0
                }
            }
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Label { text: "Charge limits"; color: Theme.muted; font.pixelSize: 12; font.bold: true }

                RowLayout {
                    width: parent.width
                    spacing: 10

                    SpinBox {
                        id: startBox
                        Accessible.name: "Start charging below percent"
                        from: 0
                        to: endBox.value - 1
                        value: center.chargeStartPercent >= 0 ? center.chargeStartPercent : 80
                        editable: true
                        onValueModified: refreshSticky()
                    }
                    Label { text: "to"; color: Theme.muted }
                    SpinBox {
                        id: endBox
                        Accessible.name: "Stop charging at percent"
                        from: startBox.value + 1
                        to: 100
                        value: center.chargeEndPercent >= 0 ? center.chargeEndPercent : 90
                        editable: true
                        onValueModified: refreshSticky()
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
                    color: Theme.secondary
                    font.pixelSize: 12
                }
                Row {
                    spacing: 8
                    ActionButton {
                        text: "50–60%"
                        onClicked: center.setBatteryThresholds(50, 60)
                    }
                    ActionButton {
                        text: "70–80%"
                        onClicked: center.setBatteryThresholds(70, 80)
                    }
                    ActionButton {
                        text: "90–100%"
                        onClicked: center.setBatteryThresholds(90, 100)
                    }
                }
                Label {
                    text: "Choose when charging starts and stops. Lower limits help preserve battery health when plugged in."
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

                Label {
                    text: "Travel (charge to 100%)"
                    color: Theme.muted
                    font.pixelSize: 12
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
                    ActionButton {
                        text: center.travelActive ? "Extend trip" : "Start travel"
                        primary: true
                        enabled: center.chargeStartPercent >= 0
                                 && center.chargeEndPercent > center.chargeStartPercent
                        onClicked: center.startTravel(
                                       Number(travelBox.model.get(travelBox.currentIndex).days))
                    }
                    ActionButton {
                        text: "Restore now"
                        visible: center.travelActive
                        onClicked: center.cancelTravel()
                    }
                }
                Label {
                    visible: center.travelActive
                    text: center.travelRestoreText
                    color: Theme.accent
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
                Label {
                    text: "Saves the current start/end pair, sets end to 100%, then restores that pair after N days while this app is running — or on the next launch after the date. Needs the battery write opt-in and Polkit. No extra EC register."
                    color: Theme.muted
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
        }
    }
}
