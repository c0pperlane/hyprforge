pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.layer

// One placed widget, in editing clothes: drag to move, eight handles to
// resize, a name chip, and selection chrome. Geometry is written straight back
// to the Store, so the live desktop layer updates as you drag.
Item {
    id: root

    required property var instance
    required property Item canvas

    readonly property string wid: instance.id
    readonly property bool selected: EditorState.isSelected(root.wid)
    readonly property bool locked: instance.locked
    readonly property bool primary: EditorState.primary === root.wid
    readonly property real zoom: EditorState.zoom
    // Chrome is drawn at constant on-screen size regardless of zoom, otherwise
    // handles become unusable at 30%.
    readonly property real px: 1 / Math.max(0.08, root.zoom)

    x: instance.x
    y: instance.y
    width: instance.w
    height: instance.h
    z: instance.z + (root.selected ? 1000 : 0)
    rotation: instance.rot
    opacity: instance.hidden ? 0.25 : 1

    WidgetHost {
        id: host

        anchors.fill: parent
        type: root.instance.type
        wid: root.wid
        editing: true
        // On the artboard the widget is on screen and being looked at, so it
        // gets its services - but only while it is the target display's.
        instantiate: root.visible
        live: root.visible
        selected: root.selected
        opacity: root.instance.op
        props: {
            try {
                return JSON.parse(root.instance.props);
            } catch (e) {
                return ({});
            }
        }
    }

    // Hover/selection outline
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.selected ? 2 * root.px : dragArea.containsMouse ? 1 * root.px : 0
        border.color: root.locked ? Theme.error : root.selected ? Theme.primary : Theme.alpha(Theme.primary, 0.55)
        radius: 2 * root.px
    }

    // Name chip
    Rectangle {
        visible: root.selected || dragArea.containsMouse
        anchors.bottom: parent.top
        anchors.bottomMargin: 6 * root.px
        anchors.left: parent.left
        width: chipRow.implicitWidth + 14 * root.px
        height: 20 * root.px
        radius: height / 2
        color: root.selected ? Theme.primary : Theme.alpha(Theme.surfaceContainerHighest, 0.9)

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: 4 * root.px

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.locked ? "lock" : Registry.def(root.instance.type)?.icon ?? "widgets"
                size: 11 * root.px
                color: root.selected ? Theme.fgPrimary : Theme.fgSurfaceVariant
            }

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: Registry.def(root.instance.type)?.name ?? root.instance.type
                font.pixelSize: 10 * root.px
                font.weight: Font.DemiBold
                color: root.selected ? Theme.fgPrimary : Theme.fgSurfaceVariant
            }
        }
    }

    // Size readout while dragging or resizing
    Rectangle {
        visible: dragArea.dragging || root.resizing
        anchors.top: parent.bottom
        anchors.topMargin: 6 * root.px
        anchors.horizontalCenter: parent.horizontalCenter
        width: readout.implicitWidth + 14 * root.px
        height: 20 * root.px
        radius: 6 * root.px
        color: Theme.alpha(Theme.surfaceContainerHighest, 0.95)

        Txt {
            id: readout

            anchors.centerIn: parent
            text: {
                const base = `${Math.round(root.instance.x)}, ${Math.round(root.instance.y)}  ·  ${Math.round(root.instance.w)} × ${Math.round(root.instance.h)}`;
                const match = [];
                if (root.matchedWidth)
                    match.push(`= w ${Math.round(root.matchedWidth)}`);
                if (root.matchedHeight)
                    match.push(`= h ${Math.round(root.matchedHeight)}`);
                return match.length ? `${base}   ${match.join("  ")}` : base;
            }
            font.family: Theme.mono
            font.pixelSize: 10 * root.px
            color: root.matchedWidth || root.matchedHeight ? Theme.primary : Theme.fgSurface
        }
    }

    property bool resizing: false
    // Set while a resize is locked onto a sibling's width/height, so the
    // readout can say so.
    property real matchedWidth: 0
    property real matchedHeight: 0

    // --- move -------------------------------------------------------------

    MouseArea {
        id: dragArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.locked ? Qt.ForbiddenCursor : dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        // Let interactive widgets stay inert while editing - a click here means
        // "select this element", never "skip track".
        preventStealing: true

        property bool dragging: false
        property real pressX: 0
        property real pressY: 0
        property var startRects: ({})

        onEntered: EditorState.hovered = root.wid
        onExited: if (EditorState.hovered === root.wid)
            EditorState.hovered = ""

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (!root.selected)
                    EditorState.select(root.wid);
                const p = root.canvas.mapFromItem(root, mouse.x, mouse.y);
                root.canvas.requestContextMenu(p.x, p.y, root.wid);
                return;
            }

            if (mouse.modifiers & Qt.ControlModifier)
                EditorState.toggle(root.wid);
            else if (mouse.modifiers & Qt.ShiftModifier)
                EditorState.addToSelection(root.wid);
            else if (!root.selected)
                EditorState.select(root.wid);

            if (root.locked)
                return;

            // Measured against the canvas, not this item: the frame moves
            // while you drag it, so its own coordinate space shifts under the
            // cursor and the delta would compound. The canvas stays put, and
            // dividing by zoom converts screen pixels to design pixels.
            const press = dragArea.mapToItem(root.canvas, mouse.x, mouse.y);
            dragArea.pressX = press.x;
            dragArea.pressY = press.y;
            dragArea.startRects = ({});
            for (const id of EditorState.selection) {
                const w = Store.get(id);
                if (w && !w.locked)
                    dragArea.startRects[id] = {
                        x: w.x,
                        y: w.y,
                        w: w.w,
                        h: w.h
                    };
            }
            Store.pushUndo();
            dragArea.dragging = true;
        }

        onPositionChanged: mouse => {
            if (!dragArea.dragging)
                return;

            const p = dragArea.mapToItem(root.canvas, mouse.x, mouse.y);
            let dx = (p.x - dragArea.pressX) / root.zoom;
            let dy = (p.y - dragArea.pressY) / root.zoom;

            // Shift constrains to the dominant axis, as in every design tool.
            if (mouse.modifiers & Qt.ShiftModifier) {
                if (Math.abs(dx) > Math.abs(dy))
                    dy = 0;
                else
                    dx = 0;
            }

            const start = dragArea.startRects[root.wid];
            if (!start)
                return;

            const snapped = root.canvas.snapRect(start.x + dx, start.y + dy, start.w, start.h, root.wid, null);
            EditorState.guides = snapped.guides;

            const appliedDx = snapped.x - start.x;
            const appliedDy = snapped.y - start.y;

            for (const id of Object.keys(dragArea.startRects)) {
                const s = dragArea.startRects[id];
                Store.setGeometry(id, s.x + appliedDx, s.y + appliedDy, undefined, undefined);
            }
        }

        onReleased: {
            dragArea.dragging = false;
            EditorState.guides = [];
        }

        onDoubleClicked: {
            EditorState.select(root.wid);
            EditorState.inspectorOpen = true;
        }
    }

    // --- resize handles ---------------------------------------------------

    Repeater {
        model: root.selected && !root.locked && !EditorState.multiSelection ? handleModel : []

        Rectangle {
            id: handle

            required property var modelData

            readonly property real hx: modelData.ax
            readonly property real hy: modelData.ay

            width: 10 * root.px
            height: 10 * root.px
            radius: modelData.corner ? 2 * root.px : width / 2
            color: Theme.surfaceContainerLowest
            border.width: 2 * root.px
            border.color: Theme.primary
            z: 100

            x: root.width * handle.hx - width / 2
            y: root.height * handle.hy - height / 2

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6 * root.px
                cursorShape: handle.modelData.cursor

                property real sx: 0
                property real sy: 0
                property var start: null

                onPressed: mouse => {
                    const w = Store.get(root.wid);
                    handleArea.start = {
                        x: w.x,
                        y: w.y,
                        w: w.w,
                        h: w.h
                    };
                    const p = mapToItem(root.canvas, mouse.x, mouse.y);
                    handleArea.sx = p.x;
                    handleArea.sy = p.y;
                    Store.pushUndo();
                    root.resizing = true;
                }

                id: handleArea

                onPositionChanged: mouse => {
                    if (!handleArea.start)
                        return;
                    const p = mapToItem(root.canvas, mouse.x, mouse.y);
                    const dx = (p.x - handleArea.sx) / root.zoom;
                    const dy = (p.y - handleArea.sy) / root.zoom;

                    const s = handleArea.start;
                    const m = handle.modelData;

                    let nx = s.x + (m.left ? dx : 0);
                    let ny = s.y + (m.top ? dy : 0);
                    let nw = s.w + (m.left ? -dx : m.right ? dx : 0);
                    let nh = s.h + (m.top ? -dy : m.bottom ? dy : 0);

                    const def = Registry.def(root.instance.type);
                    const minW = def?.min?.w ?? 40;
                    const minH = def?.min?.h ?? 30;

                    // Shift keeps the original aspect ratio.
                    if ((mouse.modifiers & Qt.ShiftModifier) && m.corner) {
                        const ar = s.w / Math.max(1, s.h);
                        if (Math.abs(nw - s.w) > Math.abs(nh - s.h))
                            nh = nw / ar;
                        else
                            nw = nh * ar;
                        if (m.left)
                            nx = s.x + s.w - nw;
                        if (m.top)
                            ny = s.y + s.h - nh;
                    }

                    if (nw < minW) {
                        if (m.left)
                            nx = s.x + s.w - minW;
                        nw = minW;
                    }
                    if (nh < minH) {
                        if (m.top)
                            ny = s.y + s.h - minH;
                        nh = minH;
                    }

                    // Size snapping first: lock onto a sibling's width or
                    // height (or the usable area's) before worrying about where
                    // the edges land. Doing it the other way round means the
                    // position magnet drags you off an exact size match.
                    const sizes = root.canvas.siblingSizes(root.wid);
                    const usable = root.canvas.usable;
                    root.matchedWidth = 0;
                    root.matchedHeight = 0;

                    // Whole-cell widths and heights are candidates too, so a
                    // resize can land on "three cells" as readily as on "the
                    // same width as that one".
                    const cell = Math.max(1, Settings.grid.size);
                    const gridW = Settings.snap.toGrid ? [Math.round(nw / cell) * cell] : [];
                    const gridH = Settings.snap.toGrid ? [Math.round(nh / cell) * cell] : [];

                    if (Settings.snap.enabled && Settings.snap.toSizes) {
                        if (m.left || m.right) {
                            const sw = root.canvas.snapDimension(nw, sizes.widths.concat(gridW, [usable.width, usable.width / 2, usable.width / 3]));
                            if (sw !== null) {
                                if (m.left)
                                    nx += nw - sw;
                                nw = sw;
                                root.matchedWidth = sw;
                            }
                        }
                        if (m.top || m.bottom) {
                            const sh = root.canvas.snapDimension(nh, sizes.heights.concat(gridH, [usable.height, usable.height / 2, usable.height / 3]));
                            if (sh !== null) {
                                if (m.top)
                                    ny += nh - sh;
                                nh = sh;
                                root.matchedHeight = sh;
                            }
                        }
                    }

                    // An axis that just locked onto a size keeps it: position
                    // snapping there would change the dimension again.
                    const edges = {
                        left: !!m.left && !root.matchedWidth,
                        right: !!m.right && !root.matchedWidth,
                        top: !!m.top && !root.matchedHeight,
                        bottom: !!m.bottom && !root.matchedHeight,
                        centre: false
                    };
                    // Cell mode: quantise the size outright, and pin the edge
                    // that is not being dragged so the box grows in whole cells
                    // from where it already is.
                    if (Settings.snap.enabled && Settings.snap.cells) {
                        const qw = Math.max(cell, Math.round(nw / cell) * cell);
                        const qh = Math.max(cell, Math.round(nh / cell) * cell);
                        if (m.left)
                            nx += nw - qw;
                        if (m.top)
                            ny += nh - qh;
                        nw = qw;
                        nh = qh;
                        root.matchedWidth = 0;
                        root.matchedHeight = 0;
                    }

                    const snapped = root.canvas.snapRect(nx, ny, nw, nh, root.wid, edges);
                    EditorState.guides = snapped.guides;

                    // Snapping moves the rect; for edges being dragged, shift
                    // the size by the same amount so the opposite edge stays put.
                    const ddx = snapped.x - nx;
                    const ddy = snapped.y - ny;
                    if (m.left) {
                        nx = snapped.x;
                        nw -= ddx;
                    } else if (m.right) {
                        nw += ddx;
                    }
                    if (m.top) {
                        ny = snapped.y;
                        nh -= ddy;
                    } else if (m.bottom) {
                        nh += ddy;
                    }

                    Store.setGeometry(root.wid, nx, ny, Math.max(minW, nw), Math.max(minH, nh));
                }

                onReleased: {
                    handleArea.start = null;
                    root.resizing = false;
                    root.matchedWidth = 0;
                    root.matchedHeight = 0;
                    EditorState.guides = [];
                }
            }
        }
    }

    readonly property var handleModel: [
        {
            ax: 0,
            ay: 0,
            left: true,
            top: true,
            corner: true,
            cursor: Qt.SizeFDiagCursor
        },
        {
            ax: 0.5,
            ay: 0,
            top: true,
            cursor: Qt.SizeVerCursor
        },
        {
            ax: 1,
            ay: 0,
            right: true,
            top: true,
            corner: true,
            cursor: Qt.SizeBDiagCursor
        },
        {
            ax: 1,
            ay: 0.5,
            right: true,
            cursor: Qt.SizeHorCursor
        },
        {
            ax: 1,
            ay: 1,
            right: true,
            bottom: true,
            corner: true,
            cursor: Qt.SizeFDiagCursor
        },
        {
            ax: 0.5,
            ay: 1,
            bottom: true,
            cursor: Qt.SizeVerCursor
        },
        {
            ax: 0,
            ay: 1,
            left: true,
            bottom: true,
            corner: true,
            cursor: Qt.SizeBDiagCursor
        },
        {
            ax: 0,
            ay: 0.5,
            left: true,
            cursor: Qt.SizeHorCursor
        }
    ]
}
