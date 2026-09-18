pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

// Which threads the scheduler is actually using, as a grid of all 32.
//
// This is not Core Load with a different palette. Core Load reads /proc/stat,
// which cannot tell a core that is asleep from one that is merely unloaded -
// both are "idle". Core parking here is sched_ext core compaction: scx_lavd
// keeps tasks on a small set of CPUs and does not dispatch to the rest, so
// those drop into C2/C3. The only honest way to see that is cpuidle residency,
// which is what this draws: a dark cell is a core the scheduler has put away,
// a lit one is a core it is using.
WidgetBase {
    id: root

    needs: ["sys.parking"]

    readonly property var park: Sys.parking
    readonly property var cores: root.park.cpus ?? []
    readonly property int columns: Math.max(1, Math.round(root.num("columns", 8)))
    readonly property real gap: Math.max(0, root.num("gap", 4))
    readonly property bool parkedIsDark: root.str("emphasis", "active") === "active"

    // A cell is either parked or it is not - that is the reading. But a core
    // at 90% idle is not parked and looks identical to one at 5% if the cell
    // is binary, so the unparked ones carry their busy fraction as intensity.
    //
    // Working cores are amber and only turn red past the threshold, so "this
    // core is in use" and "this core is pinned" are different colours rather
    // than different shades of the same one.
    function tintFor(idle: real, parked: bool): color {
        if (parked)
            return root.parkedIsDark ? Theme.alpha(root.muted, 0.18) : root.accent;
        const busy = Math.max(0, Math.min(1, 1 - idle));
        const warn = root.num("warn", 0.8);
        const base = busy < warn ? Theme.warning : Theme.mix(Theme.warning, Theme.error, Math.min(1, (busy - warn) / Math.max(0.01, 1 - warn)));
        return Theme.alpha(base, 0.28 + busy * 0.72);
    }

    Txt {
        id: heading

        visible: root.flag("showTitle", true)
        anchors.left: parent.left
        anchors.top: parent.top
        height: visible ? implicitHeight : 0
        text: root.str("title", "PARKED CORES")
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 1
        color: root.muted
        elide: Text.ElideRight
        width: Math.max(0, parent.width - readout.width - 10)
    }

    Txt {
        id: readout

        visible: heading.visible
        anchors.right: parent.right
        anchors.top: parent.top
        // Nothing attached means the kernel is on EEVDF and no core is parked
        // by anything; saying "0/32" would imply the mechanism is running.
        text: !root.park.valid ? "…" : root.park.scheduler ? `${root.park.parked}/${root.cores.length}` : "off"
        font.family: Theme.mono
        font.pixelSize: 11
        color: root.park.scheduler ? root.fg : root.muted
    }

    Grid {
        id: grid

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.topMargin: heading.visible ? 8 : 0
        anchors.bottom: footer.visible ? footer.top : parent.bottom
        anchors.bottomMargin: footer.visible ? 8 : 0
        columns: root.columns
        rowSpacing: root.gap
        columnSpacing: root.gap

        Repeater {
            // Keyed on the core count, which never changes on a running
            // machine, so these delegates live as long as the widget and can
            // safely animate - a delegate destroyed mid-Behaviour is what used
            // to take the shell down.
            model: root.cores.length

            Rectangle {
                required property int index

                readonly property real idle: root.cores[index] ?? 0
                readonly property bool parked: root.park.scheduler !== "" && idle >= Sys.parkedIdlePct

                readonly property real cellW: (grid.width - (root.columns - 1) * root.gap) / root.columns
                readonly property int rows: Math.max(1, Math.ceil(root.cores.length / root.columns))

                width: cellW
                height: root.flag("square", false) ? cellW : Math.max(4, (grid.height - (rows - 1) * root.gap) / rows)
                radius: Math.min(root.num("rounding", 7), Math.min(width, height) / 2)
                color: root.tintFor(idle, parked)

                Behavior on color {
                    ColorAnimation {
                        duration: 320
                    }
                }

                ListTxt {
                    anchors.centerIn: parent
                    visible: root.flag("showIndex", false) && parent.width > 16 && parent.height > 12
                    text: `${parent.index}`
                    font.pixelSize: Math.max(8, Math.round(Math.min(parent.width, parent.height) * 0.36))
                    color: Theme.contrast(parent.color)
                    opacity: 0.85
                }
            }
        }
    }

    Txt {
        id: footer

        visible: root.flag("showFooter", true) && root.park.valid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        elide: Text.ElideRight
        font.family: Theme.mono
        font.pixelSize: 10
        color: root.muted
        text: {
            if (!root.park.valid)
                return "";
            if (!root.park.scheduler)
                return "no sched_ext scheduler attached";
            const busy = root.park.busyPct.toFixed(1);
            return `${root.park.scheduler} · ${busy}% busy · ${root.park.deepPct.toFixed(0)}% deep idle`;
        }
    }
}
