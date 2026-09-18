import QtQuick
import qs.components
import qs.config

// A grouping surface to sit other widgets on. Put it behind a cluster and send
// it to the back; everything else reads as one panel.
WidgetBase {
    id: root

    // The gradient sits on top of WidgetBase's own Surface, picking up its
    // radius so the corners stay clean.
    Rectangle {
        anchors.fill: parent
        visible: root.flag("gradient", true) && (root.p.bg ?? "none") !== "none"
        radius: root.num("radius", 22)
        opacity: 0.5

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: Theme.alpha(root.colour("gradientTo", Theme.surfaceContainerLowest), 0.85)
            }
        }
    }

    Txt {
        visible: !!root.str("title", "")
        anchors.left: parent.left
        anchors.top: parent.top
        text: root.str("title", "").toUpperCase()
        font.pixelSize: root.num("titleSize", 13)
        font.weight: Font.Bold
        font.letterSpacing: 1.6
        color: root.muted
    }
}
