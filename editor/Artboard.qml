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

    // Zoom is bounded, not infinite. The floor is derived from the board
    // rather than fixed: "half the size that fits on screen" means the same
    // thing on a 1080p panel and a 4K one, where a hardcoded 0.08 would be
    // unusable on one and pointless on the other. You can always get back
    // with the fit button.
    readonly property real fitZoom: root.laidOut ? Math.min((width - 160) / root.tw, (height - 160) / root.th) : 1
    // Never above 1: the "100%" reset in the toolbar has to stay reachable
    // even when the board is small and the viewport is huge.
    readonly property real minZoom: Math.min(1, Math.max(0.05, root.fitZoom * 0.5))
    readonly property real maxZoom: 6

    function clampZoom(z: real): real {
        return Math.max(root.minZoom, Math.min(root.maxZoom, z));
    }

    function fit(): void {
        if (!root.laidOut)
            return;
        root.fitted = true;
        EditorState.zoom = Math.max(0.05, Math.min(2, root.fitZoom));
        centre();
    }

    function centre(): void {
        EditorState.panX = (width - root.tw * EditorState.zoom) / 2;
        EditorState.panY = (height - root.th * EditorState.zoom) / 2;
    }

    function zoomAt(factor: real, px: real, py: real): void {
        const old = EditorState.zoom;
        const next = root.clampZoom(old * factor);
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

    // --- spacing snapping ---------------------------------------------------
    //
    // Edge snapping lines things up; it says nothing about the space between
    // them. Dragging a third card under two that sit 20px apart, alignment
    // gets the left edges flush and then leaves the gap wherever the mouse
    // happened to stop. This adds the other half: candidate positions where
    // the gap to a neighbour equals a gap the layout already uses, or where
    // the element sits exactly halfway between the two it is being dropped
    // between.
    //
    // Both axes work the same way, so the geometry is written once against
    // "near/far" edges and the caller says which axis those are.

    function boxesFor(excludeId: string, axisY: bool, rect: var): var {
        // Only siblings that overlap on the *other* axis count: a widget off
        // in another column is not part of this column's rhythm, and treating
        // it as one produces snaps that look like nothing at all.
        const out = [];
        const lo = axisY ? rect.x : rect.y;
        const hi = lo + (axisY ? rect.w : rect.h);
        for (let i = 0; i < Store.widgets.count; i++) {
            const w = Store.widgets.get(i);
            if (w.screen !== EditorState.target || w.id === excludeId || w.hidden)
                continue;
            const olo = axisY ? w.x : w.y;
            const ohi = olo + (axisY ? w.w : w.h);
            if (ohi <= lo || olo >= hi)
                continue;
            out.push({
                near: axisY ? w.y : w.x,
                far: (axisY ? w.y : w.x) + (axisY ? w.h : w.w),
                lo: olo,
                hi: ohi
            });
        }
        out.sort((a, b) => a.near - b.near);
        return out;
    }

    // Every gap the current layout already uses on this axis, deduped to whole
    // pixels. Taken from the whole board rather than only this column, so a
    // new column can pick up the spacing an existing one established.
    function knownGaps(excludeId: string, axisY: bool): var {
        const rows = [];
        for (let i = 0; i < Store.widgets.count; i++) {
            const w = Store.widgets.get(i);
            if (w.screen !== EditorState.target || w.id === excludeId || w.hidden)
                continue;
            rows.push({
                near: axisY ? w.y : w.x,
                far: (axisY ? w.y : w.x) + (axisY ? w.h : w.w),
                lo: axisY ? w.x : w.y,
                hi: (axisY ? w.x : w.y) + (axisY ? w.w : w.h)
            });
        }
        const seen = ({});
        const out = [];
        for (const a of rows)
            for (const b of rows) {
                if (a === b || b.near < a.far)
                    continue;
                if (b.lo >= a.hi || b.hi <= a.lo)
                    continue;   // not in line with each other
                const g = Math.round(b.near - a.far);
                if (g <= 0 || g > Settings.snap.maxGap || seen[g])
                    continue;
                // Only the gap between *neighbours* is a gap. Measured across
                // something else, the distance from the first card to the
                // third is a number the layout never intended, and offering it
                // as a magnet makes the snap feel arbitrary.
                let blocked = false;
                for (const c of rows) {
                    if (c === a || c === b || c.lo >= a.hi || c.hi <= a.lo)
                        continue;
                    if (c.far > a.far && c.near < b.near) {
                        blocked = true;
                        break;
                    }
                }
                if (blocked)
                    continue;
                seen[g] = true;
                out.push(g);
            }
        return out;
    }

    // Candidate near-edge positions for the dragged rect, as {pos, gap}.
    function spacingCandidates(rect: var, id: string, axisY: bool): var {
        if (!Settings.snap.toSpacing)
            return [];
        const size = axisY ? rect.h : rect.w;
        const boxes = root.boxesFor(id, axisY, rect);
        if (!boxes.length)
            return [];

        const gaps = root.knownGaps(id, axisY);
        const out = [];

        for (const b of boxes)
            for (const g of gaps) {
                out.push({
                    pos: b.far + g,
                    gap: g
                });      // below / right of it
                out.push({
                    pos: b.near - g - size,
                    gap: g
                });   // above / left of it
            }

        // Centred between two neighbours: the case with no established gap to
        // copy, which is most of the time when the second element goes down.
        for (let i = 0; i < boxes.length - 1; i++) {
            const free = boxes[i + 1].near - boxes[i].far - size;
            if (free > 1 && free / 2 <= Settings.snap.maxGap)
                out.push({
                    pos: boxes[i].far + free / 2,
                    gap: free / 2
                });
        }
        return out;
    }

    // After a spacing snap is chosen, find every gap on that axis that now
    // measures the same, so the overlay can show the whole rhythm rather than
    // just the one edge that snapped.
    function spacingBands(rect: var, id: string, axisY: bool, gap: real): var {
        const size = axisY ? rect.h : rect.w;
        const near = axisY ? rect.y : rect.x;
        const far = near + size;
        const bands = [];
        const tol = 0.75;

        const me = {
            near: near,
            far: far,
            lo: axisY ? rect.x : rect.y,
            hi: (axisY ? rect.x : rect.y) + (axisY ? rect.w : rect.h)
        };
        const boxes = root.boxesFor(id, axisY, rect).concat([me]).sort((a, b) => a.near - b.near);

        for (let i = 0; i < boxes.length - 1; i++) {
            const g = boxes[i + 1].near - boxes[i].far;
            if (Math.abs(g - gap) > tol)
                continue;
            bands.push({
                from: boxes[i].far,
                to: boxes[i + 1].near,
                // Drawn down the middle of the overlap the two share, so the
                // marker sits between them rather than off to one side.
                cross: (Math.max(boxes[i].lo, boxes[i + 1].lo) + Math.min(boxes[i].hi, boxes[i + 1].hi)) / 2
            });
        }
        return bands;
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

        // Spacing competes with alignment on plain distance, at the same
        // weight as a sibling edge: matching the gap a layout already uses is
        // as deliberate a relationship as lining two edges up, and both beat
        // the grid, which stays the weakest magnet. Weighting spacing below
        // the grid looked reasonable and made it almost unreachable - with a
        // 32px grid no point on the board is more than 16px from a line.
        //
        // Only the whole rect moves, so spacing applies to a drag, not to the
        // edge being pulled during a resize.
        const wholeRect = useEdges.left && useEdges.right && useEdges.top && useEdges.bottom;

        function bestSpacing(own, axisY) {
            if (!wholeRect)
                return null;
            let winner = null;
            for (const c of root.spacingCandidates({
                x: x,
                y: y,
                w: w,
                h: h
            }, id, axisY)) {
                const delta = c.pos - own;
                const score = Math.abs(delta);
                if (Math.abs(delta) <= d && (!winner || score < winner.score))
                    winner = {
                        delta: delta,
                        gap: c.gap,
                        score: score
                    };
            }
            return winner;
        }

        const spaceX = bestSpacing(x, false);
        const spaceY = bestSpacing(y, true);

        if (spaceX && (!bestX || spaceX.score < bestX.score)) {
            result.x = x + spaceX.delta;
            for (const b of root.spacingBands({
                x: result.x,
                y: y,
                w: w,
                h: h
            }, id, false, spaceX.gap))
                result.guides.push({
                    kind: "spacing",
                    vertical: true,
                    gap: spaceX.gap,
                    from: b.from,
                    to: b.to,
                    cross: b.cross
                });
        } else if (bestX) {
            result.x = x + bestX.delta;
            result.guides.push({
                vertical: true,
                pos: bestX.line,
                kind: bestX.kind
            });
        }

        if (spaceY && (!bestY || spaceY.score < bestY.score)) {
            result.y = y + spaceY.delta;
            for (const b of root.spacingBands({
                x: x,
                y: result.y,
                w: w,
                h: h
            }, id, true, spaceY.gap))
                result.guides.push({
                    kind: "spacing",
                    vertical: false,
                    gap: spaceY.gap,
                    from: b.from,
                    to: b.to,
                    cross: b.cross
                });
        } else if (bestY) {
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

    // The area around the board. Opaque on purpose: this used to be 60% over
    // the editor's own 72% scrim, which leaves about a ninth of whatever is
    // behind the editor still showing. At 100% zoom the board covers it and
    // nobody notices; zoom out and your actual windows appear around the
    // edges, which reads as the editor being broken rather than translucent.
    Rectangle {
        anchors.fill: parent
        color: Theme.background
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
            model: Settings.snap.showGuides ? EditorState.guides.filter(g => g.kind !== "spacing") : []

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

        // --- spacing markers ----------------------------------------------
        //
        // Every gap that matches the one just snapped to, not only the one the
        // pointer is near: the point of the snap is the rhythm, so showing one
        // measurement of it would be showing the wrong thing.

        Repeater {
            model: Settings.snap.showGuides ? EditorState.guides.filter(g => g.kind === "spacing") : []

            Item {
                required property var modelData

                readonly property bool vert: modelData.vertical
                readonly property real thickness: 1 / root.zoom
                readonly property real cap: 5 / root.zoom

                x: vert ? modelData.from : modelData.cross
                y: vert ? modelData.cross : modelData.from
                width: vert ? Math.max(0, modelData.to - modelData.from) : 0
                height: vert ? 0 : Math.max(0, modelData.to - modelData.from)
                z: 9100

                // The span itself.
                Rectangle {
                    x: parent.vert ? 0 : -parent.thickness / 2
                    y: parent.vert ? -parent.thickness / 2 : 0
                    width: parent.vert ? parent.width : parent.thickness
                    height: parent.vert ? parent.thickness : parent.height
                    color: Theme.error
                }

                // End caps, so a gap of a few pixels is still legible as a
                // measurement rather than a stray dot.
                Repeater {
                    model: 2

                    Rectangle {
                        required property int index

                        readonly property real at: index === 0 ? 0 : (parent.vert ? parent.width : parent.height)

                        x: parent.vert ? at - parent.thickness / 2 : -parent.cap
                        y: parent.vert ? -parent.cap : at - parent.thickness / 2
                        width: parent.vert ? parent.thickness : parent.cap * 2
                        height: parent.vert ? parent.cap * 2 : parent.thickness
                        color: Theme.error
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: gapLabel.implicitWidth + 8 / root.zoom
                    height: gapLabel.implicitHeight + 3 / root.zoom
                    radius: height / 2
                    color: Theme.error
                    visible: (parent.vert ? parent.width : parent.height) * root.zoom > 26

                    ListTxt {
                        id: gapLabel

                        anchors.centerIn: parent
                        text: `${Math.round(parent.parent.modelData.gap)}`
                        font.family: Theme.mono
                        font.pixelSize: Math.max(7, Math.round(9 / root.zoom))
                        color: Theme.contrast(Theme.error)
                    }
                }
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
