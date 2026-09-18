pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.editor
import qs.editor.controls
import qs.services

// Stacking order for the current monitor, topmost first. Doubles as a way to
// reach elements that are hidden behind something else.
FloatingPanel {
    id: root

    readonly property var items: {
        const out = [];
        for (let i = 0; i < Store.widgets.count; i++) {
            const w = Store.widgets.get(i);
            if (w.screen === EditorState.target)
                out.push({
                    id: w.id,
                    type: w.type,
                    z: w.z,
                    locked: w.locked,
                    hidden: w.hidden,
                    cond: Store.parseCond(w.cond)
                });
        }
        return out.sort((a, b) => b.z - a.z);
    }

    title: "Layers"
    icon: "layers"

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 6
        anchors.bottomMargin: 12
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col

            width: parent.width
            spacing: 3

            Repeater {
                model: root.items

                Rectangle {
                    id: row

                    required property var modelData

                    readonly property bool selected: EditorState.isSelected(modelData.id)

                    width: col.width
                    height: 36
                    radius: 10
                    color: row.selected ? Theme.alpha(Theme.primary, 0.2) : rowArea.containsMouse ? Theme.alpha(Theme.fgSurface, 0.07) : "transparent"
                    opacity: modelData.hidden ? 0.45 : 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Icon {
                        id: rowIcon

                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        text: Registry.def(row.modelData.type)?.icon ?? "widgets"
                        size: 16
                        color: row.selected ? Theme.primary : Theme.fgSurfaceVariant
                    }

                    Txt {
                        anchors.left: rowIcon.right
                        anchors.leftMargin: 9
                        anchors.right: condMark.visible ? condMark.left : rowActions.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: Registry.def(row.modelData.type)?.name ?? row.modelData.type
                        font.pixelSize: 12
                        font.weight: row.selected ? Font.DemiBold : Font.Normal
                        color: Theme.fgSurface
                    }

                    // A widget that is on the desktop only sometimes should
                    // say so here, or its absence looks like a bug rather than
                    // a rule someone wrote.
                    Icon {
                        id: condMark

                        visible: Cond.has(row.modelData.cond)
                        anchors.right: rowActions.left
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: "rule"
                        size: 14
                        color: Cond.evaluate(row.modelData.cond, EditorState.target) ? Theme.primary : Theme.fgSurfaceVariant
                        opacity: 0.9

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onEntered: EditorState.status(row.modelData.cond.rules.map(r => Cond.label(r)).join(row.modelData.cond.mode === "any" ? "  or  " : "  and  "))
                        }
                    }

                    Row {
                        id: rowActions

                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Btn {
                            icon: "keyboard_arrow_up"
                            iconSize: 15
                            padding: 4
                            colour: Theme.fgSurfaceVariant
                            hoverColour: Theme.primary
                            onClicked: Store.toFront(row.modelData.id)
                        }

                        Btn {
                            icon: "keyboard_arrow_down"
                            iconSize: 15
                            padding: 4
                            colour: Theme.fgSurfaceVariant
                            hoverColour: Theme.primary
                            onClicked: Store.toBack(row.modelData.id)
                        }

                        Btn {
                            icon: row.modelData.hidden ? "visibility_off" : "visibility"
                            iconSize: 15
                            padding: 4
                            colour: row.modelData.hidden ? Theme.error : Theme.fgSurfaceVariant
                            hoverColour: Theme.primary
                            onClicked: Store.set(row.modelData.id, "hidden", !row.modelData.hidden, true)
                        }

                        Btn {
                            icon: row.modelData.locked ? "lock" : "lock_open"
                            iconSize: 15
                            padding: 4
                            colour: row.modelData.locked ? Theme.error : Theme.fgSurfaceVariant
                            hoverColour: Theme.primary
                            onClicked: Store.set(row.modelData.id, "locked", !row.modelData.locked, true)
                        }
                    }

                    MouseArea {
                        id: rowArea

                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: rowActions.left
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: mouse => {
                            if (mouse.modifiers & Qt.ControlModifier)
                                EditorState.toggle(row.modelData.id);
                            else
                                EditorState.select(row.modelData.id);
                        }
                    }
                }
            }

            Txt {
                visible: !root.items.length
                width: col.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 26
                text: "Nothing placed on this display yet"
                font.pixelSize: 12
                color: Theme.fgSurfaceVariant
                wrapMode: Text.Wrap
            }
        }
    }
}
