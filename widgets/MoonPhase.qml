import QtQuick
import qs.components
import qs.config
import qs.services

// Current moon phase, drawn rather than fetched.
//
// Uses the mean synodic month against a known new moon. That is accurate to
// well under a day, which is all a desktop ornament needs and costs nothing -
// no service, no network, no timer beyond the date already ticking.
WidgetBase {
    id: root

    readonly property real synodicMonth: 29.530588853
    readonly property real knownNewMoon: Date.UTC(2000, 0, 6, 18, 14) // 2000-01-06 18:14 UTC

    readonly property real age: {
        const days = (Clock.now.getTime() - root.knownNewMoon) / 86400000;
        const a = days % root.synodicMonth;
        return a < 0 ? a + root.synodicMonth : a;
    }

    // 0 = new, 0.5 = full, 1 = new again.
    readonly property real phase: root.age / root.synodicMonth
    readonly property real illumination: (1 - Math.cos(2 * Math.PI * root.phase)) / 2
    readonly property bool waxing: root.phase < 0.5

    readonly property string phaseName: {
        const p = root.phase;
        if (p < 0.02 || p > 0.98)
            return "New moon";
        if (p < 0.23)
            return "Waxing crescent";
        if (p < 0.27)
            return "First quarter";
        if (p < 0.48)
            return "Waxing gibbous";
        if (p < 0.52)
            return "Full moon";
        if (p < 0.73)
            return "Waning gibbous";
        if (p < 0.77)
            return "Last quarter";
        return "Waning crescent";
    }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Canvas {
            id: disc

            anchors.horizontalCenter: parent.horizontalCenter
            width: root.num("size", 90)
            height: width
            renderStrategy: Canvas.Cooperative
            antialiasing: true

            readonly property color lit: root.colour("litColour", root.fg)
            readonly property color dark: Theme.alpha(root.muted, 0.28)

            onWidthChanged: requestPaint()
            onLitChanged: requestPaint()

            Connections {
                target: root

                function onPhaseChanged(): void {
                    disc.requestPaint();
                }
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const r = width / 2;

                // The unlit disc, then the lit region on top.
                ctx.beginPath();
                ctx.arc(r, r, r, 0, Math.PI * 2);
                ctx.fillStyle = disc.dark;
                ctx.fill();

                // k runs +1 at new moon through 0 at the quarters to -1 at full.
                // The terminator is an ellipse whose x-radius is r*|k|: at the
                // quarters that collapses to a straight line, and at new/full it
                // matches the limb exactly, giving zero or total coverage.
                const k = Math.cos(2 * Math.PI * root.phase);

                ctx.save();
                // Everything below draws a waxing moon (lit on the right);
                // waning is the same shape mirrored, which is far less
                // error-prone than deriving a second set of sweep directions.
                if (!root.waxing) {
                    ctx.translate(width, 0);
                    ctx.scale(-1, 1);
                }

                ctx.beginPath();
                // Right-hand limb, top to bottom.
                ctx.arc(r, r, r, -Math.PI / 2, Math.PI / 2, false);

                // Terminator back up to the top. Qt's Canvas has no ellipse()
                // - scaling the coordinate system around the centre turns a
                // circular arc into the ellipse we need. An unguarded 0 scale
                // collapses the transform, hence the floor.
                ctx.save();
                ctx.translate(r, r);
                ctx.scale(Math.max(0.0001, Math.abs(k)), 1);
                ctx.arc(0, 0, r, Math.PI / 2, -Math.PI / 2, k > 0);
                ctx.restore();

                ctx.closePath();
                ctx.fillStyle = disc.lit;
                ctx.fill();
                ctx.restore();
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showName", true)
            text: root.phaseName
            font.pixelSize: root.num("textSize", 13)
            font.weight: Font.Medium
            color: root.fg
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showDetail", true)
            text: `${Math.round(root.illumination * 100)}% lit · day ${Math.floor(root.age)}`
            font.pixelSize: Math.max(9, root.num("textSize", 13) * 0.8)
            color: root.muted
        }
    }
}
