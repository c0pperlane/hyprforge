import QtQuick
import qs.components
import qs.config

// A floating tool palette inside the editor overlay: drag by the header,
// collapse to just the title bar, resize from the bottom-right grip, close
// with the X. Position is remembered for the session.
Item {
    id: root

    property string title: ""
    property string icon: ""
    property bool collapsed: false
    property bool closable: true
    property bool resizable: true
    property real minWidth: 220
    property real minHeight: 160
    property real maxHeight: parent ? parent.height - 80 : 900

    property bool open: true

    signal closeRequested

    default property alias content: body.data

    visible: root.open && opacity > 0
    opacity: root.open ? 1 : 0
    scale: root.open ? 1 : 0.96

    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    height: root.collapsed ? header.height + 12 : root.fullHeight
    property real fullHeight: 400

    Behavior on height {
        NumberAnimation {
            duration: 210
            easing.type: Easing.OutCubic
        }
    }

    // Only called after a drag - assigning x/y here would overwrite the
    // consumer's positioning bindings before the panel has ever been moved.
    function clampPosition(): void {
        if (!parent)
            return;
        root.x = Math.max(8, Math.min(parent.width - root.width - 8, root.x));
        root.y = Math.max(8, Math.min(parent.height - 60, root.y));
    }

    Rectangle {
        id: shell

        anchors.fill: parent
        radius: 20
        color: Theme.alpha(Theme.surfaceContainer, 0.97)
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.65)
        clip: true

        // Palettes sit over a busy wallpaper; a soft top highlight keeps the
        // edge readable without a heavy border.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Theme.alpha(Theme.fgSurface, 0.1)
        }

        Item {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 42

            Icon {
                id: headerIcon

                visible: !!root.icon
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                size: 18
                color: Theme.primary
            }

            Txt {
                anchors.left: root.icon ? headerIcon.right : parent.left
                anchors.leftMargin: root.icon ? 9 : 16
                anchors.right: headerButtons.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
                color: Theme.fgSurface
            }

            Row {
                id: headerButtons

                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Btn {
                    icon: root.collapsed ? "expand_more" : "expand_less"
                    iconSize: 17
                    colour: Theme.fgSurfaceVariant
                    hoverColour: Theme.fgSurface
                    padding: 6
                    onClicked: root.collapsed = !root.collapsed
                }

                Btn {
                    visible: root.closable
                    icon: "close"
                    iconSize: 17
                    colour: Theme.fgSurfaceVariant
                    hoverColour: Theme.error
                    padding: 6
                    onClicked: root.closeRequested()
                }
            }

            MouseArea {
                id: dragArea

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: headerButtons.left
                cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                drag.target: root
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 8
                drag.maximumX: root.parent ? root.parent.width - root.width - 8 : 2000
                drag.minimumY: 8
                drag.maximumY: root.parent ? root.parent.height - 52 : 2000

                onDoubleClicked: root.collapsed = !root.collapsed
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                height: 1
                color: Theme.alpha(Theme.outlineVariant, 0.4)
                opacity: root.collapsed ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }
        }

        Item {
            id: body

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 0
            opacity: root.collapsed ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        // Resize grip
        Item {
            visible: root.resizable && !root.collapsed
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 20
            height: 20

            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    width: 2 + index * 3
                    height: 2
                    radius: 1
                    color: Theme.alpha(Theme.fgSurfaceVariant, 0.5)
                    x: 16 - width
                    y: 6 + index * 4
                    rotation: -45
                    transformOrigin: Item.Center
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.SizeFDiagCursor

                property real startX: 0
                property real startY: 0
                property real startW: 0
                property real startH: 0

                onPressed: mouse => {
                    startX = mouse.x;
                    startY = mouse.y;
                    startW = root.width;
                    startH = root.fullHeight;
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    root.width = Math.max(root.minWidth, startW + (mouse.x - startX));
                    root.fullHeight = Math.max(root.minHeight, Math.min(root.maxHeight, startH + (mouse.y - startY)));
                }
            }
        }
    }
}
