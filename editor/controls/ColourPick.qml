import QtQuick
import QtQuick.Window
import qs.components
import qs.config

// Colour editor. A swatch opens a palette of the live M3 roles plus a hex
// field - picking a role keeps the widget following the wallpaper scheme,
// typing a hex pins it.
Item {
    id: root

    property string value: "primary"
    readonly property color resolved: Theme.resolve(root.value, Theme.primary)
    readonly property bool custom: root.value.charAt(0) === "#"
    readonly property real popupHeight: grid.implicitHeight + hexField.height + 28

    signal picked(string value)

    implicitHeight: 32

    Rectangle {
        id: chip

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(parent.width, 150)
        height: 30
        radius: 9
        color: Theme.alpha(Theme.fgSurface, chipArea.containsMouse ? 0.12 : 0.07)

        Rectangle {
            id: swatch

            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 7
            color: root.resolved
            border.width: 1
            border.color: Theme.alpha(Theme.fgSurface, 0.2)
        }

        Txt {
            anchors.left: swatch.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.value
            font.pixelSize: 11
            font.family: root.custom ? Theme.mono : Theme.sans
            color: Theme.fgSurface
            elide: Text.ElideMiddle
        }

        MouseArea {
            id: chipArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pop.open = !pop.open
        }

    }

    // Hosted outside this item - see Popover: the Inspector clips in two
    // places, and a picker drawn inside them comes out sliced off.
    Popover {
        id: pop

        anchorItem: chip
        alignRight: true
        contentWidth: 236
        contentHeight: root.popupHeight
        margin: 6

        Rectangle {
            id: popup

            anchors.fill: parent
            radius: 14
            color: Theme.surfaceContainerHighest
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, 0.6)

            Grid {
                id: grid

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                columns: 7
                spacing: 6

                Repeater {
                    model: Theme.roles

                    Rectangle {
                        required property string modelData

                        width: 26
                        height: 26
                        radius: 8
                        color: Theme.resolve(modelData, Theme.primary)
                        border.width: modelData === root.value ? 2 : 1
                        border.color: modelData === root.value ? Theme.fgSurface : Theme.alpha(Theme.fgSurface, 0.18)

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.picked(modelData);
                                pop.open = false;
                            }
                        }

                    }

                }

            }

            Fld {
                id: hexField

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10
                mono: true
                placeholder: "#rrggbb"
                value: root.custom ? root.value : ""
                onCommitted: (v) => {
                    const t = v.trim();
                    if (/^#[0-9a-fA-F]{6}$/.test(t)) {
                        root.picked(t);
                        pop.open = false;
                    }
                }
            }

        }

    }

}
