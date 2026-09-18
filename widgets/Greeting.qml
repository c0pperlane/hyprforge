import QtQuick
import qs.components
import qs.config
import qs.services

// "Good evening, name" - the part of the desktop that talks back.
WidgetBase {
    id: root

    readonly property string part: {
        const h = Clock.hours;
        if (h < 5)
            return "Good night";
        if (h < 12)
            return "Good morning";
        if (h < 18)
            return "Good afternoon";
        return "Good evening";
    }

    readonly property string who: root.str("name", "") || Sys.user

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Txt {
            width: parent.width
            text: `${root.part}, ${root.who}`
            font.pixelSize: root.num("size", 40)
            display: true
            font.weight: root.num("weight", 500)
            axisWidth: 85
            color: root.fg
            glow: true
        }

        Txt {
            visible: !!root.str("subtitle", "")
            width: parent.width
            text: root.str("subtitle", "")
            font.pixelSize: Math.max(11, root.num("size", 40) * 0.34)
            color: root.muted
            glow: true
        }
    }
}
