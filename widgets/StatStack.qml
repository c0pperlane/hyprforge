import QtQuick
import qs.components
import qs.config
import qs.services

// Several metrics as labelled meters. Rows are driven by a newline-separated
// list of metric keys, so the stack is whatever mix you care about.
WidgetBase {
    id: root

    needs: {
        const out = [];
        for (const k of root.keys)
            for (const d of Sys.demandsFor(k))
                if (out.indexOf(d) < 0)
                    out.push(d);
        return out;
    }

    readonly property var keys: {
        const ks = root.lines("sources");
        return ks.length ? ks : ["cpu"];
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.num("spacing", 14)

        Repeater {
            model: root.keys

            Item {
                id: row

                required property string modelData

                readonly property var m: Sys.metric(modelData)
                readonly property color tint: Theme.chart[index % Theme.chart.length]

                required property int index

                width: parent.width
                height: labelRow.height + root.num("thickness", 8) + 5

                Item {
                    id: labelRow

                    width: parent.width
                    height: 16

                    Icon {
                        id: rowIcon

                        visible: root.flag("showIcon", true)
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.m.icon
                        size: 14
                        color: row.tint
                    }

                    Txt {
                        anchors.left: root.flag("showIcon", true) ? rowIcon.right : parent.left
                        anchors.leftMargin: root.flag("showIcon", true) ? 6 : 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.m.label
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: root.muted
                    }

                    Txt {
                        visible: root.flag("showValue", true)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.m.text
                        font.family: Theme.mono
                        font.pixelSize: 12
                        color: root.fg
                    }
                }

                Meter {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    value: row.m.value
                    style: root.str("style", "bar")
                    thickness: root.num("thickness", 8)
                    colour: row.tint
                    trackColour: Theme.alpha(root.fg, 0.12)
                }
            }
        }
    }
}
