pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Editor + layer preferences, persisted to ~/.config/caelestia/forge/settings.json.
// Everything the floating Canvas panel exposes lives here; the file is watched so
// hand-edits apply live too.
Singleton {
    id: root

    readonly property alias fonts: adapter.fonts
    readonly property alias appearance: adapter.appearance
    readonly property alias style: adapter.style
    readonly property alias grid: adapter.grid
    readonly property alias snap: adapter.snap
    readonly property alias editor: adapter.editor
    readonly property alias layer: adapter.layer

    function save(): void {
        view.writeAdapter();
    }

    FileView {
        id: view

        path: `${Theme.configPath}/settings.json`
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        // No file yet on a fresh install - write the defaults out so the user
        // has something to hand-edit, instead of silently running on defaults.
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            // Font choices. Blank means "use Forge's bundled default" - the
            // same Google Sans Flex the shell ships. Written here by the
            // Typography panel and by `caelestia-forge-fonts`, which is also
            // what pushes the same choice out to the shell, fontconfig, GTK
            // and Discord.
            property JsonObject fonts: JsonObject {
                property string sans: ""
                property string mono: ""
                property string display: ""
                property int size: 11
                property bool force: false
                property string targets: "forge,shell,fontconfig,gtk,discord"
            }

            property JsonObject appearance: JsonObject {
                // "smooth" uses Qt's distance-field text renderer: shapes stay
                // clean at any size, under the editor's canvas zoom, and on
                // rotated widgets. "crisp" is native rasterisation - sharper
                // for small text at exactly 1:1, but it visibly breaks up as
                // soon as anything is scaled.
                property string textRendering: "smooth"
                // Mipmaps for downscaled images (album art, wallpaper): without
                // them, a large picture shrunk into a small widget aliases into
                // a sparkly mess.
                property bool mipmaps: true
                property bool smoothImages: true
            }

            property JsonObject style: JsonObject {
                // Preset applied to newly placed elements; see config/Presets.qml.
                property string preset: "caelestia"
                property bool applyToNew: true
            }

            property JsonObject grid: JsonObject {
                property int size: 32           // base cell, px
                property int subdivisions: 2    // minor lines per cell
                property bool visible: true
                property real opacity: 0.4
                property bool dots: false       // dot grid instead of lines
            }

            property JsonObject snap: JsonObject {
                property bool enabled: true
                property bool toGrid: true
                property bool toEdges: true     // screen edges + safe margins
                property bool toWidgets: true   // sibling alignment guides
                property bool toSizes: true     // match a sibling's width/height
                // Spacing snapping: land on a gap the layout already uses, or
                // halfway between two neighbours, rather than only on their
                // edges. What makes a stack evenly padded without measuring.
                property bool toSpacing: true
                property int maxGap: 400        // gaps wider than this are not
                                                // a rhythm, they are a gap
                // Cell mode: position and size always land on whole grid cells,
                // with no magnet threshold - the grid stops being a hint and
                // becomes the layout.
                property bool cells: false
                property int gap: 0             // gutter left inside each cell
                property int threshold: 10      // px magnet distance
                property int margin: 26         // safe-area inset for edge snap
                property bool showGuides: true
            }

            property JsonObject editor: JsonObject {
                property real dim: 0.72         // scrim over the live desktop
                property bool blur: true
                property bool showWallpaper: true
                property bool emptyDesktop: true // hide windows behind the canvas
                property bool showRulers: true
                property bool showSafeArea: true
                property bool animatePlacement: true
            }

            property JsonObject layer: JsonObject {
                property bool enabled: true
                property bool hideWhenCovered: true // fade out when a window tiles over
                property real inactiveOpacity: 0
                property bool shadows: true
            }
        }
    }
}
