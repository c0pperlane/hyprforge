import QtQuick
import qs.components
import qs.config
import qs.services

// Charge state, three ways.
WidgetBase {
    id: root

    readonly property real level: Sys.batteryLevel
    readonly property bool plugged: Sys.plugged
    readonly property color tint: root.plugged ? Theme.success : root.level < 0.15 ? Theme.error : root.accent
    readonly property string style: root.str("style", "ring")

    // Sized off the widget itself. It used to be Math.min(parent.height, ...)
    // with the Row as parent - but a Row takes its height *from* its children,
    // so the ring's size depended on the ring's size. It collapsed, and the
    // text column slid underneath it.
    readonly property real ringSize: Math.max(28, Math.min(root.height - root.pad * 2, root.width * 0.42))

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "ring"
            width: visible ? root.ringSize : 0
            height: root.ringSize

            Ring {
                anchors.fill: parent
                value: root.level
                thickness: Math.max(4, width * 0.11)
                colour: root.tint
                trackColour: Theme.alpha(root.tint, 0.16)
            }

            Icon {
                anchors.centerIn: parent
                text: root.plugged ? "bolt" : "battery_full"
                size: parent.width * 0.32
                fill: root.plugged ? 1 : 0
                color: root.tint
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "pill"
            width: visible ? 54 : 0
            height: 26

            Rectangle {
                anchors.fill: parent
                anchors.rightMargin: 5
                radius: 8
                color: "transparent"
                border.width: 2
                border.color: Theme.alpha(root.fg, 0.45)

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 4
                    width: Math.max(3, (parent.width - 8) * root.level)
                    radius: 4
                    color: root.tint
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 4
                height: 10
                radius: 2
                color: Theme.alpha(root.fg, 0.45)
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Row {
                spacing: 6

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.hasBattery ? `${Math.round(root.level * 100)}%` : "—"
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                    axisWidth: 80
                    color: root.fg
                }

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.plugged && root.style !== "ring"
                    text: "bolt"
                    size: 17
                    fill: 1
                    color: Theme.success
                }
            }

            Txt {
                visible: root.flag("showTime", true)
                text: Sys.batteryState
                font.pixelSize: 12
                color: root.muted
            }

            Txt {
                visible: root.flag("showPower", true) && Sys.changeRate > 0
                text: `${Sys.changeRate.toFixed(1)} W`
                font.family: Theme.mono
                font.pixelSize: 11
                color: Theme.alpha(root.muted, 0.85)
            }
        }
    }

    Meter {
        visible: root.style === "bar"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        value: root.level
        thickness: 8
        colour: root.tint
        trackColour: Theme.alpha(root.fg, 0.12)
    }
}
