import QtQuick
import qs.components
import qs.config
import qs.services

// The usable rectangle, drawn on the artboard. (Named UsableArea, not
// SafeArea: Qt has its own SafeArea attached property for mobile insets, and
// declaring a component by that name shadows it.)
// the screen minus whatever
// caelestia's bar and border have reserved, minus your own extra margin.
// Corner brackets rather than a full frame, so it reads as a guide instead of
// competing with the widgets sitting inside it.
Item {
    id: root

    required property string screenName
    property real zoom: 1
    property real extraMargin: 0
    property bool showLabels: true

    readonly property var reserved: Outputs.reservedFor(root.screenName)
    readonly property real insetLeft: reserved.left + root.extraMargin
    readonly property real insetTop: reserved.top + root.extraMargin
    readonly property real insetRight: reserved.right + root.extraMargin
    readonly property real insetBottom: reserved.bottom + root.extraMargin

    // Geometry of the usable area, in design coordinates. Anything that wants
    // to align to "the screen" should align to this, not to 0,0.
    readonly property rect usable: Qt.rect(root.insetLeft, root.insetTop, Math.max(0, root.width - root.insetLeft - root.insetRight), Math.max(0, root.height - root.insetTop - root.insetBottom))

    // Chrome drawn at a constant on-screen size whatever the canvas zoom is.
    readonly property real px: 1 / Math.max(0.08, root.zoom)
    readonly property color tint: reserved.known ? Theme.tertiary : Theme.error

    Item {
        id: area

        x: root.usable.x
        y: root.usable.y
        width: root.usable.width
        height: root.usable.height

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: root.px
            border.color: Theme.alpha(root.tint, 0.28)
        }

        // Corner brackets
        Repeater {
            model: [
                {
                    ax: 0,
                    ay: 0,
                    sx: 1,
                    sy: 1
                },
                {
                    ax: 1,
                    ay: 0,
                    sx: -1,
                    sy: 1
                },
                {
                    ax: 1,
                    ay: 1,
                    sx: -1,
                    sy: -1
                },
                {
                    ax: 0,
                    ay: 1,
                    sx: 1,
                    sy: -1
                }
            ]

            Item {
                required property var modelData

                readonly property real arm: 34 * root.px
                readonly property real weight: 2.5 * root.px

                x: area.width * modelData.ax
                y: area.height * modelData.ay

                Rectangle {
                    x: parent.modelData.sx > 0 ? 0 : -parent.arm
                    y: parent.modelData.sy > 0 ? 0 : -parent.weight
                    width: parent.arm
                    height: parent.weight
                    radius: height / 2
                    color: root.tint
                }

                Rectangle {
                    x: parent.modelData.sx > 0 ? 0 : -parent.weight
                    y: parent.modelData.sy > 0 ? 0 : -parent.arm
                    width: parent.weight
                    height: parent.arm
                    radius: width / 2
                    color: root.tint
                }
            }
        }
    }

    // Hatched bands over the space the bar and border have taken, so it is
    // obvious *why* the usable area is not the whole screen.
    Repeater {
        model: [
            {
                x: 0,
                y: 0,
                w: root.reserved.left,
                h: root.height
            },
            {
                x: root.width - root.reserved.right,
                y: 0,
                w: root.reserved.right,
                h: root.height
            },
            {
                x: 0,
                y: 0,
                w: root.width,
                h: root.reserved.top
            },
            {
                x: 0,
                y: root.height - root.reserved.bottom,
                w: root.width,
                h: root.reserved.bottom
            }
        ]

        Rectangle {
            required property var modelData

            x: modelData.x
            y: modelData.y
            width: modelData.w
            height: modelData.h
            visible: modelData.w > 0 && modelData.h > 0
            color: Theme.alpha(root.tint, 0.1)
        }
    }

    // Inset readouts, one per side that actually reserves anything.
    Repeater {
        model: root.showLabels ? [
            {
                v: root.reserved.left,
                x: root.reserved.left / 2,
                y: root.height / 2,
                label: "bar"
            },
            {
                v: root.reserved.top,
                x: root.width / 2,
                y: root.reserved.top / 2,
                label: ""
            },
            {
                v: root.reserved.right,
                x: root.width - root.reserved.right / 2,
                y: root.height / 2,
                label: ""
            },
            {
                v: root.reserved.bottom,
                x: root.width / 2,
                y: root.height - root.reserved.bottom / 2,
                label: ""
            }
        ] : []

        Rectangle {
            required property var modelData

            visible: modelData.v > 0
            x: modelData.x - width / 2
            y: modelData.y - height / 2
            width: insetLabel.implicitWidth + 12 * root.px
            height: 18 * root.px
            radius: 5 * root.px
            color: Theme.alpha(Theme.surfaceContainerHighest, 0.92)

            Txt {
                id: insetLabel

                anchors.centerIn: parent
                text: modelData.label ? `${modelData.label} ${modelData.v}` : `${modelData.v}`
                font.family: Theme.mono
                font.pixelSize: 10 * root.px
                color: root.tint
            }
        }
    }

    // Says so out loud when Hyprland hasn't told us anything, rather than
    // quietly drawing a full-screen rectangle that looks like a valid answer.
    Rectangle {
        visible: !root.reserved.known
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 40 * root.px
        width: unknownLabel.implicitWidth + 20 * root.px
        height: 24 * root.px
        radius: 8 * root.px
        color: Theme.alpha(Theme.error, 0.2)

        Txt {
            id: unknownLabel

            anchors.centerIn: parent
            text: "no reserved area reported for this output"
            font.pixelSize: 11 * root.px
            color: Theme.error
        }
    }
}
