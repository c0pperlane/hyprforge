import QtQuick

// A travelling sine line.
//
// Replaces caelestia-shell's WavyLine with plain QML, keeping the same
// property names so the widget reads the same either way. Doing it here rather
// than adapting theirs drops Caelestia.Components as a dependency entirely -
// it was the only type Forge used out of that module, and a sine path is not
// worth a hard requirement.
//
// `value` is how much of the span is drawn (0..1), `waveProgress` is the phase
// and is meant to be animated 0 -> 1 on a loop, and `frequency` is how many
// whole cycles fit across `fullLength`.
Canvas {
    id: root

    property color color: "white"
    property real lineWidth: 3
    property real frequency: 3
    property real startX: 0
    property real fullLength: width
    property real amplitudeMultiplier: 1
    property real value: 1
    property real waveProgress: 0

    // Repainting is the whole cost of this element, so it is sampled at a
    // fixed step rather than per pixel: at 3 cycles across a few hundred
    // points the curve is already smooth, and the step keeps a very wide
    // widget from turning into a very long path.
    readonly property int steps: Math.max(24, Math.min(480, Math.round(root.fullLength / 3)))

    onColorChanged: root.requestPaint()
    onLineWidthChanged: root.requestPaint()
    onFrequencyChanged: root.requestPaint()
    onStartXChanged: root.requestPaint()
    onFullLengthChanged: root.requestPaint()
    onAmplitudeMultiplierChanged: root.requestPaint()
    onValueChanged: root.requestPaint()
    onWaveProgressChanged: root.requestPaint()

    onPaint: {
        const ctx = root.getContext("2d");
        ctx.reset();

        const span = Math.max(0, root.fullLength);
        const drawn = span * Math.max(0, Math.min(1, root.value));
        if (drawn <= 0 || root.height <= 0)
            return;

        // Half the line width of headroom at each end, so the stroke's round
        // cap is not clipped by the item's own bounds at the peaks.
        const amp = Math.max(0, (root.height - root.lineWidth) / 2) * root.amplitudeMultiplier;
        const mid = root.height / 2;
        const phase = root.waveProgress * Math.PI * 2;
        const k = root.frequency * Math.PI * 2 / Math.max(1, span);

        ctx.beginPath();
        for (let i = 0; i <= root.steps; i++) {
            const x = drawn * i / root.steps;
            const y = mid + Math.sin(x * k + phase) * amp;
            if (i === 0)
                ctx.moveTo(root.startX + x, y);
            else
                ctx.lineTo(root.startX + x, y);
        }

        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.lineWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.stroke();
    }
}
