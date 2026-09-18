pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

// Network interfaces and their addresses.
WidgetBase {
    id: root

    needs: ["sys.netif"]

    readonly property var rows: {
        const all = Sys.interfaces ?? [];
        const shown = root.flag("upOnly", true) ? all.filter(i => i.up) : all;
        return shown.slice(0, Math.max(1, Math.round(root.num("count", 3))));
    }

    function iconFor(name: string): string {
        if (/^(wl|wlan|wlp)/.test(name))
            return "wifi";
        if (/^(en|eth|eno|enp)/.test(name))
            return "lan";
        if (/^(tun|wg|tap|proton|mullvad)/.test(name))
            return "vpn_lock";
        if (/^(docker|br-|virbr)/.test(name))
            return "hub";
        return "settings_ethernet";
    }

    Item {
        id: heading

        visible: root.flag("showTitle", true)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: visible ? 17 : 0

        Txt {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "NETWORK"
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            color: root.muted
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.topMargin: heading.visible ? 8 : 0
        spacing: root.num("spacing", 10)

        Repeater {
            model: root.rows

            Item {
                required property var modelData

                width: parent.width
                height: root.num("size", 13) * (root.flag("showAddress", true) ? 2.2 : 1.4)

                Icon {
                    id: ifIcon

                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: root.iconFor(parent.modelData.name)
                    size: root.num("size", 13) * 1.2
                    color: parent.modelData.up ? root.accent : root.muted
                }

                ListTxt {
                    anchors.left: ifIcon.right
                    anchors.leftMargin: 8
                    anchors.top: parent.top
                    anchors.right: stateLabel.left
                    anchors.rightMargin: 6
                    text: parent.modelData.name
                    font.pixelSize: root.num("size", 13)
                    font.weight: Font.Medium
                    color: parent.modelData.up ? root.fg : root.muted
                    elide: Text.ElideRight
                }

                ListTxt {
                    id: stateLabel

                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: parent.modelData.state
                    font.pixelSize: root.num("size", 13) * 0.8
                    color: parent.modelData.up ? root.accent : root.muted
                }

                ListTxt {
                    visible: root.flag("showAddress", true)
                    anchors.left: ifIcon.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: parent.modelData.v4 || parent.modelData.v6 || "no address"
                    font.family: Theme.mono
                    font.pixelSize: root.num("size", 13) * 0.82
                    color: root.muted
                    elide: Text.ElideRight
                }
            }
        }

        ListTxt {
            visible: !root.rows.length
            text: "No interfaces up"
            font.pixelSize: root.num("size", 13)
            color: root.muted
        }
    }
}
