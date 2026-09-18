import QtQuick
import qs.components
import qs.config

// Slider with an editable numeric readout - dragging is fine for exploring,
// typing is what you want when you know the number you need.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real step: 1
    property bool integer: step >= 1

    // `begin` fires once when a drag starts, which is where the caller should
    // push its undo entry - pushing per moved() would flood the stack.
    signal begin
    signal moved(real value)
    signal committed(real value)

    implicitHeight: 30

    readonly property real span: Math.max(0.0001, root.to - root.from)
    readonly property real fraction: Math.min(1, Math.max(0, (root.value - root.from) / root.span))

    function quantise(v: real): real {
        const snapped = Math.round((v - root.from) / root.step) * root.step + root.from;
        const clamped = Math.min(root.to, Math.max(root.from, snapped));
        return root.integer ? Math.round(clamped) : Math.round(clamped * 1000) / 1000;
    }

    Item {
        id: bar

        anchors.left: parent.left
        anchors.right: readout.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 24

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Theme.alpha(Theme.fgSurface, 0.14)
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(4, parent.width * root.fraction)
            height: 4
            radius: 2
            color: Theme.primary
        }

        Rectangle {
            id: handle

            anchors.verticalCenter: parent.verticalCenter
            x: Math.min(parent.width - width, Math.max(0, parent.width * root.fraction - width / 2))
            width: area.pressed ? 8 : 14
            height: area.pressed ? 24 : 14
            radius: width / 2
            color: Theme.primary

            Behavior on width {
                NumberAnimation {
                    duration: 120
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor

            function apply(mx: real): void {
                const f = Math.min(1, Math.max(0, (mx + 6) / bar.width));
                root.moved(root.quantise(root.from + f * root.span));
            }

            onPressed: mouse => {
                root.begin();
                apply(mouse.x);
            }
            onPositionChanged: mouse => {
                if (pressed)
                    apply(mouse.x);
            }
            onReleased: root.committed(root.value)
            onWheel: wheel => {
                root.begin();
                const dir = wheel.angleDelta.y > 0 ? 1 : -1;
                root.moved(root.quantise(root.value + dir * root.step));
                root.committed(root.value);
            }
        }
    }

    Rectangle {
        id: readout

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 54
        height: 26
        radius: 8
        color: input.activeFocus ? Theme.alpha(Theme.primary, 0.16) : Theme.alpha(Theme.fgSurface, 0.07)

        TextInput {
            id: input

            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.mono
            font.pixelSize: 11
            color: Theme.fgSurface
            selectionColor: Theme.primary
            selectedTextColor: Theme.fgPrimary
            selectByMouse: true

            text: root.integer ? `${Math.round(root.value)}` : `${Math.round(root.value * 100) / 100}`

            onEditingFinished: {
                const v = parseFloat(text);
                if (!isNaN(v)) {
                    root.begin();
                    root.moved(root.quantise(v));
                    root.committed(root.value);
                }
                focus = false;
            }
        }
    }
}
