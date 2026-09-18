pragma Singleton

import QtQuick
import Quickshell

// Editor-session state: what's selected, where the canvas is, which monitor is
// being designed. Deliberately not persisted - it's view state, not document
// state (that's Store).
Singleton {
    id: root

    // Monitor whose layout is being edited. Design coordinates are that
    // monitor's real pixels, so a layout is always authored 1:1.
    property string target: ""
    property real targetWidth: 1920
    property real targetHeight: 1080

    property real zoom: 1
    property real panX: 0
    property real panY: 0

    property var selection: []
    property string hovered: ""
    property bool marqueeActive: false

    // Chrome visibility - "preview" hides every panel so the design can be
    // judged on its own.
    // True while the editor overlay exists, so services that only matter to the
    // editor can idle the rest of the time.
    property bool editorActive: false

    property bool preview: false
    property bool libraryOpen: true
    property bool inspectorOpen: true
    property bool layersOpen: false
    property bool canvasPanelOpen: false
    property bool styleOpen: false
    property bool typographyOpen: false

    property var guides: []          // live alignment guides during a drag
    property string statusText: ""

    signal fitRequested
    signal focusWidget(string id)

    readonly property bool hasSelection: root.selection.length > 0
    readonly property bool multiSelection: root.selection.length > 1
    readonly property string primary: root.selection.length ? root.selection[root.selection.length - 1] : ""

    function isSelected(id: string): bool {
        return root.selection.indexOf(id) >= 0;
    }

    function select(id: string): void {
        root.selection = id ? [id] : [];
    }

    function toggle(id: string): void {
        const s = root.selection.slice();
        const i = s.indexOf(id);
        if (i >= 0)
            s.splice(i, 1);
        else
            s.push(id);
        root.selection = s;
    }

    function addToSelection(id: string): void {
        if (!root.isSelected(id))
            root.selection = root.selection.concat([id]);
    }

    function setSelection(ids: var): void {
        root.selection = ids ?? [];
    }

    function clearSelection(): void {
        root.selection = [];
    }

    // Drops ids that no longer exist (after a delete or an undo).
    function prune(): void {
        const s = root.selection.filter(id => Store.indexOf(id) >= 0);
        if (s.length !== root.selection.length)
            root.selection = s;
    }

    function status(msg: string): void {
        root.statusText = msg;
        statusTimer.restart();
    }

    Timer {
        id: statusTimer

        interval: 2400
        onTriggered: root.statusText = ""
    }

    Connections {
        target: Store

        function onChanged(): void {
            root.prune();
        }
    }
}
