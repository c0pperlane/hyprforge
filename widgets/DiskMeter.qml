import QtQuick
import qs.components
import qs.config
import qs.services

// Disk read/write throughput, with history.
WidgetBase {
    id: root

    needs: ["sys.diskio", "sys.history"]

    readonly property color readColour: root.colour("readColour", Theme.primary)
    readonly property color writeColour: root.colour("writeColour", Theme.tertiary)

    Item {
        id: values

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.num("valueSize", 20) * 1.6

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: "download"
                size: root.num("valueSize", 20) * 0.65
                color: root.readColour
            }

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: Sys.metrics.diskRead.text
                font.family: Theme.mono
                font.pixelSize: root.num("valueSize", 20)
                font.weight: Font.Medium
                color: root.fg
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: "upload"
                size: root.num("valueSize", 20) * 0.65
                color: root.writeColour
            }

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: Sys.metrics.diskWrite.text
                font.family: Theme.mono
                font.pixelSize: root.num("valueSize", 20)
                font.weight: Font.Medium
                color: root.fg
            }
        }
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: values.bottom
        anchors.topMargin: 6
        anchors.bottom: parent.bottom
        visible: root.flag("graph", true)

        Spark {
            anchors.fill: parent
            points: Sys.historyFor("diskRead")
            maxValue: 1
            colour: root.readColour
            fill: true
            thickness: root.num("thickness", 2)
        }

        Spark {
            anchors.fill: parent
            points: Sys.historyFor("diskWrite")
            maxValue: 1
            colour: root.writeColour
            fill: false
            thickness: root.num("thickness", 2)
        }
    }
}
