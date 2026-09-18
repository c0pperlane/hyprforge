import QtQuick
import qs.config

// Linear meter with three looks: a filled bar, discrete segments, or a thin
// rule with a travelling dot.
Item {
    id: root

    property real value: 0
    property string style: "bar"
    property real thickness: 8
    property color colour: Theme.primary
    property color trackColour: Theme.alpha(Theme.fgSurface, 0.13)
    property int segments: 20

    implicitHeight: root.thickness

    property real animated: root.value

    Behavior on animated {
        NumberAnimation {
            duration: 380
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        visible: root.style === "bar"
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness
        radius: height / 2
        color: root.trackColour

        Rectangle {
            width: Math.max(height, parent.width * Math.min(1, Math.max(0, root.animated)))
            height: parent.height
            radius: height / 2
            color: root.colour
        }
    }

    Row {
        visible: root.style === "segments"
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: 3

        Repeater {
            model: root.segments

            Rectangle {
                required property int index

                width: (root.width - (root.segments - 1) * 3) / root.segments
                height: root.thickness
                radius: Math.min(2, height / 2)
                color: index / root.segments < root.animated ? root.colour : root.trackColour

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }
            }
        }
    }

    Item {
        visible: root.style === "line"
        anchors.fill: parent

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Math.max(1, root.thickness / 4)
            radius: height / 2
            color: root.trackColour
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * Math.min(1, Math.max(0, root.animated))
            height: Math.max(1, root.thickness / 4)
            radius: height / 2
            color: root.colour
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.min(parent.width - width, Math.max(0, parent.width * root.animated - width / 2))
            width: root.thickness
            height: root.thickness
            radius: height / 2
            color: root.colour
        }
    }
}
