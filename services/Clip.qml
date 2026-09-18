pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Clipboard history, via cliphist.
//
// cliphist stores entries as "<id>\t<preview>"; the preview for an image is a
// placeholder like "[[ binary data 112 KiB png 536x220 ]]", which is worth
// surfacing as an image chip rather than as that literal string.
Singleton {
    id: root

    property var entries: []
    readonly property bool available: root.entries.length > 0 || root.checked

    property bool checked: false

    function parsePreview(text: string): var {
        const img = /^\[\[\s*binary data\s+([\d.]+\s*\w+)\s+(\w+)\s+(\d+x\d+)/.exec(text);
        if (img)
            return {
                image: true,
                label: `${img[2].toUpperCase()} ${img[3]}`,
                detail: img[1]
            };
        return {
            image: false,
            label: text,
            detail: ""
        };
    }

    function copy(id: string): void {
        // Round-trips through cliphist so the full entry is restored, not the
        // truncated preview the list shows.
        Quickshell.execDetached(["sh", "-c", `cliphist decode ${id} | wl-copy`]);
    }

    function wipe(): void {
        Quickshell.execDetached(["sh", "-c", "cliphist wipe"]);
        listProc.running = true;
    }

    Process {
        id: listProc

        command: ["sh", "-c", "cliphist list 2>/dev/null | head -n 40"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 1)
                        continue;
                    const id = line.slice(0, tab).trim();
                    const preview = line.slice(tab + 1);
                    const p = root.parsePreview(preview);
                    out.push({
                        id: id,
                        image: p.image,
                        label: p.label,
                        detail: p.detail
                    });
                }
                root.entries = out;
                root.checked = true;
            }
        }
    }

    Timer {
        interval: 2500
        running: Demand.needed("clipboard")
        repeat: true
        triggeredOnStart: true
        onTriggered: listProc.running = true
    }
}
