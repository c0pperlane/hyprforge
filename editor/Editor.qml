pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.config
import qs.editor.panels
import qs.services

// The designer. A fullscreen overlay that replaces the desktop with an
// artboard for the monitor you're designing, plus floating tool palettes.
//
// Only one editor window exists even on a multi-monitor setup: the monitor
// being designed is a *choice* (the Display selector in the toolbar), not
// wherever the window happens to be. That way you can lay out the headless/AR
// outputs from the laptop panel.
PanelWindow {
    id: root

    property bool open: false

    // Not `closed`: PanelWindow already has a signal by that name.
    signal dismissed

    readonly property ShellScreen focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    function targetScreenFor(name: string): var {
        return Quickshell.screens.find(s => s.name === name) ?? root.focusedScreen;
    }

    function setTarget(name: string): void {
        const s = root.targetScreenFor(name);
        if (!s)
            return;
        EditorState.target = s.name;
        EditorState.targetWidth = s.width;
        EditorState.targetHeight = s.height;
        EditorState.clearSelection();
        canvas.fit();
    }

    // Add a widget at the centre of the current view, or at a design point.
    //
    // `var` rather than `real` for the coordinates: an omitted `real` argument
    // arrives as NaN, not undefined, so the "was a position given?" check below
    // used to pass and the widget was placed at NaN,NaN - which serialises to
    // null and renders as an invisible, unclickable element. Clicking a library
    // card (rather than dragging it) took exactly that path.
    function addWidget(type: string, designX: var, designY: var): void {
        const def = Registry.def(type);
        if (!def)
            return;
        let x = designX;
        let y = designY;
        if (!Number.isFinite(x) || !Number.isFinite(y)) {
            const c = canvas.toDesign(canvas.width / 2, canvas.height / 2);
            x = c.x - def.size.w / 2;
            y = c.y - def.size.h / 2;
        }
        const id = Store.add(type, EditorState.target, Math.round(x), Math.round(y), null);
        EditorState.select(id);
        EditorState.status(`Added ${def.name}`);
    }

    // --- selection-wide operations ---------------------------------------

    function deleteSelection(): void {
        if (!EditorState.hasSelection)
            return;
        Store.pushUndo();
        const ids = EditorState.selection.slice();
        for (const id of ids) {
            const i = Store.indexOf(id);
            if (i >= 0)
                Store.widgets.remove(i);
        }
        Store.touch();
        EditorState.clearSelection();
        EditorState.status(`Deleted ${ids.length} element${ids.length === 1 ? "" : "s"}`);
    }

    function duplicateSelection(): void {
        const ids = EditorState.selection.slice();
        const made = [];
        for (const id of ids) {
            const n = Store.duplicate(id);
            if (n)
                made.push(n);
        }
        if (made.length)
            EditorState.setSelection(made);
    }

    function nudge(dx: real, dy: real): void {
        if (!EditorState.hasSelection)
            return;
        Store.pushUndo();
        for (const id of EditorState.selection) {
            const w = Store.get(id);
            if (w && !w.locked)
                Store.setGeometry(id, w.x + dx, w.y + dy, undefined, undefined);
        }
    }

    function align(mode: string): void {
        const ids = EditorState.selection.filter(id => !Store.get(id)?.locked);
        if (!ids.length)
            return;
        Store.pushUndo();

        // A single selection aligns against the artboard; several align to
        // their shared bounding box - the behaviour people expect from Figma.
        const useBoard = ids.length === 1;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const id of ids) {
            const w = Store.get(id);
            minX = Math.min(minX, w.x);
            minY = Math.min(minY, w.y);
            maxX = Math.max(maxX, w.x + w.w);
            maxY = Math.max(maxY, w.y + w.h);
        }
        if (useBoard) {
            const u = canvas.usable;
            minX = u.x;
            minY = u.y;
            maxX = u.x + u.width;
            maxY = u.y + u.height;
        }

        for (const id of ids) {
            const w = Store.get(id);
            let x = w.x;
            let y = w.y;
            if (mode === "left")
                x = minX;
            else if (mode === "right")
                x = maxX - w.w;
            else if (mode === "hcentre")
                x = (minX + maxX) / 2 - w.w / 2;
            else if (mode === "top")
                y = minY;
            else if (mode === "bottom")
                y = maxY - w.h;
            else if (mode === "vcentre")
                y = (minY + maxY) / 2 - w.h / 2;
            Store.setGeometry(id, x, y, undefined, undefined);
        }
        EditorState.status(`Aligned ${mode}`);
    }

    // Makes everything in the selection the same size as the one selected last
    // - the same reference every design tool uses, and the reason the toolbar
    // says "match" rather than "equalise".
    function matchSize(mode: string): void {
        const ref = Store.get(EditorState.primary);
        if (!ref || EditorState.selection.length < 2)
            return;
        Store.pushUndo();
        let n = 0;
        for (const id of EditorState.selection) {
            if (id === ref.id)
                continue;
            const w = Store.get(id);
            if (!w || w.locked)
                continue;
            Store.setGeometry(id, undefined, undefined, mode === "height" ? undefined : ref.w, mode === "width" ? undefined : ref.h);
            n++;
        }
        EditorState.status(`Matched ${mode === "both" ? "size" : mode} on ${n} element${n === 1 ? "" : "s"}`);
    }

    // Quantises elements onto whole grid cells in one go - the tidy-up for a
    // layout that was placed by eye before the grid was turned on.
    function snapToGrid(all: bool): void {
        const cell = Math.max(1, Settings.grid.size);
        const gap = Math.max(0, Settings.snap.gap);
        const ids = [];
        if (all) {
            for (let i = 0; i < Store.widgets.count; i++) {
                const w = Store.widgets.get(i);
                if (w.screen === EditorState.target)
                    ids.push(w.id);
            }
        } else {
            for (const id of EditorState.selection)
                ids.push(id);
        }
        if (!ids.length)
            return;

        Store.pushUndo();
        let n = 0;
        for (const id of ids) {
            const w = Store.get(id);
            if (!w || w.locked)
                continue;
            const x = Math.round(w.x / cell) * cell;
            const y = Math.round(w.y / cell) * cell;
            // Round the far edge rather than the width, so an element keeps the
            // cells it visually occupies instead of drifting a cell narrower.
            const right = Math.round((w.x + w.w) / cell) * cell;
            const bottom = Math.round((w.y + w.h) / cell) * cell;
            Store.setGeometry(id, x + gap / 2, y + gap / 2, Math.max(cell, right - x - gap), Math.max(cell, bottom - y - gap));
            n++;
        }
        EditorState.status(`Snapped ${n} element${n === 1 ? "" : "s"} to the grid`);
    }

    function distribute(horizontal: bool): void {
        const ids = EditorState.selection.filter(id => !Store.get(id)?.locked);
        if (ids.length < 3)
            return;
        Store.pushUndo();
        const items = ids.map(id => Store.get(id)).sort((a, b) => horizontal ? a.x - b.x : a.y - b.y);
        const first = items[0];
        const last = items[items.length - 1];
        const span = horizontal ? (last.x + last.w) - first.x : (last.y + last.h) - first.y;
        let used = 0;
        for (const it of items)
            used += horizontal ? it.w : it.h;
        const gap = (span - used) / (items.length - 1);

        let cursor = horizontal ? first.x : first.y;
        for (const it of items) {
            if (horizontal) {
                Store.setGeometry(it.id, cursor, undefined, undefined, undefined);
                cursor += it.w + gap;
            } else {
                Store.setGeometry(it.id, undefined, cursor, undefined, undefined);
                cursor += it.h + gap;
            }
        }
        EditorState.status("Distributed");
    }

    screen: root.focusedScreen
    WlrLayershell.namespace: "hyprforge-editor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Component.onCompleted: {
        EditorState.editorActive = true;
        root.setTarget(root.focusedScreen?.name ?? "");
        // A layer rule gives the overlay a real backdrop blur. `hyprctl
        // keyword` rather than Hyprland.dispatch because this setup drives
        // Hyprland from Lua, where dispatch() expects Lua call syntax.
        // Runtime-only and scoped to our namespace, so nothing persists.
        if (Settings.editor.blur)
            Quickshell.execDetached(["hyprctl", "keyword", "layerrule", "blur,namespace:hyprforge-editor"]);
    }

    // --- backdrop ---------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, Settings.editor.dim)
    }

    // --- canvas -----------------------------------------------------------

    Artboard {
        id: canvas

        anchors.fill: parent
        focus: true

        onRequestContextMenu: (mx, my, id) => {
            contextMenu.targetId = id;
            contextMenu.popupAt(mx, my);
        }

        // Key handling lives on the artboard: PanelWindow is not an Item, so
        // the Keys attached property can't go on the window itself.
        Keys.onPressed: event => root.handleKey(event)
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Space) {
                canvas.spaceHeld = false;
                event.accepted = true;
            }
        }
    }

    function handleKey(event: var): void {
        const ctrl = event.modifiers & Qt.ControlModifier;
        const shift = event.modifiers & Qt.ShiftModifier;
        // In cell mode the arrow keys move by a cell - nudging by one pixel
        // would immediately break the alignment cell mode exists to keep.
        const cell = Math.max(1, Settings.grid.size);
        const step = Settings.snap.cells ? (shift ? cell * 4 : cell) : (shift ? 10 : 1);

        switch (event.key) {
        case Qt.Key_Escape:
            if (contextMenu.visible)
                contextMenu.visible = false;
            else if (EditorState.hasSelection)
                EditorState.clearSelection();
            else
                root.dismissed();
            event.accepted = true;
            return;
        case Qt.Key_Delete:
        case Qt.Key_Backspace:
            root.deleteSelection();
            event.accepted = true;
            return;
        case Qt.Key_Left:
            root.nudge(-step, 0);
            event.accepted = true;
            return;
        case Qt.Key_Right:
            root.nudge(step, 0);
            event.accepted = true;
            return;
        case Qt.Key_Up:
            root.nudge(0, -step);
            event.accepted = true;
            return;
        case Qt.Key_Down:
            root.nudge(0, step);
            event.accepted = true;
            return;
        case Qt.Key_Space:
            canvas.spaceHeld = true;
            event.accepted = true;
            return;
        }

        if (ctrl) {
            switch (event.key) {
            case Qt.Key_Z:
                if (shift)
                    Store.redo();
                else
                    Store.undo();
                EditorState.status(shift ? "Redo" : "Undo");
                event.accepted = true;
                return;
            case Qt.Key_Y:
                Store.redo();
                event.accepted = true;
                return;
            case Qt.Key_D:
                root.duplicateSelection();
                event.accepted = true;
                return;
            case Qt.Key_C:
                Store.copy(EditorState.selection);
                EditorState.status("Copied");
                event.accepted = true;
                return;
            case Qt.Key_V:
                EditorState.setSelection(Store.paste(EditorState.target, 28, 28));
                event.accepted = true;
                return;
            case Qt.Key_A:
                const all = [];
                for (let i = 0; i < Store.widgets.count; i++) {
                    const w = Store.widgets.get(i);
                    if (w.screen === EditorState.target && !w.locked)
                        all.push(w.id);
                }
                EditorState.setSelection(all);
                event.accepted = true;
                return;
            case Qt.Key_S:
                Store.save();
                EditorState.status("Saved");
                event.accepted = true;
                return;
            case Qt.Key_0:
                EditorState.zoom = 1;
                canvas.centre();
                event.accepted = true;
                return;
            case Qt.Key_1:
                canvas.fit();
                event.accepted = true;
                return;
            case Qt.Key_Plus:
            case Qt.Key_Equal:
                canvas.zoomAt(1.15, canvas.width / 2, canvas.height / 2);
                event.accepted = true;
                return;
            case Qt.Key_Minus:
                canvas.zoomAt(1 / 1.15, canvas.width / 2, canvas.height / 2);
                event.accepted = true;
                return;
            }
            return;
        }

        switch (event.key) {
        case Qt.Key_G:
            Settings.grid.visible = !Settings.grid.visible;
            Settings.save();
            EditorState.status(`Grid ${Settings.grid.visible ? "on" : "off"}`);
            event.accepted = true;
            return;
        case Qt.Key_S:
            Settings.snap.enabled = !Settings.snap.enabled;
            Settings.save();
            EditorState.status(`Snapping ${Settings.snap.enabled ? "on" : "off"}`);
            event.accepted = true;
            return;
        case Qt.Key_L:
            if (EditorState.hasSelection) {
                const w = Store.get(EditorState.primary);
                for (const id of EditorState.selection)
                    Store.set(id, "locked", !w.locked, false);
                Store.pushUndo();
                EditorState.status(w.locked ? "Unlocked" : "Locked");
            }
            event.accepted = true;
            return;
        case Qt.Key_H:
            if (EditorState.hasSelection) {
                const w = Store.get(EditorState.primary);
                for (const id of EditorState.selection)
                    Store.set(id, "hidden", !w.hidden, false);
                EditorState.status(w.hidden ? "Shown" : "Hidden");
            }
            event.accepted = true;
            return;
        case Qt.Key_Tab:
            EditorState.preview = !EditorState.preview;
            event.accepted = true;
            return;
        case Qt.Key_T:
            EditorState.styleOpen = !EditorState.styleOpen;
            event.accepted = true;
            return;
        case Qt.Key_F:
            EditorState.typographyOpen = !EditorState.typographyOpen;
            event.accepted = true;
            return;
        case Qt.Key_C:
            Settings.snap.cells = !Settings.snap.cells;
            Settings.save();
            EditorState.status(`Cell mode ${Settings.snap.cells ? "on" : "off"}`);
            event.accepted = true;
            return;
        case Qt.Key_B:
            Settings.editor.showSafeArea = !Settings.editor.showSafeArea;
            Settings.save();
            EditorState.status(`Usable area ${Settings.editor.showSafeArea ? "on" : "off"}`);
            event.accepted = true;
            return;
        case Qt.Key_F1:
            help.visible = !help.visible;
            event.accepted = true;
            return;
        }
    }

    // --- chrome -----------------------------------------------------------

    Item {
        id: chrome

        anchors.fill: parent

        // Palettes are positioned once, as soon as the chrome has a real size -
        // not bound to the edges, because they are draggable and a binding
        // would be broken by the first drag anyway. Component.onCompleted is
        // too early: width/height are still zero there.
        property bool placed: false

        function placePanels(): void {
            if (chrome.placed || chrome.width < 400 || chrome.height < 400)
                return;
            chrome.placed = true;

            library.x = 18;
            library.y = 88;

            inspector.x = chrome.width - inspector.width - 18;
            inspector.y = 88;

            layers.x = chrome.width - layers.width - 18;
            layers.y = chrome.height - layers.fullHeight - 76;

            canvasPanel.x = 18;
            canvasPanel.y = chrome.height - canvasPanel.fullHeight - 76;

            // Its own column, left of the Inspector - the two are often wanted
            // at the same time (pick a style, then tune the result).
            stylePanel.x = chrome.width - inspector.width - stylePanel.width - 30;
            stylePanel.y = 88;

            typography.x = library.x + library.width + 24;
            typography.y = 88;
        }

        onWidthChanged: placePanels()
        onHeightChanged: placePanels()
        Component.onCompleted: placePanels()
        opacity: EditorState.preview ? 0 : 1
        visible: opacity > 0
        enabled: !EditorState.preview

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Toolbar {
            id: toolbar

            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter

            onCloseRequested: root.dismissed()
            onFitRequested: canvas.fit()
            onZoomIn: canvas.zoomAt(1.15, canvas.width / 2, canvas.height / 2)
            onZoomOut: canvas.zoomAt(1 / 1.15, canvas.width / 2, canvas.height / 2)
            onTargetPicked: name => root.setTarget(name)
            onAlignRequested: mode => root.align(mode)
            onDistributeRequested: horizontal => root.distribute(horizontal)
            onMatchSizeRequested: mode => root.matchSize(mode)
        }

        // Palettes are placed once rather than bound to the edges: they are
        // draggable, and a positional binding would be silently broken the
        // first time one is moved anyway.
        LibraryPanel {
            id: library

            width: 292
            fullHeight: Math.min(620, parent.height - 200)
            open: EditorState.libraryOpen


            onCloseRequested: EditorState.libraryOpen = false
            onAddRequested: type => root.addWidget(type, undefined, undefined)

            onDragBegan: type => {
                ghost.type = type;
                ghost.visible = true;
            }
            onDragMoved: (gx, gy) => {
                // Scene coordinates: the ghost and the canvas both live in the
                // same window, so no per-item mapping chain is needed.
                const p = chrome.mapFromItem(null, gx, gy);
                ghost.x = p.x + 14;
                ghost.y = p.y + 14;
            }
            onDragEnded: ghost.visible = false
            onDropped: (type, gx, gy) => {
                const p = canvas.mapFromItem(null, gx, gy);
                if (p.x < 0 || p.y < 0 || p.x > canvas.width || p.y > canvas.height)
                    return;
                const d = canvas.toDesign(p.x, p.y);
                const def = Registry.def(type);
                root.addWidget(type, d.x - def.size.w / 2, d.y - def.size.h / 2);
            }
        }

        InspectorPanel {
            id: inspector

            width: 330
            fullHeight: Math.min(760, parent.height - 160)
            open: EditorState.inspectorOpen


            onCloseRequested: EditorState.inspectorOpen = false
        }

        LayersPanel {
            id: layers

            width: 300
            fullHeight: 320
            open: EditorState.layersOpen


            onCloseRequested: EditorState.layersOpen = false
        }

        TypographyPanel {
            id: typography

            width: 340
            fullHeight: Math.min(980, parent.height - 130)
            open: EditorState.typographyOpen

            onCloseRequested: EditorState.typographyOpen = false
        }

        StylePanel {
            id: stylePanel

            width: 330
            fullHeight: Math.min(720, parent.height - 180)
            open: EditorState.styleOpen

            onCloseRequested: EditorState.styleOpen = false
        }

        CanvasPanel {
            id: canvasPanel

            width: 292
            fullHeight: Math.min(720, parent.height - 200)
            open: EditorState.canvasPanelOpen


            onCloseRequested: EditorState.canvasPanelOpen = false
            onSnapSelectionRequested: root.snapToGrid(false)
            onSnapAllRequested: root.snapToGrid(true)
        }

        StatusBar {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 14

            zoom: EditorState.zoom
            onHelpToggled: help.visible = !help.visible
        }

        ContextMenu {
            id: contextMenu

            onAction: (name, id) => root.menuAction(name, id)
        }

        // Follows the cursor while dragging out of the Library.
        Rectangle {
            id: ghost

            property string type: ""

            visible: false
            z: 9800
            width: ghostRow.implicitWidth + 22
            height: 40
            radius: 14
            color: Theme.alpha(Theme.primary, 0.92)

            Row {
                id: ghostRow

                anchors.centerIn: parent
                spacing: 8

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Registry.def(ghost.type)?.icon ?? "widgets"
                    size: 18
                    color: Theme.fgPrimary
                }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Registry.def(ghost.type)?.name ?? ""
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.fgPrimary
                }
            }
        }

        HelpOverlay {
            id: help

            anchors.fill: parent
            visible: false
            onDismissed: help.visible = false
        }
    }

    function menuAction(name: string, id: string): void {
        switch (name) {
        case "duplicate":
            root.duplicateSelection();
            break;
        case "delete":
            root.deleteSelection();
            break;
        case "front":
            for (const s of EditorState.selection)
                Store.toFront(s);
            break;
        case "back":
            for (const s of EditorState.selection)
                Store.toBack(s);
            break;
        case "lock":
            for (const s of EditorState.selection)
                Store.set(s, "locked", !Store.get(s).locked, false);
            break;
        case "hide":
            for (const s of EditorState.selection)
                Store.set(s, "hidden", !Store.get(s).hidden, false);
            break;
        case "reset":
            for (const s of EditorState.selection)
                Store.resetProps(s);
            break;
        case "paste":
            EditorState.setSelection(Store.paste(EditorState.target, 28, 28));
            break;
        case "selectAll":
            const all = [];
            for (let i = 0; i < Store.widgets.count; i++) {
                const w = Store.widgets.get(i);
                if (w.screen === EditorState.target)
                    all.push(w.id);
            }
            EditorState.setSelection(all);
            break;
        }
    }

    Component.onDestruction: EditorState.editorActive = false

    // Save on close so nothing is lost even if the debounce hasn't fired.
    onOpenChanged: {
        if (!open)
            Store.save();
    }
}
