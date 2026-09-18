pragma Singleton

import QtQuick
import Quickshell

// Ref-counting for expensive services.
//
// A desktop widget spends most of its life invisible - covered by a window,
// hidden, or on a display you are not looking at - and there is no reason for
// it to keep a `nvidia-smi` poll or a weather request alive while it is. Each
// widget declares the service keys it needs; the host acquires them while the
// widget is actually being displayed and releases them the moment it is not.
// Services bind their timers to `needed(key)`.
//
// Holders are tracked as a set of instance ids rather than a plain count, so a
// widget that acquires twice (a prop change re-running the sync) cannot inflate
// the count, and a destroyed widget can drop everything it held in one call
// without having to remember what that was.
Singleton {
    id: root

    // key -> { holderId: true }. Replaced wholesale on every change so
    // holdersChanged fires and `needed()` is a real, non-elidable dependency -
    // mutating in place and bumping a counter read as `void root.rev` works
    // only until the compiler decides that read is dead code.
    property var holders: ({})

    // Why the list below is empty, when it is. The layer publishes this so
    // `caelestia-forge status` can tell "gating is working, the desktop is
    // covered" apart from "the widgets are broken" - they look identical from
    // the outside, and only one of them is a problem.
    property string idleReason: ""

    // How many layer surfaces are currently drawing widgets. With more than
    // one monitor a covered screen must not claim the whole layer is idle, so
    // `idleReason` only means anything while this is zero.
    property int liveLayers: 0

    // How many widget instances currently consider themselves on display.
    // Purely diagnostic: a layer that is drawing while this is zero means the
    // host is not marking anything live, which is a bug, not thrift.
    property int liveWidgets: 0

    function needed(key: string): bool {
        const h = root.holders[key];
        return !!h && Object.keys(h).length > 0;
    }

    function count(key: string): int {
        const h = root.holders[key];
        return h ? Object.keys(h).length : 0;
    }

    function acquire(key: string, id: string): void {
        if (!key || !id)
            return;
        const cur = root.holders[key];
        if (cur && cur[id])
            return; // already held - nothing changes, don't churn bindings
        const next = Object.assign({}, root.holders);
        next[key] = Object.assign({}, cur ?? ({}));
        next[key][id] = true;
        root.holders = next;
    }

    function release(key: string, id: string): void {
        const cur = root.holders[key];
        if (!cur || !cur[id])
            return;
        const next = Object.assign({}, root.holders);
        const set = Object.assign({}, cur);
        delete set[id];
        if (Object.keys(set).length)
            next[key] = set;
        else
            delete next[key];
        root.holders = next;
    }

    // Drops every key this holder was holding. Called when a widget is torn
    // down, so a lost release can't pin a service on forever.
    function releaseAll(id: string): void {
        if (!id)
            return;
        let changed = false;
        const next = ({});
        for (const key of Object.keys(root.holders)) {
            const set = Object.assign({}, root.holders[key]);
            if (set[id]) {
                delete set[id];
                changed = true;
            }
            if (Object.keys(set).length)
                next[key] = set;
        }
        if (changed)
            root.holders = next;
    }

    // Replaces everything a holder wants in one step: acquires what is new,
    // releases what it no longer needs. One reassignment, one binding pass.
    function sync(id: string, keys: var): void {
        if (!id)
            return;
        const wanted = ({});
        for (const k of keys ?? [])
            if (k)
                wanted[k] = true;

        const next = ({});
        let changed = false;

        for (const key of Object.keys(root.holders)) {
            const set = Object.assign({}, root.holders[key]);
            if (set[id] && !wanted[key]) {
                delete set[id];
                changed = true;
            }
            if (Object.keys(set).length)
                next[key] = set;
        }

        for (const key of Object.keys(wanted)) {
            if (!next[key] || !next[key][id]) {
                next[key] = Object.assign({}, next[key] ?? ({}));
                next[key][id] = true;
                changed = true;
            }
        }

        if (changed)
            root.holders = next;
    }

    // For diagnostics: what is currently keeping things awake.
    readonly property var active: {
        const out = [];
        for (const key of Object.keys(root.holders))
            out.push(`${key}(${Object.keys(root.holders[key]).length})`);
        return out.sort();
    }
}
