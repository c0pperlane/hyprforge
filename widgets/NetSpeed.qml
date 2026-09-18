import QtQuick
import qs.components
import qs.config
import qs.services

// Live throughput, up and down, with both curves on one plot.
WidgetBase {
    id: root

    needs: ["sys.net", "sys.history"]

    readonly property color downColour: root.colour("downColour", Theme.primary)
    readonly property color upColour: root.colour("upColour", Theme.tertiary)

    Item {
        id: values

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.num("valueSize", 22) * 1.6

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Row {
                spacing: 5

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "download"
                    size: root.num("valueSize", 22) * 0.65
                    color: root.downColour
                }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.metrics.netDown.text
                    font.family: Theme.mono
                    font.pixelSize: root.num("valueSize", 22)
                    font.weight: Font.Medium
                    color: root.fg
                }
            }
        }

        Column {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Row {
                spacing: 5

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "upload"
                    size: root.num("valueSize", 22) * 0.65
                    color: root.upColour
                }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.metrics.netUp.text
                    font.family: Theme.mono
                    font.pixelSize: root.num("valueSize", 22)
                    font.weight: Font.Medium
                    color: root.fg
                }
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
            points: Sys.historyFor("netDown")
            maxValue: 1
            colour: root.downColour
            fill: true
            thickness: 2
        }

        Spark {
            anchors.fill: parent
            points: Sys.historyFor("netUp")
            maxValue: 1
            colour: root.upColour
            fill: false
            thickness: 2
        }
    }
}
