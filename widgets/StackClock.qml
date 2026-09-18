import QtQuick
import qs.components
import qs.config
import qs.services

// Hours stacked over minutes, poster-style, with an optional accent rule.
WidgetBase {
    id: root

    readonly property real glyph: root.num("size", 150)

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: -root.glyph * 0.18

        Txt {
            text: Clock.hh(root.flag("hour12", false))
            font.pixelSize: root.glyph
            display: true
            font.weight: root.num("weight", 750)
            axisWidth: root.num("width", 32)
            color: root.fg
            elide: Text.ElideNone
        }

        Txt {
            text: Clock.pad(Clock.minutes)
            font.pixelSize: root.glyph
            display: true
            font.weight: root.num("weight", 750)
            axisWidth: root.num("width", 32)
            color: root.accent
            elide: Text.ElideNone
        }

        Item {
            width: parent.width
            height: root.glyph * 0.22
        }
    }

    Rectangle {
        visible: root.flag("rule", true)
        anchors.left: parent.left
        anchors.bottom: caption.visible ? caption.top : parent.bottom
        anchors.bottomMargin: 10
        width: Math.min(parent.width, root.glyph * 0.55)
        height: 3
        radius: 2
        color: root.accent
    }

    Txt {
        id: caption

        visible: !!root.str("label", "")
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: root.str("label", "").toUpperCase()
        font.pixelSize: Math.max(10, root.glyph * 0.09)
        font.weight: Font.DemiBold
        font.letterSpacing: 2
        color: root.muted
    }
}
