//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.layer
import qs.editor

// Hyprforge - a desktop designer for the caelestia dots.
//
// Two halves in one process:
//   * WidgetLayer  - the always-on layer-shell surfaces that render whatever
//                    the user has placed, on every monitor.
//   * Editor       - an on-demand fullscreen canvas that takes over the screen
//                    so those same widgets can be dragged, snapped and tuned.
//
// Toggle it from anywhere with:  qs -c hyprforge ipc call editor toggle
ShellRoot {
    id: root

    property bool editorOpen: false

    WidgetLayer {
        editorOpen: root.editorOpen
    }

    LazyLoader {
        id: editorLoader

        active: root.editorOpen

        Editor {
            open: root.editorOpen
            onDismissed: root.editorOpen = false
        }
    }

    IpcHandler {
        target: "editor"

        function toggle(): string {
            root.editorOpen = !root.editorOpen;
            return root.editorOpen ? "opened" : "closed";
        }

        function open(): string {
            root.editorOpen = true;
            return "opened";
        }

        function close(): string {
            root.editorOpen = false;
            return "closed";
        }

        function isOpen(): bool {
            return root.editorOpen;
        }
    }

    // Diagnostics. `demand` is the honest answer to "is this thing doing work
    // right now" - it lists every service currently held awake and by how many
    // widgets. If that prints an empty list while the desktop is covered, the
    // gating is doing its job.
    IpcHandler {
        target: "diag"

        function demand(): string {
            const a = Demand.active;
            if (a.length)
                return a.join(" ");
            if (Demand.liveLayers > 0)
                return `(idle - nothing held; ${Demand.liveLayers} layer(s) drawing, ${Demand.liveWidgets} widget(s) live)`;
            return Demand.idleReason ? `(idle - nothing held: ${Demand.idleReason})` : "(idle - nothing held)";
        }

        // Which metric source is live, and what it is currently reporting.
        // The point of this one is that the answer should look the same on a
        // caelestia machine and a bare one.
        function backend(): string {
            const src = Cae.available ? "caelestia-shell" : "fallback (/proc, sysfs, df)";
            const audio = Cae.available ? "caelestia FFT" : (Cava.cliRunning ? "cava CLI" : "none - level only, via PipeWire");
            return [`source: ${src}`, `cpu: ${(Sys.cpuPercent * 100).toFixed(1)}% ${Sys.cpuName}`, `cpuTemp: ${Sys.cpuTemp.toFixed(0)}C`, `mem: ${(Sys.memPercent * 100).toFixed(1)}% of ${(Sys.memTotalBytes / 1073741824).toFixed(1)}G`, `gpu: ${(Sys.gpuPercent * 100).toFixed(0)}% ${Sys.gpuName} ${Sys.gpuTemp.toFixed(0)}C`, `storage: ${(Sys.storagePercent * 100).toFixed(1)}% over ${Sys.disks.length} disk(s)`, `net: down ${(Sys.netDown / 1024).toFixed(1)} KiB/s up ${(Sys.netUp / 1024).toFixed(1)} KiB/s`, `spectrum: ${audio}`].join("\n");
        }

        function widgets(): string {
            const counts = ({});
            for (let i = 0; i < Store.widgets.count; i++) {
                const t = Store.widgets.get(i).type;
                counts[t] = (counts[t] ?? 0) + 1;
            }
            return Object.keys(counts).sort().map(k => `${k}=${counts[k]}`).join(" ");
        }
    }

    IpcHandler {
        target: "layer"

        function toggle(): string {
            Settings.layer.enabled = !Settings.layer.enabled;
            Settings.save();
            return Settings.layer.enabled ? "shown" : "hidden";
        }

        function reload(): string {
            Store.reloadFromDisk();
            return "reloaded";
        }
    }
}
