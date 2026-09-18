import QtQuick
import qs.config
import qs.widgets

// Instantiates one catalogue widget by type name and keeps its props in sync.
Item {
    id: root

    required property string type
    // Instance id, so self-editing widgets can persist through the Store.
    property string wid: ""
    property var props: ({})

    // Whether this instance is actually on display. Drives service demand.
    property bool live: false

    // Whether to construct it at all. A widget belonging to another output, or
    // marked hidden, is never built - the catalogue only declares Components,
    // so nothing exists until something asks for it.
    property bool instantiate: true
    property bool editing: false
    property bool selected: false

    readonly property Item widget: loader.item
    readonly property bool interactive: loader.item?.interactive ?? false
    readonly property bool textInput: loader.item?.textInput ?? false
    readonly property bool textFocused: loader.item?.textFocused ?? false

    function releaseFocus(): void {
        if (loader.item && loader.item.releaseFocus)
            loader.item.releaseFocus();
    }
    readonly property bool ready: loader.status === Loader.Ready

    Loader {
        id: loader

        anchors.fill: parent
        asynchronous: true
        active: root.instantiate
        sourceComponent: Catalog.component(root.type)

        onStatusChanged: {
            if (status === Loader.Error)
                console.warn(`Forge: failed to load widget "${root.type}"`);
        }
    }

    Binding {
        target: loader.item
        property: "p"
        value: root.props
        when: loader.status === Loader.Ready
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: loader.item
        property: "wid"
        value: root.wid
        when: loader.status === Loader.Ready
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: loader.item
        property: "live"
        value: root.live
        when: loader.status === Loader.Ready
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: loader.item
        property: "editing"
        value: root.editing
        when: loader.status === Loader.Ready
        restoreMode: Binding.RestoreNone
    }

    Connections {
        target: loader.item

        function onPropChangeRequested(key: string, value: var): void {
            if (root.wid)
                Store.setProp(root.wid, key, value, true);
        }
    }

    Binding {
        target: loader.item
        property: "selected"
        value: root.selected
        when: loader.status === Loader.Ready
        restoreMode: Binding.RestoreNone
    }

    // Placeholder while an async widget is still coming up, so dragging a
    // freshly dropped element doesn't chase an invisible box.
    Rectangle {
        anchors.fill: parent
        visible: loader.status === Loader.Loading
        radius: 18
        color: Theme.alpha(Theme.fgSurface, 0.06)
    }
}
