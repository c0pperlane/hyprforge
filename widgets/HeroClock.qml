import QtQuick
import qs.components
import qs.config
import qs.services

// The centrepiece clock: variable-width Google Sans Flex, optional date line.
WidgetBase {
    id: root

    needs: root.flag("seconds", false) ? ["clock.seconds"] : []

    readonly property int hAlign: {
        const a = root.str("align", "center");
        return a === "left" ? Text.AlignLeft : a === "right" ? Text.AlignRight : Text.AlignHCenter;
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: -root.num("size", 168) * 0.06

        Txt {
            width: parent.width
            horizontalAlignment: root.hAlign
            text: {
                const s = `${Clock.hh(root.flag("hour12", false))}:${Clock.pad(Clock.minutes)}`;
                return root.flag("seconds", false) ? `${s}:${Clock.pad(Clock.seconds)}` : s;
            }
            font.pixelSize: root.num("size", 168)
            display: true
            font.weight: root.num("weight", 900)
            axisWidth: root.num("width", 38)
            font.letterSpacing: root.num("letterSpacing", -2)
            color: root.fg
            glow: root.flag("glow", true)
            elide: Text.ElideNone
        }

        Txt {
            visible: root.str("subtitle", "long") !== "none"
            width: parent.width
            horizontalAlignment: root.hAlign
            topPadding: root.num("size", 168) * 0.1
            text: {
                const mode = root.str("subtitle", "long");
                if (mode === "short")
                    return Clock.fmt("ddd d MMM").toUpperCase();
                return Clock.fmt("dddd, d MMMM");
            }
            font.pixelSize: Math.max(12, root.num("size", 168) * 0.11)
            font.weight: Font.Medium
            font.letterSpacing: Math.max(1, root.num("size", 168) * 0.02)
            axisWidth: 90
            color: root.muted
            glow: root.flag("glow", true)
        }
    }
}
