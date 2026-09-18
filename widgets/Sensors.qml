pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

// Every temperature the machine reports, hottest first.
WidgetBase {
    id: root

    needs: ["sys.temps"]

    readonly property real warn: root.num("warn", 75)
    readonly property real ceiling: root.num("ceiling", 100)

    readonly property var rows: {
        const all = Sys.temperatures ?? [];
        const filter = root.lines("filter");
        const matched = filter.length ? all.filter(t => filter.some(f => t.chip.toLowerCase().includes(f.toLowerCase()) || t.label.toLowerCase().includes(f.toLowerCase()))) : all;
        return matched.slice(0, Math.max(1, Math.round(root.num("count", 5))));
    }

    function tint(c: real): color {
        if (c < root.warn)
            return root.accent;
        return Theme.mix(root.accent, Theme.error, Math.min(1, (c - root.warn) / Math.max(1, root.ceiling - root.warn)));
    }

    Item {
        id: heading

        visible: root.flag("showTitle", true)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: visible ? 17 : 0

        Icon {
            id: headIcon

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "thermostat"
            size: 14
            color: root.accent
        }

        Txt {
            anchors.left: headIcon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "TEMPERATURES"
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            color: root.muted
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.topMargin: heading.visible ? 8 : 0
        spacing: root.num("spacing", 9)

        Repeater {
            model: root.rows

            Item {
                required property var modelData

                width: parent.width
                height: root.num("size", 12) + (root.flag("showBars", true) ? root.num("thickness", 5) + 4 : 0)

                ListTxt {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.right: figure.left
                    anchors.rightMargin: 6
                    text: root.flag("showChip", true) ? `${parent.modelData.chip} · ${parent.modelData.label}` : parent.modelData.label
                    font.pixelSize: root.num("size", 12)
                    color: root.muted
                    elide: Text.ElideRight
                }

                ListTxt {
                    id: figure

                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: `${parent.modelData.celsius.toFixed(1)}°`
                    font.family: Theme.mono
                    font.pixelSize: root.num("size", 12)
                    color: root.tint(parent.modelData.celsius)
                }

                Meter {
                    visible: root.flag("showBars", true)
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    value: Math.min(1, parent.modelData.celsius / root.ceiling)
                    thickness: root.num("thickness", 5)
                    colour: root.tint(parent.modelData.celsius)
                    trackColour: Theme.alpha(root.fg, 0.12)
                }
            }
        }

        ListTxt {
            visible: !root.rows.length
            text: "No sensors reported"
            font.pixelSize: root.num("size", 12)
            color: root.muted
        }
    }
}
