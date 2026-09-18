pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Keep the session awake.
//
// Holds a systemd idle inhibitor for as long as the helper process lives -
// killing it is the release. That is the documented way to do this and works
// regardless of which idle daemon is in use, which matters here because
// hypridle is not installed.
Singleton {
    id: root

    readonly property bool active: inhibitor.running

    function enable(): void {
        if (!inhibitor.running)
            inhibitor.running = true;
    }

    function disable(): void {
        inhibitor.running = false;
    }

    function toggle(): void {
        if (root.active)
            root.disable();
        else
            root.enable();
    }

    Process {
        id: inhibitor

        running: false
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Caelestia Forge", "--why=Idle inhibitor widget", "--mode=block", "sleep", "infinity"]
    }
}
