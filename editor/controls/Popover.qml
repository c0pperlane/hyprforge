pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import qs.config

// Hosts a dropdown or picker panel outside the control that owns it.
//
// A popup declared as a child of its control is clipped by whatever clips the
// control - and in the Inspector two things do: Section clips so it can
// animate its own collapse, and the panel's Flickable clips so scrolled
// content stays inside the palette. A menu drawn there comes out sliced off,
// which is exactly what it did.
//
// So the content is reparented to the window's contentItem and positioned
// against the anchor by hand. Anchors cannot cross that boundary, and
// mapToItem is a function call rather than a binding - nothing would tell it
// to recompute - so the position is recomputed on a short timer that runs only
// while the popover is open. That covers scrolling the Inspector, dragging the
// palette by its header and the window resizing, without any of them having to
// know this exists.
Item {
    id: root

    property Item anchorItem: root.parent
    property bool open: false
    property real contentWidth: 200
    property real contentHeight: 200
    // Right-aligned to the anchor rather than left, for controls that sit
    // against the right edge of a row.
    property bool alignRight: false
    property real margin: 5

    default property alias content: holder.data

    // Falls back to the control itself if there is no window to escape into.
    // Clipped is worse than correct, but invisible is worse than both.
    readonly property Item host: root.Window.contentItem ?? root

    // Opens upward when the anchor is close enough to the bottom edge that the
    // content would run off it.
    readonly property bool flipUp: {
        if (!root.host || !root.anchorItem)
            return false;
        const below = root.anchorItem.mapToItem(root.host, 0, root.anchorItem.height);
        return !!below && root.host.height > 0 && below.y + root.contentHeight + 16 > root.host.height;
    }

    function reposition(): void {
        if (!root.host || !root.anchorItem || !root.open)
            return;
        const p = root.anchorItem.mapToItem(root.host, 0, 0);
        if (!p)
            return;
        frame.x = root.alignRight ? p.x + root.anchorItem.width - frame.width : p.x;
        frame.y = root.flipUp ? p.y - frame.height - root.margin : p.y + root.anchorItem.height + root.margin;
    }

    onOpenChanged: root.reposition()

    Timer {
        running: root.open
        interval: 50
        repeat: true
        triggeredOnStart: true
        onTriggered: root.reposition()
    }

    // Anything outside dismisses it. Below the content, above everything else,
    // and only while open - an always-present transparent sheet would swallow
    // clicks meant for the widgets underneath.
    MouseArea {
        parent: root.host
        anchors.fill: parent
        visible: root.open && root.host !== root
        z: 998
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: root.open = false
    }

    Item {
        id: frame

        parent: root.host
        visible: root.open
        z: 999
        width: root.contentWidth
        height: root.contentHeight

        Item {
            id: holder

            anchors.fill: parent
        }
    }
}
