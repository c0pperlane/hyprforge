import QtQuick
import qs.components
import qs.config
import qs.services

// Screen brightness. Scroll to change.
WidgetBase {
    id: root

    interactive: true
    needs: ["brightness"]

    readonly property real level: Backlight.fraction
    readonly property string style: root.str("style", "ring")

    Ring {
        anchors.centerIn: parent
        visible: root.style === "ring"
        width: Math.min(parent.width, parent.height)
        height: width
        value: root.level
        thickness: root.num("thickness", 10)
        colour: root.accent
        trackColour: Theme.alpha(root.accent, 0.16)
    }

    Column {
        anchors.centerIn: parent
        visible: root.style === "ring"
        spacing: -2

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showIcon", true)
            text: root.level < 0.34 ? "brightness_low" : root.level < 0.67 ? "brightness_medium" : "brightness_high"
            size: root.num("size", 22) * 0.85
            fill: 1
            color: root.accent
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Backlight.available ? `${Math.round(root.level * 100)}%` : "—"
            font.pixelSize: root.num("size", 22)
            font.weight: Font.DemiBold
            axisWidth: 80
            color: root.fg
        }
    }

    // --- bar style ----------------------------------------------------------
    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.style === "bar"
        spacing: 10

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.level < 0.34 ? "brightness_low" : root.level < 0.67 ? "brightness_medium" : "brightness_high"
            size: root.num("size", 22)
            fill: 1
            color: root.accent
        }

        Meter {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - root.num("size", 22) - 10 - (root.flag("showValue", true) ? 46 : 0)
            value: root.level
            thickness: root.num("thickness", 10)
            colour: root.accent
            trackColour: Theme.alpha(root.fg, 0.12)
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.flag("showValue", true)
            text: `${Math.round(root.level * 100)}%`
            font.family: Theme.mono
            font.pixelSize: root.num("size", 22) * 0.65
            color: root.muted
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.editing && Backlight.available
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => Backlight.adjust((wheel.angleDelta.y > 0 ? 1 : -1) * root.num("step", 0.05))
    }
}
