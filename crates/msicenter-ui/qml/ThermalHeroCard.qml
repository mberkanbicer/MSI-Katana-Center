import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Theme.js" as Theme

// Primary focal point of Status: package temperature huge, worst core +
// top fan subline, live sparkline. Reads center directly like StatCard.
Panel {
    id: card
    function packageTemp() {
        for (let i = 0; i < center.cpuCores.length; i++) {
            const c = center.cpuCores[i];
            if (c.id.indexOf("Package") === 0 && c.temp !== undefined)
                return c.temp;
        }
        return undefined;
    }
    function hottestCore() {
        let best = null;
        for (let i = 0; i < center.cpuCores.length; i++) {
            const c = center.cpuCores[i];
            if (c.temp !== undefined && (best === null || c.temp > best.temp))
                best = c;
        }
        return best;
    }
    function topFan() {
        let best = null;
        for (let i = 0; i < center.fanEntries.length; i++) {
            const f = center.fanEntries[i];
            if (best === null || f.rpm > best.rpm)
                best = f;
        }
        return best;
    }
    function summary() {
        const t = card.packageTemp();
        const hot = card.hottestCore();
        const fan = card.topFan();
        if (t === undefined && hot === null)
            return "Thermal data unavailable";
        let s = t !== undefined ? ("Package at " + Math.round(t) + " degrees. ") : "";
        if (hot !== null)
            s += "Hottest " + hot.id + " at " + hot.temp.toFixed(1) + " degrees. ";
        if (fan !== null)
            s += "Top fan " + fan.channel + " at " + fan.rpm + " RPM.";
        return s;
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 8
        Label {
            text: "THERMAL STATUS"
            color: Theme.muted
            font.pixelSize: 11
            font.weight: Font.Medium
            font.letterSpacing: 0.6
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 4
                Label {
                    text: {
                        if (!center.dataReady)
                            return "…";
                        const t = card.packageTemp();
                        return t !== undefined ? Math.round(t) + "°C" : "Unavailable";
                    }
                    Accessible.name: card.summary()
                    color: Theme.text
                    font.pixelSize: 40
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.6
                }
                Label {
                    text: {
                        const hot = card.hottestCore();
                        const fan = card.topFan();
                        let s = hot !== null ? ("Hottest " + hot.id + " · " + hot.temp.toFixed(1) + "°C") : "";
                        if (fan !== null)
                            s += (s !== "" ? "   ·   " : "") + "Top fan " + fan.channel + " · " + fan.rpm + " RPM";
                        return s !== "" ? s : "Waiting for readings…";
                    }
                    color: Theme.secondary
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
            Sparkline {
                Layout.preferredWidth: 240
                Layout.minimumWidth: 120
                implicitHeight: 84
                Layout.alignment: Qt.AlignVCenter
                values: center.historyCpu
                maxValue: 100
                stroke: Theme.amber
            }
        }
        Label {
            text: center.coolerBoostOn ? "Cooler Boost is active" : "Live readings · every ~2 seconds"
            color: Theme.muted
            font.pixelSize: 11
        }
    }
}
