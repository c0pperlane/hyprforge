import QtQuick
import qs.config

// Design grid drawn in artboard space. Repaints only when the grid settings or
// the zoom change, so panning and dragging stay free of canvas work.
Canvas {
    id: root

    property real zoom: 1

    readonly property int cell: Math.max(2, Settings.grid.size)
    readonly property int subs: Math.max(1, Settings.grid.subdivisions)
    readonly property bool dots: Settings.grid.dots

    visible: Settings.grid.visible
    opacity: Settings.grid.opacity
    renderStrategy: Canvas.Cooperative
    antialiasing: false

    onCellChanged: requestPaint()
    onSubsChanged: requestPaint()
    onDotsChanged: requestPaint()
    onZoomChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    Connections {
        target: Theme

        function onPrimaryChanged(): void {
            root.requestPaint();
        }
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (width <= 0 || height <= 0)
            return;

        const hair = 1 / Math.max(0.08, root.zoom);
        const minor = root.cell / root.subs;
        // Below ~4 device pixels apart the minor grid is just noise.
        const drawMinor = minor * root.zoom > 4;

        const line = Theme.fgSurface;
        const rgb = `${Math.round(line.r * 255)}, ${Math.round(line.g * 255)}, ${Math.round(line.b * 255)}`;

        if (root.dots) {
            ctx.fillStyle = `rgba(${rgb}, 0.5)`;
            const r = Math.max(0.6, hair * 1.2);
            for (let x = 0; x <= width; x += root.cell)
                for (let y = 0; y <= height; y += root.cell) {
                    ctx.beginPath();
                    ctx.arc(x, y, r, 0, Math.PI * 2);
                    ctx.fill();
                }
            return;
        }

        if (drawMinor) {
            ctx.strokeStyle = `rgba(${rgb}, 0.12)`;
            ctx.lineWidth = hair;
            ctx.beginPath();
            for (let x = 0; x <= width; x += minor) {
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
            }
            for (let y = 0; y <= height; y += minor) {
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
            }
            ctx.stroke();
        }

        ctx.strokeStyle = `rgba(${rgb}, 0.3)`;
        ctx.lineWidth = hair;
        ctx.beginPath();
        for (let x = 0; x <= width; x += root.cell) {
            ctx.moveTo(x, 0);
            ctx.lineTo(x, height);
        }
        for (let y = 0; y <= height; y += root.cell) {
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
        }
        ctx.stroke();

        // Centre lines - the most useful alignment reference on a desktop.
        ctx.strokeStyle = `rgba(${rgb}, 0.42)`;
        ctx.lineWidth = hair * 1.5;
        ctx.beginPath();
        ctx.moveTo(width / 2, 0);
        ctx.lineTo(width / 2, height);
        ctx.moveTo(0, height / 2);
        ctx.lineTo(width, height / 2);
        ctx.stroke();
    }
}
