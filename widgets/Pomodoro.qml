import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// A work/break timer. Click to start or pause, right-click to reset.
//
// Only asks for a one-second clock while it is actually counting - a paused
// pomodoro costs nothing.
WidgetBase {
    id: root

    interactive: true
    needs: root.running ? ["clock.seconds"] : []

    property bool running: false
    property bool onBreak: false
    property int remaining: root.workSeconds
    property int completed: 0

    readonly property int workSeconds: Math.round(root.num("work", 25) * 60)
    readonly property int breakSeconds: Math.round(root.num("break", 5) * 60)
    readonly property int longBreakSeconds: Math.round(root.num("longBreak", 15) * 60)
    readonly property int longEvery: Math.max(1, Math.round(root.num("longEvery", 4)))

    readonly property int total: root.onBreak ? (root.completed % root.longEvery === 0 && root.completed > 0 ? root.longBreakSeconds : root.breakSeconds) : root.workSeconds
    readonly property real progress: root.total > 0 ? 1 - root.remaining / root.total : 0
    readonly property color tint: root.onBreak ? root.colour("breakColour", Theme.tertiary) : root.accent

    function reset(): void {
        root.running = false;
        root.onBreak = false;
        root.remaining = root.workSeconds;
    }

    function advance(): void {
        if (root.onBreak) {
            root.onBreak = false;
            root.remaining = root.workSeconds;
        } else {
            root.completed++;
            root.onBreak = true;
            root.remaining = root.completed % root.longEvery === 0 ? root.longBreakSeconds : root.breakSeconds;
        }
        if (root.flag("notify", true))
            Quickshell.execDetached(["notify-send", "-a", "Pomodoro", root.onBreak ? "Break time" : "Back to work", root.onBreak ? `${Math.round(root.remaining / 60)} minutes` : `${Math.round(root.workSeconds / 60)} minutes`]);
        if (!root.flag("autoContinue", true))
            root.running = false;
    }

    // Counts down off the shared clock rather than its own interval, so the
    // widget cannot drift away from the wall clock while the machine is busy.
    property int lastTick: Clock.seconds

    Connections {
        target: Clock
        enabled: root.running

        function onSecondsChanged(): void {
            if (Clock.seconds === root.lastTick)
                return;
            root.lastTick = Clock.seconds;
            if (root.remaining > 0)
                root.remaining--;
            if (root.remaining <= 0)
                root.advance();
        }
    }

    onWorkSecondsChanged: if (!root.running && !root.onBreak)
        root.remaining = root.workSeconds

    Ring {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        value: root.progress
        thickness: root.num("thickness", 9)
        colour: root.tint
        trackColour: Theme.alpha(root.tint, 0.16)
    }

    Column {
        anchors.centerIn: parent
        spacing: -2

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `${Math.floor(root.remaining / 60)}:${root.remaining % 60 < 10 ? "0" : ""}${root.remaining % 60}`
            font.family: Theme.mono
            font.pixelSize: root.num("size", 26)
            font.weight: Font.DemiBold
            color: root.fg
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.running ? (root.onBreak ? "BREAK" : "FOCUS") : "PAUSED"
            font.pixelSize: Math.max(8, root.num("size", 26) * 0.34)
            font.weight: Font.Bold
            font.letterSpacing: 1.4
            color: root.running ? root.tint : root.muted
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showCount", true) && root.completed > 0
            text: `${root.completed} done`
            font.pixelSize: Math.max(8, root.num("size", 26) * 0.3)
            color: root.muted
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.editing
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.reset();
            else {
                root.lastTick = Clock.seconds;
                root.running = !root.running;
            }
        }
    }
}
