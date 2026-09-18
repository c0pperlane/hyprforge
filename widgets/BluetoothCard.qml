pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.config

// Paired bluetooth devices and their battery, where they report it.
//
// Bluez is event-driven over DBus, so there is nothing to poll and nothing to
// gate on a timer - the list is simply bound.
WidgetBase {
    id: root

    interactive: root.flag("clickToConnect", true)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: root.adapter?.enabled ?? false

    readonly property var devices: {
        const all = (Bluetooth.devices?.values ?? []).filter(d => root.flag("connectedOnly", false) ? d.connected : (d.paired || d.connected || d.bonded));
        // Connected first, then by name, so the useful ones are at the top.
        return all.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0) || (a.deviceName || a.name || "").localeCompare(b.deviceName || b.name || "")).slice(0, Math.max(1, Math.round(root.num("count", 4))));
    }

    Item {
        id: heading

        visible: root.flag("showTitle", true)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: visible ? 18 : 0

        Icon {
            id: headIcon

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.enabled ? "bluetooth" : "bluetooth_disabled"
            size: 14
            color: root.enabled ? root.accent : root.muted
        }

        Txt {
            anchors.left: headIcon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: root.enabled ? "Bluetooth" : "Bluetooth off"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            color: root.muted
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.topMargin: heading.visible ? 8 : 0
        spacing: root.num("spacing", 8)

        Repeater {
            model: root.devices

            Item {
                id: row

                required property var modelData

                width: parent.width
                height: root.num("size", 13) * 1.7

                Icon {
                    id: devIcon

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        const i = (row.modelData.icon ?? "").toLowerCase();
                        if (i.includes("headset") || i.includes("headphone"))
                            return "headphones";
                        if (i.includes("audio") || i.includes("speaker"))
                            return "speaker";
                        if (i.includes("mouse"))
                            return "mouse";
                        if (i.includes("keyboard"))
                            return "keyboard";
                        if (i.includes("phone"))
                            return "devices";
                        return "bluetooth";
                    }
                    size: root.num("size", 13) * 1.15
                    color: row.modelData.connected ? root.accent : root.muted
                }

                ListTxt {
                    anchors.left: devIcon.right
                    anchors.leftMargin: 8
                    anchors.right: batteryLabel.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.deviceName || row.modelData.name || row.modelData.address
                    font.pixelSize: root.num("size", 13)
                    font.weight: row.modelData.connected ? Font.Medium : Font.Normal
                    color: row.modelData.connected ? root.fg : root.muted
                    elide: Text.ElideRight
                }

                ListTxt {
                    id: batteryLabel

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.modelData.batteryAvailable && root.flag("showBattery", true)
                    text: `${Math.round((row.modelData.battery ?? 0) * 100)}%`
                    font.family: Theme.mono
                    font.pixelSize: root.num("size", 13) * 0.85
                    color: (row.modelData.battery ?? 1) < 0.2 ? Theme.error : root.muted
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.flag("clickToConnect", true) && !root.editing
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (row.modelData.connected)
                            row.modelData.disconnect();
                        else
                            row.modelData.connect();
                    }
                }
            }
        }

        ListTxt {
            visible: !root.devices.length
            text: root.enabled ? "No paired devices" : "Adapter is off"
            font.pixelSize: root.num("size", 13)
            color: root.muted
        }
    }
}
