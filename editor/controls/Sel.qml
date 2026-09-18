import QtQuick
import QtQuick.Window
import qs.components
import qs.config

// Choice control. Renders as a segmented button when the options are few and
// short, and as a dropdown otherwise - same API either way.
Item {
    id: root

    property var options: []        // [string] or [{value,label}]
    property string value: ""
    property bool forceMenu: false

    signal picked(string value)

    readonly property var normalised: (root.options ?? []).map(o => typeof o === "string" ? ({
                value: o,
                label: o.charAt(0).toUpperCase() + o.slice(1)
            }) : o)

    readonly property bool segmented: !root.forceMenu && root.normalised.length <= 3 && root.normalised.every(o => o.label.length <= 9)

    readonly property string currentLabel: root.normalised.find(o => o.value === root.value)?.label ?? root.value

    implicitHeight: 32

    // --- segmented --------------------------------------------------------
    Rectangle {
        visible: root.segmented
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(parent.width, seg.implicitWidth + 6)
        height: 30
        radius: 15
        color: Theme.alpha(Theme.fgSurface, 0.07)

        Row {
            id: seg

            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: root.normalised

                Rectangle {
                    required property var modelData

                    readonly property bool active: modelData.value === root.value

                    width: Math.max(44, segLabel.implicitWidth + 20)
                    height: 26
                    radius: 13
                    color: active ? Theme.primary : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                        }
                    }

                    Txt {
                        id: segLabel

                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: parent.active ? Theme.fgPrimary : Theme.fgSurfaceVariant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.picked(modelData.value)
                    }
                }
            }
        }
    }

    // --- dropdown ---------------------------------------------------------
    Rectangle {
        id: field

        visible: !root.segmented
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        radius: 9
        color: Theme.alpha(Theme.fgSurface, menuArea.containsMouse ? 0.12 : 0.07)

        Behavior on color {
            ColorAnimation {
                duration: 130
            }
        }

        Txt {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: chev.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentLabel
            font.pixelSize: 12
            color: Theme.fgSurface
        }

        Icon {
            id: chev

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "expand_more"
            size: 18
            color: Theme.fgSurfaceVariant
            rotation: pop.open ? 180 : 0

            Behavior on rotation {
                NumberAnimation {
                    duration: 160
                }
            }
        }

        MouseArea {
            id: menuArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pop.open = !pop.open
        }
    }

    readonly property real menuHeight: Math.min(240, menuCol.implicitHeight + 8)

    // Hosted outside this item: the Inspector's sections and its Flickable
    // both clip, and a menu drawn inside them comes out sliced off.
    Popover {
        id: pop

        anchorItem: field
        contentWidth: field.width
        contentHeight: root.menuHeight
        margin: 4

    Rectangle {
        id: menu

        anchors.fill: parent
        radius: 12
        color: Theme.surfaceContainerHighest
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.6)
        clip: true

        Flickable {
            anchors.fill: parent
            anchors.margins: 4
            contentHeight: menuCol.implicitHeight
            interactive: contentHeight > height
            clip: true

            Column {
                id: menuCol

                width: parent.width

                Repeater {
                    model: root.normalised

                    Rectangle {
                        required property var modelData

                        width: menuCol.width
                        height: 30
                        radius: 8
                        color: itemArea.containsMouse ? Theme.alpha(Theme.primary, 0.16) : "transparent"

                        Txt {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            font.pixelSize: 12
                            color: modelData.value === root.value ? Theme.primary : Theme.fgSurface
                        }

                        MouseArea {
                            id: itemArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.picked(modelData.value);
                                pop.open = false;
                            }
                        }
                    }
                }
            }
        }
    }
    }
}
