pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Audio spectrum shared by every visualiser widget. `bars` is raised to the
// largest bar count any live widget asks for, so two visualisers at different
// resolutions still only run one cava.
//
// This is the one service with no fallback: it is an FFT of the monitor
// stream done in caelestia's C++, and there is nothing in Qt to stand in for
// it. Without caelestia `available` is false and the visualiser widgets say
// so rather than animating silence.
Singleton {
    id: root

    property var requests: ({})

    readonly property bool available: !!Cae.audio
    readonly property var values: Cae.audio?.values ?? []
    // Cheap "is anything making noise" signal, handy for reactive decor.
    readonly property real level: {
        const v = root.values;
        if (!v || !v.length)
            return 0;
        let s = 0;
        for (let i = 0; i < v.length; i++)
            s += v[i];
        return s / v.length;
    }

    function request(id: string, bars: int): void {
        const r = root.requests;
        r[id] = bars;
        root.requests = r;
        root.recompute();
    }

    function release(id: string): void {
        const r = root.requests;
        delete r[id];
        root.requests = r;
        root.recompute();
    }

    function recompute(): void {
        let max = 0;
        for (const k of Object.keys(root.requests))
            max = Math.max(max, root.requests[k]);
        if (Cae.audio)
            Cae.audio.bars = Math.max(8, max);
    }

    // The ServiceRef that actually gates the capture lives in cae/Audio.qml,
    // on the same Demand key: the map here still decides the bar count, but
    // whether anything runs is the mechanism every other service uses.
}
