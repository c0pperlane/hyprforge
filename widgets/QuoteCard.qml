import QtQuick
import qs.components
import qs.config
import qs.services

// Rotating line of text. The index advances on a timer and is derived from the
// clock, so two of these on screen aren't in lockstep.
WidgetBase {
    id: root

    property int index: 0

    readonly property var all: root.lines("lines")
    readonly property string current: root.all.length ? root.all[root.index % root.all.length] : "Add some lines in the inspector"

    Timer {
        interval: Math.max(1, root.num("interval", 30)) * 60000
        running: root.all.length > 1
        repeat: true
        onTriggered: root.index++
    }

    Icon {
        id: mark

        visible: root.flag("mark", true)
        anchors.left: parent.left
        anchors.top: parent.top
        text: "format_quote"
        size: root.num("size", 20) * 1.7
        fill: 1
        color: Theme.alpha(root.accent, 0.55)
    }

    Txt {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: root.flag("mark", true) ? mark.bottom : parent.top
        anchors.topMargin: root.flag("mark", true) ? 2 : 0
        anchors.bottom: parent.bottom

        text: root.current
        font.pixelSize: root.num("size", 20)
        font.weight: Font.Normal
        font.italic: root.flag("italic", false)
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        color: root.fg
        animate: true
        axisWidth: 95
    }
}
