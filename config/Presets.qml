pragma Singleton

import QtQuick
import Quickshell

// Style presets: named sets of the shared Surface/Colour props.
//
// The anchor is "Caelestia Modal", which reproduces how this shell actually
// draws its own modals right now - opaque m3surfaceContainer at
// Tokens.rounding.extraLarge, no border, no shadow. It reads as opaque because
// appearance.transparency.enabled is off in shell.json; "Caelestia Glass" is
// the same shape for when that is turned back on.
//
// `props` is applied to every element. `extras` is applied only where the
// widget's own schema actually has that key, so a preset can say "turn on the
// legibility shadow" without inventing props on widgets that have none.
Singleton {
    id: root

    readonly property var presets: [
        {
            id: "caelestia",
            name: "Caelestia Modal",
            blurb: "What the shell's own drawers look like: opaque surface, 28px corners",
            props: {
                bg: "solid",
                bgColour: "surfaceContainer",
                bgOpacity: 1,
                radius: 28,
                radiusLinked: true,
                padding: 20,
                border: false,
                borderColour: "outlineVariant",
                shadow: false,
                accent: "primary",
                fg: "fgSurface",
                muted: "fgSurfaceVariant"
            },
            extras: {
                glow: false
            }
        },
        {
            id: "card",
            name: "Caelestia Card",
            blurb: "The tighter inner-card look from the bar popouts and telemetry corner",
            props: {
                bg: "solid",
                bgColour: "surfaceContainerHigh",
                bgOpacity: 1,
                radius: 16,
                radiusLinked: true,
                padding: 16,
                border: false,
                borderColour: "outlineVariant",
                shadow: false,
                accent: "primary",
                fg: "fgSurface",
                muted: "fgSurfaceVariant"
            },
            extras: {
                glow: false
            }
        },
        {
            id: "translucent",
            name: "Caelestia Translucent",
            blurb: "Same shape, see-through - pairs with transparency turned on in the shell",
            props: {
                bg: "tonal",
                bgColour: "surfaceContainer",
                bgOpacity: 0.72,
                radius: 28,
                radiusLinked: true,
                padding: 20,
                border: true,
                borderColour: "outlineVariant",
                shadow: false,
                accent: "primary",
                fg: "fgSurface",
                muted: "fgSurfaceVariant"
            },
            extras: {
                glow: false
            }
        },
        {
            id: "glass",
            name: "Glass",
            blurb: "Frosted, edge-lit, floats over a busy wallpaper",
            props: {
                bg: "glass",
                bgColour: "surfaceContainer",
                bgOpacity: 0.62,
                radius: 28,
                radiusLinked: true,
                padding: 20,
                border: true,
                borderColour: "outlineVariant",
                shadow: true,
                accent: "primary",
                fg: "fgSurface",
                muted: "fgSurfaceVariant"
            },
            extras: {
                glow: false
            }
        },
        {
            id: "elevated",
            name: "Elevated",
            blurb: "Lifted off the wallpaper with a soft drop shadow",
            props: {
                bg: "solid",
                bgColour: "surfaceContainerHighest",
                bgOpacity: 1,
                radius: 24,
                radiusLinked: true,
                padding: 20,
                border: false,
                borderColour: "outlineVariant",
                shadow: true,
                accent: "primary",
                fg: "fgSurface",
                muted: "fgSurfaceVariant"
            },
            extras: {
                glow: false
            }
        },
        {
            id: "ink",
            name: "Ink",
            blurb: "Near-black panels - the safe choice over a bright or busy wallpaper",
            props: {
                bg: "solid",
                bgColour: "surfaceContainerLowest",
                bgOpacity: 1,
                radius: 18,
                radiusLinked: true,
                padding: 18,
                border: false,
                borderColour: "outlineVariant",
                shadow: false,
                accent: "primary",
                fg: "fgSurface",
                muted: "fgSurfaceVariant"
            },
            extras: {
                glow: false
            }
        },
        {
            id: "outline",
            name: "Outline",
            blurb: "Barely-there wash and a hairline, so the wallpaper still reads",
            props: {
                bg: "outline",
                bgColour: "surfaceContainer",
                bgOpacity: 0.9,
                radius: 20,
                radiusLinked: true,
                padding: 18,
                border: true,
                borderColour: "outlineVariant",
                shadow: false,
                accent: "primary",
                fg: "fgSurface",
                muted: "fgSurfaceVariant"
            },
            extras: {
                glow: false
            }
        },
        {
            id: "tinted",
            name: "Tinted",
            blurb: "Accent-coloured containers - loud, good for a small feature cluster",
            props: {
                bg: "solid",
                bgColour: "primaryContainer",
                bgOpacity: 1,
                radius: 24,
                radiusLinked: true,
                padding: 20,
                border: false,
                borderColour: "primary",
                shadow: false,
                accent: "fgPrimaryContainer",
                fg: "fgPrimaryContainer",
                muted: "fgPrimaryContainer"
            },
            extras: {
                glow: false
            }
        },
        {
            id: "pill",
            name: "Pill",
            blurb: "Fully rounded - made for the short, wide elements",
            props: {
                bg: "solid",
                bgColour: "surfaceContainer",
                bgOpacity: 1,
                radius: 999,
                radiusLinked: true,
                padding: 16,
                border: false,
                borderColour: "outlineVariant",
                shadow: false,
                accent: "primary",
                fg: "fgSurface",
                muted: "fgSurfaceVariant"
            },
            extras: {
                glow: false
            }
        },
        {
            id: "bare",
            name: "Bare",
            blurb: "No surface at all - type and graphics straight on the wallpaper",
            props: {
                bg: "none",
                bgColour: "surfaceContainer",
                bgOpacity: 0,
                radius: 0,
                radiusLinked: true,
                padding: 0,
                border: false,
                borderColour: "outlineVariant",
                shadow: false,
                accent: "primary",
                fg: "fgSurface",
                muted: "fgSurfaceVariant"
            },
            // Nothing behind the text, so the contrast shadow earns its place.
            extras: {
                glow: true
            }
        }
    ]

    readonly property var byId: {
        const m = ({});
        for (const p of presets)
            m[p.id] = p;
        return m;
    }

    function get(id: string): var {
        return root.byId[id] ?? root.byId.caelestia;
    }

    // Merges a preset over an existing prop set. `extras` only lands on widgets
    // whose schema declares that key.
    function merge(type: string, props: var, id: string): var {
        const preset = root.get(id);
        const out = Object.assign({}, props ?? ({}));
        for (const [k, v] of Object.entries(preset.props))
            out[k] = v;

        const schema = Registry.schema(type);
        for (const [k, v] of Object.entries(preset.extras ?? ({}))) {
            if (schema.some(s => s.key === k))
                out[k] = v;
        }
        return out;
    }

    function applyTo(ids: var, id: string): int {
        if (!ids || !ids.length)
            return 0;
        Store.pushUndo();
        let n = 0;
        for (const wid of ids) {
            const w = Store.get(wid);
            if (!w || w.locked)
                continue;
            Store.setProps(wid, root.merge(w.type, Store.props(wid), id));
            n++;
        }
        return n;
    }

    function applyToScreen(screen: string, id: string): int {
        const ids = [];
        for (let i = 0; i < Store.widgets.count; i++) {
            const w = Store.widgets.get(i);
            if (w.screen === screen)
                ids.push(w.id);
        }
        return root.applyTo(ids, id);
    }
}
