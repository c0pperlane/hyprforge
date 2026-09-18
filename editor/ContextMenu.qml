import QtQuick
import qs.components
import qs.config

// Right-click menu. Entries change depending on whether the click landed on an
// element or on empty canvas.
Item {
    id: root

    property string targetId: ""

    signal action(string name, string id)

    anchors.fill: parent
    visible: false
    z: 8000

    function popupAt(px: real, py: real): void {
        root.x = 0;
        root.y = 0;
        menu.x = Math.min(px, root.width - menu.width - 12);
        menu.y = Math.min(py, root.height - menu.height - 12);
        root.visible = true;
    }

    readonly property var entries: {
        if (!root.targetId)
            return [
                {
                    name: "paste",
                    label: "Paste",
                    icon: "content_paste",
                    enabled: !!Store.clipboard
                },
                {
                    name: "selectAll",
                    label: "Select all",
                    icon: "select_all",
                    enabled: true
                }
            ];

        const w = Store.get(root.targetId);
        return [
            {
                name: "duplicate",
                label: "Duplicate",
                icon: "content_copy",
                enabled: true
            },
            {
                name: "front",
                label: "Bring to front",
                icon: "flip_to_front",
                enabled: true
            },
            {
                name: "back",
                label: "Send to back",
                icon: "flip_to_back",
                enabled: true
            },
            {
                name: "lock",
                label: w?.locked ? "Unlock" : "Lock",
                icon: w?.locked ? "lock_open" : "lock",
                enabled: true
            },
            {
                name: "hide",
                label: w?.hidden ? "Show" : "Hide",
                icon: w?.hidden ? "visibility" : "visibility_off",
                enabled: true
            },
            {
                name: "reset",
                label: "Reset styling",
                icon: "restart_alt",
                enabled: true
            },
            {
                name: "delete",
                label: "Delete",
                icon: "delete",
                enabled: true,
                danger: true
            }
        ];
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.visible = false
    }

    Rectangle {
        id: menu

        width: 210
        height: col.implicitHeight + 12
        radius: 14
        color: Theme.surfaceContainerHighest
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.6)

        Column {
            id: col

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6

            Repeater {
                model: root.entries

                Rectangle {
                    required property var modelData

                    width: col.width
                    height: 32
                    radius: 9
                    opacity: modelData.enabled ? 1 : 0.4
                    color: itemArea.containsMouse && modelData.enabled ? Theme.alpha(modelData.danger ? Theme.error : Theme.primary, 0.16) : "transparent"

                    Icon {
                        id: entryIcon

                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.icon
                        size: 16
                        color: modelData.danger ? Theme.error : Theme.fgSurfaceVariant
                    }

                    Txt {
                        anchors.left: entryIcon.right
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        font.pixelSize: 12
                        color: modelData.danger ? Theme.error : Theme.fgSurface
                    }

                    MouseArea {
                        id: itemArea

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: modelData.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.action(modelData.name, root.targetId);
                            root.visible = false;
                        }
                    }
                }
            }
        }
    }
}
