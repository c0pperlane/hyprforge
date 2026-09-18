import QtQuick
import qs.components
import qs.config

// Bottom strip: what's selected, transient status messages, and the shortcut
// hint that leads to the full cheatsheet.
Item {
    id: root

    property real zoom: 1

    signal helpToggled

    implicitWidth: pill.width
    implicitHeight: pill.height

    Rectangle {
        id: pill

        width: statusRow.implicitWidth + 28
        height: 38
        radius: 19
        color: Theme.alpha(Theme.surfaceContainer, 0.95)
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.5)

        Row {
            id: statusRow

            anchors.centerIn: parent
            spacing: 14

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: EditorState.hasSelection ? "check_box" : "select_all"
                    size: 15
                    color: EditorState.hasSelection ? Theme.primary : Theme.fgSurfaceVariant
                }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        const n = EditorState.selection.length;
                        if (n === 0)
                            return `${Store.countOn(EditorState.target)} elements`;
                        if (n === 1) {
                            const w = Store.get(EditorState.primary);
                            return w ? (Registry.def(w.type)?.name ?? w.type) : "1 selected";
                        }
                        return `${n} selected`;
                    }
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Theme.fgSurface
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 18
                color: Theme.alpha(Theme.outlineVariant, 0.5)
            }

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!EditorState.statusText
                text: EditorState.statusText
                font.pixelSize: 12
                color: Theme.primary
            }

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                visible: !EditorState.statusText
                text: Settings.snap.enabled ? `snap ${Settings.grid.size}px` : "free placement"
                font.pixelSize: 12
                color: Theme.fgSurfaceVariant
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 18
                color: Theme.alpha(Theme.outlineVariant, 0.5)
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "keyboard"
                label: "F1"
                iconSize: 15
                padding: 6
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: root.helpToggled()
            }
        }
    }
}
