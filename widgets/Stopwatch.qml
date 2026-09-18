import QtQuick
import qs.components
import qs.config
import qs.services

// Stopwatch. Click to start or stop, right-click to reset.
//
// Counts from a wall-clock start time rather than by incrementing a counter, so
// it stays accurate even if the process is busy or briefly suspended.
WidgetBase {
    id: root

    interactive: true
    needs: root.running ? ["clock.seconds"] : []

    property bool running: false
    property real startedAt: 0
    property real accumulated: 0
    property int tick: 0

    readonly property real elapsed: {
        void root.tick;
        return root.accumulated + (root.running ? (Date.now() - root.startedAt) / 1000 : 0);
    }

    function start(): void {
        root.startedAt = Date.now();
        root.running = true;
    }

    function stop(): void {
        root.accumulated = root.elapsed;
        root.running = false;
    }

    function reset(): void {
        root.running = false;
        root.accumulated = 0;
        root.tick++;
    }

    function fmt(s: real): string {
        const total = Math.max(0, Math.floor(s));
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const sec = total % 60;
        const pad = n => n < 10 ? `0${n}` : `${n}`;
        return h > 0 ? `${h}:${pad(m)}:${pad(sec)}` : `${pad(m)}:${pad(sec)}`;
    }

    // Date.now() is not reactive; the shared clock is what nudges the readout.
    Connections {
        target: Clock
        enabled: root.running

        function onSecondsChanged(): void {
            root.tick++;
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.fmt(root.elapsed)
            font.family: Theme.mono
            font.pixelSize: root.num("size", 30)
            font.weight: Font.DemiBold
            color: root.running ? root.accent : root.fg
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flag("showLabel", true)
            text: root.running ? "RUNNING" : root.elapsed > 0 ? "STOPPED" : "STOPWATCH"
            font.pixelSize: Math.max(8, root.num("size", 30) * 0.3)
            font.weight: Font.Bold
            font.letterSpacing: 1.4
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
            else if (root.running)
                root.stop();
            else
                root.start();
        }
    }
}
