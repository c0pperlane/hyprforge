import QtQuick
import qs.components
import qs.config
import qs.services

// Time remaining until a target instant.
WidgetBase {
    id: root

    needs: root.str("units", "dhm").includes("s") ? ["clock.seconds"] : []

    readonly property var remaining: {
        const raw = root.str("target", "").trim().replace("T", " ");
        const target = new Date(raw.includes(" ") ? raw : `${raw} 00:00`);
        if (isNaN(target.getTime()))
            return null;
        let ms = target.getTime() - Clock.now.getTime();
        const past = ms < 0;
        ms = Math.abs(ms);
        return {
            past: past,
            d: Math.floor(ms / 86400000),
            h: Math.floor(ms / 3600000) % 24,
            m: Math.floor(ms / 60000) % 60,
            s: Math.floor(ms / 1000) % 60
        };
    }

    readonly property var parts: {
        const r = root.remaining;
        if (!r)
            return [];
        const mode = root.str("units", "dhm");
        const out = [
            {
                v: r.d,
                l: "days"
            }
        ];
        if (mode.includes("h"))
            out.push({
                v: r.h,
                l: "hrs"
            });
        if (mode.includes("m"))
            out.push({
                v: r.m,
                l: "min"
            });
        if (mode.includes("s"))
            out.push({
                v: r.s,
                l: "sec"
            });
        return out;
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Txt {
            width: parent.width
            text: root.str("title", "Countdown")
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.letterSpacing: 1.4
            color: root.accent
        }

        Row {
            spacing: 18

            Repeater {
                model: root.parts

                Column {
                    required property var modelData

                    spacing: -2

                    Txt {
                        text: `${modelData.v}`
                        font.pixelSize: 40
                        font.weight: Font.Bold
                        axisWidth: 70
                        color: root.fg
                    }

                    Txt {
                        text: modelData.l
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.letterSpacing: 1
                        color: root.muted
                    }
                }
            }
        }

        Txt {
            visible: !root.remaining || root.remaining.past
            width: parent.width
            text: root.remaining ? "already passed" : "set a valid target date"
            font.pixelSize: 11
            color: root.muted
        }
    }
}
