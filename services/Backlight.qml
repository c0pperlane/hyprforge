pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Screen backlight.
//
// Reads sysfs directly (cheap, and the file changes when anything else adjusts
// brightness) but writes through brightnessctl, because the sysfs node is not
// user-writable and brightnessctl ships a udev rule for exactly this.
Singleton {
    id: root

    property string device: ""
    property real current: 0
    property real maximum: 0

    readonly property bool available: root.maximum > 0
    readonly property real fraction: root.maximum > 0 ? root.current / root.maximum : 0

    function setFraction(f: real): void {
        if (!root.available)
            return;
        const pct = Math.round(Math.max(0.01, Math.min(1, f)) * 100);
        Quickshell.execDetached(["brightnessctl", "-d", root.device, "set", `${pct}%`]);
        // Optimistic update so the dial moves with the scroll rather than
        // waiting for the next sysfs read.
        root.current = root.maximum * (pct / 100);
    }

    function adjust(delta: real): void {
        root.setFraction(root.fraction + delta);
    }

    Process {
        id: findDevice

        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight/ 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        printErrors: false
        onLoaded: root.maximum = parseInt(text().trim()) || 0
    }

    FileView {
        id: actual

        path: root.device ? `/sys/class/backlight/${root.device}/actual_brightness` : ""
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.current = parseInt(text().trim()) || 0
    }

    // The watch catches external changes; this is only a safety net for
    // drivers that update the file without an inotify event.
    Timer {
        interval: 5000
        running: Demand.needed("brightness") && root.available
        repeat: true
        onTriggered: actual.reload()
    }
}
