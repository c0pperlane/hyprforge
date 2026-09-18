import QtQuick
import Quickshell
import qs.components
import qs.config

// A button that runs something.
WidgetBase {
    id: root

    interactive: true

    readonly property bool column: root.str("layout", "column") === "column"

    Rectangle {
        anchors.fill: parent
        radius: root.num("radius", 22)
        color: area.containsMouse ? Theme.alpha(root.accent, 0.16) : "transparent"
        scale: area.containsPress ? 0.96 : 1

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }
    }

    Grid {
        anchors.centerIn: parent
        rows: root.column ? 2 : 1
        columns: root.column ? 1 : 2
        rowSpacing: 7
        columnSpacing: 11
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Icon {
            text: root.str("icon", "rocket_launch")
            size: root.num("iconSize", 34)
            fill: area.containsMouse ? 1 : 0
            color: root.accent
        }

        Txt {
            visible: !!root.str("label", "")
            text: root.str("label", "")
            font.pixelSize: Math.max(11, root.num("iconSize", 34) * 0.4)
            font.weight: Font.Medium
            color: root.fg
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editing
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const c = root.str("command", "");
            if (c)
                Quickshell.execDetached(["sh", "-c", c]);
        }
    }
}
