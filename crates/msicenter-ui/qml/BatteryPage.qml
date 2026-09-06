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
            }
            implicitHeight: 150
        }
    }
}
