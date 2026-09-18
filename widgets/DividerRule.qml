import QtQuick
import qs.components
import qs.config

// A line.
WidgetBase {
    id: root

    readonly property bool vertical: root.str("orientation", "horizontal") === "vertical"
    readonly property real weight: root.num("thickness", 2)

    Item {
        anchors.centerIn: parent
        width: root.vertical ? root.weight : parent.width
        height: root.vertical ? parent.height : root.weight

        Rectangle {
            anchors.fill: parent
            visible: root.str("style", "solid") !== "dotted"
            radius: root.flag("cap", true) ? Math.min(width, height) / 2 : 0
            color: root.str("style", "solid") === "solid" ? root.accent : "transparent"

            gradient: root.str("style", "solid") === "fade" ? fadeGradient : null
        }

        Row {
            visible: root.str("style", "solid") === "dotted" && !root.vertical
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.weight * 1.8

            Repeater {
                model: Math.max(1, Math.floor(root.width / (root.weight * 2.8)))

                Rectangle {
                    width: root.weight
                    height: root.weight
                    radius: root.weight / 2
                    color: root.accent
                }
            }
        }

        Column {
            visible: root.str("style", "solid") === "dotted" && root.vertical
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.weight * 1.8

            Repeater {
                model: Math.max(1, Math.floor(root.height / (root.weight * 2.8)))

                Rectangle {
                    width: root.weight
                    height: root.weight
                    radius: root.weight / 2
                    color: root.accent
                }
            }
        }
    }

    Gradient {
        id: fadeGradient

        orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal

        GradientStop {
            position: 0
            color: "transparent"
        }
        GradientStop {
            position: 0.5
            color: root.accent
        }
        GradientStop {
            position: 1
            color: "transparent"
        }
    }
}
