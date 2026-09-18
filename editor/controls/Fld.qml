import QtQuick
import qs.components
import qs.config

// Single-line text field. Commits on Enter or focus loss, not per keystroke -
// otherwise every character would be its own undo step.
Item {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool mono: false

    signal committed(string value)
    signal edited(string value)

    implicitHeight: 32

    function setText(t: string): void {
        input.text = t;
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.bottomMargin: 1
        radius: 9
        color: Theme.alpha(Theme.fgSurface, input.activeFocus ? 0.12 : 0.07)
        border.width: input.activeFocus ? 1 : 0
        border.color: Theme.primary

        Behavior on color {
            ColorAnimation {
                duration: 130
            }
        }

        TextInput {
            id: input

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: Text.AlignVCenter
            font.family: root.mono ? Theme.mono : Theme.sans
            font.pixelSize: 12
            color: Theme.fgSurface
            selectionColor: Theme.primary
            selectedTextColor: Theme.fgPrimary
            selectByMouse: true
            clip: true

            text: root.value

            onTextEdited: root.edited(text)
            onEditingFinished: root.committed(text)
            Keys.onEscapePressed: {
                text = root.value;
                focus = false;
            }
        }

        Txt {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: !input.text && !input.activeFocus
            text: root.placeholder
            font.pixelSize: 12
            color: Theme.alpha(Theme.fgSurfaceVariant, 0.6)
        }
    }
}
