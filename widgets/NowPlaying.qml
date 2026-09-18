import QtQuick
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Album art, metadata, a draggable scrubber and transport controls.
// `interactive` makes the live desktop layer punch an input hole for exactly
// this widget's rectangle, so the buttons work without the rest of the layer
// swallowing clicks.
WidgetBase {
    id: root

    needs: root.flag("progress", true) ? ["media.position"] : []

    interactive: true

    readonly property real artSize: Math.min(height - pad * 2, 110)
    readonly property string artStyle: root.str("art", "rounded")

    Item {
        id: art

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.artStyle !== "none"
        width: visible ? root.artSize : 0
        height: root.artSize

        ClippingRectangle {
            anchors.fill: parent
            radius: root.artStyle === "circle" ? width / 2 : root.artStyle === "blob" ? width * 0.34 : 16
            color: Theme.alpha(root.fg, 0.08)

            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: Settings.appearance.smoothImages
                mipmap: Settings.appearance.mipmaps
                cache: true
                visible: Media.art.length > 0
            }

            Icon {
                anchors.centerIn: parent
                visible: !Media.art
                text: "music_note"
                size: parent.width * 0.4
                color: Theme.alpha(root.fg, 0.4)
            }
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: root.artStyle === "none" ? 0 : 14
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Txt {
            width: parent.width
            text: Media.hasPlayer ? (Media.title || "Unknown track") : root.str("idleText", "Nothing playing")
            font.pixelSize: root.num("titleSize", 18)
            font.weight: Font.DemiBold
            color: root.fg
            animate: true
        }

        Txt {
            width: parent.width
            visible: Media.hasPlayer
            text: [Media.artist, Media.album].filter(s => !!s).join("  ·  ")
            font.pixelSize: Math.max(10, root.num("titleSize", 18) * 0.68)
            color: root.muted
        }

        Item {
            width: parent.width
            height: root.flag("progress", true) && Media.hasPlayer ? 22 : 6
            visible: height > 6

            Txt {
                id: elapsed

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Media.time(Media.position)
                font.family: Theme.mono
                font.pixelSize: 10
                color: root.muted
            }

            Txt {
                id: total

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Media.time(Media.length)
                font.family: Theme.mono
                font.pixelSize: 10
                color: root.muted
            }

            Item {
                anchors.left: elapsed.right
                anchors.right: total.left
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 14

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.alpha(root.fg, 0.16)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Media.progress
                    height: 4
                    radius: 2
                    color: root.accent
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(parent.width - width, Math.max(0, parent.width * Media.progress - width / 2))
                    width: 10
                    height: 10
                    radius: 5
                    color: root.accent
                    visible: !root.editing
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    enabled: !root.editing
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => Media.seekFraction(Math.min(1, Math.max(0, (mouse.x + 5) / width)))
                }
            }
        }

        Row {
            visible: root.flag("controls", true)
            spacing: 2

            Btn {
                icon: "skip_previous"
                iconSize: root.num("titleSize", 18) * 1.1
                fill: 1
                colour: root.fg
                hoverColour: root.accent
                enabled: !root.editing
                onClicked: Media.previous()
            }

            Btn {
                icon: Media.playing ? "pause" : "play_arrow"
                iconSize: root.num("titleSize", 18) * 1.35
                fill: 1
                colour: root.accent
                hoverColour: root.accent
                enabled: !root.editing
                onClicked: Media.toggle()
            }

            Btn {
                icon: "skip_next"
                iconSize: root.num("titleSize", 18) * 1.1
                fill: 1
                colour: root.fg
                hoverColour: root.accent
                enabled: !root.editing
                onClicked: Media.next()
            }
        }
    }
}
