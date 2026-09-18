import QtQuick
import qs.components
import qs.config

// Corner radius: one value while linked, four when not.
//
// Laid out as an actual rectangle with a field at each corner, because "top
// left / top right / bottom left / bottom right" in a list is a puzzle to map
// onto the thing you are looking at.
Item {
    id: root

    property real radius: 22
    property bool linked: true
    property real tl: 22
    property real tr: 22
    property real bl: 22
    property real br: 22
    property real from: 0
    property real to: 80

    // Corners squared by attachment, shown as such but not editable - the
    // widget is joined to a neighbour there and the stored value is what it
    // returns to when it is moved away.
    property var attached: ({
            tl: false,
            tr: false,
            bl: false,
            br: false
        })

    signal changed(var patch)

    implicitHeight: root.linked ? 34 : 104

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    // --- linked: a single slider -------------------------------------------
    Item {
        anchors.left: parent.left
        anchors.right: linkButton.left
        anchors.rightMargin: 8
        anchors.top: parent.top
        height: 34
        visible: root.linked

        Sld {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            from: root.from
            to: root.to
            step: 1
            value: root.radius
            onMoved: v => root.changed({
                    radius: v,
                    radiusTL: v,
                    radiusTR: v,
                    radiusBL: v,
                    radiusBR: v
                })
        }
    }

    // --- unlinked: a field per corner ---------------------------------------
    Item {
        id: box

        anchors.left: parent.left
        anchors.right: linkButton.left
        anchors.rightMargin: 8
        anchors.top: parent.top
        height: 100
        visible: !root.linked

        Rectangle {
            anchors.fill: parent
            anchors.margins: 16
            color: "transparent"
            border.width: 1
            border.color: Theme.alpha(Theme.fgSurface, 0.14)
            topLeftRadius: Math.min(20, root.attached.tl ? 0 : root.tl)
            topRightRadius: Math.min(20, root.attached.tr ? 0 : root.tr)
            bottomLeftRadius: Math.min(20, root.attached.bl ? 0 : root.bl)
            bottomRightRadius: Math.min(20, root.attached.br ? 0 : root.br)
        }

        Repeater {
            model: [
                {
                    key: "radiusTL",
                    corner: "tl",
                    ax: 0,
                    ay: 0
                },
                {
                    key: "radiusTR",
                    corner: "tr",
                    ax: 1,
                    ay: 0
                },
                {
                    key: "radiusBL",
                    corner: "bl",
                    ax: 0,
                    ay: 1
                },
                {
                    key: "radiusBR",
                    corner: "br",
                    ax: 1,
                    ay: 1
                }
            ]

            Rectangle {
                id: field

                required property var modelData

                readonly property bool joined: root.attached[modelData.corner]
                readonly property real value: root[modelData.corner]

                width: 44
                height: 28
                radius: 8
                x: (box.width - width) * modelData.ax
                y: (box.height - height) * modelData.ay
                color: field.joined ? Theme.alpha(Theme.tertiary, 0.18) : Theme.alpha(Theme.fgSurface, input.activeFocus ? 0.14 : 0.07)

                TextInput {
                    id: input

                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: field.joined ? Theme.tertiary : Theme.fgSurface
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.fgPrimary
                    selectByMouse: true
                    readOnly: field.joined
                    text: field.joined ? "join" : `${Math.round(field.value)}`

                    onEditingFinished: {
                        const v = parseFloat(text);
                        if (!isNaN(v)) {
                            const patch = ({});
                            patch[field.modelData.key] = Math.max(root.from, Math.min(root.to, Math.round(v)));
                            root.changed(patch);
                        }
                        focus = false;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    enabled: !field.joined
                    cursorShape: Qt.SizeVerCursor
                    onWheel: wheel => {
                        const patch = ({});
                        patch[field.modelData.key] = Math.max(root.from, Math.min(root.to, field.value + (wheel.angleDelta.y > 0 ? 1 : -1) * (wheel.modifiers & Qt.ShiftModifier ? 10 : 1)));
                        root.changed(patch);
                    }
                }
            }
        }
    }

    Btn {
        id: linkButton

        anchors.right: parent.right
        anchors.top: parent.top
        icon: root.linked ? "link" : "link_off"
        iconSize: 17
        padding: 7
        radius: 9
        checked: root.linked
        colour: Theme.fgSurfaceVariant
        hoverColour: Theme.primary
        background: Theme.alpha(Theme.fgSurface, 0.06)

        onClicked: {
            const next = !root.linked;
            const patch = {
                radiusLinked: next
            };
            // Going unlinked seeds every corner from the shared value, so the
            // shape does not jump the moment you unlink it.
            if (!next) {
                patch.radiusTL = root.radius;
                patch.radiusTR = root.radius;
                patch.radiusBL = root.radius;
                patch.radiusBR = root.radius;
            }
            root.changed(patch);
        }
    }
}
