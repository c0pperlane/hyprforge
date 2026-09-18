import QtQuick
import qs.components
import qs.config

// Collapsible group inside a panel.
Item {
    id: root

    property string title: ""
    property string icon: ""
    property bool expanded: true
    property int spacing: 10

    default property alias content: body.data

    implicitHeight: header.height + (root.expanded ? body.implicitHeight + 8 : 0)
    width: parent ? parent.width : 260
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: header

        width: parent.width
        height: 30

        Icon {
            id: chevron

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "chevron_right"
            size: 17
            color: Theme.fgSurfaceVariant
            rotation: root.expanded ? 90 : 0

            Behavior on rotation {
                NumberAnimation {
                    duration: 170
                    easing.type: Easing.OutCubic
                }
            }
        }

        Icon {
            id: leadIcon

            visible: !!root.icon
            anchors.left: chevron.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            size: 16
            color: Theme.primary
        }

        Txt {
            anchors.left: root.icon ? leadIcon.right : chevron.right
            anchors.leftMargin: 6
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.title.toUpperCase()
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1.3
            color: Theme.fgSurfaceVariant
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    Column {
        id: body

        anchors.top: header.bottom
        anchors.topMargin: 4
        width: parent.width
        spacing: root.spacing
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }
    }
}
