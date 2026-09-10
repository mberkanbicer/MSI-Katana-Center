import QtQuick
import "Theme.js" as Theme

Canvas {
    id: icon
    property string name: "overview"
    property color tint: Theme.muted
    implicitWidth: 22
    implicitHeight: 22
    onNameChanged: requestPaint()
    onTintChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d")
        c.reset()
        c.scale(width / 24, height / 24)
        c.strokeStyle = tint
        c.lineWidth = 1.6
        c.lineCap = "round"
        c.lineJoin = "round"
        function line(points) {
            c.beginPath()
            c.moveTo(points[0][0], points[0][1])
            for (let i = 1; i < points.length; i++) c.lineTo(points[i][0], points[i][1])
            c.stroke()
        }
        if (name === "overview") {
            c.strokeRect(3, 3, 7, 7); c.strokeRect(14, 3, 7, 7)
            c.strokeRect(3, 14, 7, 7); c.strokeRect(14, 14, 7, 7)
        } else if (name === "power") {
            line([[13,2],[5,13],[11,13],[10,22],[19,10],[13,10],[13,2]])
        } else if (name === "battery") {
            c.strokeRect(2, 6, 18, 12)
            line([[22,10],[22,14]]); line([[6,10],[6,14]]); line([[10,10],[10,14]])
        } else if (name === "keyboard") {
            c.strokeRect(2, 5, 20, 14)
            for (let x = 6; x <= 18; x += 4) { line([[x,9],[x+1,9]]); line([[x,12],[x+1,12]]) }
            line([[7,16],[17,16]])
        } else if (name === "scenes") {
            line([[3,8],[12,3],[21,8],[12,13],[3,8]])
            line([[3,12],[12,17],[21,12]]); line([[3,16],[12,21],[21,16]])
        } else if (name === "refresh") {
            c.beginPath(); c.arc(12,12,8,0.3,5.4); c.stroke()
            line([[18,3],[18,8],[13,8]])
        } else if (name === "diagnostics") {
            c.strokeRect(6, 4, 12, 17)
            line([[9,4],[9,2],[15,2],[15,4]])
            line([[8.5,13],[11,15.5],[15.5,9.5]])
        } else if (name === "fan") {
            c.beginPath(); c.arc(12, 12, 8.5, 0, 6.2832); c.stroke()
            for (const a of [0, 2.0944, 4.1888]) {
                c.beginPath()
                c.arc(12 + 4 * Math.cos(a), 12 + 4 * Math.sin(a), 3.2, a, a + 3.6)
                c.stroke()
            }
        } else if (name === "more") {
            c.fillStyle = tint
            for (const x of [5, 12, 19]) { c.beginPath(); c.arc(x, 12, 1.6, 0, 6.2832); c.fill() }
        } else {
            line([[2,12],[7,12],[10,5],[14,19],[17,12],[22,12]])
        }
    }
}
