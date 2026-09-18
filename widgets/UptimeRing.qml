import QtQuick
import qs.components
import qs.config
import qs.services

// How long the machine has been up, as a ring that fills over a chosen span.
WidgetBase {
    id: root

    needs: ["sys.host"]

    readonly property real hours: {
        // Sys keeps uptime as a formatted string; parse it back rather than
        // adding a second reader of /proc/uptime.
        const s = Sys.uptime;
        const d = /(\d+)d/.exec(s);
        const h = /(\d+)h/.exec(s);
        const m = /(\d+)m/.exec(s);
        return (d ? parseInt(d[1]) * 24 : 0) + (h ? parseInt(h[1]) : 0) + (m ? parseInt(m[1]) / 60 : 0);
    }

    readonly property real span: {
        switch (root.str("span", "day")) {
        case "week":
            return 24 * 7;
        case "month":
            return 24 * 30;
        default:
            return 24;
        }
    }

    Ring {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        value: Math.min(1, root.hours / root.span)
        thickness: root.num("thickness", 10)
        colour: root.accent
        track: true
        trackColour: Theme.alpha(root.accent, 0.16)
    }

    Column {
        anchors.centerIn: parent
        spacing: -1

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showIcon", true)
            text: "schedule"
            size: root.num("valueSize", 20) * 0.8
            color: root.accent
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Sys.uptime || "—"
            font.pixelSize: root.num("valueSize", 20)
            font.weight: Font.DemiBold
            axisWidth: 80
            color: root.fg
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showLabel", true)
            text: "UPTIME"
            font.pixelSize: Math.max(8, root.num("valueSize", 20) * 0.42)
            font.weight: Font.DemiBold
            font.letterSpacing: 1.4
            color: root.muted
        }
    }
}
