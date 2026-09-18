pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

// The live desktop: one layer-shell surface per monitor rendering everything
// placed in the editor.
//
// Sits on WlrLayer.Bottom rather than Background so interactive widgets
// (transport controls, checklists, launcher tiles) actually receive clicks -
// the Background layer is meant for wallpaper content and doesn't route input
// reliably. Input is masked down to just the interactive widgets' rectangles,
// so the rest of the desktop stays clickable as if nothing were there.
Variants {
    id: root

    required property bool editorOpen

    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData

        // Guarded: a Variants instance briefly sees a null modelData while the
        // screen list is being rebuilt, and an unguarded read there throws and
        // leaves screenName empty - which makes every widget on that output
        // blink out, because they match on this string.
        readonly property string screenName: modelData?.name ?? ""
        // Only the pure-display widgets fade; keeping interactive ones alive
        // would mean invisible click targets.
        readonly property bool onDesktop: {
            if (!Settings.layer.hideWhenCovered)
                return true;
            const mon = Hyprland.monitorFor(win.modelData);
            const tops = mon?.activeWorkspace?.toplevels?.values ?? [];
            return tops.every(t => t.lastIpcObject?.floating ?? false);
        }

        screen: modelData
        WlrLayershell.namespace: "hyprforge"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        // OnDemand only while a text widget is actually on this output: the
        // compositor then hands this surface keyboard focus when you click into
        // it, and leaves it alone otherwise. None means a sticky note can be
        // clicked but never typed into.
        WlrLayershell.keyboardFocus: win.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        property bool wantsKeyboard: false
        // Any text widget on this output currently holding the caret.
        property bool textFocused: false

        function releaseTextFocus(): void {
            for (let i = 0; i < repeater.count; i++)
                repeater.itemAt(i)?.releaseFocus();
        }
        color: "transparent"

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        visible: Settings.layer.enabled

        // Widgets only count as displayed when this layer is actually drawing
        // them: enabled, not eclipsed by the editor, and either on a visible
        // desktop or configured to stay put when covered.
        readonly property bool layerLive: Settings.layer.enabled && !root.editorOpen && (win.onDesktop || Settings.layer.inactiveOpacity > 0)

        // Counted rather than recomputed, and guarded by what was last
        // counted: the change handler and Component.onCompleted both fire
        // during startup, and an unguarded increment in each leaves the tally
        // one too high for the rest of the session.
        property bool countedLive: false

        function countLive(): void {
            if (win.layerLive === win.countedLive)
                return;
            win.countedLive = win.layerLive;
            Demand.liveLayers += win.layerLive ? 1 : -1;
        }

        onLayerLiveChanged: {
            win.countLive();
            win.publishReason();
        }

        Component.onCompleted: {
            win.countLive();
            win.publishReason();
            maskBuilder.restart();
        }

        Component.onDestruction: {
            if (win.countedLive)
                Demand.liveLayers--;
        }

        function publishReason(): void {
            if (win.layerLive)
                Demand.idleReason = "";
            else if (!Settings.layer.enabled)
                Demand.idleReason = "widget layer hidden";
            else if (root.editorOpen)
                Demand.idleReason = "editor is open";
            else
                Demand.idleReason = "desktop is covered by windows";
        }

        mask: Region {
            id: maskRegion

            intersection: Intersection.Combine
        }

        // Catches clicks anywhere outside the focused field while the mask is
        // widened. Behind the widgets, so their own handling still wins.
        MouseArea {
            anchors.fill: parent
            z: -1
            enabled: win.textFocused
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: win.releaseTextFocus()
        }

        // Losing compositor focus - clicking a real window, switching
        // workspace - should let go of the caret too. Read through the Window
        // attached property: PanelWindow itself has no `active`.
        readonly property bool surfaceActive: surface.Window.active

        onSurfaceActiveChanged: {
            if (!win.surfaceActive && win.textFocused)
                win.releaseTextFocus();
        }

        Item {
            id: surface

            anchors.fill: parent

            // Layer-shell windows have no opacity of their own, so the fade
            // lives on the content item. Hidden outright while the editor owns
            // the screen - it draws its own draggable copy of these widgets.
            opacity: root.editorOpen ? 0 : win.onDesktop ? 1 : Settings.layer.inactiveOpacity

            Behavior on opacity {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                id: repeater

                model: Store.widgets

                Item {
                    id: slot

                    // `model` as a whole rather than per-role required
                    // properties: the roles are named x/y/z, which would
                    // collide with Item's own final properties.
                    required property var model

                    readonly property bool mine: model.screen === win.screenName

                    // Visibility conditions. An unmet condition un-builds the
                    // widget rather than hiding it, so an element waiting for
                    // its condition costs nothing - which is the whole point
                    // of putting one on it.
                    readonly property var cond: Store.parseCond(model.cond)
                    readonly property bool condMet: Cond.evaluate(slot.cond, win.screenName)

                    // A condition that reads a service has to keep that
                    // service awake while the widget is *placed*, not while it
                    // is built: "show when lyrics exist" cannot come true if
                    // nothing is fetching lyrics. This is the one demand the
                    // layer holds on behalf of something it is not drawing,
                    // and only for widgets whose rules actually need it.
                    readonly property string condDemandId: `cond:${model.id}`
                    readonly property var condDemands: win.layerLive && mine && !model.hidden ? Cond.demands(slot.cond) : []

                    onCondDemandsChanged: Demand.sync(slot.condDemandId, slot.condDemands)
                    Component.onCompleted: Demand.sync(slot.condDemandId, slot.condDemands)
                    Component.onDestruction: Demand.releaseAll(slot.condDemandId)

                    visible: mine && !model.hidden && condMet
                    enabled: visible
                    x: model.x
                    y: model.y
                    width: model.w
                    height: model.h
                    z: model.z
                    rotation: model.rot
                    opacity: model.op

                    WidgetHost {
                        id: host

                        anchors.fill: parent
                        type: slot.model.type
                        wid: slot.model.id
                        instantiate: slot.mine && !slot.model.hidden && slot.condMet
                        live: win.layerLive && slot.mine && !slot.model.hidden && slot.condMet
                        props: {
                            try {
                                return JSON.parse(slot.model.props);
                            } catch (e) {
                                return ({});
                            }
                        }
                        onInteractiveChanged: maskBuilder.restart()
                        onTextInputChanged: maskBuilder.restart()
                    }

                    readonly property bool wantsInput: host.interactive
                    readonly property bool wantsKeyboard: host.textInput
                    readonly property bool holdsFocus: host.textFocused

                    function releaseFocus(): void {
                        host.releaseFocus();
                    }

                    onVisibleChanged: maskBuilder.restart()
                    onWantsInputChanged: maskBuilder.restart()
                    onWantsKeyboardChanged: maskBuilder.restart()
                    onHoldsFocusChanged: maskBuilder.restart()
                }
            }
        }

        // Rebuilding the input mask means creating Region objects, so it is
        // debounced rather than run per property change during a drag.
        Timer {
            id: maskBuilder

            interval: 120
            onTriggered: win.rebuildMask()
        }

        Component {
            id: regionComp

            Region {
                required property Item target

                item: target
                intersection: Intersection.Combine
            }
        }

        property var maskRegions: []

        function rebuildMask(): void {
            for (const r of win.maskRegions)
                r.destroy();

            const regions = [];
            let keyboard = false;
            let focused = false;
            for (let i = 0; i < repeater.count; i++) {
                const slot = repeater.itemAt(i);
                if (!slot?.visible)
                    continue;
                if (slot.wantsInput)
                    regions.push(regionComp.createObject(win, {
                        target: slot
                    }));
                if (slot.wantsKeyboard)
                    keyboard = true;
                if (slot.holdsFocus)
                    focused = true;
            }
            win.wantsKeyboard = keyboard;
            win.textFocused = focused;

            // While something is being typed into, claim the whole output so a
            // click on bare wallpaper reaches us and can drop the caret. The
            // mask shrinks straight back once focus is released.
            if (focused)
                regions.push(regionComp.createObject(win, {
                    target: surface
                }));

            win.maskRegions = regions;
            maskRegion.regions = regions;
        }

        Connections {
            target: Store

            function onChanged(): void {
                maskBuilder.restart();
            }
        }
    }
}
