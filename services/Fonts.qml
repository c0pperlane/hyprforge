pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Installed fonts, and the bridge to `caelestia-forge-fonts`.
//
// The actual file surgery - shell.json, fontconfig, GTK settings, Discord's
// quickCss - lives in that script rather than here: it is easier to read, it
// can be run and reverted without opening the editor, and a half-applied font
// change is not something you want to debug through QML's process plumbing.
Singleton {
    id: root

    readonly property string tool: "caelestia-forge-fonts"

    property var families: []
    property var monoFamilies: []
    property var iconFamilies: []
    property bool loaded: false

    property bool busy: false
    property string lastMessage: ""

    // What is currently applied, as reported by the script.
    property var applied: ({})
    readonly property bool isApplied: applied.applied ?? false

    signal finished(bool ok, string message)

    function refresh(): void {
        listProc.running = true;
        statusProc.running = true;
    }

    function isMono(family: string): bool {
        return root.monoFamilies.indexOf(family) >= 0;
    }

    function isIcon(family: string): bool {
        return root.iconFamilies.indexOf(family) >= 0;
    }

    // Families worth offering for body text: everything except the icon and
    // symbol fonts, which would render the UI as rectangles.
    readonly property var textFamilies: {
        const icons = root.iconFamilies;
        return root.families.filter(f => icons.indexOf(f) < 0);
    }

    function search(query: string, monoOnly: bool): var {
        const pool = monoOnly ? root.monoFamilies : root.textFamilies;
        const q = (query ?? "").trim().toLowerCase();
        if (!q)
            return pool;
        return pool.filter(f => f.toLowerCase().includes(q));
    }

    function apply(sans: string, mono: string, display: string, size: int, force: bool, targets: string): void {
        const args = [root.tool, "apply", "--sans", sans, "--mono", mono, "--display", display, "--size", `${size}`, "--targets", targets];
        if (force)
            args.push("--force");
        applyProc.command = args;
        root.busy = true;
        root.lastMessage = "Applying…";
        applyProc.running = true;
    }

    function revert(): void {
        applyProc.command = [root.tool, "revert"];
        root.busy = true;
        root.lastMessage = "Reverting…";
        applyProc.running = true;
    }

    Process {
        id: listProc

        command: [root.tool, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.families = d.families ?? [];
                    root.monoFamilies = d.mono ?? [];
                    root.iconFamilies = d.icons ?? [];
                    root.loaded = true;
                } catch (e) {
                    console.warn("Forge: could not read the font list -", e);
                }
            }
        }
    }

    Process {
        id: statusProc

        command: [root.tool, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.applied = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: applyProc

        stdout: StdioCollector {
            onStreamFinished: root.lastMessage = text.trim().split("\n").filter(l => l.length).pop() ?? ""
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.lastMessage = text.trim();
            }
        }

        onExited: (code, status) => {
            root.busy = false;
            statusProc.running = true;
            root.finished(code === 0, root.lastMessage);
        }
    }

    Component.onCompleted: root.refresh()
}
