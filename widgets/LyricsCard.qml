pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

// Synced lyrics.
//
// Named LyricsCard, not Lyrics: a component called Lyrics in this module would
// shadow the Caelestia.Services singleton of that name for every other widget
// in the directory.
//
// Three layouts and a configurable idea of "empty", because a lyrics widget
// spends a lot of its life with nothing to show and what it should do then is
// entirely a matter of taste - vanish, say so quietly, or hold its place.
WidgetBase {
    id: root

    needs: ["lyrics", "media.position"]

    interactive: root.flag("clickToSeek", true)

    readonly property string mode: root.str("mode", "scroll")
    readonly property string whenEmpty: root.str("whenEmpty", "message")
    readonly property string state: LyricsSvc.state
    readonly property bool empty: root.state !== "playing"

    readonly property string emptyText: {
        switch (root.state) {
        case "loading":
            return root.str("loadingText", "Looking for lyrics…");
        case "none":
            return root.str("noLyricsText", "No lyrics");
        case "unavailable":
            return "Lyrics need caelestia-shell";
        case "idle":
            return root.str("idleText", "Nothing playing");
        default:
            return "";
        }
    }

    readonly property int hAlign: {
        const a = root.str("align", "left");
        return a === "center" ? Text.AlignHCenter : a === "right" ? Text.AlignRight : Text.AlignLeft;
    }

    // "hide" really does mean invisible - but never in the editor, where an
    // element you cannot see is an element you cannot select or move.
    opacity: root.empty && root.whenEmpty === "hide" && !root.editing ? 0 : 1
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    // --- track header -------------------------------------------------------
    //
    // The label lives inside a container that collapses to zero height when
    // hidden. Setting `height: visible ? implicitHeight : 0` directly on a Text
    // makes Qt report a binding loop, because the height it is being given is
    // derived from the height it works out for itself.
    Item {
        id: header

        readonly property bool shown: root.flag("showTrack", false) && LyricsSvc.hasPlayer

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: header.shown ? label.implicitHeight : 0
        visible: header.shown

        Txt {
            id: label

            anchors.left: parent.left
            anchors.right: parent.right
            horizontalAlignment: root.hAlign
            text: [LyricsSvc.trackArtist, LyricsSvc.trackTitle].filter(s => !!s).join("  ·  ")
            font.pixelSize: Math.max(9, root.num("size", 18) * 0.62)
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            color: root.muted
            elide: Text.ElideRight
        }
    }

    Item {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: header.visible ? 8 : 0
        anchors.bottom: parent.bottom

        // --- empty states ---------------------------------------------------
        Item {
            anchors.fill: parent
            visible: root.empty && root.whenEmpty !== "hide"

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 6

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.whenEmpty === "icon" || root.flag("emptyIcon", true)
                    text: root.state === "loading" ? "hourglass" : root.state === "idle" ? "music_off" : root.state === "unavailable" ? "extension_off" : "lyrics"
                    size: root.num("size", 18) * 1.3
                    color: Theme.alpha(root.muted, 0.7)

                    RotationAnimation on rotation {
                        running: root.state === "loading" && root.visible
                        from: 0
                        to: 360
                        duration: 1600
                        loops: Animation.Infinite
                    }
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.whenEmpty === "message"
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.emptyText
                    font.pixelSize: Math.max(10, root.num("size", 18) * 0.8)
                    color: root.muted
                    wrapMode: Text.Wrap
                    glow: root.flag("glow", false)
                }
            }
        }

        // --- one line, centred ----------------------------------------------
        Txt {
            anchors.fill: parent
            visible: !root.empty && root.mode === "current"
            horizontalAlignment: root.hAlign
            verticalAlignment: Text.AlignVCenter
            text: LyricsSvc.lines[LyricsSvc.index] ?? ""
            font.pixelSize: root.num("size", 18)
            font.weight: Font.DemiBold
            color: root.colour("highlight", root.accent)
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            animate: true
            glow: root.flag("glow", false)
        }

        // --- previous / current / next ---------------------------------------
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.empty && root.mode === "three"
            spacing: root.num("size", 18) * 0.35

            Repeater {
                model: [-1, 0, 1]

                Txt {
                    required property int modelData

                    readonly property int line: LyricsSvc.index + modelData

                    width: parent.width
                    horizontalAlignment: root.hAlign
                    text: (LyricsSvc.lines[line] ?? "").trim()
                    font.pixelSize: root.num("size", 18) * (modelData === 0 ? 1 : 0.82)
                    font.weight: modelData === 0 ? Font.DemiBold : Font.Normal
                    color: modelData === 0 ? root.colour("highlight", root.accent) : Theme.alpha(root.fg, root.num("dim", 0.45))
                    elide: Text.ElideRight
                    glow: root.flag("glow", false)

                    Behavior on color {
                        ColorAnimation {
                            duration: 220
                        }
                    }
                }
            }
        }

        // --- scrolling list ---------------------------------------------------
        ListView {
            id: list

            anchors.fill: parent
            visible: !root.empty && root.mode === "scroll"
            clip: true
            interactive: false
            model: LyricsSvc.lines
            spacing: root.num("size", 18) * 0.42

            currentIndex: LyricsSvc.index

            // Keeps the current line parked in the middle of the widget and
            // lets the ListView animate the travel, rather than recentring in
            // a jump on every line change.
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: height / 2 - root.num("size", 18)
            preferredHighlightEnd: height / 2 + root.num("size", 18)
            highlightMoveDuration: 380
            highlightMoveVelocity: -1

            onModelChanged: Qt.callLater(() => list.positionViewAtIndex(list.currentIndex, ListView.Center))

            // ListTxt, not Txt: no Behaviors, so no property interceptors on an
            // object this view destroys and recreates on every track change.
            delegate: ListTxt {
                required property string modelData
                required property int index

                readonly property bool current: index === LyricsSvc.index

                width: list.width
                horizontalAlignment: root.hAlign
                text: modelData.trim() || "\u266a"
                font.pixelSize: root.num("size", 18) * (current ? 1 : 0.94)
                font.weight: current ? Font.DemiBold : Font.Normal
                color: current ? root.colour("highlight", root.accent) : Theme.alpha(root.fg, root.num("dim", 0.45))
                wrapMode: Text.Wrap

                MouseArea {
                    anchors.fill: parent
                    enabled: root.flag("clickToSeek", true) && !root.editing
                    cursorShape: Qt.PointingHandCursor
                    onClicked: LyricsSvc.seekToLine(parent.index)
                }
            }
        }

        // Fades the top and bottom edges so lines arrive and leave rather than
        // being chopped off at the boundary.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.num("size", 18) * 1.6
            visible: root.flag("fade", true) && root.mode === "scroll" && !root.empty && (root.p.bg ?? "none") !== "none"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Theme.resolve(root.p.bgColour, Theme.surfaceContainer)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.num("size", 18) * 1.6
            visible: root.flag("fade", true) && root.mode === "scroll" && !root.empty && (root.p.bg ?? "none") !== "none"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: Theme.resolve(root.p.bgColour, Theme.surfaceContainer)
                }
            }
        }
    }
}
