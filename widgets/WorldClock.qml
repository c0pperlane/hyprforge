import QtQuick
import qs.components
import qs.config
import qs.services

// Cities and their local time. Offsets are given explicitly ("Berlin|2")
// rather than via tz database names, because QML's Date has no tz support -
// this keeps the widget honest about what it can actually do.
WidgetBase {
    id: root

    readonly property var zones: {
        void Clock.minutes;   // per minute is enough; seconds would pin the clock awake
        const utc = Clock.now.getTime() + Clock.now.getTimezoneOffset() * 60000;
        return root.lines("zones").map(l => {
            const parts = l.split("|");
            const off = parseFloat(parts[1] ?? "0") || 0;
            const d = new Date(utc + off * 3600000);
            return {
                label: (parts[0] ?? "").trim(),
                time: `${Clock.pad(d.getHours())}:${Clock.pad(d.getMinutes())}`,
                night: d.getHours() < 7 || d.getHours() >= 20,
                offset: off
            };
        });
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.str("orientation", "row") === "row" ? rowLayout : colLayout
    }

    Component {
        id: rowLayout

        Row {
            spacing: 22

            Repeater {
                model: root.zones

                Column {
                    required property var modelData

                    spacing: 1

                    Row {
                        spacing: 5

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.night ? "dark_mode" : "light_mode"
                            size: Math.max(10, root.num("size", 30) * 0.42)
                            color: root.accent
                        }

                        ListTxt {
                            text: modelData.label.toUpperCase()
                            font.pixelSize: Math.max(9, root.num("size", 30) * 0.36)
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                            color: root.muted
                        }
                    }

                    ListTxt {
                        text: modelData.time
                        font.pixelSize: root.num("size", 30)
                        font.weight: Font.Medium
                        axisWidth: 75
                        color: root.fg
                    }
                }
            }
        }
    }

    Component {
        id: colLayout

        Column {
            width: parent.width
            spacing: 8

            Repeater {
                model: root.zones

                Item {
                    required property var modelData

                    width: parent.width
                    height: root.num("size", 30) * 1.15

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.night ? "dark_mode" : "light_mode"
                            size: Math.max(10, root.num("size", 30) * 0.5)
                            color: root.accent
                        }

                        ListTxt {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            font.pixelSize: Math.max(10, root.num("size", 30) * 0.5)
                            font.weight: Font.Medium
                            color: root.muted
                        }
                    }

                    ListTxt {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.time
                        font.pixelSize: root.num("size", 30)
                        font.weight: Font.Medium
                        axisWidth: 75
                        color: root.fg
                    }
                }
            }
        }
    }
}
