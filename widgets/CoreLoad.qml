pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

// Every CPU core at once. A single aggregate figure hides the thing you usually
// want to know - whether one thread is pinned or the whole package is busy.
WidgetBase {
    id: root

    needs: ["sys.cores"]

    readonly property var cores: Sys.cores
    readonly property int columns: Math.max(1, Math.round(root.num("columns", 8)))
    readonly property string style: root.str("style", "bars")

    function tintFor(load: real): color {
        // Below the warn threshold the accent is used flat; above it the colour
        // ramps toward the error tone so a hot core is visible at a glance.
        const warn = root.num("warn", 0.75);
        if (load < warn)
            return root.accent;
        return Theme.mix(root.accent, Theme.error, Math.min(1, (load - warn) / Math.max(0.01, 1 - warn)));
    }

    Txt {
        id: heading

        visible: root.flag("showTitle", true)
        anchors.left: parent.left
        anchors.top: parent.top
        height: visible ? implicitHeight : 0
        text: `${root.cores.length} cores`
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 1
        color: root.muted
    }

    Txt {
        visible: heading.visible
        anchors.right: parent.right
        anchors.top: parent.top
        text: Sys.metrics.cpu.text
        font.family: Theme.mono
        font.pixelSize: 11
        color: root.fg
    }

    // --- vertical bars ------------------------------------------------------
    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.topMargin: heading.visible ? 8 : 0
        anchors.bottom: parent.bottom
        visible: root.style === "bars"
        spacing: Math.max(1, root.num("gap", 3))

        Repeater {
            // Keyed on the core *count*, which never changes in practice, so
            // these delegates live for the widget's lifetime and can animate.
            model: root.style === "bars" ? root.cores.length : 0

            Item {
                required property int index

                readonly property real load: root.cores[index] ?? 0

                width: (root.width - root.pad * 2 - (root.cores.length - 1) * Math.max(1, root.num("gap", 3))) / Math.max(1, root.cores.length)
                height: parent.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(width * 0.5, parent.height * parent.load)
                    radius: Math.min(root.num("rounding", 4), width / 2)
                    color: root.tintFor(parent.load)

                    Behavior on height {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 260
                        }
                    }

                }
            }
        }
    }

    // --- heat grid ----------------------------------------------------------
    Grid {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.topMargin: heading.visible ? 8 : 0
        anchors.bottom: parent.bottom
        visible: root.style === "grid"
        columns: root.columns
        rowSpacing: Math.max(1, root.num("gap", 3))
        columnSpacing: Math.max(1, root.num("gap", 3))

        Repeater {
            model: root.style === "grid" ? root.cores.length : 0

            Rectangle {
                required property int index

                readonly property real load: root.cores[index] ?? 0

                readonly property real cell: (root.width - root.pad * 2 - (root.columns - 1) * Math.max(1, root.num("gap", 3))) / root.columns

                width: cell
                height: cell
                radius: Math.min(root.num("rounding", 4), width / 2)
                color: Theme.alpha(root.tintFor(load), 0.18 + load * 0.82)

                Behavior on color {
                    ColorAnimation {
                        duration: 260
                    }
                }


                ListTxt {
                    anchors.centerIn: parent
                    visible: root.flag("showIndex", false) && parent.width > 18
                    text: `${parent.index}`
                    font.pixelSize: Math.max(8, parent.width * 0.32)
                    color: Theme.contrast(parent.color)
                }
            }
        }
    }
}
