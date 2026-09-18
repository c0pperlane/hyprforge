import QtQuick
import QtQuick.Effects
import qs.config

// The background every widget can opt into: none / tonal / solid / glass /
// outline. Kept as one component so the Surface section of the Inspector means
// the same thing on every element.
Item {
    id: root

    property string mode: "none"
    property color colour: Theme.surfaceContainer
    property real fillOpacity: 0.85
    property real radius: 22
    // Per-corner overrides. -1 means "use `radius`", which keeps every existing
    // caller working unchanged.
    property real topLeftRadius: -1
    property real topRightRadius: -1
    property real bottomLeftRadius: -1
    property real bottomRightRadius: -1

    function corner(v: real): real {
        return v < 0 ? root.radius : v;
    }
    property bool border: false
    property color borderColour: Theme.outlineVariant
    property bool shadow: false

    readonly property bool hasFill: root.mode !== "none"

    Rectangle {
        id: fill

        anchors.fill: parent
        radius: root.radius
        topLeftRadius: root.corner(root.topLeftRadius)
        topRightRadius: root.corner(root.topRightRadius)
        bottomLeftRadius: root.corner(root.bottomLeftRadius)
        bottomRightRadius: root.corner(root.bottomRightRadius)
        visible: root.mode !== "none"

        color: {
            if (root.mode === "solid")
                return root.colour;
            if (root.mode === "outline")
                return Theme.alpha(root.colour, root.fillOpacity * 0.12);
            if (root.mode === "glass")
                return Theme.alpha(root.colour, root.fillOpacity * 0.45);
            return Theme.alpha(root.colour, root.fillOpacity);
        }

        border.width: root.border || root.mode === "outline" || root.mode === "glass" ? 1 : 0
        border.color: root.mode === "glass" ? Theme.alpha(Theme.fgSurface, 0.14) : Theme.alpha(root.borderColour, root.mode === "outline" ? 0.9 : 0.6)

        // A top-edge highlight is what actually sells "glass" without a real
        // backdrop blur, which layer-shell surfaces can't do on their own.
        Rectangle {
            visible: root.mode === "glass"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: parent.radius * 0.5
            height: 1
            radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 0.5
                    color: Theme.alpha(Theme.fgSurface, 0.22)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
        }

        layer.enabled: root.shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.alpha("#000000", 0.45)
            shadowBlur: 0.9
            shadowVerticalOffset: 6
            shadowScale: 1
        }

        Behavior on color {
            ColorAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }
}
