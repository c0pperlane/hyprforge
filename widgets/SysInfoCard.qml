import QtQuick
import qs.components
import qs.config
import qs.services

// Neofetch, but a desktop widget.
WidgetBase {
    id: root

    needs: {
        const out = ["sys.host"];
        const wanted = root.lines("rows");
        if (wanted.indexOf("cpu") >= 0)
            out.push("sys.cpu");
        if (wanted.indexOf("gpu") >= 0)
            out.push("sys.gpu");
        if (wanted.indexOf("fans") >= 0 || wanted.indexOf("power") >= 0)
            out.push("sys.power");
        return out;
    }

    readonly property var rows: {
        const l = root.lines("rows");
        return (l.length ? l : ["host", "kernel", "uptime"]).map(k => Sys.infoRow(k));
    }

    Row {
        anchors.fill: parent
        spacing: 14

        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.flag("showLogo", true)
            width: visible ? Math.min(72, parent.height * 0.8) : 0
            height: width

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.alpha(root.accent, 0.16)
            }

            Icon {
                anchors.centerIn: parent
                text: "desktop_windows"
                size: parent.width * 0.45
                color: root.accent
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (root.flag("showLogo", true) ? Math.min(72, root.height * 0.8) + 14 : 0)
            spacing: 5

            Txt {
                width: parent.width
                text: Sys.osPretty || "Linux"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: root.fg
            }

            Repeater {
                model: root.rows

                Item {
                    required property var modelData

                    width: parent.width
                    height: 17

                    ListTxt {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.num("labelWidth", 92)
                        text: modelData.label
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: root.accent
                    }

                    ListTxt {
                        anchors.left: parent.left
                        anchors.leftMargin: root.num("labelWidth", 92)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.value
                        font.family: Theme.mono
                        font.pixelSize: 12
                        color: root.muted
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
