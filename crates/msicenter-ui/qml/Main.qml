import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "Theme.js" as Theme

ApplicationWindow {
    id: root
    visible: true
    width: 1180
    height: 820
    minimumWidth: 900
    minimumHeight: 620
    title: "MSI Katana Center"
    color: Theme.background
    font.family: "Noto Sans"
    font.pixelSize: 13
    Material.theme: Material.Dark
    Material.primary: Theme.sidebar
    Material.accent: Theme.accent
    Material.background: Theme.surface
    Material.foreground: Theme.text
    property int currentPage: 0
    // {text, detail, enabled, handler} claimed by the active control page;
    // null hides StickyActionBar (Status/Support have no primary action).
    property var stickyAction: null
    property double nowTick: 0
    property var lastBannerSeen: ""
    readonly property bool stale: center.dataReady && center.lastUpdateMs > 0 && (root.nowTick - center.lastUpdateMs > 10000)
    function dismissBanner(msg, isErr) {
        for (let i = 0; i < bannerQueue.count; i++) {
            const item = bannerQueue.get(i);
            if (item.text === msg && item.isError === isErr) {
                bannerQueue.remove(i);
                return;
            }
        }
    }
    ListModel { id: bannerQueue }
    Timer {
        interval: 2000; repeat: true; running: true
        onTriggered: {
            root.nowTick = Date.now();
            for (let i = bannerQueue.count - 1; i >= 0; i--) {
                const item = bannerQueue.get(i);
                if (!item.isError && root.nowTick - item.at > 6000)
                    bannerQueue.remove(i);
            }
        }
    }
    Connections {
        target: center
        function onChanged() {
            if (center.actionMessage !== "" && center.actionMessage !== root.lastBannerSeen) {
                root.lastBannerSeen = center.actionMessage;
                bannerQueue.append({text: center.actionMessage, isError: center.actionError, at: Date.now()});
                while (bannerQueue.count > 3) {
                    let dropped = false;
                    for (let i = 0; i < bannerQueue.count; i++) {
                        if (!bannerQueue.get(i).isError) {
                            bannerQueue.remove(i);
                            dropped = true;
                            break;
                        }
                    }
                    if (!dropped)
                        bannerQueue.remove(0);
                }
            }
        }
    }
    readonly property var pages: [
        {title: "Overview", icon: "overview"},
        {title: "Cooling", icon: "fan"},
        {title: "Power", icon: "power"},
        {title: "Battery", icon: "battery"},
        {title: "Keyboard RGB", icon: "keyboard"},
        {title: "Scenes", icon: "scenes"},
        {title: "Diagnostics", icon: "diagnostics"}
    ]

    onClosing: (close) => {
        if (trayAvailable) { close.accepted = false; root.hide() }
    }
    Shortcut {
        sequences: ["Ctrl+Shift+C"]
        context: Qt.ApplicationShortcut
        enabled: !trayAvailable
        onActivated: center.setCoolerBoost(!center.coolerBoostOn)
    }
    Shortcut {
        sequences: ["Ctrl+Shift+B"]
        context: Qt.ApplicationShortcut
        enabled: !trayAvailable
        onActivated: center.setSuperBattery(!center.superBatteryOn)
    }
    Shortcut {
        sequences: ["Ctrl+Shift+L"]
        context: Qt.ApplicationShortcut
        enabled: !trayAvailable
        onActivated: center.setRgbColorFromHex(15, "000000")
    }
    Shortcut {
        sequences: ["Ctrl+Shift+P"]
        context: Qt.ApplicationShortcut
        enabled: !trayAvailable
        onActivated: center.panicReset()
    }
    Shortcut { sequence: "Ctrl+1"; onActivated: root.currentPage = 0 }
    Shortcut { sequence: "Ctrl+2"; onActivated: root.currentPage = 1 }
    Shortcut { sequence: "Ctrl+3"; onActivated: root.currentPage = 2 }
    Shortcut { sequence: "Ctrl+4"; onActivated: root.currentPage = 3 }
    Shortcut { sequence: "Ctrl+5"; onActivated: root.currentPage = 4 }
    Shortcut { sequence: "Ctrl+6"; onActivated: root.currentPage = 5 }
    Shortcut { sequence: "Ctrl+7"; onActivated: root.currentPage = 6 }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.width < 1020 ? 204 : 228
            color: Theme.sidebar
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 8
                RowLayout {
                    Layout.topMargin: 14
                    Layout.bottomMargin: 34
                    spacing: 12
                    Rectangle {
                        width: 38; height: 38; radius: 11
                        color: Theme.accent
                        Label {
                            anchors.centerIn: parent
                            text: "M"
                            font.pixelSize: 23
                            font.weight: Font.Black
                            color: Theme.background
                        }
                    }
                    Column {
                        spacing: 2
                        Label { text: "MSI"; font.pixelSize: 18; font.weight: Font.Bold; color: Theme.text }
                        Label { text: "LINUX CENTER"; font.pixelSize: 9; font.letterSpacing: 1.6; color: Theme.muted }
                    }
                }
                Label {
                    text: "WORKSPACE"
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    color: Theme.muted
                    leftPadding: 12
                    Layout.bottomMargin: 8
                }
                Repeater {
                    model: root.pages
                    ItemDelegate {
                        id: navItem
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 46
                        highlighted: root.currentPage === index
                        hoverEnabled: true
                        text: modelData.title
                        Accessible.name: text
                        onClicked: root.currentPage = index
                        contentItem: RowLayout {
                            spacing: 13
                            LineIcon { name: navItem.modelData.icon; tint: navItem.highlighted ? Theme.accent : Theme.muted }
                            Label {
                                text: navItem.text
                                Layout.fillWidth: true
                                color: navItem.highlighted ? Theme.accent : Theme.secondary
                                font.pixelSize: 13
                                font.weight: navItem.highlighted ? Font.DemiBold : Font.Normal
                            }
                        }
                        background: Rectangle {
                            radius: 10
                            color: navItem.highlighted ? Theme.accentSoft : navItem.hovered ? Theme.elevated : "transparent"
                            border.color: navItem.visualFocus ? Theme.accent : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border; Layout.bottomMargin: 14 }
                Label { text: "YOUR DEVICE"; font.pixelSize: 10; font.letterSpacing: 1.2; color: Theme.muted }
                Label {
                    text: center.profileText || "No device matched"
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    color: Theme.secondary
                }
                Label {
                    text: center.supportText ? "Support · " + center.supportText : "Waiting for device"
                    font.pixelSize: 11
                    color: Theme.muted
                    Layout.bottomMargin: 12
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                color: Theme.background
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    spacing: 10
                    Label { text: "Device control"; color: Theme.muted; font.pixelSize: 12 }
                    Label { text: "/"; color: Theme.border }
                    Label { text: root.pages[root.currentPage].title; color: Theme.secondary; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        radius: 14
                        implicitHeight: 28
                        implicitWidth: pillRow.implicitWidth + 24
                        color: Theme.surface
                        border.color: Theme.border
                        Accessible.name: pillLabel.text
                        Accessible.role: Accessible.StatusIndicator
                        RowLayout {
                            id: pillRow
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle {
                                width: 7; height: 7; radius: 4
                                color: root.stale ? Theme.amber : center.lastError ? Theme.danger : center.profileText ? Theme.success : Theme.muted
                            }
                            Label {
                                id: pillLabel
                                text: root.stale ? "Stale — retrying" : center.lastError ? "Connection issue" : center.profileText ? "Device connected" : "Connecting"
                                color: Theme.secondary
                                font.pixelSize: 11
                            }
                        }
                    }
                    ToolButton {
                        implicitWidth: 48; implicitHeight: 48
                        Accessible.name: "Refresh device"
                        ToolTip.visible: hovered
                        ToolTip.text: "Refresh device"
                        contentItem: LineIcon { name: "refresh"; tint: Theme.secondary }
                        onClicked: center.refreshNow()
                    }
                    ToolButton {
                        id: panicButton
                        implicitWidth: 48; implicitHeight: 48
                        Accessible.name: "More actions"
                        ToolTip.visible: hovered
                        ToolTip.text: "More actions"
                        contentItem: LineIcon { name: "more"; tint: Theme.secondary }
                        onClicked: panicMenu.open()
                        Menu {
                            id: panicMenu
                            MenuItem {
                                text: "Panic reset…"
                                onTriggered: panicDialog.open()
                            }
                        }
                    }
                }
            }
            Column {
                Layout.fillWidth: true
                spacing: 0
                visible: bannerQueue.count > 0
                Repeater {
                    model: bannerQueue
                    delegate: Rectangle {
                        required property string text
                        required property bool isError
                        property string bannerMsg: text
                        property bool bannerError: isError
                        width: parent.width
                        implicitHeight: Math.max(56, bannerLabel.implicitHeight + 24)
                        Behavior on implicitHeight { NumberAnimation { duration: 140 } }
                        color: bannerError ? Theme.dangerSoft : Theme.successSoft
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 28
                            anchors.rightMargin: 16
                            spacing: 12
                            Label {
                                id: bannerLabel
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                Layout.alignment: Qt.AlignVCenter
                                text: bannerMsg
                                color: bannerError ? Theme.danger : Theme.success
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                Accessible.role: Accessible.AlertMessage
                            }
                            ToolButton {
                                implicitWidth: 48; implicitHeight: 48
                                visible: bannerError
                                Accessible.name: "Dismiss message"
                                text: "×"
                                font.pixelSize: 18
                                onClicked: dismissBanner(bannerMsg, bannerError)
                            }
                        }
                    }
                }
            }
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentPage
                OverviewPage {}
                CoolingPage {}
                PowerPage {}
                BatteryPage {}
                RgbPage {}
                ScenesPage {}
                DiagnosticsPage {}
            }
            StickyActionBar {
                actionText: root.stickyAction ? root.stickyAction.text : ""
                actionDetail: root.stickyAction ? (root.stickyAction.detail || "") : ""
                actionEnabled: root.stickyAction ? root.stickyAction.enabled !== false : false
                onTriggered: { if (root.stickyAction && root.stickyAction.handler) root.stickyAction.handler(); }
            }
        }
    }
    OSD { id: osd }
    Dialog {
        id: panicDialog
        title: "Panic reset"
        modal: true
        anchors.centerIn: parent
        implicitWidth: 440
        standardButtons: Dialog.Cancel
        contentItem: Label {
            text: "Cooler Boost off, Super Battery off, fan auto. Shift/performance mode is untouched. Polkit authorization may prompt."
            color: Theme.secondary
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
        footer: DialogButtonBox {
            alignment: Qt.AlignRight
            ActionButton {
                text: "Reset now"
                destructive: true
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: panicDialog.accept()
            }
        }
        onAccepted: center.panicReset()
    }
    Connections {
        target: center
        function onActionDone(ok, title, detail) { osd.showMessage(title, detail, !ok) }
    }
}
