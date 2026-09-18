pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// Keyboard layout and audio, for the widgets that show them.
//
// Both sources are event-driven rather than polled, so there is nothing to gate
// on a timer - but the Pipewire object tracker is only bound while something is
// actually displaying a volume, since tracking a node has a real cost.
Singleton {
    id: root

    // --- keyboard -----------------------------------------------------------

    // Without caelestia there is no HyprExtras, so the main keyboard cannot be
    // identified and the layout readout falls back to the configured list.
    readonly property var keyboard: Cae.extras?.devices?.keyboards?.find(kb => kb.main) ?? null
    readonly property string layoutList: root.keyboard?.layout ?? ""
    readonly property string activeKeymap: root.keyboard?.activeKeymap ?? ""

    // Hyprland reports the configured list ("de,us") and the active keymap as a
    // human name ("German"). Prefer a short code derived from the list, falling
    // back to the long name when there is only one.
    readonly property var layouts: root.layoutList ? root.layoutList.split(",").map(s => s.trim()) : []

    readonly property string shortLayout: {
        if (!root.layouts.length)
            return root.activeKeymap ? root.activeKeymap.slice(0, 2).toUpperCase() : "??";
        // Hyprland does not report which index is active, only the keymap name;
        // match it against the list where we can.
        const km = root.activeKeymap.toLowerCase();
        const names = {
            "german": "de",
            "english": "us",
            "english (us)": "us",
            "french": "fr",
            "spanish": "es",
            "italian": "it",
            "russian": "ru",
            "polish": "pl",
            "turkish": "tr",
            "portuguese": "pt",
            "dutch": "nl",
            "swedish": "se",
            "norwegian": "no",
            "danish": "dk",
            "finnish": "fi",
            "czech": "cz",
            "hungarian": "hu"
        };
        for (const key of Object.keys(names))
            if (km.startsWith(key) && root.layouts.indexOf(names[key]) >= 0)
                return names[key].toUpperCase();
        return root.layouts[0].toUpperCase();
    }

    function cycleLayout(): void {
        if (root.layouts.length > 1 && root.keyboard)
            Hyprland.dispatch(`switchxkblayout ${root.keyboard.name} next`);
    }
}
