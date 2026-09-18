pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.editor
import qs.editor.controls

// The element library. Click a card to drop it in the middle of the view, or
// drag it onto the exact spot you want.
FloatingPanel {
    id: root

    property string query: ""
    property string category: "All"

    signal addRequested(string type)
    signal dragBegan(string type)
    signal dragMoved(real gx, real gy)
    signal dropped(string type, real gx, real gy)
    signal dragEnded

    readonly property var filtered: {
        const base = Registry.search(root.query);
        return root.category === "All" ? base : base.filter(d => d.category === root.category);
    }

    title: "Library"
    icon: "widgets"

    Column {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 10
        anchors.bottomMargin: 12
        spacing: 10

        Fld {
            width: parent.width
            placeholder: "Search elements…"
            value: root.query
            onEdited: v => root.query = v
        }

        Flickable {
            width: parent.width
            height: 30
            contentWidth: chips.implicitWidth
            flickableDirection: Flickable.HorizontalFlick
            clip: true

            Row {
                id: chips

                spacing: 6

                Repeater {
                    model: ["All"].concat(Registry.categories)

                    Rectangle {
                        required property string modelData

                        readonly property bool active: modelData === root.category

                        width: chipLabel.implicitWidth + 22
                        height: 28
                        radius: 14
                        color: active ? Theme.primary : Theme.alpha(Theme.fgSurface, 0.07)

                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }
                        }

                        Txt {
                            id: chipLabel

                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: parent.active ? Theme.fgPrimary : Theme.fgSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.category = modelData
                        }
                    }
                }
            }
        }

        Flickable {
            width: parent.width
            height: parent.height - y
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list

                width: parent.width
                spacing: 6

                Repeater {
                    model: root.filtered

                    Rectangle {
                        id: card

                        required property var modelData

                        width: list.width
                        height: 58
                        radius: 14
                        color: cardArea.containsMouse ? Theme.alpha(Theme.primary, 0.14) : Theme.alpha(Theme.fgSurface, 0.045)

                        Behavior on color {
                            ColorAnimation {
                                duration: 130
                            }
                        }

                        Rectangle {
                            id: cardIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38
                            height: 38
                            radius: 12
                            color: Theme.alpha(Theme.primary, 0.18)

                            Icon {
                                anchors.centerIn: parent
                                text: card.modelData.icon
                                size: 20
                                color: Theme.primary
                            }
                        }

                        Column {
                            anchors.left: cardIcon.right
                            anchors.leftMargin: 11
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Txt {
                                width: parent.width
                                text: card.modelData.name
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.fgSurface
                            }

                            Txt {
                                width: parent.width
                                text: card.modelData.blurb
                                font.pixelSize: 11
                                color: Theme.fgSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: cardArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                            property bool dragging: false
                            property real pressGX: 0
                            property real pressGY: 0

                            function globalPos(mx: real, my: real): var {
                                return cardArea.mapToItem(null, mx, my);
                            }

                            onPressed: mouse => {
                                const g = globalPos(mouse.x, mouse.y);
                                cardArea.pressGX = g.x;
                                cardArea.pressGY = g.y;
                                cardArea.dragging = false;
                            }

                            onPositionChanged: mouse => {
                                if (!pressed)
                                    return;
                                const g = globalPos(mouse.x, mouse.y);
                                if (!cardArea.dragging) {
                                    // Small threshold so a slightly shaky click
                                    // still counts as a click.
                                    if (Math.abs(g.x - cardArea.pressGX) < 6 && Math.abs(g.y - cardArea.pressGY) < 6)
                                        return;
                                    cardArea.dragging = true;
                                    root.dragBegan(card.modelData.type);
                                }
                                root.dragMoved(g.x, g.y);
                            }

                            onReleased: mouse => {
                                if (cardArea.dragging) {
                                    const g = globalPos(mouse.x, mouse.y);
                                    root.dropped(card.modelData.type, g.x, g.y);
                                    root.dragEnded();
                                    cardArea.dragging = false;
                                } else {
                                    root.addRequested(card.modelData.type);
                                }
                            }

                            onCanceled: {
                                cardArea.dragging = false;
                                root.dragEnded();
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: root.filtered.length ? 0 : 90
                    visible: !root.filtered.length

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "search_off"
                            size: 26
                            color: Theme.fgSurfaceVariant
                        }

                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Nothing matches"
                            font.pixelSize: 12
                            color: Theme.fgSurfaceVariant
                        }
                    }
                }
            }
        }
    }
}
