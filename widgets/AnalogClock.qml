import QtQuick
import QtQuick.Shapes
import qs.components
import qs.config
import qs.services

// Swiss-railway-ish face. The second hand sweeps by animating a continuous
// angle rather than stepping, which reads far better at 240Hz.
WidgetBase {
    id: root

    // The sweeping second hand is the only reason this needs a
    // one-second clock; nothing else here does.
    needs: ["clock.seconds"]

    readonly property real dim: Math.min(width - pad * 2, height - pad * 2)
    readonly property real r: dim / 2
    readonly property real thick: root.num("thickness", 4)

    readonly property real secondAngle: {
        // Clock.seconds is itself the dependency; no discarded read needed.
        return (Clock.seconds / 60) * 360;
    }
    readonly property real minuteAngle: (Clock.minutes + Clock.seconds / 60) / 60 * 360
    readonly property real hourAngle: ((Clock.hours % 12) + Clock.minutes / 60) / 12 * 360

    Item {
        id: face

        anchors.centerIn: parent
        width: root.dim
        height: root.dim

        Rectangle {
            visible: root.flag("face", true)
            anchors.fill: parent
            radius: width / 2
            color: Theme.alpha(root.colour("bgColour", Theme.surfaceContainer), root.num("bgOpacity", 0.85) * 0.6)
            border.width: 1
            border.color: Theme.alpha(root.fg, 0.1)
        }

        // Tick marks
        Repeater {
            model: {
                const t = root.str("ticks", "hours");
                return t === "none" ? 0 : t === "quarters" ? 4 : t === "hours" ? 12 : 60;
            }

            Rectangle {
                required property int index

                readonly property int step: root.str("ticks", "hours") === "minutes" ? 60 : root.str("ticks", "hours") === "quarters" ? 4 : 12
                readonly property bool major: step === 60 ? index % 5 === 0 : true

                width: major ? Math.max(2, root.thick * 0.55) : 1
                height: major ? root.r * 0.1 : root.r * 0.05
                radius: width / 2
                color: Theme.alpha(root.fg, major ? 0.55 : 0.28)
                x: face.width / 2 - width / 2
                y: root.r * 0.07
                transform: Rotation {
                    origin.x: width / 2
                    origin.y: root.r - root.r * 0.07
                    angle: index * (360 / step)
                }
            }
        }

        Repeater {
            model: root.flag("numerals", false) ? 12 : 0

            Txt {
                required property int index

                readonly property real a: (index * 30 - 90) * Math.PI / 180

                text: `${index === 0 ? 12 : index}`
                font.pixelSize: root.r * 0.17
                font.weight: Font.DemiBold
                color: Theme.alpha(root.fg, 0.7)
                x: face.width / 2 + Math.cos(a) * root.r * 0.78 - width / 2
                y: face.height / 2 + Math.sin(a) * root.r * 0.78 - height / 2
            }
        }

        // Hands
        Hand {
            length: root.r * 0.52
            thickness: root.thick * 1.15
            colour: root.fg
            angle: root.hourAngle
        }

        Hand {
            length: root.r * 0.76
            thickness: root.thick * 0.85
            colour: root.fg
            angle: root.minuteAngle
        }

        Hand {
            id: secondHand

            length: root.r * 0.84
            thickness: Math.max(1.2, root.thick * 0.35)
            colour: root.accent
            tail: root.r * 0.18
            angle: root.secondAngle

            Behavior on angle {
                enabled: root.flag("sweep", true) && secondHand.angle > 0
                NumberAnimation {
                    duration: 850
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.thick * 1.9
            height: width
            radius: width / 2
            color: root.accent
        }
    }

    component Hand: Item {
        id: hand

        property real length: 10
        property real thickness: 3
        property real tail: 0
        property color colour: "white"
        property real angle: 0

        // Sized to twice the hand length and centred, so the rotation origin
        // is simply the item's centre - i.e. the middle of the face.
        anchors.centerIn: parent
        width: hand.thickness
        height: hand.length * 2

        transform: Rotation {
            origin.x: hand.width / 2
            origin.y: hand.height / 2
            angle: hand.angle
        }

        Rectangle {
            y: 0
            width: parent.width
            height: hand.length + hand.tail
            radius: width / 2
            color: hand.colour
        }
    }
}
