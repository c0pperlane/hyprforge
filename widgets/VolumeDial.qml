import QtQuick
import qs.components
import qs.config
import qs.services

// Output volume. Scroll to change, click to mute.
WidgetBase {
    id: root

    interactive: true
    needs: ["volume"]

    readonly property real level: Volume.volume
    readonly property bool muted: Volume.muted
    readonly property color tint: root.muted ? root.muted_ : root.accent
    readonly property color muted_: Theme.alpha(root.fg, 0.35)

    Ring {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        // Over 100% is possible on Pipewire; show it as a full ring rather than
        // letting the arc wrap past the start and read as near-silent.
        value: Math.min(1, root.level)
        thickness: root.num("thickness", 10)
        colour: root.level > 1 ? Theme.error : root.tint
        trackColour: Theme.alpha(root.tint, 0.16)
    }

    Column {
        anchors.centerIn: parent
        spacing: -2

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showIcon", true)
            text: root.muted ? "volume_off" : root.level < 0.01 ? "volume_mute" : root.level < 0.5 ? "volume_down" : "volume_up"
            size: root.num("size", 22) * 0.85
            fill: 1
            color: root.tint
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.muted ? "muted" : `${Math.round(root.level * 100)}%`
            font.pixelSize: root.num("size", 22)
            font.weight: Font.DemiBold
            axisWidth: 80
            color: root.fg
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showDevice", false)
            width: root.width - root.pad * 2
            horizontalAlignment: Text.AlignHCenter
            text: Volume.sinkName
            font.pixelSize: Math.max(8, root.num("size", 22) * 0.4)
            color: root.muted_
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.editing
        cursorShape: Qt.PointingHandCursor
        onClicked: Volume.toggleMute()
        onWheel: wheel => Volume.adjust((wheel.angleDelta.y > 0 ? 1 : -1) * root.num("step", 0.05))
    }
}
