import QtQuick

Canvas {
    id: chart
    property var values: []
    property int maxValue: 100
    property color stroke: "#E2A35B"
    implicitHeight: 56
    onValuesChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const pts = values
        if (!pts || pts.length < 2 || width < 2 || height < 2)
            return
        const maxY = Math.max(1, maxValue)
        const pad = 2
        ctx.strokeStyle = stroke
        ctx.lineWidth = 1.5
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
