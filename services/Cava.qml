pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Services
import qs.config

// Audio spectrum shared by every visualiser widget. `bars` is raised to the
// largest bar count any live widget asks for, so two visualisers at different
// resolutions still only run one cava.
Singleton {
    id: root

    property var requests: ({})

    readonly property CavaProvider provider: cava
    readonly property list<real> values: cava.values
    // Cheap "is anything making noise" signal, handy for reactive decor.
    readonly property real level: {
        const v = cava.values;
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
        cava.bars = Math.max(8, max);
    }

    CavaProvider {
        id: cava

        bars: 42
    }

    ServiceRef {
        // Cava kept its own request/release map before Demand existed; the map
        // still decides the bar count, but whether the capture runs at all is
        // now the same mechanism every other service uses.
        service: Demand.needed("cava") ? cava : null
    }
}
