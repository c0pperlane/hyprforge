pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Synced lyrics.
//
// Two sources, chosen the same way Sys.qml chooses between caelestia's
// metrics and /proc: caelestia's own pipeline when it is installed, LrcFetch
// (a plain-QML fetcher against lrclib.net) when it is not. Both write the
// same shape to disk -
//   <mapPath>              "Artist - Title" -> { backend, id, offset }
//   <cacheDir>/<BACKEND>/<id>.lrc   a plain LRC file with [mm:ss.xxx] stamps
// - so everything below this point (parsing, timing, seeking, the empty
// states) reads one pair of paths and does not know or care which side wrote
// them.
//
// Driving the C++ Lyrics service directly from this process did not work - it
// sat on "loading" forever while the shell's own copy resolved the same track
// fine - and even if it had, two processes racing to fetch and rewrite one
// cache is not a good design. setTrack is still called on the caelestia side,
// because that is what makes the shell's pipeline go and fill the cache for a
// track nobody has opened the dashboard on yet; the display then follows the
// files, whoever wrote them.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // caelestia's own paths when it is doing the fetching, LrcFetch's when it
    // is not. Never a mix of the two - a stale entry in one map pointing at
    // the other's cache directory would just be a miss.
    readonly property string mapPath: Cae.available ? `${Theme.statePath}/lyrics/lyrics_map.json` : LrcFetch.mapPath
    readonly property string cacheDir: Cae.available ? `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/caelestia/lyrics` : LrcFetch.cacheDir

    // Side effect in a binding so it re-runs per track, the same shape the
    // shell's own lyric list uses.
    readonly property var trackBinding: {
        if (!Demand.needed("lyrics"))
            return null;
        const p = Media.active;
        if (p && p.trackTitle) {
            if (Cae.available) {
                Cae.words?.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, p.length);
            } else {
                // Deferred rather than called straight from here: setTrack on
                // the fallback side is a QML function that writes ordinary
                // properties (LrcFetch.map, curKey), and those propagate
                // through Demand and FileView the same way anything else in
                // this file does. Calling it synchronously, nested inside the
                // evaluation of this binding, is exactly the shape a binding
                // loop needs - Qt caught one in testing. Cae.words.setTrack
                // above has no such risk: it is a call into a C++ slot with
                // no QML property on either side of it. Qt.callLater runs
                // this once the current evaluation has actually finished.
                const artist = p.trackArtist, title = p.trackTitle, album = p.trackAlbum, length = p.length;
                Qt.callLater(() => LrcFetch.setTrack(artist, title, album, length));
            }
        } else if (Cae.available) {
            Cae.words?.clearTrack();
        }
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

    // There is always a fetcher now - caelestia's, or LrcFetch's own. This
    // stays as a property (rather than being inlined into `state`) because it
    // is still a real question worth asking on its own, e.g. from the
    // Inspector or a future diagnostic.
    readonly property bool available: true

    readonly property string state: {
        if (root.hasLyrics)
            return "playing";
        if (!Media.hasPlayer)
            return "idle";
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
