pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

// Where the package actually spends its time: one stacked bar of C-state
// residency, averaged across every core over the sampling window.
//
// The companion to Parked Cores. That one answers "how many cores is the
// scheduler using"; this answers "and how deeply are the rest asleep", which
// is the difference between a core that is merely unloaded and one that has
// reached C3 and stopped costing anything.
WidgetBase {
    id: root

    needs: ["sys.parking"]

    readonly property var park: Sys.parking

    // Deepest last, so the bar reads left-to-right from awake to asleep.
    readonly property var order: ["busy", "POLL", "C1", "C2", "C3"]

    readonly property real warn: root.num("warn", 0.8)

    readonly property color busyTint: {
        const busy = (root.park.busyPct ?? 0) / 100;
        const warn = root.warn;
        return busy < warn ? Theme.warning : Theme.mix(Theme.warning, Theme.error, Math.min(1, (busy - warn) / Math.max(0.01, 1 - warn)));
    }

    readonly property var segments: {
        if (!root.park.valid)
            return [];
        const states = root.park.states ?? ({});
        const all = ({
                busy: root.park.busyPct
            });
        for (const k of Object.keys(states))
            all[k] = states[k];

        // Anything the kernel reports that this list has not anticipated still
        // has to appear, or the bar silently stops adding up to 100%.
        const keys = root.order.filter(k => all[k] !== undefined).concat(Object.keys(all).filter(k => root.order.indexOf(k) < 0).sort());

        const out = [];
        for (let i = 0; i < keys.length; i++) {
            const pct = all[keys[i]];
            if (pct <= 0.05)
                continue;
            out.push({
                label: keys[i] === "busy" ? "busy" : keys[i],
                pct: pct,
                // Busy is amber, and only goes red once the package is past
                // the threshold - the sleep states keep the accent ramp, so
                // the bar separates "awake" from "how deeply asleep".
                tint: keys[i] === "busy" ? root.busyTint : Theme.alpha(root.accent, 0.85 - 0.16 * i)
            });
        }
        return out;
    }

    Txt {
        id: heading

        visible: root.flag("showTitle", true)
        anchors.left: parent.left
        anchors.top: parent.top
        height: visible ? implicitHeight : 0
        text: root.str("title", "IDLE RESIDENCY")
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 1
        color: root.muted
    }

    Txt {
        visible: heading.visible
        anchors.right: parent.right
        anchors.top: parent.top
        // The window matters: this is a delta between polls, not a
        // since-boot average, and a since-boot average describes no
        // particular moment.
        text: root.park.valid ? `${root.park.windowS.toFixed(1)}s` : "…"
        font.family: Theme.mono
        font.pixelSize: 11
        color: root.muted
    }

    Item {
        id: bar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.topMargin: heading.visible ? 10 : 0
        height: Math.max(6, root.num("barHeight", 14))

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.alpha(root.muted, 0.14)
            visible: !root.park.valid
        }

        Row {
            id: stack

            anchors.fill: parent
            spacing: 0
            visible: root.park.valid

            Repeater {
                model: root.segments.length

                Item {
                    required property int index

                    readonly property var seg: root.segments[index] ?? ({
                            pct: 0,
                            tint: root.accent
                        })

                    width: bar.width * Math.max(0, seg.pct) / 100
                    height: bar.height

                    Rectangle {
                        // Square the inner joins so the stack reads as one bar
                        // rather than a row of separate pills.
                        anchors.fill: parent
                        anchors.leftMargin: index === 0 ? 0 : -bar.height
                        radius: bar.height / 2
                        color: parent.seg.tint
                        clip: false
                        z: -parent.index

                        Behavior on color {
                            ColorAnimation {
                                duration: 260
                            }
                        }
                    }
                }
            }
        }
    }

    Flow {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: bar.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        visible: root.flag("showLegend", true) && root.park.valid
        spacing: 12

        Repeater {
            model: root.segments.length

            Row {
                required property int index

                readonly property var seg: root.segments[index] ?? ({
                        label: "",
                        pct: 0,
                        tint: root.accent
                    })

                spacing: 5

                Rectangle {
                    width: 8
                    height: 8
                    radius: 2
                    color: parent.seg.tint
                    anchors.verticalCenter: parent.verticalCenter
                }

                ListTxt {
                    text: `${parent.seg.label} ${parent.seg.pct.toFixed(1)}%`
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: root.fg
                }
            }
        }
    }
}
