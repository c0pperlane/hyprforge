pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The document: every placed widget instance, for every monitor.
//
// Backed by ~/.config/hyprforge/layout.json. Instance props are kept as a
// JSON *string* role rather than a nested object because QML's ListModel turns
// nested JS objects into nested ListModels, which then can't round-trip back
// through JSON.stringify. Stringifying keeps setProperty() atomic and makes the
// undo stack a plain list of strings.
Singleton {
    id: root

    // Schema version of layout.json; bump when the on-disk shape changes.
    readonly property int version: 1

    readonly property alias widgets: model
    property bool loaded: false
    property bool dirty: false
    property bool repairedOnLoad: false

    property var undoStack: []
    property var redoStack: []
    readonly property bool canUndo: undoStack.length > 0
    readonly property bool canRedo: redoStack.length > 0

    property var clipboard: null

    signal changed
    signal instanceAdded(string id)

    // --- output identity --------------------------------------------------
    //
    // A widget records which display it belongs to. Storing only the connector
    // name turned out to be wrong: this laptop's internal panel enumerates as
    // eDP-1 on one boot and eDP-2 on the next, and caelestia's own telemetry
    // code carries a comment saying exactly that. A layout authored on eDP-2
    // then renders on no display at all.
    //
    // So each widget also carries `output`, a stable-ish identity taken from
    // the monitor description (make + model), and the layout is reconciled
    // against the connected displays on load and whenever they change.

    function canonicalFor(name: string): string {
        const mon = Hyprland.monitors.values.find(m => m.name === name);
        const desc = mon?.lastIpcObject?.description ?? "";
        return desc.trim();
    }

    function screenNames(): var {
        return Quickshell.screens.map(s => s.name);
    }

    // Re-points widgets whose recorded display is gone. Idempotent, and safe to
    // call whenever the display list changes.
    function reconcileScreens(): void {
        const names = root.screenNames();
        if (!names.length)
            return; // displays not enumerated yet

        // name -> canonical identity, for the displays actually present
        const canon = ({});
        for (const n of names)
            canon[n] = root.canonicalFor(n);

        let moved = 0;
        for (let i = 0; i < model.count; i++) {
            const w = model.get(i);
            if (names.indexOf(w.screen) >= 0) {
                // Still valid - make sure its identity is recorded for next time.
                if (!w.output && canon[w.screen])
                    model.setProperty(i, "output", canon[w.screen]);
                continue;
            }

            let target = "";
            // 1. Same physical panel, different connector name.
            if (w.output) {
                for (const n of names)
                    if (canon[n] && canon[n] === w.output) {
                        target = n;
                        break;
                    }
            }
            // 2. Same connector family - eDP-2 and eDP-1 are the same laptop
            //    panel renamed, which is the case this whole mechanism exists
            //    for and the one layouts authored before `output` will hit.
            if (!target) {
                const family = w.screen.replace(/-\d+$/, "");
                for (const n of names)
                    if (n.replace(/-\d+$/, "") === family) {
                        target = n;
                        break;
                    }
            }
            // 3. Nothing matched and there is only one display: it can only
            //    have meant that one.
            if (!target && names.length === 1)
                target = names[0];

            if (target) {
                model.setProperty(i, "screen", target);
                if (canon[target])
                    model.setProperty(i, "output", canon[target]);
                moved++;
            }
        }

        if (moved > 0) {
            console.warn(`Forge: moved ${moved} element(s) onto a renamed display`);
            root.touch();
        }
    }

    // --- lookup -----------------------------------------------------------

    function indexOf(id: string): int {
        for (let i = 0; i < model.count; i++)
            if (model.get(i).id === id)
                return i;
        return -1;
    }

    function get(id: string): var {
        const i = indexOf(id);
        return i < 0 ? null : model.get(i);
    }

    function props(id: string): var {
        const w = get(id);
        if (!w)
            return {};
        try {
            return JSON.parse(w.props);
        } catch (e) {
            return {};
        }
    }

    function countOn(screen: string): int {
        let n = 0;
        for (let i = 0; i < model.count; i++)
            if (model.get(i).screen === screen)
                n++;
        return n;
    }

    function nextZ(screen: string): int {
        let z = 0;
        for (let i = 0; i < model.count; i++) {
            const w = model.get(i);
            if (w.screen === screen)
                z = Math.max(z, w.z);
        }
        return z + 1;
    }

    // --- mutation ---------------------------------------------------------

    function uid(): string {
        return `w${Date.now().toString(36)}${Math.floor(Math.random() * 46656).toString(36).padStart(3, "0")}`;
    }

    function add(type: string, screen: string, x: var, y: var, overrides: var): string {
        const def = Registry.def(type);
        if (!def) {
            console.warn("Forge: unknown widget type", type);
            return "";
        }

        const o = overrides ?? ({});
        const id = uid();

        pushUndo();
        // Everything numeric goes through sane(): `??` only catches null and
        // undefined, so a NaN that reached here would sail straight through it
        // and land in the document.
        model.append({
            id: id,
            type: type,
            screen: screen,
            output: root.canonicalFor(screen),
            x: root.sane(o.x ?? x, 120, -100000),
            y: root.sane(o.y ?? y, 120, -100000),
            w: root.sane(o.w, def.size.w, 8),
            h: root.sane(o.h, def.size.h, 8),
            z: Number.isFinite(o.z) ? o.z : nextZ(screen),
            rot: Number.isFinite(o.rot) ? o.rot : 0,
            op: Number.isFinite(o.op) ? o.op : 1,
            locked: o.locked ?? false,
            hidden: o.hidden ?? false,
            cond: root.normaliseCond(o.cond),
            props: JSON.stringify(root.seedProps(type, o.props))
        });
        touch();
        instanceAdded(id);
        return id;
    }

    // Defaults, then the active style preset, then whatever the caller passed -
    // so a pasted or duplicated widget keeps its own look, but a freshly placed
    // one picks up the style you selected.
    function seedProps(type: string, overrides: var): var {
        let props = Registry.defaults(type);
        if (Settings.style.applyToNew)
            props = Presets.merge(type, props, Settings.style.preset);
        return Object.assign(props, overrides ?? ({}));
    }

    function remove(id: string): void {
        const i = indexOf(id);
        if (i < 0)
            return;
        pushUndo();
        model.remove(i);
        touch();
    }

    function duplicate(id: string): string {
        const w = get(id);
        if (!w)
            return "";
        return add(w.type, w.screen, w.x + 28, w.y + 28, {
            w: w.w,
            h: w.h,
            rot: w.rot,
            op: w.op,
            cond: w.cond,
            props: JSON.parse(w.props)
        });
    }

    // `record` false during a drag - the undo entry is pushed once on press.
    function set(id: string, key: string, value: var, record: bool): void {
        const i = indexOf(id);
        if (i < 0)
            return;
        if (record)
            pushUndo();
        model.setProperty(i, key, value);
        touch();
    }

    // Parameters are `var`, not `real`, and every one is checked with
    // Number.isFinite.
    //
    // This is not fussiness. A QML parameter annotated `real` coerces an
    // omitted argument to NaN rather than leaving it undefined, so the obvious
    // `if (w !== undefined && w !== null)` guard passes, Math.round(NaN) is
    // NaN, and JSON.stringify writes NaN as `null`. Every caller that moves
    // something without resizing it - drag, arrow-nudge, align, distribute,
    // match-size - was quietly nulling out width and height. A widget with no
    // size still paints the children that overflow it, which looks like "half
    // the widget rendered" and cannot be clicked, because its hit area is zero.
    function setGeometry(id: string, x: var, y: var, w: var, h: var): void {
        const i = indexOf(id);
        if (i < 0)
            return;
        const def = Registry.def(model.get(i).type);
        if (Number.isFinite(x))
            model.setProperty(i, "x", Math.round(x));
        if (Number.isFinite(y))
            model.setProperty(i, "y", Math.round(y));
        if (Number.isFinite(w))
            model.setProperty(i, "w", Math.max(def?.min?.w ?? 24, Math.round(w)));
        if (Number.isFinite(h))
            model.setProperty(i, "h", Math.max(def?.min?.h ?? 24, Math.round(h)));
        touch();
    }

    // Last line of defence for geometry read back off disk or handed in by a
    // caller: anything non-finite or absurdly small falls back to the widget's
    // catalogue size rather than rendering as an invisible, unclickable dot.
    function sane(value: var, fallback: real, floor: real): real {
        const n = Number(value);
        if (!Number.isFinite(n) || n < (floor ?? 0))
            return fallback;
        return Math.round(n);
    }

    // --- visibility conditions ---------------------------------------------
    //
    // Stored as a JSON string alongside props, for the same reason: a ListModel
    // role has to be a flat value, and a nested object read back out of one is
    // a copy nobody can mutate in place.

    function normaliseCond(value: var): string {
        if (!value)
            return "";
        let o = value;
        if (typeof value === "string") {
            if (!value.trim())
                return "";
            try {
                o = JSON.parse(value);
            } catch (e) {
                return "";
            }
        }
        const rules = [];
        for (const r of o?.rules ?? []) {
            if (!r || !r.key)
                continue;
            const out = {
                key: `${r.key}`,
                not: !!r.not
            };
            if (r.value !== undefined && r.value !== null && r.value !== "")
                out.value = r.value;
            rules.push(out);
        }
        if (!rules.length)
            return "";
        return JSON.stringify({
            mode: o?.mode === "any" ? "any" : "all",
            rules: rules
        });
    }

    // Takes the stored string rather than an id, so a delegate can bind to
    // its own `model.cond` role and actually be notified when it changes -
    // reading the row back out of the model inside a function is a lookup, not
    // a dependency, and the binding would never re-run.
    function parseCond(text: var): var {
        const empty = ({
                mode: "all",
                rules: []
            });
        if (!text)
            return empty;
        try {
            const o = JSON.parse(text);
            return ({
                    mode: o.mode === "any" ? "any" : "all",
                    rules: o.rules ?? []
                });
        } catch (e) {
            return empty;
        }
    }

    function cond(id: string): var {
        return root.parseCond(get(id)?.cond);
    }

    function setCond(id: string, value: var, record: bool): void {
        const i = indexOf(id);
        if (i < 0)
            return;
        if (record ?? true)
            pushUndo();
        model.setProperty(i, "cond", root.normaliseCond(value));
        touch();
    }

    function setProp(id: string, key: string, value: var, record: bool): void {
        const i = indexOf(id);
        if (i < 0)
            return;
        if (record)
            pushUndo();
        const p = props(id);
        p[key] = value;
        model.setProperty(i, "props", JSON.stringify(p));
        touch();
    }

    // Replaces the whole prop set at once - used when applying a style preset,
    // where a per-key round trip would be a dozen redundant saves.
    function setProps(id: string, props: var): void {
        const i = indexOf(id);
        if (i < 0)
            return;
        model.setProperty(i, "props", JSON.stringify(props));
        touch();
    }

    function resetProps(id: string): void {
        const w = get(id);
        if (!w)
            return;
        pushUndo();
        model.setProperty(indexOf(id), "props", JSON.stringify(Registry.defaults(w.type)));
        touch();
    }

    // --- z order ----------------------------------------------------------

    function toFront(id: string): void {
        const w = get(id);
        if (w)
            set(id, "z", nextZ(w.screen), true);
    }

    function toBack(id: string): void {
        const w = get(id);
        if (!w)
            return;
        pushUndo();
        let min = 0;
        for (let i = 0; i < model.count; i++)
            if (model.get(i).screen === w.screen)
                min = Math.min(min, model.get(i).z);
        model.setProperty(indexOf(id), "z", min - 1);
        touch();
    }

    // --- clipboard --------------------------------------------------------

    function copy(ids: var): void {
        const out = [];
        for (const id of ids) {
            const w = get(id);
            if (w)
                out.push({
                    type: w.type,
                    w: w.w,
                    h: w.h,
                    x: w.x,
                    y: w.y,
                    rot: w.rot,
                    op: w.op,
                    cond: w.cond,
                    props: JSON.parse(w.props)
                });
        }
        root.clipboard = out.length ? out : null;
    }

    function paste(screen: string, dx: var, dy: var): var {
        if (!root.clipboard)
            return [];
        const ids = [];
        const ox = Number.isFinite(dx) ? dx : 28;
        const oy = Number.isFinite(dy) ? dy : 28;
        for (const c of root.clipboard)
            ids.push(add(c.type, screen, c.x + ox, c.y + oy, c));
        return ids;
    }

    function clearScreen(screen: string): void {
        pushUndo();
        for (let i = model.count - 1; i >= 0; i--)
            if (model.get(i).screen === screen)
                model.remove(i);
        touch();
    }

    // --- undo -------------------------------------------------------------

    function serialise(): string {
        const out = [];
        for (let i = 0; i < model.count; i++) {
            const w = model.get(i);
            const def = Registry.def(w.type);
            out.push({
                id: w.id,
                type: w.type,
                screen: w.screen,
                output: w.output ?? "",
                x: root.sane(w.x, 0, -100000),
                y: root.sane(w.y, 0, -100000),
                w: root.sane(w.w, def?.size?.w ?? 200, 8),
                h: root.sane(w.h, def?.size?.h ?? 120, 8),
                z: w.z,
                rot: w.rot,
                op: w.op,
                locked: w.locked,
                hidden: w.hidden,
                cond: root.cond(w.id),
                props: JSON.parse(w.props)
            });
        }
        return JSON.stringify({
            version: root.version,
            widgets: out
        }, null, 2);
    }

    // Shadows/glows replaced a plain `shadow: bool` with `shadowMode` plus
    // angle, distance, blur, spread, colour and opacity - and every one of
    // those defaults was chosen to equal the old fixed-angle, fixed-blur
    // shadow's actual constants, so a widget that only ever set `shadow: true`
    // keeps rendering identically without needing the rest migrated too.
    function migrateProps(props: var): var {
        if (!props || props.shadow === undefined)
            return props;
        const p = Object.assign({}, props);
        if (p.shadow === true && p.shadowMode === undefined)
            p.shadowMode = "drop";
        delete p.shadow;
        return p;
    }

    function deserialise(text: string): void {
        model.clear();
        if (!text || !text.trim())
            return;
        const data = JSON.parse(text);
        let repaired = 0;
        let migrated = 0;
        for (const w of data.widgets ?? []) {
            const def = Registry.def(w.type);
            if (!def)
                continue; // widget type went away - drop it rather than crash

            const width = root.sane(w.w, def.size.w, 8);
            const height = root.sane(w.h, def.size.h, 8);
            if (width !== w.w || height !== w.h)
                repaired++;

            const rawProps = w.props ?? {};
            const props = root.migrateProps(rawProps);
            if (props !== rawProps)
                migrated++;

            model.append({
                id: w.id ?? uid(),
                type: w.type,
                screen: w.screen ?? "",
                output: w.output ?? "",
                x: root.sane(w.x, 0, -100000),
                y: root.sane(w.y, 0, -100000),
                w: width,
                h: height,
                z: Number.isFinite(w.z) ? w.z : 0,
                rot: Number.isFinite(w.rot) ? w.rot : 0,
                op: Number.isFinite(w.op) ? w.op : 1,
                locked: w.locked ?? false,
                hidden: w.hidden ?? false,
                cond: root.normaliseCond(w.cond),
                props: JSON.stringify(Object.assign(Registry.defaults(w.type), props))
            });
        }
        if (repaired > 0) {
            console.warn(`Forge: repaired the geometry of ${repaired} element(s) with missing or invalid size`);
            // Persist the repair, otherwise it is redone on every start and the
            // broken values stay on disk waiting to confuse the next reader.
            root.repairedOnLoad = true;
        }
        if (migrated > 0)
            root.repairedOnLoad = true; // same "persist it once" mechanism
    }

    function pushUndo(): void {
        const s = serialise();
        const stack = root.undoStack.slice();
        stack.push(s);
        if (stack.length > 120)
            stack.shift();
        root.undoStack = stack;
        root.redoStack = [];
    }

    function undo(): void {
        if (!root.undoStack.length)
            return;
        const stack = root.undoStack.slice();
        const s = stack.pop();
        const redo = root.redoStack.slice();
        redo.push(serialise());
        root.undoStack = stack;
        root.redoStack = redo;
        deserialise(s);
        touch();
    }

    function redo(): void {
        if (!root.redoStack.length)
            return;
        const redoS = root.redoStack.slice();
        const s = redoS.pop();
        const undoS = root.undoStack.slice();
        undoS.push(serialise());
        root.redoStack = redoS;
        root.undoStack = undoS;
        deserialise(s);
        touch();
    }

    // --- persistence ------------------------------------------------------

    function touch(): void {
        root.dirty = true;
        root.changed();
        saveTimer.restart();
    }

    function save(): void {
        saveTimer.stop();
        view.setText(serialise());
        root.dirty = false;
    }

    ListModel {
        id: model
    }

    // Displays are not necessarily enumerated by the time layout.json is read,
    // so reconciliation waits a beat and then re-runs on every change to the
    // display list.
    Timer {
        id: reconcileTimer

        interval: 600
        onTriggered: root.reconcileScreens()
    }

    Connections {
        target: Quickshell

        function onScreensChanged(): void {
            reconcileTimer.restart();
        }
    }

    Timer {
        id: saveTimer

        interval: 500
        onTriggered: root.save()
    }

    FileView {
        id: view

        path: `${Theme.configPath}/layout.json`
        printErrors: false
        // Deliberately not watching: every save would bounce back as a reload
        // and blow away in-flight edits. Use Store.reload() to pick up an
        // external edit.
        watchChanges: false

        onLoaded: {
            try {
                root.deserialise(text());
            } catch (e) {
                console.warn("Forge: layout.json is malformed -", e);
            }
            root.loaded = true;
            reconcileTimer.restart();
            root.changed();
            if (root.repairedOnLoad) {
                root.repairedOnLoad = false;
                root.save();
            }
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                root.save(); // seed an empty document
        }

        function externalReload(): void {
            reload();
        }
    }

    function reloadFromDisk(): void {
        view.externalReload();
    }
}
