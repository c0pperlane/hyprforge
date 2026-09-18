pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// What each monitor actually leaves you to work with.
//
// Hyprland reports a `reserved` inset per output - [left, top, right, bottom] -
// which is the space layer-shell surfaces have claimed: on this setup that's
// caelestia's bar down the left edge and its border on the other three sides.
// Guessing a uniform margin instead would put widgets under the bar on one side
// and waste 50px on the others.
Singleton {
    id: root

    readonly property var monitors: Hyprland.monitors.values

    function monitorNamed(name: string): var {
        // `monitors` and each monitor's lastIpcObject are ordinary notifying
        // properties, so reading them is dependency enough - no discarded-read
        // trick needed, and none that a compiler could drop.
        return root.monitors.find(m => m.name === name) ?? null;
    }

    // Falls back to zero insets rather than a guess: a wrong safe area is worse
    // than none, because you'd lay out against a line that isn't there.
    function reservedFor(name: string): var {
        const m = root.monitorNamed(name);
        const r = m?.lastIpcObject?.reserved;
        if (!r || r.length < 4)
            return {
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                known: false
            };
        return {
            left: r[0],
            top: r[1],
            right: r[2],
            bottom: r[3],
            known: true
        };
    }

    function sizeOf(name: string): var {
        const m = root.monitorNamed(name);
        const s = Quickshell.screens.find(x => x.name === name);
        return {
            width: m?.lastIpcObject?.width ?? s?.width ?? 1920,
            height: m?.lastIpcObject?.height ?? s?.height ?? 1080
        };
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: var): void {
            // Anything that can move a layer surface can change the reserved
            // area: a bar toggling, a monitor being added, a resolution change.
            const n = event.name;
            if (n === "monitoradded" || n === "monitorremoved" || n === "configreloaded")
                root.refresh();
        }
    }

    function refresh(): void {
        Hyprland.refreshMonitors();
    }

    // The reserved area is not pushed over IPC when a layer surface changes its
    // exclusive zone, so it has to be polled. Only while the editor is open,
    // though: nothing outside the editor reads it, and refreshing Hyprland's
    // monitor list replaces the monitor objects, which churns every binding
    // that reads them.
    Timer {
        interval: 10000
        running: EditorState.editorActive
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
