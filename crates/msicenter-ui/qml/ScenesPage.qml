import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth

    property int selectedScene: -1

    Column {
        x: 24
        width: page.availableWidth - 48
        spacing: 14
        topPadding: 24
        bottomPadding: 24

        Label {
            text: "Scenes"
            font.pixelSize: 22
            font.bold: true
            color: "#E8DCCB"
        }
        Label {
            text: "Named bundles of the same gated writes — not MSI Silent / Balanced / Extreme. "
                  + "Quiet only sets fan silent; it does not write performance/shift mode."
            color: "#8C7F6F"
            font.pixelSize: 12
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }

        Rectangle {
            width: parent.width
            Layout.preferredHeight: Math.min(280, 48 * Math.max(center.sceneNames.length, 1))
            radius: 10
            color: "#292420"
            border.color: "#3A332B"
            border.width: 1
            clip: true

            ListView {
                id: sceneList
                anchors.fill: parent
                anchors.margins: 6
                model: center.sceneNames
                currentIndex: page.selectedScene
                onCurrentIndexChanged: page.selectedScene = currentIndex
                delegate: ItemDelegate {
                    required property string modelData
                    required property int index
                    width: sceneList.width - 12
                    height: 40
                    highlighted: ListView.isCurrentItem
                    text: modelData
                    onClicked: sceneList.currentIndex = index
                    contentItem: Label {
                        text: parent.text
                        color: parent.highlighted ? "#E2A35B" : "#E8DCCB"
                        font.pixelSize: 13
                        font.bold: parent.highlighted
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }
                    background: Rectangle {
                        radius: 6
                        color: parent.highlighted ? "#3A332B" : "transparent"
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: sceneList.count === 0
                    text: "No scenes yet — Add examples, or create ~/.config/msi-linux-center/scenes.json"
                    color: "#8C7F6F"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
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
                    text: "Apply a scene when the app starts"
                    checked: center.restoreSceneOnStart
                    onToggled: {
                        if (checked === center.restoreSceneOnStart)
                            return
                        center.setRestoreSceneOnStart(checked)
                    }
                }
                ComboBox {
                    enabled: center.restoreSceneOnStart
                    Layout.preferredWidth: 280
                    model: center.restoreSceneChoices
                    currentIndex: center.restoreSceneChoiceIndex
                    onActivated: (index) => center.setRestoreSceneChoiceIndex(index)
                }
                Label {
                    text: "Off by default so a cold boot stays firmware stock. "
                          + "Uses the same gated scene apply; missing opt-ins fail per setting. "
                          + "Polkit may prompt at login if autostart is on."
                    color: "#8C7F6F"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
            implicitHeight: 160
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
                    text: "Switch scene on AC / battery"
                    checked: center.powerSceneSwitch
                    onToggled: {
                        if (checked === center.powerSceneSwitch)
                            return
                        center.setPowerSceneSwitch(checked)
                    }
                }
                Label {
                    text: center.powerSourceText
                    color: "#B5A896"
                    font.pixelSize: 12
                }
                RowLayout {
                    spacing: 10
                    Label {
                        text: "On AC"
                        color: "#8C7F6F"
                        font.pixelSize: 11
                    }
                    ComboBox {
                        enabled: center.powerSceneSwitch
                        Layout.preferredWidth: 220
                        model: center.sceneChoicesWithNone
                        currentIndex: center.acSceneChoiceIndex
                        onActivated: (index) => center.setAcSceneChoiceIndex(index)
                    }
                }
                RowLayout {
                    spacing: 10
                    Label {
                        text: "On battery"
                        color: "#8C7F6F"
                        font.pixelSize: 11
                    }
                    ComboBox {
                        enabled: center.powerSceneSwitch
                        Layout.preferredWidth: 220
                        model: center.sceneChoicesWithNone
                        currentIndex: center.batterySceneChoiceIndex
                        onActivated: (index) => center.setBatterySceneChoiceIndex(index)
                    }
                }
                Label {
                    text: "Edge-triggered: applies only when you plug or unplug, not on first read and not after a manual scene. Charging / Full / Not charging count as AC; Discharging as battery. (none) skips that side."
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
                Switch {
                    text: "Battery-level scene rules"
                    checked: center.batteryLevelRules
                    onToggled: {
                        if (checked === center.batteryLevelRules)
                            return
                        center.setBatteryLevelRules(checked)
                    }
                }
                RowLayout {
                    spacing: 10
                    Label {
                        text: "Below"
                        color: "#8C7F6F"
                        font.pixelSize: 11
                    }
                    SpinBox {
                        from: 5
                        to: 95
                        value: center.batteryLowPercent
                        enabled: center.batteryLevelRules
                        onValueModified: center.setBatteryLowPercent(value)
                    }
                    Label {
                        text: "% discharging →"
                        color: "#8C7F6F"
                        font.pixelSize: 11
                    }
                    ComboBox {
                        enabled: center.batteryLevelRules
                        Layout.preferredWidth: 200
                        model: center.sceneChoicesWithNone
                        currentIndex: center.batteryLowSceneChoiceIndex
                        onActivated: (index) => center.setBatteryLowSceneChoiceIndex(index)
                    }
                }
                RowLayout {
                    spacing: 10
                    Label {
                        text: "Above"
                        color: "#8C7F6F"
                        font.pixelSize: 11
                    }
                    SpinBox {
                        from: 10
                        to: 100
                        value: center.batteryHighPercent
                        enabled: center.batteryLevelRules
                        onValueModified: center.setBatteryHighPercent(value)
                    }
                    Label {
                        text: "% charging →"
                        color: "#8C7F6F"
                        font.pixelSize: 11
                    }
                    ComboBox {
                        enabled: center.batteryLevelRules
                        Layout.preferredWidth: 200
                        model: center.sceneChoicesWithNone
                        currentIndex: center.batteryHighSceneChoiceIndex
                        onActivated: (index) => center.setBatteryHighSceneChoiceIndex(index)
                    }
                }
                Label {
                    text: "Once per crossing. Low fires only while discharging, high only while charging. First reading is ignored. (none) skips that side."
                    color: "#8C7F6F"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
            implicitHeight: 210
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
                    text: "Scene schedule"
                    checked: center.sceneSchedule
                    onToggled: {
                        if (checked === center.sceneSchedule)
                            return
                        center.setSceneSchedule(checked)
                    }
                }
                Repeater {
                    model: center.scheduleRules
                    ColumnLayout {
                        id: ruleRow
                        required property var modelData
                        required property int index
                        spacing: 6
                        Row {
                            spacing: 4
                            Repeater {
                                model: ["M", "T", "W", "T", "F", "S", "S"]
                                Button {
                                    required property string modelData
                                    required property int index
                                    text: modelData
                                    checkable: true
                                    width: 32
                                    checked: (Number(ruleRow.modelData.days) & (1 << index)) !== 0
                                    enabled: center.sceneSchedule
                                    onClicked: center.toggleScheduleDay(ruleRow.index, index)
                                }
                            }
                        }
                        RowLayout {
                            spacing: 6
                            Label { text: "Start"; color: "#8C7F6F"; font.pixelSize: 11 }
                            SpinBox {
                                from: 0; to: 23
                                value: modelData.startHour
                                enabled: center.sceneSchedule
                                onValueModified: center.setScheduleRuleStart(index, value, modelData.startMinute)
                            }
                            SpinBox {
                                from: 0; to: 59
                                value: modelData.startMinute
                                enabled: center.sceneSchedule
                                onValueModified: center.setScheduleRuleStart(index, modelData.startHour, value)
                            }
                            Label { text: "End"; color: "#8C7F6F"; font.pixelSize: 11 }
                            SpinBox {
                                from: 0; to: 23
                                value: modelData.endHour
                                enabled: center.sceneSchedule
                                onValueModified: center.setScheduleRuleEnd(index, value, modelData.endMinute)
                            }
                            SpinBox {
                                from: 0; to: 59
                                value: modelData.endMinute
                                enabled: center.sceneSchedule
                                onValueModified: center.setScheduleRuleEnd(index, modelData.endHour, value)
                            }
                            ComboBox {
                                enabled: center.sceneSchedule
                                Layout.preferredWidth: 160
                                model: center.sceneChoicesWithNone
                                currentIndex: {
                                    const name = modelData.scene
                                    if (!name)
                                        return 0
                                    const i = center.sceneNames.indexOf(name)
                                    return i < 0 ? 0 : i + 1
                                }
                                onActivated: (i) => center.setScheduleRuleScene(index, i)
                            }
                            Button {
                                text: "Remove"
                                enabled: center.sceneSchedule
                                onClicked: center.removeScheduleRule(index)
                            }
                        }
                    }
                }
                Button {
                    text: "Add rule"
                    enabled: center.sceneSchedule && center.scheduleRules.length < 8
                    onClicked: center.addScheduleRule()
                }
                Label {
                    text: "First matching rule wins. Applies when a window starts, and at app start if you are already inside one. Overnight ranges (22:00–07:00) are fine. Manual scenes inside a window stick until the next window. Needs this app running (autostart); no systemd timer, so Polkit is not popped at 07:00 by a background unit."
                    color: "#8C7F6F"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
            }
            implicitHeight: 150 + center.scheduleRules.length * 96
        }

        Row {
            spacing: 10
            Button {
                text: "Apply selected scene"
                enabled: page.selectedScene >= 0 && !center.sceneApplying
                onClicked: center.applyScene(center.sceneNames[page.selectedScene])
            }
            Button {
                text: "Reload"
                onClicked: center.reloadScenes()
            }
            Button {
                text: "Add examples"
                enabled: !center.sceneApplying
                onClicked: center.addExampleScenes()
            }
            Button {
                text: "Import…"
                onClicked: center.importScenes()
            }
            Button {
                text: "Export…"
                onClicked: center.exportScenes()
            }
            BusyIndicator {
                visible: center.sceneApplying
                implicitWidth: 24
                implicitHeight: 24
            }
        }

        Rectangle {
            visible: center.sceneResultText !== ""
            width: parent.width
            radius: 10
            color: "#2C3220"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4
                Repeater {
                    model: center.sceneResultText.split("\n")
                    Label {
                        required property string modelData
                        text: modelData
                        color: modelData.startsWith("FAIL") ? "#DD6B58" : "#A9BA7C"
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                }
            }
            implicitHeight: Math.max(40, 22 * center.sceneResultText.split("\n").length + 20)
        }

        Label {
            text: "Quiet: fan silent, Cooler Boost off, Super Battery off. "
                  + "Cool: Cooler Boost on, fan auto. Battery saver: Super Battery on, fan auto "
                  + "(not eco shift). Gaming lights: red wave only. "
                  + "Add examples merges missing names and never overwrites yours. "
                  + "RGB is never persisted by a scene."
            color: "#8C7F6F"
            font.pixelSize: 11
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }
    }
}
