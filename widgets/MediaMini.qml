import QtQuick
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Compact now-playing pill: art, title, one button.
WidgetBase {
    id: root

    interactive: true

    readonly property real artSize: Math.max(20, root.height - root.pad * 2)

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 9

        ClippingRectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.flag("showArt", true)
            // Off the widget, not the Row - see BatteryCard for why.
            width: visible ? root.artSize : 0
            height: root.artSize
            radius: 10
            color: Theme.alpha(root.fg, 0.08)

            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: Settings.appearance.smoothImages
                mipmap: Settings.appearance.mipmaps
                visible: !!Media.art
            }

            Icon {
                anchors.centerIn: parent
                visible: !Media.art
                text: "music_note"
                size: parent.width * 0.45
                color: Theme.alpha(root.fg, 0.4)
            }
        }

        Btn {
            anchors.verticalCenter: parent.verticalCenter
            icon: Media.playing ? "pause" : "play_arrow"
            iconSize: root.num("size", 14) * 1.5
            fill: 1
            colour: root.accent
            hoverColour: root.accent
            enabled: !root.editing
            onClicked: Media.toggle()
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x
            text: Media.hasPlayer ? [Media.title, Media.artist].filter(s => !!s).join(" — ") : "Nothing playing"
            font.pixelSize: root.num("size", 14)
            font.weight: Font.Medium
            color: root.fg
            animate: true
        }
    }
}
