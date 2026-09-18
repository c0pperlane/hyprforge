import QtQuick
import qs.components
import qs.config

// Keyboard cheatsheet (F1). Everything the editor can do without the mouse.
Item {
    id: root

    signal dismissed

    z: 9000

    readonly property var groups: [
        {
            title: "Canvas",
            items: [
                ["Middle-drag / Space-drag", "Pan"],
                ["Ctrl + Wheel", "Zoom to cursor"],
                ["Ctrl + 0", "Zoom to 100%"],
                ["Ctrl + 1", "Fit artboard"],
                ["Drag on empty space", "Marquee select"],
                ["Tab", "Preview (hide chrome)"]
            ]
        },
        {
            title: "Elements",
            items: [
                ["Drag", "Move"],
                ["Shift + drag", "Constrain to one axis"],
                ["Shift + corner handle", "Resize keeping aspect"],
                ["Arrows", "Nudge 1px"],
                ["Shift + arrows", "Nudge 10px"],
                ["Ctrl + click", "Add/remove from selection"],
                ["Ctrl + D", "Duplicate"],
                ["Delete", "Remove"],
                ["L / H", "Lock / hide"]
            ]
        },
        {
            title: "Document",
            items: [
                ["Ctrl + Z", "Undo"],
                ["Ctrl + Shift + Z", "Redo"],
                ["Ctrl + C / V", "Copy / paste"],
                ["Ctrl + A", "Select all"],
                ["Ctrl + S", "Save now"],
                ["G", "Toggle grid"],
                ["S", "Toggle snapping"],
                ["Esc", "Deselect, then close"]
            ]
        }
    ]

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.82)

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 120, 980)
        height: Math.min(parent.height - 120, content.implicitHeight + 100)
        radius: 26
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.6)

        Txt {
            id: heading

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 34
            text: "Keyboard"
            font.pixelSize: 26
            font.weight: Font.Bold
            axisWidth: 80
            color: Theme.fgSurface
        }

        Btn {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 22
            icon: "close"
            iconSize: 20
            colour: Theme.fgSurfaceVariant
            hoverColour: Theme.error
            onClicked: root.dismissed()
        }

        Row {
            id: content

            anchors.top: heading.bottom
            anchors.topMargin: 22
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 34
            spacing: 30

            Repeater {
                model: root.groups

                Column {
                    required property var modelData

                    width: (content.width - 60) / 3
                    spacing: 9

                    Txt {
                        text: modelData.title.toUpperCase()
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: Theme.primary
                        bottomPadding: 4
                    }

                    Repeater {
                        model: modelData.items

                        Item {
                            required property var modelData

                            width: parent.width
                            height: 26

                            Rectangle {
                                id: keyChip

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: keyText.implicitWidth + 14
                                height: 22
                                radius: 7
                                color: Theme.alpha(Theme.fgSurface, 0.08)

                                Txt {
                                    id: keyText

                                    anchors.centerIn: parent
                                    text: modelData[0]
                                    font.family: Theme.mono
                                    font.pixelSize: 10
                                    color: Theme.fgSurface
                                }
                            }

                            Txt {
                                anchors.left: keyChip.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData[1]
                                font.pixelSize: 12
                                color: Theme.fgSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }
}
