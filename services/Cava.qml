pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config

// Audio reactivity for the visualiser widgets, tiered by what is installed.
//
// Two separate things live here, because they need different sources:
//
//   `level`     - one scalar, "how loud is it right now". PipeWire answers
//                 this directly (a peak monitor on the default sink), which
//                 Quickshell already exposes and Volume.qml already relies
//                 on unconditionally - no caelestia, no extra package,
//                 always real. This is all WaveLine has ever needed.
//
//   `values`    - a full per-frequency-band spectrum, for Visualiser. That
//                 needs an actual FFT of the stream, which PipeWire's own
//                 client API does not give you - only a peak level. Two
//                 sources can supply it: caelestia's C++ CavaProvider, or
//                 the real `cava` CLI (a small, commonly-packaged tool
//                 unrelated to caelestia, which happens to share the name)
//                 run with `method = pipewire` and told to print raw values
//                 to stdout instead of drawing a terminal UI. Absent both,
//                 there simply isn't a per-band source, and `spectrum` says
//                 so rather than a fabricated bar chart pretending to be one.
Singleton {
    id: root

    property var requests: ({})

    // A plain property, recomputed imperatively by request()/release() below
    // - not a `readonly property int bars: Math.max(...Object.values(...))`
    // binding, which was the first shape this took. Tested in isolation:
    // that binding's own dependency on `requests` did not reliably
    // re-trigger after a reassignment reached it through Object.keys() /
    // Object.values(), even though a plain property-to-property alias to the
    // same `requests` updated correctly. Whatever the exact mechanism, it is
    // not worth trusting - this is the same "counter, not a discarded
    // computed read" reasoning Demand.qml documents for the identical shape
    // of problem.
    property int bars: 8

    function request(id: string, count: int): void {
        const r = root.requests;
        r[id] = count;
        root.requests = r;
        root.recomputeBars();
    }

    function release(id: string): void {
        const r = root.requests;
        delete r[id];
        root.requests = r;
        root.recomputeBars();
    }

    function recomputeBars(): void {
        let max = 0;
        for (const k of Object.keys(root.requests))
            max = Math.max(max, root.requests[k]);
        const next = Math.max(8, max);
        if (next !== root.bars)
            root.bars = next;
    }

    // --- per-band spectrum: caelestia, then the cava CLI, then nothing ------

    readonly property bool spectrum: !!Cae.audio || root.cliRunning
    readonly property var values: Cae.audio?.values ?? (root.cliRunning ? root.cliValues : [])

    onBarsChanged: {
        if (Cae.audio)
            Cae.audio.bars = root.bars;
        else if (root.cliWanted)
            root.restartCli();
    }

    // --- overall loudness: always real, always PipeWire -------------------
    //
    // Deliberately independent of `values` above: averaging an empty spectrum
    // would leave WaveLine flat on a machine with neither caelestia nor cava,
    // which defeats the entire point of putting this on PipeWire.
    readonly property real level: Cae.audio ? root.average(Cae.audio.values) : peakMon.peak

    function average(v: var): real {
        if (!v || !v.length)
            return 0;
        let s = 0;
        for (let i = 0; i < v.length; i++)
            s += v[i];
        return s / v.length;
    }

    PwObjectTracker {
        // Same reasoning as Volume.qml: this is what makes the node's audio
        // properties live, gated on demand so nothing is tracked while
        // caelestia already covers it or no widget is on screen.
        objects: !Cae.available && Demand.needed("cava") && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    PwNodePeakMonitor {
        id: peakMon

        node: Pipewire.defaultAudioSink
        enabled: !Cae.available && Demand.needed("cava")
    }

    // --- the cava CLI, when caelestia is not doing this job --------------

    readonly property bool cliWanted: !Cae.available && Demand.needed("cava")
    property bool cliRunning: false
    property var cliValues: []
    property int cliConfiguredBars: -1

    readonly property string cliConfigPath: `${Theme.configPath}/cava.conf`

    function cliConfig(n: int): string {
        // raw/ascii output, one semicolon-separated line per frame - piped
        // straight into SplitParser below. method = pipewire, not pulse or
        // alsa: it is the thing this file exists to prove is enough on its
        // own.
        return `[general]\nbars = ${n}\nframerate = 30\n\n[input]\nmethod = pipewire\nsource = auto\n\n[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 100\nbar_delimiter = 59\nframe_delimiter = 10\nchannels = mono\n`;
    }

    function restartCli(): void {
        if (!root.cliWanted) {
            cliProcess.running = false;
            return;
        }
        if (root.cliConfiguredBars !== root.bars) {
            root.cliConfiguredBars = root.bars;
            cliConfigFile.setText(root.cliConfig(root.bars));
        }
        // cava does not pick up a bar-count change without a fresh process; a
        // brief gap avoids flipping running false -> true within the same
        // tick, which Process does not treat as a real restart.
        cliProcess.running = false;
        cliRestartTimer.restart();
    }

    // Drives the process entirely imperatively - matching how Sys.qml starts
    // its own one-shot external commands - rather than a declarative
    // `running:` binding, because a bar-count change needs an actual stop and
    // restart, not just a value flip.
    onCliWantedChanged: root.restartCli()

    Timer {
        id: cliRestartTimer

        interval: 150
        onTriggered: cliProcess.running = root.cliWanted
    }

    // Theme.configPath already exists by the time anything else in Forge
    // runs - Store.qml writes layout.json straight into it with no mkdir of
    // its own - so this can write directly, the same assumption WeatherSvc's
    // geo-cache makes.
    FileView {
        id: cliConfigFile

        path: root.cliConfigPath
        printErrors: false
    }

    Process {
        id: cliProcess

        running: false
        command: ["cava", "-p", root.cliConfigPath]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                const parts = line.split(";").filter(s => s.length > 0);
                if (!parts.length)
                    return;
                root.cliRunning = true;
                root.cliValues = parts.map(s => Math.max(0, Math.min(1, parseInt(s) / 100)));
            }
        }

        // Covers both "cava is not installed" (the process never starts) and
        // it exiting for any other reason - either way there is no live
        // spectrum any more, and `spectrum` needs to say so.
        onRunningChanged: if (!running) {
            root.cliRunning = false;
            root.cliValues = [];
        }
    }
}
