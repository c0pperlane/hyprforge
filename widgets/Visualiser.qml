import QtQuick
import qs.components
import qs.config
import qs.services

// Cava spectrum.
//
// Drawn as plain rectangles rather than with Caelestia's VisualiserBars: that
// item maps its input through its own internal scaling, which rendered
// near-zero-height bars at this widget's size no matter what values it was
// fed. Doing it here costs one Rectangle per bar (nothing, at these counts)
// and makes gain, the idle floor, and centre-mirroring behave exactly as the
// Inspector says they will.
WidgetBase {
    id: root

    needs: ["cava"]

    readonly property string cavaId: `vis${Math.random().toString(36).slice(2, 8)}`
    readonly property int barCount: Math.round(root.num("bars", 42))
    readonly property string mirror: root.str("mirror", "up")
    readonly property bool centred: root.mirror === "center"
    readonly property bool downward: root.mirror === "down"

    // Cava's output is quiet at typical desktop volumes; a gain makes the
    // widget usable without the user having to ride the slider.
    readonly property real gain: root.num("gain", 2.6)
    readonly property real floorLevel: root.num("minHeight", 0.02)

    readonly property var levels: {
        const v = Cava.values ?? [];
        const n = root.barCount;
        const out = [];
        for (let i = 0; i < n; i++) {
            // Cava may report a different bar count than requested for a frame
            // or two after a change; resample rather than render a short row.
            const src = v.length ? v[Math.min(v.length - 1, Math.floor(i * v.length / n))] : 0;
            out.push(Math.max(root.floorLevel, Math.min(1, src * root.gain)));
        }
        return out;
    }

    onLiveChanged: root.syncCava()
    Component.onCompleted: root.syncCava()
    Component.onDestruction: Cava.release(root.cavaId)

    // Registering a bar count is what sizes the shared capture; doing it while
    // off-screen would keep cava running for a widget nobody can see.
    function syncCava(): void {
        if (root.live && root.needs.indexOf("cava") >= 0)
            Cava.request(root.cavaId, root.barCount);
        else
            Cava.release(root.cavaId);
    }
    onBarCountChanged: root.syncCava()

    Row {
        id: row

        anchors.fill: parent
        spacing: root.num("spacing", 0.35) * (root.width / Math.max(1, root.barCount)) * 0.9

        readonly property real barWidth: Math.max(1, (root.width - root.pad * 2 - spacing * (root.barCount - 1)) / root.barCount)

        Repeater {
            model: root.barCount

            Item {
                id: slot

                required property int index

                readonly property real level: root.levels[index] ?? 0
                // Softens the spectrum's jagged top end so the bars read as one
                // shape rather than 42 independent flickers.
                readonly property real eased: level

                width: row.barWidth
                height: row.height

                Rectangle {
                    id: bar

                    width: parent.width
                    height: Math.max(width * 0.6, (root.centred ? slot.height / 2 : slot.height) * slot.eased)
                    radius: Math.min(root.num("rounding", 6), width / 2)

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: root.downward ? parent.top : undefined
                    anchors.bottom: root.downward || root.centred ? undefined : parent.bottom
                    anchors.verticalCenter: root.centred ? parent.verticalCenter : undefined

                    color: root.flag("gradient", true) ? Theme.mix(root.accent, root.colour("muted", Theme.fgSurfaceVariant), Math.min(1, slot.eased * 0.9)) : root.accent
                    opacity: 0.9

                    Behavior on height {
                        NumberAnimation {
                            duration: 90
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                // Centre mode mirrors downward from the midline.
                Rectangle {
                    visible: root.centred
                    width: parent.width
                    height: bar.height
                    radius: bar.radius
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.verticalCenter
                    color: bar.color
                    opacity: 0.45
                }
            }
        }
    }
}
