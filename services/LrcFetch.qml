pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// LRCLIB fallback fetcher.
//
// Caelestia's own pipeline is a C++ service that fetches synced lyrics and
// leaves them on disk; LyricsSvc just reads whatever lands there. Without
// caelestia nothing was ever filling that cache, so this is the other half:
// a plain-QML fetcher against lrclib.net (a free, keyless, public API),
// writing into the exact same shape caelestia uses -
//
//   <cacheDir>/lyrics_map.json      "Artist - Title" -> { backend, id, offset }
//   <cacheDir>/LRCLIB/<id>.lrc      the LRC text
//
// - so LyricsSvc's existing read side needs to know nothing about where the
// files came from. It only ever points at caelestia's directories or these
// ones, never both, and either way the reader is the same few lines.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string cacheDir: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/hyprforge/lyrics`
    readonly property string mapPath: `${root.cacheDir}/lyrics_map.json`

    property var map: ({})

    // The track currently being tracked, so a rapid skip back to a track
    // already in flight (or already resolved) does not fire a second request.
    property string curKey: ""

    // Keys resolved (found or missed) *this run*, checked before the map
    // file's own watcher would otherwise catch up - the gap between writing
    // the file and onFileChanged firing is real, if short, and a track that
    // loops in that gap would otherwise be queried twice.
    property var known: ({})

    function markKnown(key: string): void {
        const k = root.known;
        k[key] = true;
        root.known = k;
    }

    // Called from LyricsSvc's trackBinding in place of Cae.words.setTrack(),
    // only when caelestia is not doing this job itself.
    function setTrack(artist: string, title: string, album: string, durationSec: real): void {
        const a = (artist ?? "").trim();
        const t = (title ?? "").trim();
        if (!a || !t) {
            root.curKey = "";
            return;
        }

        const key = `${a} - ${t}`;
        if (root.curKey === key)
            return;
        root.curKey = key;

        // Already on disk - found or a recorded miss - or already tried this
        // run. Either way LyricsSvc's own reader (watching the same files)
        // will show whatever is there; there is nothing left to fetch.
        if (root.known[key] || root.map[key])
            return;

        root.query(key, a, t, (album ?? "").trim(), Math.max(0, Math.round(durationSec ?? 0)));
    }

    // --- network ------------------------------------------------------------

    function request(url: string, onOk: var, onFail: var): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                onFail(xhr.status);
                return;
            }
            try {
                onOk(JSON.parse(xhr.responseText));
            } catch (e) {
                onFail(0);
            }
        };
        xhr.open("GET", url);
        // Not required, but LRCLIB's own docs ask clients to identify
        // themselves; wrapped because QML's XHR does not guarantee every
        // header name is accepted and this is not worth failing a request
        // over.
        try {
            xhr.setRequestHeader("Lrclib-Client", "Hyprforge (https://github.com/c0pperlane/hyprforge)");
        } catch (e) {}
        xhr.send();
    }

    // /get wants an exact-ish match and, critically, will not even accept the
    // request without a duration - tested against the real API rather than
    // assumed. So it is only tried when Media actually reported one; a track
    // whose length is unknown goes straight to search.
    function query(key: string, artist: string, title: string, album: string, durationSec: real): void {
        if (durationSec <= 0) {
            root.search(key, artist, title);
            return;
        }

        const qp = `artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(title)}` + (album ? `&album_name=${encodeURIComponent(album)}` : "") + `&duration=${durationSec}`;

        root.request(`https://lrclib.net/api/get?${qp}`, json => {
            if (json && json.syncedLyrics)
                root.save(key, json.id, json.syncedLyrics);
            else
                root.search(key, artist, title);
        }, status => {
            // 404 is LRCLIB's honest "no exact match", worth trying a looser
            // search for. Anything else - rate limited, their service down,
            // no network - is transient: leave the key untried so the next
            // time this track plays, in this session or a future one, it is
            // retried rather than permanently written off.
            if (status === 404)
                root.search(key, artist, title);
        });
    }

    function search(key: string, artist: string, title: string): void {
        const qp = `artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(title)}`;
        root.request(`https://lrclib.net/api/search?${qp}`, list => {
            const hit = Array.isArray(list) ? list.find(r => r && r.syncedLyrics) : null;
            if (hit)
                root.save(key, hit.id, hit.syncedLyrics);
            else
                root.miss(key); // a genuine search, zero synced results - this one really has none
        }, status => {}); // transient - leave untried, same reasoning as query()
    }

    // --- persistence ----------------------------------------------------
    //
    // Directory creation and both writes are ordered through one process
    // rather than assumed: FileView.setText() into a directory that may not
    // exist yet is not a risk worth taking for what is otherwise a two-line
    // write.

    property var pendingLrc: null // { id, text } | null

    function miss(key: string): void {
        root.persist(key, {
            backend: "LRCLIB",
            id: "_none",
            offset: 0
        }, null);
    }

    function save(key: string, id: var, lrcText: string): void {
        root.persist(key, {
            backend: "LRCLIB",
            id: `${id}`,
            offset: 0
        }, lrcText);
    }

    function persist(key: string, entry: var, lrcText: var): void {
        root.markKnown(key);
        const m = Object.assign({}, root.map);
        m[key] = entry;
        root.map = m;
        root.pendingLrc = lrcText !== null ? {
            id: entry.id,
            text: lrcText
        } : null;
        ensureDir.running = true;
    }

    Process {
        id: ensureDir

        running: false
        command: ["mkdir", "-p", `${root.cacheDir}/LRCLIB`]
        onExited: {
            mapFile.setText(JSON.stringify(root.map, null, 2));
            if (root.pendingLrc) {
                lrcWriter.path = `${root.cacheDir}/LRCLIB/${root.pendingLrc.id}.lrc`;
                lrcWriter.setText(root.pendingLrc.text);
                root.pendingLrc = null;
            }
        }
    }

    FileView {
        id: mapFile

        // Loaded whenever the fallback might be asked to fetch, same
        // condition as LyricsSvc's own copy - not tying it to that copy's
        // gate directly avoids a load-order dependency between two
        // singletons for what is otherwise just two independent readers of
        // one file.
        path: (!Cae.available && Demand.needed("lyrics")) ? root.mapPath : ""
        watchChanges: true
        printErrors: false

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
        id: lrcWriter
        // Write-only: path is set immediately before each setText() call in
        // persist(), never read from.
        printErrors: false
    }
}
