import QtQuick
import qs.components
import qs.config
import qs.editor
import qs.editor.controls

// Grid, snapping and canvas behaviour. Writes straight through to
// settings.json, so these are preferences rather than document state.
FloatingPanel {
    id: root

    signal snapSelectionRequested
    signal snapAllRequested

    title: "Canvas"
    icon: "settings_overscan"

    function save(): void {
        Settings.save();
    }

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
            spacing: 4

            Section {
                title: "Grid"
                icon: "grid_4x4"

                Row2 {
                    label: "Show grid"

                    Sw {
                        width: parent.width
                        checked: Settings.grid.visible
                        onToggled: v => {
                            Settings.grid.visible = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Cell size"
                    labelWidth: 0.4

                    Sld {
                        width: parent.width
                        from: 4
                        to: 160
                        step: 2
                        value: Settings.grid.size
                        onMoved: v => {
                            Settings.grid.size = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Subdivisions"
                    labelWidth: 0.4

                    Sld {
                        width: parent.width
                        from: 1
                        to: 8
                        step: 1
                        value: Settings.grid.subdivisions
                        onMoved: v => {
                            Settings.grid.subdivisions = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Opacity"
                    labelWidth: 0.4

                    Sld {
                        width: parent.width
                        from: 0
                        to: 1
                        step: 0.05
                        value: Settings.grid.opacity
                        onMoved: v => {
                            Settings.grid.opacity = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Dot grid"

                    Sw {
                        width: parent.width
                        checked: Settings.grid.dots
                        onToggled: v => {
                            Settings.grid.dots = v;
                            root.save();
                        }
                    }
                }
            }

            Section {
                title: "Snapping"
                icon: "grid_goldenratio"

                Row2 {
                    label: "Snapping"

                    Sw {
                        width: parent.width
                        checked: Settings.snap.enabled
                        onToggled: v => {
                            Settings.snap.enabled = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "To grid cells"

                    Sw {
                        width: parent.width
                        checked: Settings.snap.toGrid
                        onToggled: v => {
                            Settings.snap.toGrid = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Match sizes"

                    Sw {
                        width: parent.width
                        checked: Settings.snap.toSizes
                        onToggled: v => {
                            Settings.snap.toSizes = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "To screen edges"

                    Sw {
                        width: parent.width
                        checked: Settings.snap.toEdges
                        onToggled: v => {
                            Settings.snap.toEdges = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "To other elements"

                    Sw {
                        width: parent.width
                        checked: Settings.snap.toWidgets
                        onToggled: v => {
                            Settings.snap.toWidgets = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "To equal spacing"
                    hint: "Match a gap the layout already uses"

                    Sw {
                        width: parent.width
                        checked: Settings.snap.toSpacing
                        onToggled: v => {
                            Settings.snap.toSpacing = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Magnet range"
                    labelWidth: 0.4

                    Sld {
                        width: parent.width
                        from: 2
                        to: 40
                        step: 1
                        value: Settings.snap.threshold
                        onMoved: v => {
                            Settings.snap.threshold = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Safe margin"
                    labelWidth: 0.4

                    Sld {
                        width: parent.width
                        from: 0
                        to: 160
                        step: 2
                        value: Settings.snap.margin
                        onMoved: v => {
                            Settings.snap.margin = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Show guides"

                    Sw {
                        width: parent.width
                        checked: Settings.snap.showGuides
                        onToggled: v => {
                            Settings.snap.showGuides = v;
                            root.save();
                        }
                    }
                }
            }

            Section {
                title: "Cell mode"
                icon: "border_all"

                Row2 {
                    label: "Lock to whole cells"
                    stacked: true

                    Sw {
                        width: parent.width
                        checked: Settings.snap.cells
                        onToggled: v => {
                            Settings.snap.cells = v;
                            root.save();
                        }
                    }
                }

                Txt {
                    width: parent.width
                    text: Settings.snap.cells ? "Everything lands on a cell boundary — position and size, no magnet threshold. Arrow keys move by one cell." : "Off: the grid is a magnet you can override by dragging past it."
                    font.pixelSize: 11
                    color: Settings.snap.cells ? Theme.primary : Theme.fgSurfaceVariant
                    wrapMode: Text.Wrap
                }

                Row2 {
                    label: "Gutter"
                    labelWidth: 0.4

                    Sld {
                        width: parent.width
                        from: 0
                        to: 48
                        step: 2
                        value: Settings.snap.gap
                        onMoved: v => {
                            Settings.snap.gap = v;
                            root.save();
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Btn {
                        icon: "grid_on"
                        label: "Selection"
                        iconSize: 15
                        padding: 10
                        radius: 11
                        enabled: EditorState.hasSelection
                        colour: Theme.fgSurfaceVariant
                        hoverColour: Theme.primary
                        background: Theme.alpha(Theme.fgSurface, 0.06)
                        onClicked: root.snapSelectionRequested()
                    }

                    Btn {
                        icon: "select_all"
                        label: "Everything"
                        iconSize: 15
                        padding: 10
                        radius: 11
                        colour: Theme.fgSurfaceVariant
                        hoverColour: Theme.primary
                        background: Theme.alpha(Theme.fgSurface, 0.06)
                        onClicked: root.snapAllRequested()
                    }
                }
            }

            Section {
                title: "Backdrop"
                icon: "wallpaper"
                expanded: false

                Row2 {
                    label: "Show wallpaper"

                    Sw {
                        width: parent.width
                        checked: Settings.editor.showWallpaper
                        onToggled: v => {
                            Settings.editor.showWallpaper = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Dim"
                    labelWidth: 0.4

                    Sld {
                        width: parent.width
                        from: 0
                        to: 1
                        step: 0.02
                        value: Settings.editor.dim
                        onMoved: v => {
                            Settings.editor.dim = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Safe area outline"

                    Sw {
                        width: parent.width
                        checked: Settings.editor.showSafeArea
                        onToggled: v => {
                            Settings.editor.showSafeArea = v;
                            root.save();
                        }
                    }
                }
            }

            Section {
                title: "Desktop layer"
                icon: "desktop_windows"
                expanded: false

                Row2 {
                    label: "Widgets on desktop"

                    Sw {
                        width: parent.width
                        checked: Settings.layer.enabled
                        onToggled: v => {
                            Settings.layer.enabled = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Fade when covered"

                    Sw {
                        width: parent.width
                        checked: Settings.layer.hideWhenCovered
                        onToggled: v => {
                            Settings.layer.hideWhenCovered = v;
                            root.save();
                        }
                    }
                }

                Row2 {
                    label: "Faded opacity"
                    labelWidth: 0.4

                    Sld {
                        width: parent.width
                        from: 0
                        to: 1
                        step: 0.05
                        value: Settings.layer.inactiveOpacity
                        onMoved: v => {
                            Settings.layer.inactiveOpacity = v;
                            root.save();
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 8
            }

            Row {
                width: parent.width
                spacing: 8

                Btn {
                    icon: "refresh"
                    label: "Reload"
                    iconSize: 15
                    padding: 10
                    radius: 11
                    colour: Theme.fgSurfaceVariant
                    hoverColour: Theme.primary
                    background: Theme.alpha(Theme.fgSurface, 0.06)
                    onClicked: {
                        Store.reloadFromDisk();
                        EditorState.status("Reloaded layout.json");
                    }
                }

                Btn {
                    icon: "delete_sweep"
                    label: "Clear display"
                    iconSize: 15
                    padding: 10
                    radius: 11
                    colour: Theme.error
                    hoverColour: Theme.error
                    background: Theme.alpha(Theme.error, 0.1)
                    onClicked: {
                        Store.clearScreen(EditorState.target);
                        EditorState.status("Cleared");
                    }
                }
            }

            Txt {
                width: parent.width
                topPadding: 10
                text: `Layout: ${Theme.configPath}/layout.json`
                font.family: Theme.mono
                font.pixelSize: 10
                color: Theme.alpha(Theme.fgSurfaceVariant, 0.8)
                wrapMode: Text.Wrap
            }

            Item {
                width: parent.width
                height: 12
            }
        }
    }
}
