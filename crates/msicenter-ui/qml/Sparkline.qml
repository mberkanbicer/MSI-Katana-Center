import QtQuick
import "Theme.js" as Theme

Canvas {
    id: chart
    property var values: []
    property int maxValue: 100
    property color stroke: Theme.accent
    implicitHeight: 56
    onValuesChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onStrokeChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = Theme.border
        ctx.lineWidth = 1
        for (let line = 0; line < 3; line++) {
            const y = 2 + (height - 4) * line / 2
            ctx.beginPath()
            ctx.moveTo(0, y)
            ctx.lineTo(width, y)
            ctx.stroke()
        }
        const pts = values
        if (!pts || pts.length < 2 || width < 2 || height < 2)
            return
        const maxY = Math.max(1, maxValue)
        const pad = 2
        ctx.strokeStyle = stroke
        ctx.lineWidth = 2
        ctx.lineJoin = "round"
        ctx.beginPath()
        for (let i = 0; i < pts.length; i++) {
            const x = pad + (width - pad * 2) * i / (pts.length - 1)
            const y = height - pad - (height - pad * 2)
                      * Math.max(0, Math.min(1, Number(pts[i]) / maxY))
            if (i === 0)
                ctx.moveTo(x, y)
            else
                ctx.lineTo(x, y)
        }
        ctx.stroke()
    }
}
