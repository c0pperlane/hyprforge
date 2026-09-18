pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.config

// Active MPRIS player, chosen the way people expect: whatever is actually
// playing wins, otherwise the last thing that was.
Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    property MprisPlayer manual: null

    readonly property MprisPlayer active: {
        if (root.manual && root.players.includes(root.manual))
            return root.manual;
        return root.players.find(p => p.isPlaying) ?? root.players.find(p => p.playbackState === MprisPlaybackState.Paused) ?? root.players[0] ?? null;
    }

    readonly property bool hasPlayer: !!root.active
    readonly property bool playing: root.active?.isPlaying ?? false
    readonly property string title: root.active?.trackTitle ?? ""
    readonly property string artist: root.active?.trackArtist ?? ""
    readonly property string album: root.active?.trackAlbum ?? ""
    readonly property string art: root.active?.trackArtUrl ?? ""
    readonly property real length: root.active?.lengthSupported ? root.active.length : 0
    readonly property real position: root.active?.positionSupported ? root.active.position : 0
    readonly property real progress: root.length > 0 ? Math.min(1, root.position / root.length) : 0

    function toggle(): void {
        if (root.active?.canTogglePlaying)
            root.active.togglePlaying();
    }

    function next(): void {
        if (root.active?.canGoNext)
            root.active.next();
    }

    function previous(): void {
        if (root.active?.canGoPrevious)
            root.active.previous();
    }

    function seekFraction(f: real): void {
        const p = root.active;
        if (p?.canSeek && p.lengthSupported && p.length > 0)
            p.position = f * p.length;
    }

    function time(s: real): string {
        if (!s || s < 0)
            return "0:00";
        const m = Math.floor(s / 60);
        const sec = Math.floor(s % 60);
        return `${m}:${sec < 10 ? "0" : ""}${sec}`;
    }

    // MPRIS position is not push-based; poll it while something is playing so
    // scrubbers actually move.
    Timer {
        // Only while something is actually showing a position: a scrubber, or
        // synced lyrics.
        running: root.playing && (root.active?.positionSupported ?? false) && (Demand.needed("media.position") || Demand.needed("lyrics"))
        interval: 500
        repeat: true
        onTriggered: root.active?.positionChanged()
    }
}
