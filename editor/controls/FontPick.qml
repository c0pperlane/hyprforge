pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import qs.components
import qs.config
import qs.services

// Font family picker. Nearly seven hundred families are installed here, so it
// is a search field over a list rather than a dropdown - and every row is drawn
// in its own face, because picking a font from a list of names set in one font
// is guesswork.
Item {
    id: root

    property string value: ""
    property string placeholder: "Default"
    property bool monoOnly: false

    signal picked(string family)

    implicitHeight: 32

    readonly property var results: Fonts.search(search.value, root.monoOnly)
    readonly property real popupHeight: 320

    Rectangle {
        id: field

        anchors.fill: parent
        anchors.topMargin: 1
        anchors.bottomMargin: 1
        radius: 9
        color: Theme.alpha(Theme.fgSurface, fieldArea.containsMouse ? 0.12 : 0.07)

        Behavior on color {
            ColorAnimation {
                duration: 130
            }
        }

        Txt {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: chev.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.value || root.placeholder
            font.family: root.value || Theme.sans
            font.pixelSize: 12
            color: root.value ? Theme.fgSurface : Theme.alpha(Theme.fgSurfaceVariant, 0.75)
            elide: Text.ElideRight
        }

        Icon {
            id: chev

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "expand_more"
            size: 18
            color: Theme.fgSurfaceVariant
            rotation: pop.open ? 180 : 0

            Behavior on rotation {
                NumberAnimation {
                    duration: 160
                }
            }
        }

        MouseArea {
            id: fieldArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                pop.open = !pop.open;
                if (pop.open)
                    search.forceFocus();
            }
        }
    }

    // Hosted outside this item - see Popover.
    Popover {
        id: pop

        anchorItem: field
        contentWidth: field.width
        contentHeight: root.popupHeight
        margin: 5

    Rectangle {
        id: popup

        anchors.fill: parent
        radius: 14
        color: Theme.surfaceContainerHighest
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.6)
        clip: true

        Fld {
            id: search

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            placeholder: root.monoOnly ? "Search monospace…" : "Search fonts…"

            function forceFocus(): void {
                value = "";
                setText("");
            }
        }

        Txt {
            id: countLabel

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: search.bottom
            anchors.margins: 10
            anchors.topMargin: 4
            text: `${root.results.length} famil${root.results.length === 1 ? "y" : "ies"}`
            font.pixelSize: 10
            color: Theme.fgSurfaceVariant
        }

        ListView {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: countLabel.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 6
            anchors.topMargin: 2
            clip: true
            model: root.results
            // Only the visible rows load their face; asking Qt to open several
            // hundred fonts at once to draw a list is not a good trade.
            cacheBuffer: 200

            delegate: Rectangle {
                required property string modelData

                width: ListView.view.width
                height: 34
                radius: 8
                color: rowArea.containsMouse ? Theme.alpha(Theme.primary, 0.16) : "transparent"

                Txt {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: checkIcon.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.modelData
                    font.family: parent.modelData
                    font.pixelSize: 13
                    color: parent.modelData === root.value ? Theme.primary : Theme.fgSurface
                    elide: Text.ElideRight
                }

                Icon {
                    id: checkIcon

                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: parent.modelData === root.value
                    text: "check"
                    size: 15
                    color: Theme.primary
                }

                MouseArea {
                    id: rowArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.picked(parent.modelData);
                        pop.open = false;
                    }
                }
            }
        }
    }
    }
}
