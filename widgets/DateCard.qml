import QtQuick
import qs.components
import qs.config
import qs.services

// Day number with weekday/month labels above and below.
WidgetBase {
    id: root

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 2

        Txt {
            visible: root.flag("showWeekday", true)
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: {
                const s = Clock.fmt("dddd");
                return root.flag("uppercase", true) ? s.toUpperCase() : s;
            }
            font.pixelSize: Math.max(10, root.num("size", 96) * 0.16)
            font.weight: Font.DemiBold
            font.letterSpacing: 2.5
            color: root.accent
        }

        Txt {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Clock.fmt("d")
            font.pixelSize: root.num("size", 96)
            display: true
            font.weight: Font.Bold
            axisWidth: 60
            color: root.fg
            elide: Text.ElideNone
        }

        Txt {
            visible: root.flag("showMonth", true)
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: {
                const s = Clock.fmt("MMMM yyyy");
                return root.flag("uppercase", true) ? s.toUpperCase() : s;
            }
            font.pixelSize: Math.max(10, root.num("size", 96) * 0.15)
            font.weight: Font.Medium
            font.letterSpacing: 1.5
            color: root.muted
        }
    }
}
