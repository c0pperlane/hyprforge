pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.config

// Default sink volume.
//
// PwObjectTracker is what makes a node's audio properties live; binding it to
// demand means Pipewire is not asked to track anything while no volume widget
// is on screen.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: root.sink?.ready ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property string sinkName: root.sink?.description || root.sink?.nickname || root.sink?.name || ""

    function setVolume(v: real): void {
        if (root.sink?.audio)
            root.sink.audio.volume = Math.max(0, Math.min(1.5, v));
    }

    function adjust(delta: real): void {
        root.setVolume(root.volume + delta);
    }

    function toggleMute(): void {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    PwObjectTracker {
        objects: Demand.needed("volume") && root.sink ? [root.sink] : []
    }
}
