import QtQuick
import qs.config

// M3-style switch.
Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 46
    implicitHeight: 28

    Rectangle {
        id: track

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 46
        height: 28
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.alpha(Theme.fgSurface, 0.1)
        border.width: root.checked ? 0 : 1.5
        border.color: Theme.outline

        Behavior on color {
            ColorAnimation {
                duration: 170
            }
        }

        Rectangle {
            id: knob

            y: (parent.height - height) / 2
            x: root.checked ? parent.width - width - 4 : 6
            width: root.checked ? 20 : 14
            height: width
            radius: width / 2
            color: root.checked ? Theme.fgPrimary : Theme.outline

            Behavior on x {
                NumberAnimation {
                    duration: 190
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.4
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: 150
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 170
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }
}
