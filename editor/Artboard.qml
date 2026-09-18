pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// The artboard (named Artboard, not Canvas, so QtQuick's own Canvas type
// stays reachable from the other files in this module): a 1:1 model of the target monitor that you pan, zoom and drop
// widgets onto.
//
// Design coordinates are the monitor's real pixels, so what you lay out here is
// literally where the widget lands on the desktop - no unit conversion, and a
// layout authored at 100% zoom needs no interpretation at paint time.
Item {
    id: root

    property bool panning: false
    property bool spaceHeld: false

    readonly property real zoom: EditorState.zoom
    readonly property real tw: EditorState.targetWidth
    readonly property real th: EditorState.targetHeight

    // The area caelestia's bar and border actually leave free, plus the user's
    // own margin. Snapping and "align to screen" both work against this rather
    // than the raw output rectangle - aligning a widget to x=0 would put it
    // underneath the bar.
    readonly property var reserved: Outputs.reservedFor(EditorState.target)
    readonly property rect usable: Qt.rect(reserved.left + Settings.snap.margin, reserved.top + Settings.snap.margin, Math.max(0, tw - reserved.left - reserved.right - Settings.snap.margin * 2), Math.max(0, th - reserved.top - reserved.bottom - Settings.snap.margin * 2))

    signal requestContextMenu(real x, real y, string id)

    // --- viewport helpers -------------------------------------------------

    // True once the viewport has real dimensions - fitting before that would
    // compute a nonsense zoom (and did, on the first run: 5%).
    readonly property bool laidOut: width > 40 && height > 40
    property bool fitted: false

    function fit(): void {
        if (!root.laidOut)
            return;
        root.fitted = true;
        const margin = 80;
        const z = Math.min((width - margin * 2) / root.tw, (height - margin * 2) / root.th);
        EditorState.zoom = Math.max(0.05, Math.min(2, z));
        centre();
    }

    function centre(): void {
        EditorState.panX = (width - root.tw * EditorState.zoom) / 2;
        EditorState.panY = (height - root.th * EditorState.zoom) / 2;
    }

    function zoomAt(factor: real, px: real, py: real): void {
        const old = EditorState.zoom;
        const next = Math.max(0.08, Math.min(4, old * factor));
        if (next === old)
            return;
        // Keep the point under the cursor fixed while zooming.
        EditorState.panX = px - (px - EditorState.panX) * (next / old);
        EditorState.panY = py - (py - EditorState.panY) * (next / old);
        EditorState.zoom = next;
    }

    function toDesign(px: real, py: real): var {
        return {
            x: (px - EditorState.panX) / EditorState.zoom,
            y: (py - EditorState.panY) / EditorState.zoom
        };
    }

    // --- snapping ---------------------------------------------------------

    readonly property real snapDistance: Settings.snap.threshold / Math.max(0.2, root.zoom)

    // Collects every line a dragged rect could align to, as {pos, kind}.
    function snapTargetsX(excludeId: string): var {
        const out = [];
        if (Settings.snap.toEdges) {
            const u = root.usable;
            out.push({
                pos: 0,
                kind: "edge"
            }, {
                pos: root.tw,
                kind: "edge"
            }, {
                pos: root.reserved.left,
                kind: "reserved"
            }, {
                pos: root.tw - root.reserved.right,
                kind: "reserved"
            }, {
                pos: u.x,
                kind: "margin"
            }, {
                pos: u.x + u.width,
                kind: "margin"
            }, {
                pos: u.x + u.width / 2,
                kind: "centre"
            }, {
                pos: root.tw / 2,
                kind: "centre"
            });
        }
        if (Settings.snap.toWidgets) {
            for (let i = 0; i < Store.widgets.count; i++) {
                const w = Store.widgets.get(i);
                if (w.screen !== EditorState.target || w.id === excludeId || w.hidden)
                    continue;
                out.push({
                    pos: w.x,
                    kind: "widget"
                }, {
                    pos: w.x + w.w,
                    kind: "widget"
                }, {
                    pos: w.x + w.w / 2,
                    kind: "widget"
                });
            }
        }
        return out;
    }

    function snapTargetsY(excludeId: string): var {
        const out = [];
        if (Settings.snap.toEdges) {
            const u = root.usable;
            out.push({
                pos: 0,
                kind: "edge"
            }, {
                pos: root.th,
                kind: "edge"
            }, {
                pos: root.reserved.top,
                kind: "reserved"
            }, {
                pos: root.th - root.reserved.bottom,
                kind: "reserved"
            }, {
                pos: u.y,
                kind: "margin"
            }, {
                pos: u.y + u.height,
                kind: "margin"
            }, {
                pos: u.y + u.height / 2,
                kind: "centre"
            }, {
                pos: root.th / 2,
                kind: "centre"
            });
        }
        if (Settings.snap.toWidgets) {
            for (let i = 0; i < Store.widgets.count; i++) {
                const w = Store.widgets.get(i);
                if (w.screen !== EditorState.target || w.id === excludeId || w.hidden)
                    continue;
                out.push({
                    pos: w.y,
                    kind: "widget"
                }, {
                    pos: w.y + w.h,
                    kind: "widget"
                }, {
                    pos: w.y + w.h / 2,
                    kind: "widget"
                });
            }
        }
        return out;
    }

    // Sibling dimensions, so a resize can lock onto "the same width as that
    // one". Position snapping alone gets edges to line up; it cannot make two
    // widgets the same size unless they also happen to start at the same place.
    function siblingSizes(excludeId: string): var {
        const widths = [];
        const heights = [];
        for (let i = 0; i < Store.widgets.count; i++) {
            const w = Store.widgets.get(i);
            if (w.screen !== EditorState.target || w.id === excludeId || w.hidden)
                continue;
            widths.push(w.w);
            heights.push(w.h);
        }
        return {
            widths: widths,
            heights: heights
        };
    }

    // Nearest candidate within the magnet distance, or null.
    function snapDimension(value: real, candidates: var): var {
        const d = root.snapDistance;
        let best = null;
        for (const c of candidates) {
            if (c <= 0)
                continue;
            if (Math.abs(c - value) <= d && (best === null || Math.abs(c - value) < Math.abs(best - value)))
                best = c;
        }
        return best;
    }

    // Grid lines either side of a value. Generated per-edge rather than kept in
    // a list, because a 32px grid on a 2560px board is 80 lines and only the
    // two nearest can ever win.
    function gridLinesNear(value: real): var {
        if (!Settings.snap.toGrid)
            return [];
        const g = Math.max(1, Settings.grid.size);
        const lo = Math.floor(value / g) * g;
        return lo === value ? [lo] : [lo, lo + g];
    }

    // Quantises a value to whole grid cells - the hard version, with no
    // threshold. Cell mode uses this; the magnet does not.
    function toCell(value: real, roundFn: var): real {
        const g = Math.max(1, Settings.grid.size);
        return (roundFn ?? Math.round)(value / g) * g;
    }

    // Returns { x, y, guides } for a proposed rect. `edges` picks which of the
    // rect's own lines may snap - resizing from the left edge shouldn't let the
    // right edge drag the box around.
    //
    // Grid lines are ordinary candidates here, competing on distance alongside
    // sibling edges and the usable-area bounds. They used to be a special case
    // applied to x and y only, which meant a resize never snapped to the grid
    // at all: the top-left corner landed on a line and the dragged edge landed
    // wherever the mouse was, so widths were never whole cells.
    function snapRect(x: real, y: real, w: real, h: real, id: string, edges: var): var {
        const result = {
            x: x,
            y: y,
            guides: []
        };
        if (!Settings.snap.enabled)
            return result;

        const useEdges = edges ?? ({
                left: true,
                right: true,
                top: true,
                bottom: true,
                centre: true
            });
        const d = root.snapDistance;

        // Grid is the weakest magnet: when a sibling edge and a grid line are
        // equally close, lining up with the sibling is what was meant.
        const weightFor = kind => kind === "grid" ? 1.35 : 1;

        function best(own, targets) {
            let winner = null;
            for (const t of targets) {
                const delta = t.pos - own;
                const score = Math.abs(delta) * weightFor(t.kind);
                if (Math.abs(delta) <= d && (!winner || score < winner.score))
                    winner = {
                        delta: delta,
                        line: t.pos,
                        kind: t.kind,
                        score: score
                    };
            }
            return winner;
        }

        const targetsX = root.snapTargetsX(id);
        const targetsY = root.snapTargetsY(id);

        const ownX = [];
        if (useEdges.left)
            ownX.push(x);
        if (useEdges.right)
            ownX.push(x + w);
        if (useEdges.centre)
            ownX.push(x + w / 2);

        const ownY = [];
        if (useEdges.top)
            ownY.push(y);
        if (useEdges.bottom)
            ownY.push(y + h);
        if (useEdges.centre)
            ownY.push(y + h / 2);

        let bestX = null;
        for (const own of ownX) {
            const grid = root.gridLinesNear(own).map(pos => ({
                        pos: pos,
                        kind: "grid"
                    }));
            const b = best(own, targetsX.concat(grid));
            if (b && (!bestX || b.score < bestX.score))
                bestX = b;
        }

        let bestY = null;
        for (const own of ownY) {
            const grid = root.gridLinesNear(own).map(pos => ({
                        pos: pos,
                        kind: "grid"
                    }));
            const b = best(own, targetsY.concat(grid));
            if (b && (!bestY || b.score < bestY.score))
                bestY = b;
        }

        if (bestX) {
            result.x = x + bestX.delta;
            result.guides.push({
                vertical: true,
                pos: bestX.line,
                kind: bestX.kind
            });
        }
        if (bestY) {
            result.y = y + bestY.delta;
            result.guides.push({
                vertical: false,
                pos: bestY.line,
                kind: bestY.kind
            });
        }

        // Cell mode overrides the magnet entirely: everything lands on a cell
        // boundary, whether or not it was near one.
        if (Settings.snap.cells) {
            result.x = root.toCell(result.x);
            result.y = root.toCell(result.y);
            result.guides = [];
        }

        return result;
    }

    clip: true

    // --- background -------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.6)
    }

    Item {
        id: artboard

        x: EditorState.panX
        y: EditorState.panY
        width: root.tw
        height: root.th
        scale: root.zoom
        transformOrigin: Item.TopLeft

        // Board background: the real wallpaper if wanted, otherwise a plain
        // "empty desktop" so layout decisions aren't fighting a busy image.
        Rectangle {
            anchors.fill: parent
            color: Theme.surfaceContainerLowest
        }

        Image {
            anchors.fill: parent
            visible: Settings.editor.showWallpaper && Wall.valid
            source: Wall.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: Settings.appearance.smoothImages
            mipmap: Settings.appearance.mipmaps
            cache: true
            opacity: 0.85
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha("#000000", Settings.editor.dim * 0.45)
        }

        // Board border + shadow so the artboard reads as a physical surface.
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1 / root.zoom
            border.color: Theme.alpha(Theme.primary, 0.5)
        }

        GridOverlay {
            anchors.fill: parent
            zoom: root.zoom
        }

        UsableArea {
            anchors.fill: parent
            visible: Settings.editor.showSafeArea
            screenName: EditorState.target
            zoom: root.zoom
            extraMargin: Settings.snap.margin
        }

        // --- widgets ------------------------------------------------------

        Repeater {
            id: frames

            model: Store.widgets

            WidgetFrame {
                required property var model
                required property int index

                instance: model
                canvas: root
                visible: model.screen === EditorState.target
                enabled: visible
            }
        }

        // --- alignment guides ---------------------------------------------

        Repeater {
            model: Settings.snap.showGuides ? EditorState.guides : []

            Rectangle {
                required property var modelData

                readonly property color guideColour: modelData.kind === "widget" ? Theme.tertiary : modelData.kind === "centre" ? Theme.error : modelData.kind === "reserved" ? Theme.secondary : modelData.kind === "grid" ? Theme.alpha(Theme.primary, 0.55) : Theme.primary

                x: modelData.vertical ? modelData.pos - width / 2 : 0
                y: modelData.vertical ? 0 : modelData.pos - height / 2
                width: modelData.vertical ? 1 / root.zoom : artboard.width
                height: modelData.vertical ? artboard.height : 1 / root.zoom
                color: guideColour
                opacity: 0.9
                z: 9000
            }
        }

        // --- marquee ------------------------------------------------------

        Rectangle {
            id: marquee

            property real originX: 0
            property real originY: 0

            visible: EditorState.marqueeActive
            color: Theme.alpha(Theme.primary, 0.12)
            border.width: 1 / root.zoom
            border.color: Theme.primary
            z: 9500
        }
    }

    // --- viewport input ---------------------------------------------------

    MouseArea {
        id: viewportArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        z: -1
        cursorShape: root.panning || root.spaceHeld ? Qt.ClosedHandCursor : Qt.ArrowCursor

        property real lastX: 0
        property real lastY: 0
        property bool marqueeing: false

        onPressed: mouse => {
            viewportArea.lastX = mouse.x;
            viewportArea.lastY = mouse.y;

            if (mouse.button === Qt.MiddleButton || root.spaceHeld) {
                root.panning = true;
                return;
            }

            if (mouse.button === Qt.RightButton) {
                root.requestContextMenu(mouse.x, mouse.y, "");
                return;
            }

            // Left press on empty canvas: start a marquee.
            const p = root.toDesign(mouse.x, mouse.y);
            marquee.originX = p.x;
            marquee.originY = p.y;
            marquee.x = p.x;
            marquee.y = p.y;
            marquee.width = 0;
            marquee.height = 0;
            viewportArea.marqueeing = true;
            EditorState.marqueeActive = true;

            if (!(mouse.modifiers & Qt.ControlModifier) && !(mouse.modifiers & Qt.ShiftModifier))
                EditorState.clearSelection();
        }

        onPositionChanged: mouse => {
            if (root.panning) {
                EditorState.panX += mouse.x - viewportArea.lastX;
                EditorState.panY += mouse.y - viewportArea.lastY;
                viewportArea.lastX = mouse.x;
                viewportArea.lastY = mouse.y;
                return;
            }

            if (!viewportArea.marqueeing)
                return;

            const p = root.toDesign(mouse.x, mouse.y);
            marquee.x = Math.min(marquee.originX, p.x);
            marquee.y = Math.min(marquee.originY, p.y);
            marquee.width = Math.abs(p.x - marquee.originX);
            marquee.height = Math.abs(p.y - marquee.originY);
        }

        onReleased: mouse => {
            root.panning = false;

            if (viewportArea.marqueeing) {
                viewportArea.marqueeing = false;
                EditorState.marqueeActive = false;

                if (marquee.width > 4 && marquee.height > 4) {
                    const hits = [];
                    for (let i = 0; i < Store.widgets.count; i++) {
                        const w = Store.widgets.get(i);
                        if (w.screen !== EditorState.target || w.hidden || w.locked)
                            continue;
                        const overlaps = w.x < marquee.x + marquee.width && w.x + w.w > marquee.x && w.y < marquee.y + marquee.height && w.y + w.h > marquee.y;
                        if (overlaps)
                            hits.push(w.id);
                    }
                    const additive = (mouse.modifiers & Qt.ControlModifier) || (mouse.modifiers & Qt.ShiftModifier);
                    EditorState.setSelection(additive ? EditorState.selection.concat(hits.filter(h => !EditorState.isSelected(h))) : hits);
                }
            }
        }

        onWheel: wheel => {
            if (wheel.modifiers & Qt.ControlModifier) {
                root.zoomAt(wheel.angleDelta.y > 0 ? 1.12 : 1 / 1.12, wheel.x, wheel.y);
            } else if (wheel.modifiers & Qt.ShiftModifier) {
                EditorState.panX += wheel.angleDelta.y * 0.6;
            } else {
                EditorState.panY += wheel.angleDelta.y * 0.6;
                EditorState.panX += wheel.angleDelta.x * 0.6;
            }
        }
    }

    // Fit as soon as the viewport is measured, once per session.
    onLaidOutChanged: if (root.laidOut && !root.fitted)
        root.fit()

    Component.onCompleted: root.fit()
}
