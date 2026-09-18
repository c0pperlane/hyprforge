import QtQuick
import qs.components
import qs.config
import qs.services

// One metric as a radial gauge. The metric is a prop, so the same element
// covers CPU, GPU, RAM, temps, disk, battery and network.
WidgetBase {
    id: root

    needs: Sys.demandsFor(root.str("source", "cpu"))

    readonly property var m: Sys.metric(root.str("source", "cpu"))
    readonly property bool warned: root.m.value * 100 >= root.num("warn", 85)
    readonly property color ringColour: root.warned ? Theme.error : root.accent

    Ring {
        id: ring

        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        value: root.m.value
        thickness: root.num("thickness", 12)
        colour: root.ringColour
        track: root.flag("track", true)
        trackColour: Theme.alpha(root.ringColour, 0.16)
        gapAngle: root.num("gap", 0)
    }

    Column {
        anchors.centerIn: parent
        spacing: -2

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showIcon", true)
            text: root.m.icon
            size: root.num("valueSize", 30) * 0.6
            color: root.ringColour
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.m.text
            font.pixelSize: root.num("valueSize", 30)
            font.weight: Font.DemiBold
            axisWidth: 80
            color: root.fg
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showLabel", true)
            text: root.m.label.toUpperCase()
            font.pixelSize: Math.max(8, root.num("valueSize", 30) * 0.3)
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
            color: root.muted
        }
    }
}
