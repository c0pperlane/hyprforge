import QtQuick
import QtQuick.Effects
import qs.config

// Text in the shell's voice: Google Sans Flex by default, with the variable
// width axis exposed because that's what gives caelestia's clocks their look.
Text {
    id: root

    property real axisWidth: 100
    property bool mono: false
    // Display type uses the separate display family when one is set.
    property bool display: false
    property bool glow: false
    // Crossfade when the text changes - used for now-playing titles and
    // anything else that swaps content while you're looking at it.
    property bool animate: false
    property color glowColour: Theme.light ? Qt.alpha("#ffffff", 0.85) : Qt.alpha("#000000", 0.85)

    // Crisp native rasterisation is only ever better at exactly 1:1; the editor
    // canvas is zoomed and widgets can be rotated, so smooth (distance-field)
    // is the default and `crisp` is the opt-out for small chrome text.
    property bool crisp: false

    antialiasing: true
    // No hintingPreference binding here: writing one more sub-property into the
    // font group from the base type, while derived widgets bind font.pixelSize
    // into the same group, makes Qt report a binding loop. It bought nothing
    // anyway - distance-field rendering ignores hinting, and Qt's default is
    // already the right choice for native rendering.
    font.family: root.mono ? Theme.mono : root.display ? Theme.display : Theme.sans
    font.pixelSize: 15
    font.weight: Font.Medium
    // Only the bundled variable font has wdth/ROND; handing those axes to an
    // arbitrary user-chosen family does nothing at best.
    font.variableAxes: root.mono || !Theme.sansIsVariable ? ({}) : ({
            wdth: root.axisWidth,
            ROND: 100
        })
    color: Theme.fgSurface
    renderType: root.crisp || Settings.appearance.textRendering === "crisp" ? Text.NativeRendering : Text.QtRendering
    textFormat: Text.PlainText
    elide: Text.ElideRight

    // Desktop widgets sit on arbitrary wallpaper; a contrast shadow is the
    // cheap approximation of per-pixel legibility handling.
    layer.enabled: root.glow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.glowColour
        shadowBlur: 0.75
        shadowVerticalOffset: 1
        shadowOpacity: 0.9
    }

    Behavior on color {
        ColorAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: 110
                easing.type: Easing.OutCubic
            }
            PropertyAction {}
            NumberAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }
}
