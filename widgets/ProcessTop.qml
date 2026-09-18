pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

// What is actually eating the machine right now.
WidgetBase {
    id: root

    needs: ["sys.procs"]

    readonly property string sortBy: root.str("sortBy", "cpu")
    readonly property int count: Math.max(1, Math.round(root.num("count", 5)))

    readonly property var rows: {
        const all = (Sys.processes ?? []).slice();
        if (root.sortBy === "mem")
            all.sort((a, b) => b.mem - a.mem);
        return all.slice(0, root.count);
    }

    Item {
        id: heading

        visible: root.flag("showTitle", true)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: visible ? 16 : 0

        Txt {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.sortBy === "mem" ? "TOP BY MEMORY" : "TOP BY CPU"
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
        spacing: root.num("spacing", 7)

        Repeater {
            // Row count is stable while the widget is configured the same way,
            // so delegates persist and the bar can animate between refreshes.
            model: root.rows.length

            Item {
                required property int index

                readonly property var entry: root.rows[index] ?? null
                readonly property real share: entry ? Math.min(1, (root.sortBy === "mem" ? entry.mem : entry.cpu) / 100) : 0

                width: parent.width
                height: root.num("size", 13) * 1.5

                // A bar behind the text rather than beside it, so the widget
                // stays readable when it is narrow.
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(2, parent.width * parent.share)
                    height: parent.height
                    radius: 6
                    color: Theme.alpha(root.accent, 0.22)

                    Behavior on width {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }

                }

                ListTxt {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: figure.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.entry ? parent.entry.name : ""
                    font.pixelSize: root.num("size", 13)
                    color: root.fg
                    elide: Text.ElideRight
                }

                ListTxt {
                    id: figure

                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.entry ? `${(root.sortBy === "mem" ? parent.entry.mem : parent.entry.cpu).toFixed(1)}%` : ""
                    font.family: Theme.mono
                    font.pixelSize: root.num("size", 13) * 0.92
                    color: root.muted
                }
            }
        }

        ListTxt {
            visible: !root.rows.length
            text: "gathering…"
            font.pixelSize: root.num("size", 13)
            color: root.muted
        }
    }
}
