import QtQuick
import qs.components
import qs.config
import qs.services

// Keep the screen awake. Click to toggle.
WidgetBase {
    id: root

    interactive: true

    readonly property bool on: Inhibit.active
    readonly property color tint: root.on ? root.colour("activeColour", Theme.error) : root.muted

    Rectangle {
        anchors.centerIn: parent
        visible: root.flag("disc", true)
        width: Math.min(parent.width, parent.height)
        height: width
        radius: width / 2
        color: Theme.alpha(root.tint, root.on ? 0.22 : 0.1)

        Behavior on color {
            ColorAnimation {
                duration: 180
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.on ? "coffee" : "bedtime"
            size: root.num("size", 30)
            fill: root.on ? 1 : 0
            color: root.tint

            Behavior on color {
                ColorAnimation {
                    duration: 180
                }
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showLabel", true)
            text: root.on ? "AWAKE" : "IDLE OK"
            font.pixelSize: Math.max(8, root.num("size", 30) * 0.3)
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            color: root.tint
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.editing
        cursorShape: Qt.PointingHandCursor
        onClicked: Inhibit.toggle()
    }
}
