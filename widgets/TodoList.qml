import QtQuick
import qs.components
import qs.config

// Tickable list. Completion is stored as a newline-separated list of the
// completed items' text, which survives reordering and edits from the
// Inspector better than an index-based set would.
WidgetBase {
    id: root

    interactive: true

    function toggle(item: string): void {
        const done = root.done.slice();
        const i = done.indexOf(item);
        if (i >= 0)
            done.splice(i, 1);
        else
            done.push(item);
        root.writeProp("done", done.join("\n"));
    }

    readonly property var items: root.lines("items")
    readonly property var done: root.lines("done")

    function isDone(item: string): bool {
        return root.done.indexOf(item) >= 0;
    }

    Txt {
        id: title

        visible: !!root.str("title", "")
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.str("title", "")
        font.pixelSize: Math.max(11, root.num("size", 14) * 0.92)
        font.weight: Font.Bold
        font.letterSpacing: 1.2
        color: root.accent
    }

    Txt {
        id: counter

        visible: title.visible && root.items.length > 0
        anchors.right: parent.right
        anchors.top: parent.top
        text: `${root.done.length}/${root.items.length}`
        font.family: Theme.mono
        font.pixelSize: Math.max(10, root.num("size", 14) * 0.8)
        color: root.muted
    }

    Flickable {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.visible ? title.bottom : parent.top
        anchors.topMargin: title.visible ? 8 : 0
        anchors.bottom: parent.bottom
        contentHeight: col.implicitHeight
        clip: true
        interactive: contentHeight > height

        Column {
            id: col

            width: parent.width
            spacing: 3

            Repeater {
                model: root.items

                Item {
                    id: line

                    required property string modelData

                    readonly property bool checked: root.isDone(modelData)

                    width: col.width
                    height: root.num("size", 14) * 1.9

                    Rectangle {
                        id: box

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.num("size", 14) * 1.15
                        height: width
                        radius: 5
                        color: line.checked ? root.accent : "transparent"
                        border.width: 1.5
                        border.color: line.checked ? root.accent : Theme.alpha(root.fg, 0.4)

                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }
                        }

                        Icon {
                            anchors.centerIn: parent
                            visible: line.checked
                            text: "check"
                            size: parent.width * 0.85
                            color: Theme.contrast(root.accent)
                        }
                    }

                    Txt {
                        anchors.left: box.right
                        anchors.leftMargin: 9
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: line.modelData
                        font.pixelSize: root.num("size", 14)
                        font.strikeout: line.checked && root.flag("strike", true)
                        color: line.checked ? root.muted : root.fg
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.editing
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggle(line.modelData)
                    }
                }
            }
        }
    }
}
