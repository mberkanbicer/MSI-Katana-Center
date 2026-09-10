import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    function fmtTemp(t) { return t === undefined ? "n/a" : t.toFixed(1) + "°C"; }
    function fmtLoad(l) { return l === undefined ? "…" : Math.round(l) + "%"; }
    function coreRow(c) { return c.id + "  " + fmtTemp(c.temp) + "  " + fmtLoad(c.load); }
    function gpuRow(g) { return fmtTemp(g.temp) + "  " + fmtLoad(g.load); }

    Column {
        x: Math.max(28, (page.availableWidth - 1120) / 2)
        width: Math.min(1120, page.availableWidth - 56)
        spacing: 18
        topPadding: 28
        bottomPadding: 28

        PageHeading {
            title: "System overview"
            subtitle: "A live view of your device. Everything that matters, in one place."
        }

        GridLayout {
            width: parent.width
            columns: page.availableWidth < 700 ? 1 : 2
            columnSpacing: 16
            rowSpacing: 16
            StatCard {
                title: "TEMPERATURE · CPU / GPU"
                value: center.ecTemps !== "" ? center.ecTemps : "Unavailable"
                footnote: "Live temperature readings"
                accent: Theme.amber
            }
            StatCard {
                title: "BATTERY"
                value: center.capacityPercent >= 0 ? center.capacityPercent + "%" : "Unavailable"
                footnote: center.batteryState
                progress: center.capacityPercent >= 0 ? center.capacityPercent / 100 : -1
            }
            StatCard {
                title: "COOLING MODE"
                value: center.ecFanMode !== "" ? center.ecFanMode : "Unavailable"
                footnote: center.coolerBoostOn ? "Cooler Boost is active" : "Fan control · msi-ec"
            }
            StatCard {
                title: "FAN SPEED"
                value: center.fanText !== "" ? center.fanText : "Unavailable"
                valueLines: center.fanEntries
                footnote: "RPM · channels unmapped"
                accent: Theme.secondary
            }
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Activity"
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }
                    ComboBox {
                        implicitWidth: 110
                        textRole: "label"
                        model: ListModel {
                            ListElement { label: "15 min"; minutes: 15 }
                            ListElement { label: "30 min"; minutes: 30 }
                            ListElement { label: "60 min"; minutes: 60 }
                        }
                        Component.onCompleted: {
                            for (let i = 0; i < count; i++) {
                                if (Number(model.get(i).minutes) === center.historyWindowMinutes) {
                                    currentIndex = i
                                    break
                                }
                            }
                        }
                        onActivated: (index) => center.setHistoryWindowMinutes(Number(model.get(index).minutes))
                    }
                    ActionButton {
                        text: "Copy CSV"
                        onClicked: center.copyHistoryCsv()
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 24
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 12
                        Label { text: "CPU temperature · °C"; color: Theme.muted; font.pixelSize: 12 }
                        Sparkline {
                            Layout.fillWidth: true
                            implicitHeight: 100
                            values: center.historyCpu
                            maxValue: 100
                            stroke: Theme.amber
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 12
                        Label { text: "Fan speed · max RPM"; color: Theme.muted; font.pixelSize: 12 }
                        Sparkline {
                            Layout.fillWidth: true
                            implicitHeight: 100
                            values: center.historyRpm
                            maxValue: Math.max(1, center.historyMaxRpm)
                            stroke: Theme.accent
                        }
                    }
                }
                Label {
                    text: center.historyCpu.length < 2
                          ? "Collecting samples… Updates about every 2 seconds."
                          : center.historyCpu.length + " CPU samples · kept in memory for this session"
                    color: Theme.muted
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                Label {
                    text: "Core & GPU details"
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Label {
                    visible: center.cpuCores.length === 0 && center.gpus.length === 0
                    text: "Unavailable on this device"
                    color: Theme.muted
                    font.pixelSize: 12
                }
                GridLayout {
                    visible: center.cpuCores.length > 0
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 4
                    Repeater {
                        model: center.cpuCores
                        delegate: Label {
                            text: coreRow(modelData)
                            color: Theme.text
                            font.pixelSize: 13
                            font.family: "monospace"
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            elide: Text.ElideRight
                        }
                    }
                }
                ColumnLayout {
                    visible: center.gpus.length > 0
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 4
                    Repeater {
                        model: center.gpus
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 8
                            Label {
                                text: modelData.name
                                color: Theme.muted
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                elide: Text.ElideRight
                            }
                            Label {
                                text: gpuRow(modelData)
                                color: Theme.text
                                font.pixelSize: 13
                                font.family: "monospace"
                            }
                        }
                    }
                }
            }
        }

        Label {
            text: "Device details"
            color: Theme.text
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        Panel {
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                Label {
                    text: center.profileText !== "" ? center.profileText : "No device profile matched"
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                }
                Label {
                    text: "EC firmware: " + (center.ecFirmware || "Unavailable")
                          + (center.ecShift ? "  ·  Shift: " + center.ecShift : "")
                    color: Theme.muted
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: page.availableWidth < 700 ? 1 : 2
                    columnSpacing: 20
                    rowSpacing: 12
                    Repeater {
                        model: [
                            {label: "Cooler Boost", value: !center.coolerBoostValid ? "Unavailable" : (center.coolerBoostOn ? "On" : "Off")},
                            {label: "Super Battery", value: !center.superBatteryValid ? "Unavailable" : (center.superBatteryOn ? "On" : "Off")},
                            {label: "Webcam", value: center.webcamText},
                            {label: "Fn / Win keys", value: center.fnWinText},
                            {label: "RGB controller", value: center.rgbControllerText},
                            {label: "Readable features", value: center.capsText}
                        ]
                        ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            spacing: 4
                            Label { text: modelData.label; color: Theme.muted; font.pixelSize: 12 }
                            Label {
                                text: modelData.value || "Unavailable"
                                color: Theme.secondary
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }
                    }
                }
            }
        }
    }
}
