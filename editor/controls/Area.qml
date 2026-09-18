import QtQuick
import qs.components
import qs.config

// Multi-line editor, used for note bodies and newline-separated lists.
Item {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool mono: false
    property int rows: 5

    signal committed(string value)

    implicitHeight: root.rows * 18 + 20

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.alpha(Theme.fgSurface, edit.activeFocus ? 0.12 : 0.07)
        border.width: edit.activeFocus ? 1 : 0
        border.color: Theme.primary
        clip: true

        Flickable {
            anchors.fill: parent
            anchors.margins: 9
            contentWidth: width
            contentHeight: edit.implicitHeight
            clip: true
            interactive: contentHeight > height

            TextEdit {
                id: edit

                width: parent.width
                wrapMode: TextEdit.Wrap
                font.family: root.mono ? Theme.mono : Theme.sans
                font.pixelSize: 12
                color: Theme.fgSurface
                selectionColor: Theme.primary
                selectedTextColor: Theme.fgPrimary
                selectByMouse: true

                text: root.value

                // Commit on focus loss so typing stays fluid but the document
                // still gets one clean undo entry per edit session.
                onActiveFocusChanged: {
                    if (!activeFocus && text !== root.value)
                        root.committed(text);
                }
            }
        }

        Txt {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 9
            visible: !edit.text && !edit.activeFocus
            text: root.placeholder
            font.pixelSize: 12
            color: Theme.alpha(Theme.fgSurfaceVariant, 0.6)
        }
    }
}
