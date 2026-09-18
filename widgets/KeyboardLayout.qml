import QtQuick
import qs.components
import qs.config
import qs.services

// Active keyboard layout. Click to cycle, when more than one is configured.
WidgetBase {
    id: root

    interactive: Inputs.layouts.length > 1

    readonly property bool multiple: Inputs.layouts.length > 1

    Column {
        anchors.centerIn: parent
        spacing: 1

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.str("style", "code") === "code" ? Inputs.shortLayout : (Inputs.activeKeymap || Inputs.shortLayout)
            font.pixelSize: root.num("size", 24)
            font.weight: Font.DemiBold
            font.letterSpacing: root.str("style", "code") === "code" ? 2 : 0
            axisWidth: 80
            color: root.fg
            glow: root.flag("glow", false)
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showLabel", true)
            text: root.multiple ? `${Inputs.layouts.length} layouts` : "layout"
            font.pixelSize: Math.max(8, root.num("size", 24) * 0.38)
            font.weight: Font.Medium
            font.letterSpacing: 1.2
            color: root.muted
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.multiple && !root.editing
        cursorShape: Qt.PointingHandCursor
        onClicked: Inputs.cycleLayout()
    }
}
