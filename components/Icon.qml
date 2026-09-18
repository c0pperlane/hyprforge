import QtQuick
import qs.config

// Material Symbols Rounded, with the FILL/GRAD/opsz axes wired up.
Text {
    id: root

    property real fill: 0
    property real size: 20
    property int grade: Theme.light ? 0 : -25

    font.family: Theme.icons
    font.pixelSize: root.size
    font.weight: Font.Normal
    font.variableAxes: ({
            FILL: root.fill,
            GRAD: root.grade,
            opsz: root.size
        })
    color: Theme.fgSurface
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    antialiasing: true
    renderType: Settings.appearance.textRendering === "crisp" ? Text.NativeRendering : Text.QtRendering

    Behavior on fill {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 200
        }
    }
}
