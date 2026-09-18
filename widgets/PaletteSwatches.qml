pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config

// The active caelestia scheme, as swatches. Useful while designing - and it
// restyles itself the moment the wallpaper changes, which makes it a live
// readout of what every other widget is pulling its colours from.
WidgetBase {
    id: root

    readonly property var roleList: {
        const wanted = root.lines("roles");
        return wanted.length ? wanted : ["primary", "secondary", "tertiary", "surfaceContainer", "fgSurface", "error"];
    }

    readonly property int columns: Math.max(1, Math.round(root.num("columns", 6)))

    Txt {
        id: heading

        visible: root.flag("showScheme", true)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: visible ? implicitHeight : 0
        text: `${Theme.schemeName}${Theme.flavour && Theme.flavour !== "default" ? " · " + Theme.flavour : ""} · ${Theme.light ? "light" : "dark"}`
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
        color: root.muted
        elide: Text.ElideRight
    }

    Grid {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.topMargin: heading.visible ? 10 : 0
        anchors.bottom: parent.bottom
        columns: root.columns
        rowSpacing: root.num("gap", 6)
        columnSpacing: root.num("gap", 6)

        Repeater {
            model: root.roleList

            Item {
                required property string modelData

                readonly property real cell: (root.width - root.pad * 2 - (root.columns - 1) * root.num("gap", 6)) / root.columns

                width: cell
                height: root.flag("showNames", false) ? cell + 14 : cell

                Rectangle {
                    width: parent.width
                    height: parent.width
                    radius: root.num("swatchRadius", 10)
                    color: Theme.resolve(parent.modelData, Theme.primary)
                    border.width: 1
                    border.color: Theme.alpha(Theme.fgSurface, 0.12)

                    Behavior on color {
                        ColorAnimation {
                            duration: 260
                        }
                    }
                }

                Txt {
                    anchors.top: parent.top
                    anchors.topMargin: parent.width + 2
                    width: parent.width
                    visible: root.flag("showNames", false)
                    text: parent.modelData
                    font.pixelSize: 8
                    color: root.muted
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
