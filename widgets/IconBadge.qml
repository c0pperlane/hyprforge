import QtQuick
import Quickshell
import qs.components
import qs.config

// A single material symbol, optionally in a disc, optionally clickable.
WidgetBase {
    id: root

    interactive: !!root.str("command", "")

    Rectangle {
        anchors.centerIn: parent
        visible: root.flag("disc", false)
        width: Math.min(parent.width, parent.height)
        height: width
        radius: width / 2
        color: area.containsMouse && root.interactive ? Theme.alpha(root.accent, 0.3) : Theme.alpha(root.accent, 0.16)

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    Icon {
        anchors.centerIn: parent
        text: root.str("icon", "favorite")
        size: root.num("size", 42)
        fill: root.num("fill", 0)
        font.weight: root.num("weight", 400)
        color: root.accent
        scale: area.containsPress ? 0.9 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 110
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive && !root.editing
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["sh", "-c", root.str("command", "")])
    }
}
