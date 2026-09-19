pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.config

// Active MPRIS player.
//
// On a caelestia system this must pick the exact same player caelestia's own
// topbar does, not just something reasonable: Words.qml drives the shell's
// lyrics fetch off whichever player is "active" here, and the shell's
// dashboard keys its own lyrics cache off whichever player it thinks is
// active. Two different rules can each be defensible on their own and still
// disagree - "whatever's playing" vs. caelestia's configured default/first
// player - whenever more than one MPRIS source is present (a paused Spotify
// next to a playing browser tab, say), and a disagreement here means Forge
// fetches and looks up lyrics for a different track than the one caelestia
// resolved, which reads as "lyrics just don't work" for no visible reason.
// So: mirror caelestia's own rule when it's installed, and fall back to
// "whatever's playing" - the sane default for a bare Hyprland box - when it
// is not.
Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    property MprisPlayer manual: null

    function identityOf(p: MprisPlayer): string {
        if (!p)
            return "";
        const cfg = Cae.playerConfig;
        if (!cfg)
            return p.identity;
        const alias = cfg.playerAliases.find(a => a.from === p.identity);
        return alias?.to ?? p.identity;
    }

    readonly property MprisPlayer active: {
        if (root.manual && root.players.includes(root.manual))
            return root.manual;
        if (Cae.available && Cae.playerConfig) {
            const def = Cae.playerConfig.defaultPlayer;
            return root.players.find(p => root.identityOf(p) === def) ?? root.players[0] ?? null;
        }
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
