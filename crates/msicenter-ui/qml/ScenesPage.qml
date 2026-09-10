import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    property int selectedScene: -1
    property string openSection: ""

    function refreshSticky() {
        const w = ApplicationWindow.window;
        if (!w)
            return;
        if (page.visible) {
            const name = page.selectedScene >= 0 ? center.sceneNames[page.selectedScene] : "";
            w.stickyAction = {
                owner: page,
                text: "Apply selected scene",
                detail: name !== "" ? name : "No scene selected",
                enabled: page.selectedScene >= 0 && !center.sceneApplying,
                handler: () => center.applyScene(center.sceneNames[page.selectedScene])
            };
        } else if (w.stickyAction && w.stickyAction.owner === page) {
            w.stickyAction = null;
        }
    }
    onVisibleChanged: refreshSticky()
    onSelectedSceneChanged: refreshSticky()
    Component.onCompleted: refreshSticky()

    Connections {
        target: center
        function onChanged() { page.refreshSticky(); }
    }

    Column {
        x: Math.max(28, (page.availableWidth - 1120) / 2)
        width: Math.min(1120, page.availableWidth - 56)
        spacing: 18
        topPadding: 28
        bottomPadding: 24

        PageHeading {
            title: "Scenes"
            subtitle: "Your favorite settings, ready when you need them."
        }
        Label {
            text: "Named bundles of the same gated writes — not MSI Silent / Balanced / Extreme. "
                  + "Quiet only sets fan silent; it does not write performance/shift mode."
            color: Theme.muted
            font.pixelSize: 12
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }

        Panel {
            width: parent.width
            implicitHeight: Math.min(280, 52 * Math.max(center.sceneNames.length, 1) + 12)
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
                    width: sceneList.width
                    height: 52
                    highlighted: ListView.isCurrentItem
                    text: modelData
                    onClicked: sceneList.currentIndex = index
                    contentItem: Label {
                        text: parent.text
                        color: parent.highlighted ? Theme.accent : Theme.text
                        font.pixelSize: 13
                        font.bold: parent.highlighted
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }
                    background: Rectangle {
                        radius: 10
                        color: parent.highlighted ? Theme.accentSoft : parent.hovered ? Theme.elevated : "transparent"
                        border.color: parent.visualFocus ? Theme.accent : "transparent"
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: sceneList.count === 0
                    width: parent.width - 24
                    wrapMode: Text.WordWrap
                    text: "No scenes yet. Choose Add examples to get started."
                    color: Theme.muted
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 10
            ActionButton {
                text: "Reload"
                onClicked: center.reloadScenes()
            }
            ActionButton {
                text: "Add examples"
                enabled: !center.sceneApplying
                onClicked: center.addExampleScenes()
            }
            ActionButton {
                text: "Import…"
                onClicked: center.importScenes()
            }
            ActionButton {
                text: "Export…"
                onClicked: center.exportScenes()
            }
            BusyIndicator {
                visible: center.sceneApplying
                implicitWidth: 24
                implicitHeight: 24
            }
        }

        Panel {
            visible: center.sceneResultText !== ""
            width: parent.width
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 4
                Repeater {
                    model: center.sceneResultText.split("\n")
                    Label {
                        required property string modelData
                        text: modelData
                        Layout.fillWidth: true
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        color: modelData.startsWith("FAIL") ? Theme.danger : Theme.success
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                }
            }
        }

        AutomationAccordion {
            title: "Restore on start"
            summary: center.restoreSceneOnStart ? (center.restoreSceneName !== "" ? center.restoreSceneName : "On") : "Off"
            open: page.openSection === "restore"
            onToggled: page.openSection = page.openSection === "restore" ? "" : "restore"
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
                color: Theme.muted
                font.pixelSize: 12
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                Layout.fillWidth: true
            }
        }

        AutomationAccordion {
            title: "AC / battery switch"
            summary: center.powerSceneSwitch ? ("AC \u2192 " + (center.acSceneName || "none") + " \u00b7 Battery \u2192 " + (center.batterySceneName || "none")) : "Off"
            open: page.openSection === "power"
            onToggled: page.openSection = page.openSection === "power" ? "" : "power"
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
                    color: Theme.secondary
                    font.pixelSize: 12
                }
                RowLayout {
                    spacing: 10
                    Label {
                        text: "On AC"
                        color: Theme.muted
                        font.pixelSize: 12
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
                        color: Theme.muted
                        font.pixelSize: 12
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
                    color: Theme.muted
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
        }

        AutomationAccordion {
            title: "Battery-level rules"
            summary: center.batteryLevelRules ? ("Below " + center.batteryLowPercent + "% \u00b7 Above " + center.batteryHighPercent + "%") : "Off"
            open: page.openSection === "levels"
            onToggled: page.openSection = page.openSection === "levels" ? "" : "levels"
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
                        color: Theme.muted
                        font.pixelSize: 12
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
                        color: Theme.muted
                        font.pixelSize: 12
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
                        color: Theme.muted
                        font.pixelSize: 12
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
                        color: Theme.muted
                        font.pixelSize: 12
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
                    color: Theme.muted
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
        }

        AutomationAccordion {
            title: "Scene schedule"
            summary: center.sceneSchedule ? (center.scheduleRules.length + (center.scheduleRules.length === 1 ? " rule" : " rules")) : "Off"
            open: page.openSection === "schedule"
            onToggled: page.openSection = page.openSection === "schedule" ? "" : "schedule"
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
                                ActionButton {
                                    required property string modelData
                                    required property int index
                                    text: modelData
                                    Accessible.name: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][index]
                                    checkable: true
                                    width: 48
                                    checked: (Number(ruleRow.modelData.days) & (1 << index)) !== 0
                                    enabled: center.sceneSchedule
                                    onClicked: center.toggleScheduleDay(ruleRow.index, index)
                                }
                            }
                        }
                        RowLayout {
                            spacing: 6
                            Label { text: "Start"; color: Theme.muted; font.pixelSize: 12 }
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
                        }
                        RowLayout {
                            spacing: 6
                            Label { text: "End"; color: Theme.muted; font.pixelSize: 12 }
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
                        }
                        RowLayout {
                            spacing: 6
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
                            ActionButton {
                                text: "Remove"
                                destructive: true
                                enabled: center.sceneSchedule
                                onClicked: center.removeScheduleRule(index)
                            }
                        }
                    }
                }
                ActionButton {
                    text: "Add rule"
                    enabled: center.sceneSchedule && center.scheduleRules.length < 8
                    onClicked: center.addScheduleRule()
                }
                Label {
                    text: "First matching rule wins. Applies when a window starts, and at app start if you are already inside one. Overnight ranges (22:00–07:00) are fine. Manual scenes inside a window stick until the next window. Needs this app running (autostart); no systemd timer, so Polkit is not popped at 07:00 by a background unit."
                    color: Theme.muted
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                }
        }


        Label {
            text: "Quiet: fan silent, Cooler Boost off, Super Battery off. "
                  + "Cool: Cooler Boost on, fan auto. Battery saver: Super Battery on, fan auto "
                  + "(not eco shift). Gaming lights: red wave only. "
                  + "Add examples merges missing names and never overwrites yours. "
                  + "RGB is never persisted by a scene."
            color: Theme.muted
            font.pixelSize: 12
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }
    }
}
