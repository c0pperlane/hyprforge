import QtQuick
import qs.components
import qs.config

// Free text with the full type scale exposed.
WidgetBase {
    id: root

    readonly property int hAlign: {
        const a = root.str("align", "left");
        return a === "center" ? Text.AlignHCenter : a === "right" ? Text.AlignRight : Text.AlignLeft;
    }

    Txt {
        anchors.fill: parent
        text: {
            const t = root.str("text", "");
            return root.flag("uppercase", false) ? t.toUpperCase() : t;
        }
        font.pixelSize: root.num("size", 34)
        font.weight: root.num("weight", 500)
        font.letterSpacing: root.num("letterSpacing", 0)
        axisWidth: root.num("width", 100)
        mono: root.flag("mono", false)
        lineHeight: root.num("lineHeight", 1)
        lineHeightMode: Text.ProportionalHeight
        horizontalAlignment: root.hAlign
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        color: root.fg
        glow: root.flag("glow", false)
    }
}
