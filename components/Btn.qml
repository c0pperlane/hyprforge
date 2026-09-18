import QtQuick
import qs.config

// Icon button with an M3-ish state layer. Used by both the widgets and the
// editor chrome so hover/press feedback is identical everywhere.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property real iconSize: 20
    property real fill: 0
    property color colour: Theme.fgSurface
    property color hoverColour: root.colour
    property color background: "transparent"
    property real radius: height / 2
    property bool checked: false
    property bool enabled: true
    property bool flat: true
    property string tooltip: ""
    property real padding: 8

    signal clicked
    signal rightClicked

    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.containsPress

    implicitWidth: contentRow.implicitWidth + root.padding * 2
    implicitHeight: Math.max(root.iconSize + root.padding * 2, 28)

    opacity: root.enabled ? 1 : 0.38

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.checked ? Theme.alpha(root.hoverColour, 0.2) : root.background

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.alpha(root.hoverColour, root.pressed ? 0.18 : root.hovered ? 0.1 : 0)

        Behavior on color {
            ColorAnimation {
                duration: 130
            }
        }
    }

    Row {
        id: contentRow

        anchors.centerIn: parent
        spacing: root.icon && root.label ? 7 : 0

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.icon
            text: root.icon
            size: root.iconSize
            fill: root.checked ? 1 : root.fill
            color: root.checked ? root.hoverColour : root.colour
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.label
            text: root.label
            font.pixelSize: Math.max(11, root.iconSize * 0.62)
            font.weight: Font.Medium
            color: root.checked ? root.hoverColour : root.colour
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
    }

    scale: root.pressed ? 0.94 : 1

    Behavior on scale {
        NumberAnimation {
            duration: 110
            easing.type: Easing.OutCubic
        }
    }
}
