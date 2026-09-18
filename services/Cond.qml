pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Bluetooth
import qs.config

// Visibility conditions.
//
// A widget can carry a set of rules that decide whether it is on the desktop
// at all: a battery card that only appears on battery, a lyrics panel that
// only appears when there are lyrics, a media card that goes away when nothing
// is playing. A rule that is not met does not hide the widget, it un-builds
// it - the layer drops the Loader, so an element waiting for its condition
// costs nothing beyond the condition itself.
//
// Rules are stored on the widget as
//
//     { mode: "all" | "any", rules: [ { key, not, value } ] }
//
// and an absent or empty set means "always", so every existing layout keeps
// working untouched.
Singleton {
    id: root

    // Every rule the editor offers. `value` describes an optional parameter;
    // `needs` are the service demand keys the rule cannot be answered without,
    // which the layer has to hold even while the widget is not built - a
    // condition that reads a service nobody is keeping awake can never come
    // true. Rules without `needs` read something that is free.
    readonly property var catalog: [
        {
            key: "power.battery",
            group: "Power",
            label: "On battery",
            icon: "battery_android_bolt"
        },
        {
            key: "power.ac",
            group: "Power",
            label: "On AC power",
            icon: "power"
        },
        {
            key: "power.charging",
            group: "Power",
            label: "Charging",
            icon: "battery_charging_full"
        },
        {
            key: "power.below",
            group: "Power",
            label: "Battery below",
            icon: "battery_alert",
            value: {
                type: "int",
                def: 20,
                min: 1,
                max: 99,
                unit: "%"
            }
        },
        {
            key: "media.playing",
            group: "Media",
            label: "Media playing",
            icon: "play_arrow"
        },
        {
            key: "media.paused",
            group: "Media",
            label: "Media paused",
            icon: "pause"
        },
        {
            key: "media.present",
            group: "Media",
            label: "A player is open",
            icon: "music_note"
        },
        {
            key: "lyrics.found",
            group: "Media",
            label: "Lyrics available",
            icon: "lyrics",
            needs: ["lyrics", "media.position"]
        },
        {
            key: "audio.muted",
            group: "Media",
            label: "Output muted",
            icon: "volume_off"
        },
        {
            key: "screen.clear",
            group: "Screen",
            label: "Desktop is clear",
            icon: "desktop_windows"
        },
        {
            key: "screen.fullscreen",
            group: "Screen",
            label: "A window is fullscreen",
            icon: "fullscreen"
        },
        {
            key: "screen.workspace",
            group: "Screen",
            label: "Workspace is",
            icon: "grid_view",
            value: {
                type: "int",
                def: 1,
                min: 1,
                max: 99,
                unit: ""
            }
        },
        {
            key: "time.after",
            group: "Time",
            label: "After",
            icon: "schedule",
            value: {
                type: "time",
                def: "18:00",
                unit: ""
            }
        },
        {
            key: "time.before",
            group: "Time",
            label: "Before",
            icon: "schedule",
            value: {
                type: "time",
                def: "09:00",
                unit: ""
            }
        },
        {
            key: "bt.connected",
            group: "System",
            label: "Bluetooth device connected",
            icon: "bluetooth_connected"
        },
        {
            key: "sys.parked",
            group: "System",
            label: "Parked cores above",
            icon: "developer_board",
            value: {
                type: "int",
                def: 16,
                min: 0,
                max: 128,
                unit: ""
            },
            needs: ["sys.parking"]
        }
    ]

    function def(key: string): var {
        return root.catalog.find(c => c.key === key) ?? null;
    }

    function label(rule: var): string {
        const d = root.def(rule?.key ?? "");
        if (!d)
            return rule?.key ?? "";
        const body = d.value === undefined ? d.label : `${d.label} ${root.valueOf(rule)}${d.value.unit ?? ""}`;
        return rule.not ? `Not ${body.charAt(0).toLowerCase()}${body.slice(1)}` : body;
    }

    function valueOf(rule: var): var {
        const d = root.def(rule?.key ?? "");
        if (!d || d.value === undefined)
            return undefined;
        return rule.value === undefined || rule.value === null || rule.value === "" ? d.value.def : rule.value;
    }

    // "22:30" -> 1350 minutes. Anything unparseable is -1, which no comparison
    // matches, so a malformed time hides nothing rather than hiding at random.
    function minutesOf(text: var): int {
        const m = `${text ?? ""}`.match(/^(\d{1,2}):(\d{2})$/);
        if (!m)
            return -1;
        const h = parseInt(m[1]);
        const min = parseInt(m[2]);
        if (h > 23 || min > 59)
            return -1;
        return h * 60 + min;
    }

    // Answers one rule. Reads the service properties directly so that a QML
    // binding calling this tracks them and re-evaluates on its own.
    function test(rule: var, screenName: string): bool {
        const key = rule?.key ?? "";
        const v = root.valueOf(rule);
        let out = false;

        switch (key) {
        case "power.battery":
            out = Sys.hasBattery && !Sys.plugged;
            break;
        case "power.ac":
            out = !Sys.hasBattery || Sys.plugged;
            break;
        case "power.charging":
            out = Sys.charging;
            break;
        case "power.below":
            out = Sys.hasBattery && Sys.batteryLevel * 100 < v;
            break;
        case "media.playing":
            out = Media.playing;
            break;
        case "media.paused":
            out = Media.hasPlayer && !Media.playing;
            break;
        case "media.present":
            out = Media.hasPlayer;
            break;
        case "lyrics.found":
            out = LyricsSvc.hasLyrics;
            break;
        case "audio.muted":
            out = Volume.muted;
            break;
        case "screen.clear":
            out = root.toplevelsOn(screenName).length === 0;
            break;
        case "screen.fullscreen":
            out = root.toplevelsOn(screenName).some(t => (t.lastIpcObject?.fullscreen ?? 0) > 0);
            break;
        case "screen.workspace":
            out = root.workspaceOn(screenName) === v;
            break;
        case "time.after":
            out = Clock.hours * 60 + Clock.minutes >= root.minutesOf(v);
            break;
        case "time.before":
            out = Clock.hours * 60 + Clock.minutes < root.minutesOf(v);
            break;
        case "bt.connected":
            out = (Bluetooth.devices?.values ?? []).some(d => d.connected);
            break;
        case "sys.parked":
            out = Sys.parking.valid && Sys.parking.parked > v;
            break;
        default:
            // An unknown key is a rule this build does not have - most likely a
            // layout written by a newer version. Treat it as met rather than
            // making the widget vanish for a reason nothing can explain.
            return true;
        }

        return rule.not ? !out : out;
    }

    // Conditions are per widget, and a widget lives on one output, so the
    // screen rules answer for *that* output rather than the focused one.
    function monitorFor(screenName: string): var {
        const mons = Hyprland.monitors?.values ?? [];
        return mons.find(m => m.name === screenName) ?? Hyprland.focusedMonitor ?? null;
    }

    function toplevelsOn(screenName: string): var {
        return root.monitorFor(screenName)?.activeWorkspace?.toplevels?.values ?? [];
    }

    function workspaceOn(screenName: string): int {
        return root.monitorFor(screenName)?.activeWorkspace?.id ?? -1;
    }

    // The whole set. An empty or absent set is "always".
    function evaluate(cond: var, screenName: string): bool {
        const rules = cond?.rules ?? [];
        if (!rules.length)
            return true;
        if ((cond.mode ?? "all") === "any")
            return rules.some(r => root.test(r, screenName));
        return rules.every(r => root.test(r, screenName));
    }

    // Service keys the set cannot be answered without. The layer holds these
    // for as long as the widget is placed, not for as long as it is built -
    // otherwise "show when lyrics exist" would need lyrics to already be
    // running, which is exactly what it is gating.
    function demands(cond: var): var {
        const out = [];
        for (const r of cond?.rules ?? [])
            for (const k of root.def(r.key)?.needs ?? [])
                if (out.indexOf(k) < 0)
                    out.push(k);
        return out;
    }

    function has(cond: var): bool {
        return (cond?.rules ?? []).length > 0;
    }
}
