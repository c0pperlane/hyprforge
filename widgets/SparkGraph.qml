import QtQuick
import qs.components
import qs.config
import qs.services

// Rolling history for one metric. Sys keeps a second-resolution buffer for
// every metric from startup, so a graph added later isn't blank.
WidgetBase {
    id: root

    // History is sampled centrally; the metric's own source has to
    // be awake as well or the curve records zeroes.
    needs: ["sys.history"].concat(Sys.demandsFor(root.str("source", "cpu")))

    readonly property string key: root.str("source", "cpu")
    readonly property var m: Sys.metric(root.key)
    readonly property var history: {
        const all = Sys.historyFor(root.key);
        const n = Math.round(root.num("points", 60));
        return all.length > n ? all.slice(all.length - n) : all;
    }

    Item {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.flag("showTitle", true) || root.flag("showValue", true) ? 22 : 0
        visible: height > 0

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: root.flag("showTitle", true)

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.m.icon
                size: 15
                color: root.accent
            }

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: root.m.label
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
                color: root.muted
            }
        }

        Txt {
            visible: root.flag("showValue", true)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.m.text
            font.family: Theme.mono
            font.pixelSize: 14
            font.weight: Font.Medium
            color: root.fg
        }
    }

    Spark {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: header.visible ? 6 : 0
        anchors.bottom: parent.bottom
        points: root.history
        maxValue: 1
        colour: root.accent
        fill: root.flag("fill", true)
        thickness: root.num("thickness", 2.5)
    }
}
