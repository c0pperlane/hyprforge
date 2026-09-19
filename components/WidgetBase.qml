import QtQuick
import QtQuick.Effects
import qs.config

// Base class for every catalogue widget.
//
// Gives each element the shared Surface treatment, resolved palette colours and
// a padded content area, so an individual widget file only contains what makes
// it that widget. Widgets declare their children normally - they land inside
// the padded area automatically.
Item {
    id: root

    // Instance props, as stored in layout.json (already merged with defaults).
    property var p: ({})
    // True while the editor is open, so widgets can suppress live animation or
    // show placeholder content instead of empty states.
    property bool editing: false
    property bool selected: false

    readonly property color accent: Theme.resolve(p.accent, Theme.primary)
    readonly property color fg: Theme.resolve(p.fg, Theme.fgSurface)
    readonly property color muted: Theme.resolve(p.muted, Theme.fgSurfaceVariant)
    readonly property real pad: p.padding ?? 0

    // Instance id, so attachment can be looked up. Set by the host.
    property string wid: ""

    // --- corners -----------------------------------------------------------
    //
    // A corner is squared when this widget is snapped flush against a
    // neighbour there, so two elements read as one panel. Otherwise it takes
    // either the single linked radius or its own per-corner value.
    readonly property var attached: Attach.cornersFor(root.wid)

    function cornerRadius(key: string, squared: bool): real {
        if (squared)
            return 0;
        if (root.flag("radiusLinked", true))
            return root.num("radius", 22);
        return root.num(key, root.num("radius", 22));
    }

    readonly property real cornerTL: root.cornerRadius("radiusTL", root.attached.tl)
    readonly property real cornerTR: root.cornerRadius("radiusTR", root.attached.tr)
    readonly property real cornerBL: root.cornerRadius("radiusBL", root.attached.bl)
    readonly property real cornerBR: root.cornerRadius("radiusBR", root.attached.br)

    // Widgets that need clicks set this; the live layer uses it to build the
    // input mask so everything else stays click-through.
    property bool interactive: false

    // Widgets with a real text field set this as well. Pointer input and
    // keyboard input are granted separately by the compositor: the input mask
    // delivers clicks, but a layer-shell surface declaring
    // WlrKeyboardFocus.None can never receive a keystroke no matter what the
    // mask says. The live layer switches to OnDemand only while something on
    // that output actually wants typing, so the desktop isn't competing for
    // focus with real windows the rest of the time.
    property bool textInput: false

    // True while this widget's text field actually holds the caret. The live
    // layer widens its input mask to the whole output while that is the case,
    // so a click on bare wallpaper can be caught and used to let go - clicking
    // the desktop moves compositor focus nowhere on its own, so without this
    // the note keeps eating keystrokes after you have moved on.
    property bool textFocused: false

    // Implemented by widgets that can hold the caret.
    function releaseFocus(): void {}

    // --- service demand ----------------------------------------------------
    //
    // `live` is set by the host: true only while this instance is genuinely
    // being displayed. A widget on a covered desktop, on another monitor, or
    // marked hidden is not live, and everything it was keeping awake is
    // released. `needs` is the set of service keys it requires - widgets whose
    // data source depends on a prop (a stat ring's metric, say) can make it a
    // binding and the demand follows automatically.
    property bool live: false
    property var needs: []

    readonly property string demandId: `w${Math.random().toString(36).slice(2, 10)}`

    function syncDemand(): void {
        Demand.sync(root.demandId, root.live ? root.needs : []);
    }

    property bool countedLive: false

    function countLive(): void {
        if (root.live === root.countedLive)
            return;
        root.countedLive = root.live;
        Demand.liveWidgets += root.live ? 1 : -1;
    }

    onLiveChanged: {
        root.syncDemand();
        root.countLive();
    }
    onNeedsChanged: root.syncDemand()
    Component.onCompleted: {
        root.syncDemand();
        root.countLive();
    }
    Component.onDestruction: {
        Demand.releaseAll(root.demandId);
        if (root.countedLive)
            Demand.liveWidgets--;
    }

    // Widgets that edit their own state (a note's body, a checklist's ticks)
    // call writeProp; WidgetHost routes it to the Store so the change is
    // persisted against this instance. The widget never needs to know its id.
    signal propChangeRequested(string key, var value)

    function writeProp(key: string, value: var): void {
        root.propChangeRequested(key, value);
    }

    default property alias content: inner.data

    function num(key: string, fallback: real): real {
        const v = root.p[key];
        return v === undefined || v === null || isNaN(v) ? fallback : v;
    }

    function str(key: string, fallback: string): string {
        const v = root.p[key];
        return v === undefined || v === null ? (fallback ?? "") : `${v}`;
    }

    function flag(key: string, fallback: bool): bool {
        const v = root.p[key];
        return v === undefined || v === null ? (fallback ?? false) : !!v;
    }

    function colour(key: string, fallback: color): color {
        return Theme.resolve(root.p[key], fallback);
    }

    // "a\nb\nc" -> ["a", "b", "c"], blanks dropped.
    function lines(key: string): var {
        return root.str(key, "").split("\n").map(s => s.trim()).filter(s => s.length > 0);
    }

    // --- shadow / glow -------------------------------------------------------
    //
    // Applied to `root` itself - Surface's fill plus whatever the widget
    // actually draws, together - rather than to the card fill alone. A widget
    // with `bg: "none"` has no fill for a shadow to be cast from (MultiEffect
    // derives one from what a layered item renders, not from its geometry),
    // and that is exactly the case a bare clock or a stat number most wants
    // one. Every default reproduces the old fixed-angle `shadow: bool`
    // exactly, so a layout saved before this existed renders unchanged
    // (Store.qml migrates the old key).
    readonly property string shadowMode: root.str("shadowMode", "none")
    readonly property bool shadowOn: root.shadowMode !== "none"
    readonly property bool shadowIsGlow: root.shadowMode === "glow"
    readonly property real shadowAngle: root.num("shadowAngle", 90)
    readonly property real shadowDistance: root.num("shadowDistance", 6)
    // Screen-space angle: 0deg points right, 90deg down - "90, straight down"
    // is both trig-correct and the old shadow's actual direction.
    readonly property real shadowDx: root.shadowIsGlow ? 0 : Math.cos(root.shadowAngle * Math.PI / 180) * root.shadowDistance
    readonly property real shadowDy: root.shadowIsGlow ? 0 : Math.sin(root.shadowAngle * Math.PI / 180) * root.shadowDistance
    // 0..1 spread reads as "how much bigger than the shape" - only glow
    // actually wants to grow past its own edges; a drop shadow that did the
    // same would look like a second, larger copy of the widget peeking out.
    readonly property real shadowScale: 1 + (root.shadowIsGlow ? root.num("shadowSpread", 0) * 0.6 : 0)

    // layer.enabled captures a fixed-size texture - exactly `width` x
    // `height`, nothing more - so it clips anything a widget draws past its
    // own box. Several widgets (HeroClock's date line among them) rely on
    // Qt's default no-clip behaviour to let a line of text run past their
    // nominal height, which was harmless until there was a layer here to cut
    // it off. Tested and confirmed with a standalone reproduction before
    // this comment was written: the clip is real, and Item.childrenRect
    // does not see through `inner` to find it, because childrenRect only
    // ever looks at its own direct children's declared geometry, not
    // theirs. shadowHost below measures one level past `inner` explicitly
    // instead - `inner`'s own direct children, which is exactly as deep as
    // `default property alias content: inner.data` ever nests a widget's
    // top-level item - and is sized to whichever is larger, its own nominal
    // box or that measurement. `inner` itself is untouched: nothing about
    // how a widget anchors or centres its content inside it changes.
    readonly property real contentRight: {
        let maxX = 0;
        for (const c of inner.children)
            if (c.visible !== false)
                maxX = Math.max(maxX, c.x + c.width);
        return maxX;
    }
    readonly property real contentBottom: {
        let maxY = 0;
        for (const c of inner.children)
            if (c.visible !== false)
                maxY = Math.max(maxY, c.y + c.height);
        return maxY;
    }

    Item {
        id: shadowHost

        anchors.left: parent.left
        anchors.top: parent.top
        width: Math.max(root.width, inner.x + root.contentRight)
        height: Math.max(root.height, inner.y + root.contentBottom)

        layer.enabled: root.shadowOn
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.alpha(root.colour("shadowColour", Theme.shadow), root.num("shadowOpacity", 0.45))
            shadowBlur: root.num("shadowBlur", 0.9)
            shadowHorizontalOffset: root.shadowDx
            shadowVerticalOffset: root.shadowDy
            shadowScale: root.shadowScale
            // Off, deliberately. MultiEffect's default is to auto-expand its
            // own render target so blur/offset never gets clipped - which
            // sounds right until two widgets sit close together, as most of
            // this app's own widgets do: the blur then bleeds straight past
            // shadowHost's own bounds and onto whatever is a few pixels below
            // it, no matter how that neighbour is arranged. Confirmed side by
            // side before shipping: the same shadow, same blur, with this on
            // versus off, next to a plain rectangle a modest gap below - on,
            // the rectangle's top edge visibly darkens; off, it stays clean.
            // The one thing this does cost is a widget whose own shadow
            // settings are pushed hard enough (large Distance, large Blur)
            // to want more room than its own box - it gets clipped at
            // shadowHost's edge rather than spilling further, which for a
            // shadow (unlike content) is the point, not a limitation.
            autoPaddingEnabled: false

            Behavior on shadowHorizontalOffset {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on shadowVerticalOffset {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on shadowScale {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        Surface {
            x: 0
            y: 0
            width: root.width
            height: root.height
            mode: root.p.bg ?? "none"
            colour: root.colour("bgColour", Theme.surfaceContainer)
            fillOpacity: root.num("bgOpacity", 0.85)
            radius: root.num("radius", 22)
            topLeftRadius: root.cornerTL
            topRightRadius: root.cornerTR
            bottomLeftRadius: root.cornerBL
            bottomRightRadius: root.cornerBR
            border: root.flag("border", false)
            borderColour: root.colour("borderColour", Theme.outlineVariant)
        }

        Item {
            id: inner

            x: root.pad
            y: root.pad
            width: root.width - root.pad * 2
            height: root.height - root.pad * 2
        }
    }
}
