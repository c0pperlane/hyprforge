pragma Singleton

import QtQuick
import Quickshell

// Which corners of each widget are "attached" to a neighbour.
//
// When two elements are snapped flush - a daylight arc sitting directly on top
// of a now-playing card, say - the corners where they meet should square off so
// the pair reads as one panel rather than two cards with a seam. Doing that by
// hand means remembering to un-square them again the moment you move something,
// so it is derived from geometry instead: edges that touch, square.
//
// Computed once per document change into a map, rather than per widget on
// demand: a ListModel's per-row changes do not notify QML bindings, so a
// function reading Store would never re-evaluate. Replacing the map wholesale
// gives every consumer a real dependency.
Singleton {
    id: root

    // Flush within this many pixels counts as touching. Snapping already lands
    // edges exactly, so this only forgives hand-nudged placements.
    readonly property int tolerance: 3

    // Overlap along the shared edge must be at least this long, so two widgets
    // meeting at a single corner point are not treated as joined.
    readonly property int minOverlap: 8

    property var map: ({})
    // Which of a widget's four SIDES - not corners - has a neighbour flush
    // against it. A corner squares only once a neighbour reaches that corner;
    // an edge here is true the moment a neighbour overlaps it by minOverlap
    // at all, whether or not it happens to reach either end. Shadows read
    // this instead of the corner map: what a shadow needs to know is "is
    // there something immediately past this edge for me to fall onto",
    // which a squared corner only sometimes answers.
    property var edgeMap: ({})

    readonly property var noCorners: ({
            tl: false,
            tr: false,
            bl: false,
            br: false
        })

    readonly property var noEdges: ({
            top: false,
            right: false,
            bottom: false,
            left: false
        })

    function cornersFor(id: string): var {
        return root.map[id] ?? root.noCorners;
    }

    function edgesFor(id: string): var {
        return root.edgeMap[id] ?? root.noEdges;
    }

    function recompute(): void {
        const items = [];
        for (let i = 0; i < Store.widgets.count; i++) {
            const w = Store.widgets.get(i);
            if (w.hidden)
                continue;
            items.push({
                id: w.id,
                screen: w.screen,
                x: w.x,
                y: w.y,
                w: w.w,
                h: w.h,
                attach: root.attachEnabled(w)
            });
        }

        const out = ({});
        const edgeOut = ({});
        const tol = root.tolerance;
        const minOv = root.minOverlap;

        for (const a of items) {
            const c = {
                tl: false,
                tr: false,
                bl: false,
                br: false
            };
            const e = {
                top: false,
                right: false,
                bottom: false,
                left: false
            };

            for (const b of items) {
                if (b === a || b.screen !== a.screen)
                    continue;

                const vOverlap = Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y);
                const hOverlap = Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x);

                // b immediately to the left of a
                if (vOverlap >= minOv && Math.abs(b.x + b.w - a.x) <= tol) {
                    // Edges are permissive on purpose - true for any
                    // neighbour, corner-joinable or not, the moment it
                    // genuinely overlaps this side. A shadow should not fall
                    // on whatever is next door regardless of whether that
                    // thing happens to be a surface eligible to visually
                    // join with this one; corners stay narrower, below.
                    e.left = true;
                    if (a.attach && b.attach) {
                        if (b.y <= a.y + tol)
                            c.tl = true;
                        if (b.y + b.h >= a.y + a.h - tol)
                            c.bl = true;
                    }
                }
                // b immediately to the right
                if (vOverlap >= minOv && Math.abs(b.x - (a.x + a.w)) <= tol) {
                    e.right = true;
                    if (a.attach && b.attach) {
                        if (b.y <= a.y + tol)
                            c.tr = true;
                        if (b.y + b.h >= a.y + a.h - tol)
                            c.br = true;
                    }
                }
                // b immediately above
                if (hOverlap >= minOv && Math.abs(b.y + b.h - a.y) <= tol) {
                    e.top = true;
                    if (a.attach && b.attach) {
                        if (b.x <= a.x + tol)
                            c.tl = true;
                        if (b.x + b.w >= a.x + a.w - tol)
                            c.tr = true;
                    }
                }
                // b immediately below
                if (hOverlap >= minOv && Math.abs(b.y - (a.y + a.h)) <= tol) {
                    e.bottom = true;
                    if (a.attach && b.attach) {
                        if (b.x <= a.x + tol)
                            c.bl = true;
                        if (b.x + b.w >= a.x + a.w - tol)
                            c.br = true;
                    }
                }
            }

            out[a.id] = c;
            edgeOut[a.id] = e;
        }

        root.map = out;
        root.edgeMap = edgeOut;
    }

    function attachEnabled(w: var): bool {
        try {
            const p = JSON.parse(w.props);
            // Only surfaces can visibly join; a bare text element has no corner
            // to square, and letting it participate would square its neighbour
            // against nothing.
            if ((p.bg ?? "none") === "none")
                return false;
            return p.attach === undefined ? true : !!p.attach;
        } catch (e) {
            return false;
        }
    }

    Connections {
        target: Store

        function onChanged(): void {
            recomputeTimer.restart();
        }
    }

    // Short enough to feel live while dragging, long enough not to run the
    // whole pass on every frame of one.
    Timer {
        id: recomputeTimer

        interval: 30
        onTriggered: root.recompute()
    }

    Component.onCompleted: recomputeTimer.restart()
}
