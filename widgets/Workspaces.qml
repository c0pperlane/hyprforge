import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.config

// Hyprland workspace indicator you can click to switch.
WidgetBase {
    id: root

    interactive: true

    readonly property int count: Math.round(root.num("count", 6))
    readonly property int active: Hyprland.focusedWorkspace?.id ?? 1
    readonly property string style: root.str("style", "pills")

    function occupied(id: int): bool {
        return (Hyprland.workspaces.values ?? []).some(w => w.id === id && (w.lastIpcObject?.windows ?? 0) > 0);
    }

    Row {
        anchors.centerIn: parent
        spacing: root.num("spacing", 8)

        Repeater {
            model: root.count

            Item {
                id: ws

                required property int index

                readonly property int id: index + 1
                readonly property bool isActive: id === root.active
                readonly property bool hasWindows: root.occupied(id)

                width: ws.isActive && root.style === "pills" ? root.num("size", 30) * 2 : root.num("size", 30)
                height: root.num("size", 30)

                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    visible: root.style !== "numbers"
                    radius: height / 2
                    color: ws.isActive ? root.accent : ws.hasWindows ? Theme.alpha(root.fg, 0.28) : Theme.alpha(root.fg, 0.12)

                    // Dots shrink to a fraction of the slot; pills fill it.
                    scale: root.style === "dots" ? (ws.isActive ? 0.6 : 0.34) : 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Txt {
                    anchors.centerIn: parent
                    visible: root.style === "numbers"
                    text: `${ws.id}`
                    font.pixelSize: root.num("size", 30) * 0.55
                    font.weight: ws.isActive ? Font.Bold : Font.Normal
                    color: ws.isActive ? root.accent : ws.hasWindows ? root.fg : Theme.alpha(root.fg, 0.4)
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.editing
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`workspace ${ws.id}`)
                }
            }
        }
    }
}
