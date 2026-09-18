pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live Material 3 palette + type scale for Forge.
//
// Forge runs as its own Quickshell config (`qs -c caelestia-forge`), so it
// cannot import the shell's `qs.services.Colours` singleton - that lives in a
// different config root. Instead we read the same source of truth the shell's
// Colours service reads: ~/.local/state/caelestia/scheme.json, rewritten by
// `caelestia scheme set`. Watching the file means Forge restyles itself the
// moment the wallpaper/scheme changes, exactly like the bar does.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string statePath: `${Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`}/caelestia`
    readonly property string configPath: `${Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`}/caelestia/forge`

    property string schemeName: "dynamic"
    property string flavour: "default"
    property bool light: false

    // --- Material 3 roles -------------------------------------------------
    property color background: "#0d0f0a"
    property color fgBackground: "#e3e7d8"
    property color surface: "#0d0f0a"
    property color surfaceDim: "#0d0f0a"
    property color surfaceBright: "#292e23"
    property color surfaceContainerLowest: "#000000"
    property color surfaceContainerLow: "#11140e"
    property color surfaceContainer: "#171b13"
    property color surfaceContainerHigh: "#1d2118"
    property color surfaceContainerHighest: "#23271d"
    property color fgSurface: "#e3e7d8"
    property color surfaceVariant: "#23271d"
    property color fgSurfaceVariant: "#a8ad9f"
    property color outline: "#72776a"
    property color outlineVariant: "#454a3e"
    property color inverseSurface: "#f9faf1"
    property color inverseOnSurface: "#54564f"
    property color shadow: "#000000"
    property color scrim: "#000000"
    property color primary: "#b6ce9e"
    property color fgPrimary: "#324621"
    property color primaryContainer: "#445832"
    property color fgPrimaryContainer: "#d3ebb9"
    property color secondary: "#bfcbae"
    property color fgSecondary: "#2b3421"
    property color secondaryContainer: "#414b36"
    property color fgSecondaryContainer: "#dbe7c9"
    property color tertiary: "#a0d0c9"
    property color fgTertiary: "#023733"
    property color tertiaryContainer: "#204e49"
    property color fgTertiaryContainer: "#bcece5"
    property color error: "#ffb4ab"
    property color fgError: "#690005"
    property color errorContainer: "#93000a"
    property color fgErrorContainer: "#ffdad6"
    property color success: "#a6d388"

    // Material 3 has no warning role, so this is the amber already carried as
    // the fourth chart accent: the one tone that reads as "working hard"
    // against every caelestia scheme without being mistaken for the error red.
    property color warning: "#e9b872"

    // Accent ramp used by charts/rings so multi-series widgets stay coherent.
    readonly property list<color> chart: [primary, tertiary, secondary, "#e9b872", error, "#8ab4f8"]

    // --- Shape ------------------------------------------------------------
    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int xs: 6
        readonly property int sm: 10
        readonly property int md: 16
        readonly property int lg: 22
        readonly property int xl: 28
        readonly property int full: 9999
    }

    readonly property QtObject space: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 18
        readonly property int xl: 26
    }

    // --- Type -------------------------------------------------------------
    // The bundled variable font is the fallback for everything; a blank choice
    // in settings means "use it".
    readonly property string bundledSans: gsf.status === FontLoader.Ready ? gsf.name : "Rubik"
    readonly property string sans: Settings.fonts.sans || root.bundledSans
    readonly property string mono: Settings.fonts.mono || "JetBrainsMono Nerd Font"
    // Display type (clocks, headings) can differ from body text.
    readonly property string display: Settings.fonts.display || root.sans
    // Never user-overridable: swap this and the whole icon set turns to tofu.
    readonly property string icons: "Material Symbols Rounded"

    // Variable-axis tricks (the narrow clock look) only work on the bundled
    // font; widgets check this before leaning on wdth.
    readonly property bool sansIsVariable: root.sans === root.bundledSans

    // Google Sans Flex is a variable font: wdth/wght/GRAD/ROND/opsz/slnt.
    // `flex()` builds a font with the variable axes set, which is how the
    // shell gets its tall narrow clock look - a real axis, not a transform.
    function flex(size: real, weight: int, width: real): font {
        return Qt.font({
            family: root.sans,
            pixelSize: size,
            weight: weight,
            variableAxes: {
                wdth: width,
                ROND: 100
            }
        });
    }

    function icon(size: real, fill: real, weight: int): font {
        return Qt.font({
            family: root.icons,
            pixelSize: size,
            weight: weight ?? 400,
            variableAxes: {
                FILL: fill ?? 0,
                GRAD: root.light ? 0 : -25,
                opsz: size
            }
        });
    }

    // Colour props store either a palette role name ("primary") or a literal
    // "#rrggbb", so a saved layout follows the wallpaper scheme by default but
    // can still be pinned to an exact colour.
    readonly property list<string> roles: ["primary", "fgPrimary", "primaryContainer", "fgPrimaryContainer", "secondary", "secondaryContainer", "tertiary", "tertiaryContainer", "fgSurface", "fgSurfaceVariant", "surface", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "outline", "outlineVariant", "error", "success", "background"]

    function resolve(spec: string, fallback: color): color {
        if (!spec)
            return fallback;
        if (spec.charAt(0) === "#")
            return spec;
        return root.hasOwnProperty(spec) ? root[spec] : fallback;
    }

    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function mix(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    // Readable foreground for an arbitrary background.
    function contrast(c: color): color {
        return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.5 ? "#101010" : "#f5f5f5";
    }

    function load(data: string): void {
        try {
            const s = JSON.parse(data);
            root.schemeName = s.name ?? "dynamic";
            root.flavour = s.flavour ?? "default";
            root.light = s.mode === "light";
            for (const [name, colour] of Object.entries(s.colours ?? {})) {
                if (name.startsWith("term"))
                    continue;
                // scheme.json uses M3's "fgPrimary" spelling; QML can't hold a
                // property called onX next to one called X (it parses as a
                // signal handler), so those land on fgX instead.
                const prop = /^on[A-Z]/.test(name) ? `fg${name.slice(2)}` : name;
                if (root.hasOwnProperty(prop))
                    root[prop] = `#${colour}`;
            }
        } catch (e) {
            console.warn("Forge: could not parse scheme.json:", e);
        }
    }

    FontLoader {
        id: gsf

        source: Quickshell.shellPath("assets/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }

    FileView {
        path: `${root.statePath}/scheme.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.load(text())
    }
}
