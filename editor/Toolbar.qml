import QtQuick
import Quickshell
import qs.components
import qs.config

// The editor's main control bar: which monitor, history, view, alignment and
// which palettes are open.
Item {
    id: root

    signal closeRequested
    signal fitRequested
    signal zoomIn
    signal zoomOut
    signal targetPicked(string name)
    signal alignRequested(string mode)
    signal distributeRequested(bool horizontal)
    signal matchSizeRequested(string mode)

    implicitWidth: bar.width
    implicitHeight: bar.height

    Rectangle {
        id: bar

        width: row.implicitWidth + 22
        height: 52
        radius: 26
        color: Theme.alpha(Theme.surfaceContainer, 0.97)
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.6)

        Row {
            id: row

            anchors.centerIn: parent
            spacing: 3

            // --- identity + display ---------------------------------------
            Item {
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    radius: 10
                    color: Theme.primary

                    Icon {
                        anchors.centerIn: parent
                        text: "dashboard_customize"
                        size: 18
                        fill: 1
                        color: Theme.fgPrimary
                    }
                }
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: displayChip.width
                height: 40

                Rectangle {
                    id: displayChip

                    anchors.verticalCenter: parent.verticalCenter
                    width: displayRow.implicitWidth + 22
                    height: 34
                    radius: 17
                    color: Theme.alpha(Theme.fgSurface, displayArea.containsMouse ? 0.12 : 0.07)

                    Row {
                        id: displayRow

                        anchors.centerIn: parent
                        spacing: 7

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "monitor"
                            size: 17
                            color: Theme.primary
                        }

                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            text: EditorState.target || "—"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.fgSurface
                        }

                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            text: `${Math.round(EditorState.targetWidth)}×${Math.round(EditorState.targetHeight)}`
                            font.family: Theme.mono
                            font.pixelSize: 10
                            color: Theme.fgSurfaceVariant
                        }

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "expand_more"
                            size: 16
                            color: Theme.fgSurfaceVariant
                        }
                    }

                    MouseArea {
                        id: displayArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: displayMenu.visible = !displayMenu.visible
                    }
                }

                Rectangle {
                    id: displayMenu

                    visible: false
                    z: 50
                    anchors.top: displayChip.bottom
                    anchors.topMargin: 8
                    anchors.left: displayChip.left
                    width: Math.max(displayChip.width, 230)
                    height: displayCol.implicitHeight + 10
                    radius: 14
                    color: Theme.surfaceContainerHighest
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.6)

                    Column {
                        id: displayCol

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 5

                        Repeater {
                            model: Quickshell.screens

                            Rectangle {
                                required property var modelData

                                width: displayCol.width
                                height: 38
                                radius: 10
                                color: screenArea.containsMouse ? Theme.alpha(Theme.primary, 0.16) : "transparent"

                                Icon {
                                    id: screenIcon

                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name === EditorState.target ? "check" : "monitor"
                                    size: 16
                                    color: modelData.name === EditorState.target ? Theme.primary : Theme.fgSurfaceVariant
                                }

                                Column {
                                    anchors.left: screenIcon.right
                                    anchors.leftMargin: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Txt {
                                        text: modelData.name
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: Theme.fgSurface
                                    }

                                    Txt {
                                        text: `${modelData.width}×${modelData.height}  ·  ${Store.countOn(modelData.name)} element${Store.countOn(modelData.name) === 1 ? "" : "s"}`
                                        font.pixelSize: 10
                                        color: Theme.fgSurfaceVariant
                                    }
                                }

                                MouseArea {
                                    id: screenArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.targetPicked(modelData.name);
                                        displayMenu.visible = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Divider {}

            // --- history --------------------------------------------------
            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "undo"
                iconSize: 19
                enabled: Store.canUndo
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: Store.undo()
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "redo"
                iconSize: 19
                enabled: Store.canRedo
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: Store.redo()
            }

            Divider {}

            // --- view -----------------------------------------------------
            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "zoom_out"
                iconSize: 19
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: root.zoomOut()
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 52
                height: 32

                Txt {
                    anchors.centerIn: parent
                    text: `${Math.round(EditorState.zoom * 100)}%`
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Theme.fgSurface
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        EditorState.zoom = 1;
                        root.fitRequested();
                    }
                }
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "zoom_in"
                iconSize: 19
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: root.zoomIn()
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "fit_screen"
                iconSize: 19
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: root.fitRequested()
            }

            Divider {}

            // --- grid / snap ----------------------------------------------
            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "grid_4x4"
                iconSize: 19
                checked: Settings.grid.visible
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: {
                    Settings.grid.visible = !Settings.grid.visible;
                    Settings.save();
                }
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "border_outer"
                iconSize: 19
                checked: Settings.editor.showSafeArea
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.tertiary
                onClicked: {
                    Settings.editor.showSafeArea = !Settings.editor.showSafeArea;
                    Settings.save();
                }
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "border_all"
                iconSize: 19
                checked: Settings.snap.cells
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: {
                    Settings.snap.cells = !Settings.snap.cells;
                    Settings.save();
                }
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "grid_goldenratio"
                iconSize: 19
                checked: Settings.snap.enabled
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: {
                    Settings.snap.enabled = !Settings.snap.enabled;
                    Settings.save();
                }
            }

            Divider {}

            // --- alignment ------------------------------------------------
            Repeater {
                model: [
                    {
                        icon: "align_horizontal_left",
                        mode: "left"
                    },
                    {
                        icon: "align_horizontal_center",
                        mode: "hcentre"
                    },
                    {
                        icon: "align_horizontal_right",
                        mode: "right"
                    },
                    {
                        icon: "align_vertical_top",
                        mode: "top"
                    },
                    {
                        icon: "align_vertical_center",
                        mode: "vcentre"
                    },
                    {
                        icon: "align_vertical_bottom",
                        mode: "bottom"
                    }
                ]

                Btn {
                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    icon: modelData.icon
                    iconSize: 18
                    enabled: EditorState.hasSelection
                    colour: Theme.fgSurfaceVariant
                    hoverColour: Theme.primary
                    onClicked: root.alignRequested(modelData.mode)
                }
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "width"
                iconSize: 18
                enabled: EditorState.selection.length > 1
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: root.matchSizeRequested("width")
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "height"
                iconSize: 18
                enabled: EditorState.selection.length > 1
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: root.matchSizeRequested("height")
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "aspect_ratio"
                iconSize: 18
                enabled: EditorState.selection.length > 1
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: root.matchSizeRequested("both")
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "horizontal_distribute"
                iconSize: 18
                enabled: EditorState.selection.length > 2
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: root.distributeRequested(true)
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "vertical_distribute"
                iconSize: 18
                enabled: EditorState.selection.length > 2
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: root.distributeRequested(false)
            }

            Divider {}

            // --- palettes -------------------------------------------------
            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "widgets"
                iconSize: 19
                checked: EditorState.libraryOpen
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: EditorState.libraryOpen = !EditorState.libraryOpen
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "tune"
                iconSize: 19
                checked: EditorState.inspectorOpen
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: EditorState.inspectorOpen = !EditorState.inspectorOpen
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "text_fields"
                iconSize: 19
                checked: EditorState.typographyOpen
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: EditorState.typographyOpen = !EditorState.typographyOpen
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "palette"
                iconSize: 19
                checked: EditorState.styleOpen
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: EditorState.styleOpen = !EditorState.styleOpen
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "layers"
                iconSize: 19
                checked: EditorState.layersOpen
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: EditorState.layersOpen = !EditorState.layersOpen
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "settings_overscan"
                iconSize: 19
                checked: EditorState.canvasPanelOpen
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.primary
                onClicked: EditorState.canvasPanelOpen = !EditorState.canvasPanelOpen
            }

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "visibility"
                iconSize: 19
                checked: EditorState.preview
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.tertiary
                onClicked: EditorState.preview = !EditorState.preview
            }

            Divider {}

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                icon: "check"
                iconSize: 20
                label: "Done"
                colour: Theme.primary
                hoverColour: Theme.primary
                padding: 12
                onClicked: root.closeRequested()
            }
        }
    }

    component Divider: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 24
        color: Theme.alpha(Theme.outlineVariant, 0.5)
    }
}
