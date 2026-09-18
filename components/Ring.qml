import QtQuick
import QtQuick.Shapes
import qs.config

// Radial gauge. Shapes gives proper round caps and antialiasing; a Canvas
// repaint per tick would be measurably worse with a dozen rings on screen.
Item {
    id: root

    property real value: 0          // 0-1
    property real thickness: 12
    property color colour: Theme.primary
    property color trackColour: Theme.alpha(Theme.fgSurface, 0.13)
    property bool track: true
    property real startAngle: -90
    property real gapAngle: 0       // degrees left open at the bottom
    property bool rounded: true

    readonly property real sweep: 360 - root.gapAngle
    readonly property real dim: Math.min(width, height)
    readonly property real r: (dim - root.thickness) / 2

    property real animated: root.value

    Behavior on animated {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        ShapePath {
            strokeColor: root.trackColour
            strokeWidth: root.track ? root.thickness : 0
            fillColor: "transparent"
            capStyle: root.rounded ? ShapePath.RoundCap : ShapePath.FlatCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.r
                radiusY: root.r
                startAngle: root.startAngle + root.gapAngle / 2
                sweepAngle: root.track ? root.sweep : 0
            }
        }

        ShapePath {
            strokeColor: root.colour
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: root.rounded ? ShapePath.RoundCap : ShapePath.FlatCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.r
                radiusY: root.r
                startAngle: root.startAngle + root.gapAngle / 2
                // Never fully zero: a zero-length round-capped arc disappears
                // entirely, which reads as "broken" rather than "idle".
                sweepAngle: Math.max(0.6, Math.min(1, root.animated) * root.sweep)
            }
        }
    }
}
