import QtQuick
import qs.components
import qs.config

// A scratchpad. The text lives in the widget's own props, so it travels with
// the layout and is editable from the Inspector too.
WidgetBase {
    id: root

    interactive: true
    textInput: true
    textFocused: editor.activeFocus

    function releaseFocus(): void {
        editor.focus = false;
    }

    Txt {
        id: title

        visible: !!root.str("title", "")
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.str("title", "")
        font.pixelSize: Math.max(11, root.num("size", 14) * 0.92)
        font.weight: Font.Bold
        font.letterSpacing: 1.2
        color: root.accent
    }

    Flickable {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.visible ? title.bottom : parent.top
        anchors.topMargin: title.visible ? 8 : 0
        anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: editor.implicitHeight
        clip: true
        interactive: contentHeight > height

        TextEdit {
            id: editor

            // Without this the field only takes focus when the click lands on
            // a glyph; on an empty note there are none, so it felt dead.
            activeFocusOnPress: true

            // Escape is the other obvious way to stop editing.
            Keys.onEscapePressed: editor.focus = false

            width: parent.width
            text: root.str("text", "")
            wrapMode: TextEdit.Wrap
            font.family: root.flag("mono", false) ? Theme.mono : Theme.sans
            font.pixelSize: root.num("size", 14)
            color: root.fg
            selectionColor: root.accent
            selectedTextColor: Theme.contrast(root.accent)
            selectByMouse: !root.editing
            readOnly: root.editing
            renderType: Text.NativeRendering

            // Written back on focus loss rather than per keystroke: one undo
            // entry per editing session instead of one per character.
            onActiveFocusChanged: {
                if (!activeFocus && text !== root.str("text", ""))
                    root.writeProp("text", text);
            }
        }
    }

    Txt {
        anchors.centerIn: parent
        visible: !editor.text && !editor.activeFocus
        text: root.editing ? "Type here once you're out of the editor" : "Click to write"
        font.pixelSize: root.num("size", 14)
        color: Theme.alpha(root.muted, 0.65)
    }

    // A click anywhere on the card lands the caret in the text, not only a
    // click that happens to hit a glyph. Sits behind the TextEdit so ordinary
    // selection and caret placement still work.
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: !root.editing
        cursorShape: Qt.IBeamCursor
        onClicked: {
            editor.forceActiveFocus();
            editor.cursorPosition = editor.length;
        }
    }
}
