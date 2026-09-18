pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services
import qs.config

// Synced lyrics, read out of caelestia's own pipeline.
//
// The shell already does the hard part and leaves the result on disk:
//   ~/.local/state/caelestia/lyrics/lyrics_map.json
//       "Artist - Title" -> { backend, id, offset }
//   ~/.cache/caelestia/lyrics/<BACKEND>/<id>.lrc
//       a plain LRC file with [mm:ss.xxx] timestamps
//
// Forge reads those rather than running a second fetcher. Driving the C++
// Lyrics service from this process did not work - it sat on "loading" forever
// while the shell's own copy resolved the same track fine - and even if it had,
// two processes racing to fetch and rewrite one cache is not a good design.
// setTrack is still called, because that is what makes the shell's pipeline go
// and fill the cache for a track nobody has opened the dashboard on yet; the
// display then follows the files, whoever wrote them.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string mapPath: `${Theme.statePath}/lyrics/lyrics_map.json`
    readonly property string cacheDir: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/caelestia/lyrics`

    // Side effect in a binding so it re-runs per track, the same shape the
    // shell's own lyric list uses.
    readonly property var trackBinding: {
        if (!Demand.needed("lyrics"))
            return null;
        const p = Media.active;
        if (p && p.trackTitle)
            Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, p.length);
        else
            Lyrics.clearTrack();
        return p;
    }

    property var map: ({})
    property real keyChangedAt: 0

    // The shell builds this key from the player's own metadata, so Forge builds
    // it the same way rather than trying to normalise anything.
    readonly property string key: Media.hasPlayer && Media.title ? `${Media.artist} - ${Media.title}` : ""
    readonly property var entry: root.key ? (root.map[root.key] ?? null) : null

    onKeyChanged: {
        root.keyChangedAt = Date.now();
        root.parsed = [];
    }

    // [{ t: milliseconds, text: string }]
    property var parsed: []
    readonly property list<string> lines: root.parsed.map(e => e.text)
    readonly property bool hasLyrics: root.parsed.length > 0

    readonly property real offset: root.entry?.offset ?? 0

    // Passed through so widgets don't each have to reach into Media as well.
    readonly property bool hasPlayer: Media.hasPlayer
    readonly property string trackTitle: Media.title
    readonly property string trackArtist: Media.artist

    // Which line is playing. Media polls position while playing, so this
    // advances on its own.
    readonly property int index: {
        const p = root.parsed;
        if (!p.length)
            return -1;
        const ms = (Media.position ?? 0) * 1000 + root.offset;
        let lo = 0;
        for (let i = 0; i < p.length; i++) {
            if (p[i].t <= ms)
                lo = i;
            else
                break;
        }
        return lo;
    }

    // A track the shell has not resolved yet is indistinguishable from a track
    // with no lyrics, so give the pipeline a grace period before calling it.
    readonly property int graceMs: 12000

    // A real property rather than a counter read as `void root.tick`: Date.now()
    // is not reactive, so something has to tell the binding that the grace
    // period has lapsed, and a discarded read is only a dependency until the
    // compiler decides otherwise.
    property bool graceExpired: false

    readonly property string state: {
        if (!Media.hasPlayer)
            return "idle";
        if (root.hasLyrics)
            return "playing";
        return root.graceExpired ? "none" : "loading";
    }

    onKeyChangedAtChanged: {
        root.graceExpired = false;
        graceTimer.restart();
    }

    Timer {
        id: graceTimer

        interval: root.graceMs
        repeat: false
        onTriggered: root.graceExpired = true
    }

    function seekToLine(i: int): void {
        const p = Media.active;
        const e = root.parsed[i];
        if (!p || !p.canSeek || !e)
            return;
        p.position = Math.max(0, (e.t - root.offset) / 1000);
    }

    // LRC: one or more [mm:ss.xx] stamps then the text. Bracketed tags whose
    // "minutes" are letters ([ar:], [ti:], [offset:]) have no digits and so are
    // skipped naturally.
    //
    // Uses an exec loop rather than String.matchAll: Qt's JS engine does not
    // implement matchAll, and the failure mode is a thrown exception inside a
    // signal handler - which Quickshell swallows, leaving an empty lyric list
    // and no error anywhere.
    function parseLrc(text: string): var {
        const out = [];
        const lines = (text ?? "").split("\n");
        const stamp = /\[(\d+):(\d+(?:\.\d+)?)\]/g;

        for (let li = 0; li < lines.length; li++) {
            const raw = lines[li];
            stamp.lastIndex = 0;

            const times = [];
            let m;
            while ((m = stamp.exec(raw)) !== null)
                times.push((parseInt(m[1]) * 60 + parseFloat(m[2])) * 1000);

            if (!times.length)
                continue;

            const body = raw.replace(stamp, "").trim();
            for (let ti = 0; ti < times.length; ti++)
                out.push({
                    t: times[ti],
                    text: body
                });
        }

        out.sort((a, b) => a.t - b.t);
        return out;
    }

    FileView {
        // Watching two files costs an inotify each; not worth holding while no
        // lyrics element exists.
        path: Demand.needed("lyrics") ? root.mapPath : ""
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            try {
                root.map = JSON.parse(text());
            } catch (e) {
                root.map = ({});
            }
        }
        onLoadFailed: root.map = ({})
    }

    FileView {
        id: lrcFile

        // Empty path while the track is unresolved; FileView simply holds off.
        path: Demand.needed("lyrics") && root.entry ? `${root.cacheDir}/${root.entry.backend}/${root.entry.id}.lrc` : ""
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.parsed = root.parseLrc(text())
        onLoadFailed: root.parsed = []
    }
}
