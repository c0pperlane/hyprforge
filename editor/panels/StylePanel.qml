pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.components
import qs.config
import qs.editor
import qs.editor.controls

// Style presets.
//
// Picking one makes it the active style (what newly placed elements get) and,
// if anything is selected, restyles that selection straight away. The buttons
// underneath cover the two bulk cases: everything on this display, or just the
// selection if you picked the style before making one.
FloatingPanel {
    id: root

    readonly property string active: Settings.style.preset

    function choose(id: string): void {
        Settings.style.preset = id;
        Settings.save();

        if (EditorState.hasSelection) {
            const n = Presets.applyTo(EditorState.selection, id);
            EditorState.status(`${Presets.get(id).name} · ${n} element${n === 1 ? "" : "s"}`);
        } else {
            EditorState.status(`${Presets.get(id).name} · new elements`);
        }
    }

    title: "Styles"
    icon: "palette"

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 6
        anchors.bottomMargin: 12
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col

            width: parent.width
            spacing: 10

            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 9
                rowSpacing: 9

                Repeater {
                    model: Presets.presets

                    Item {
                        id: card

                        required property var modelData

                        readonly property bool isActive: modelData.id === root.active
                        readonly property var pp: modelData.props

                        width: (col.width - 9) / 2
                        height: 112

                        // Live preview: the same Surface component the widgets
                        // use, fed the preset's own props - so what you see is
                        // literally what gets applied. The shadow itself is
                        // applied here rather than inside Surface, matching
                        // WidgetBase: it needs to be layered around the thing
                        // that is meant to cast it, and here that is this
                        // preview swatch, not a component of its own.
                        Item {
                            id: previewShadow

                            anchors.fill: parent
                            anchors.bottomMargin: 22

                            readonly property bool glow: card.pp.shadowMode === "glow"

                            layer.enabled: (card.pp.shadowMode ?? "none") !== "none"
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Theme.alpha(Theme.resolve(card.pp.shadowColour, Theme.shadow), card.pp.shadowOpacity ?? 0.45)
                                shadowBlur: card.pp.shadowBlur ?? 0.9
                                shadowHorizontalOffset: previewShadow.glow ? 0 : Math.cos((card.pp.shadowAngle ?? 90) * Math.PI / 180) * (card.pp.shadowDistance ?? 6)
                                shadowVerticalOffset: previewShadow.glow ? 0 : Math.sin((card.pp.shadowAngle ?? 90) * Math.PI / 180) * (card.pp.shadowDistance ?? 6)
                                shadowScale: 1 + (previewShadow.glow ? (card.pp.shadowSpread ?? 0) * 0.6 : 0)
                                // See the matching comment in WidgetBase.qml -
                                // without this, a preset preview's own shadow
                                // bleeds onto the next card in the grid.
                                autoPaddingEnabled: false
                            }

                            Surface {
                                anchors.fill: parent
                                mode: card.pp.bg
                                colour: Theme.resolve(card.pp.bgColour, Theme.surfaceContainer)
                                fillOpacity: card.pp.bgOpacity
                                radius: Math.min(card.pp.radius, 26)
                                border: card.pp.border
                                borderColour: Theme.resolve(card.pp.borderColour, Theme.outlineVariant)
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 3

                            Row {
                                spacing: 5

                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "schedule"
                                    size: 13
                                    color: Theme.resolve(card.pp.accent, Theme.primary)
                                }

                                Txt {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "09:24"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    color: Theme.resolve(card.pp.fg, Theme.fgSurface)
                                }
                            }

                            Txt {
                                text: "Tuesday"
                                font.pixelSize: 10
                                color: Theme.resolve(card.pp.muted, Theme.fgSurfaceVariant)
                            }

                            Rectangle {
                                width: parent.width * 0.62
                                height: 4
                                radius: 2
                                color: Theme.resolve(card.pp.accent, Theme.primary)
                            }
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            spacing: 4

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: card.isActive
                                text: "check_circle"
                                size: 13
                                fill: 1
                                color: Theme.primary
                            }

                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - (card.isActive ? 17 : 0)
                                text: card.modelData.name
                                font.pixelSize: 11
                                font.weight: card.isActive ? Font.DemiBold : Font.Normal
                                color: card.isActive ? Theme.primary : Theme.fgSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.bottomMargin: 22
                            radius: Math.min(card.pp.radius, 26)
                            color: "transparent"
                            border.width: card.isActive ? 2 : cardArea.containsMouse ? 1 : 0
                            border.color: card.isActive ? Theme.primary : Theme.alpha(Theme.primary, 0.5)
                        }

                        MouseArea {
                            id: cardArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.choose(card.modelData.id)
                        }
                    }
                }
            }

            Txt {
                width: parent.width
                text: Presets.get(root.active).blurb
                font.pixelSize: 11
                color: Theme.fgSurfaceVariant
                wrapMode: Text.Wrap
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.alpha(Theme.outlineVariant, 0.5)
            }

            Row {
                width: parent.width
                spacing: 8

                Btn {
                    icon: "check_box"
                    label: "Selection"
                    iconSize: 15
                    padding: 10
                    radius: 11
                    enabled: EditorState.hasSelection
                    colour: Theme.fgSurfaceVariant
                    hoverColour: Theme.primary
                    background: Theme.alpha(Theme.fgSurface, 0.06)
                    onClicked: {
                        const n = Presets.applyTo(EditorState.selection, root.active);
                        EditorState.status(`Restyled ${n} element${n === 1 ? "" : "s"}`);
                    }
                }

                Btn {
                    icon: "select_all"
                    label: "Whole display"
                    iconSize: 15
                    padding: 10
                    radius: 11
                    colour: Theme.fgSurfaceVariant
                    hoverColour: Theme.primary
                    background: Theme.alpha(Theme.fgSurface, 0.06)
                    onClicked: {
                        const n = Presets.applyToScreen(EditorState.target, root.active);
                        EditorState.status(`Restyled ${n} element${n === 1 ? "" : "s"}`);
                    }
                }
            }

            Section {
                title: "Rendering"
                icon: "text_fields"

                Row2 {
                    label: "Text"
                    labelWidth: 0.34

                    Sel {
                        width: parent.width
                        options: [
                            {
                                value: "smooth",
                                label: "Smooth"
                            },
                            {
                                value: "crisp",
                                label: "Crisp"
                            }
                        ]
                        value: Settings.appearance.textRendering
                        onPicked: v => {
                            Settings.appearance.textRendering = v;
                            Settings.save();
                        }
                    }
                }

                Row2 {
                    label: "Smooth images"

                    Sw {
                        width: parent.width
                        checked: Settings.appearance.smoothImages
                        onToggled: v => {
                            Settings.appearance.smoothImages = v;
                            Settings.save();
                        }
                    }
                }

                Row2 {
                    label: "Mipmaps"

                    Sw {
                        width: parent.width
                        checked: Settings.appearance.mipmaps
                        onToggled: v => {
                            Settings.appearance.mipmaps = v;
                            Settings.save();
                        }
                    }
                }

                Row2 {
                    label: "New elements use this style"
                    stacked: true

                    Sw {
                        width: parent.width
                        checked: Settings.style.applyToNew
                        onToggled: v => {
                            Settings.style.applyToNew = v;
                            Settings.save();
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 10
            }
        }
    }
}
