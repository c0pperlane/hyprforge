import QtQuick
import Quickshell
import qs.components
import qs.config

// A launcher strip. Entries are "icon|command" lines, which keeps it a plain
// text field in the Inspector rather than a nested list editor.
WidgetBase {
    id: root

    interactive: true

    readonly property bool vertical: root.str("orientation", "row") === "column"

    readonly property var entries: root.lines("entries").map(l => {
        const i = l.indexOf("|");
        return {
            icon: (i < 0 ? l : l.slice(0, i)).trim(),
            command: i < 0 ? "" : l.slice(i + 1).trim()
        };
    })

    function launch(command: string): void {
        if (!command || root.editing)
            return;
        // Through the login shell so aliases, PATH tweaks and shell syntax in
        // the command all behave the way they do in a terminal.
        Quickshell.execDetached(["sh", "-c", command]);
    }

    Grid {
        anchors.centerIn: parent
        rows: root.vertical ? root.entries.length : 1
        columns: root.vertical ? 1 : root.entries.length
        rowSpacing: root.num("spacing", 10)
        columnSpacing: root.num("spacing", 10)

        Repeater {
            model: root.entries

            Rectangle {
                id: tile

                required property var modelData

                width: root.num("iconSize", 26) * 2
                height: width
                radius: root.num("tileRadius", 16)
                color: tileArea.containsMouse ? Theme.alpha(root.accent, 0.25) : Theme.alpha(root.fg, 0.08)
                scale: tileArea.containsPress ? 0.92 : 1

                Behavior on color {
                    ColorAnimation {
                        duration: 130
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 110
                        easing.type: Easing.OutCubic
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    text: tile.modelData.icon
                    size: root.num("iconSize", 26)
                    color: tileArea.containsMouse ? root.accent : root.fg
                }

                MouseArea {
                    id: tileArea

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.editing
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launch(tile.modelData.command)
                }
            }
        }
    }
}
