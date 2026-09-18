import QtQuick
import qs.config

// History curve. Canvas rather than SparklineItem because the C++ item only
// accepts a CircularBuffer, which QML can't construct - this takes any array,
// so it works for every metric in Sys.
Canvas {
    id: root

    property var points: []
    property real maxValue: 1
    property color colour: Theme.primary
    property bool fill: true
    property real thickness: 2.5
    property real smoothing: 0.32   // 0 = polyline, higher = softer curve

    renderStrategy: Canvas.Cooperative
    antialiasing: true

    onPointsChanged: requestPaint()
    onColourChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const pts = root.points ?? [];
        const n = pts.length;
        if (n < 2 || width <= 0 || height <= 0)
            return;

        const pad = root.thickness;
        const h = height - pad * 2;
        const stepX = width / (n - 1);
        const max = Math.max(root.maxValue, 0.0001);

        const xy = [];
        for (let i = 0; i < n; i++) {
            const v = Math.max(0, Math.min(1, pts[i] / max));
            xy.push([i * stepX, pad + h * (1 - v)]);
        }

        ctx.beginPath();
        ctx.moveTo(xy[0][0], xy[0][1]);
        for (let i = 0; i < n - 1; i++) {
            const p0 = xy[Math.max(0, i - 1)];
            const p1 = xy[i];
            const p2 = xy[i + 1];
            const p3 = xy[Math.min(n - 1, i + 2)];
            // Catmull-Rom -> cubic bezier control points.
            const c1x = p1[0] + (p2[0] - p0[0]) * root.smoothing;
            const c1y = p1[1] + (p2[1] - p0[1]) * root.smoothing;
            const c2x = p2[0] - (p3[0] - p1[0]) * root.smoothing;
            const c2y = p2[1] - (p3[1] - p1[1]) * root.smoothing;
            ctx.bezierCurveTo(c1x, c1y, c2x, c2y, p2[0], p2[1]);
        }

        if (root.fill) {
            ctx.save();
            ctx.lineTo(width, height + pad);
            ctx.lineTo(0, height + pad);
            ctx.closePath();
            const g = ctx.createLinearGradient(0, 0, 0, height);
            g.addColorStop(0, Qt.rgba(root.colour.r, root.colour.g, root.colour.b, 0.34));
            g.addColorStop(1, Qt.rgba(root.colour.r, root.colour.g, root.colour.b, 0));
            ctx.fillStyle = g;
            ctx.fill();
            ctx.restore();

            // Re-stroke the curve alone; the fill path above closed it.
            ctx.beginPath();
            ctx.moveTo(xy[0][0], xy[0][1]);
            for (let i = 0; i < n - 1; i++) {
                const p0 = xy[Math.max(0, i - 1)];
                const p1 = xy[i];
                const p2 = xy[i + 1];
                const p3 = xy[Math.min(n - 1, i + 2)];
                ctx.bezierCurveTo(p1[0] + (p2[0] - p0[0]) * root.smoothing, p1[1] + (p2[1] - p0[1]) * root.smoothing, p2[0] - (p3[0] - p1[0]) * root.smoothing, p2[1] - (p3[1] - p1[1]) * root.smoothing, p2[0], p2[1]);
            }
        }

        ctx.strokeStyle = root.colour;
        ctx.lineWidth = root.thickness;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.stroke();
    }
}
