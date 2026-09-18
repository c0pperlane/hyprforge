pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

// Recent clipboard entries. Click one to put it back on the clipboard.
WidgetBase {
    id: root

    interactive: true
    needs: ["clipboard"]

    readonly property var rows: (Clip.entries ?? []).slice(0, Math.max(1, Math.round(root.num("count", 5))))

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
            text: "content_paste"
            size: 14
            color: root.accent
        }

        Txt {
            anchors.left: headIcon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "CLIPBOARD"
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
        spacing: root.num("spacing", 5)

        Repeater {
            model: root.rows

            Rectangle {
                id: entry

                required property var modelData

                width: parent.width
                height: root.num("size", 12) * 2.1
                radius: 9
                color: entryArea.containsMouse ? Theme.alpha(root.accent, 0.18) : Theme.alpha(root.fg, 0.05)


                Icon {
                    id: kindIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.image ? "image" : "notes"
                    size: root.num("size", 12) * 1.1
                    color: root.muted
                }

                ListTxt {
                    anchors.left: kindIcon.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    // cliphist collapses newlines already, but a pasted block
                    // still arrives with tabs that make the row jump.
                    text: entry.modelData.label.replace(/\s+/g, " ").trim()
                    font.pixelSize: root.num("size", 12)
                    font.family: entry.modelData.image ? Theme.sans : (root.flag("mono", false) ? Theme.mono : Theme.sans)
                    color: entry.modelData.image ? root.muted : root.fg
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: entryArea

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.editing
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Clip.copy(entry.modelData.id)
                }
            }
        }

        ListTxt {
            visible: !root.rows.length
            text: Clip.checked ? "Clipboard is empty" : "reading…"
            font.pixelSize: root.num("size", 12)
            color: root.muted
        }
    }
}
