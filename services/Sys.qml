pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.config

// One place every system-metric widget pulls from.
//
// Two possible sources, chosen at startup. Where caelestia-shell is installed,
// the heavy lifting is its C++ service singletons - reached through Cae rather
// than imported here, so that a machine without them still loads. They only
// poll while something holds a ServiceRef, which cae/Metrics.qml does on the
// same Demand keys used everywhere else.
//
// Where they are absent, the readings come from /proc, sysfs and one df. Same
// accessors, same demand gating, same units; see "working without caelestia"
// below. Nothing downstream of this file knows which source answered.
Singleton {
    id: root

    // Which demand key a given metric depends on. Widgets use this so their
    // demand follows whatever metric the user picked, without each widget
    // having to know how the readings are gathered.
    function demandFor(metric: string): string {
        switch (metric) {
        case "cpu":
        case "cpuTemp":
            return "sys.cpu";
        case "memory":
            return "sys.memory";
        case "swap":
            return "sys.swap";
        case "gpu":
        case "gpuTemp":
            return "sys.gpu";
        case "vram":
        case "gpuPower":
        case "gpuClock":
        case "cpuPower":
        case "cpuFreq":
        case "fanCpu":
        case "fanGpu":
            return "sys.power";
        case "disk":
            return "sys.storage";
        case "diskRead":
        case "diskWrite":
            return "sys.diskio";
        case "netDown":
        case "netUp":
            return "sys.net";
        default:
            return "";      // battery comes from UPower, which costs nothing
        }
    }

    // vram and the gpu* metrics read nvidia-smi *and* the GPU service.
    function demandsFor(metric: string): var {
        const primary = root.demandFor(metric);
        if (metric === "vram" || metric === "gpuPower" || metric === "gpuClock")
            return [primary, "sys.gpu"];
        return primary ? [primary] : [];
    }

    // The C++ services report fractions (0-1), but be forgiving in case a
    // future version switches to 0-100 - a silently 100x-off ring is a nasty
    // thing to debug.
    function norm(v: real): real {
        if (isNaN(v) || v === undefined || v === null)
            return 0;
        return v > 1.0001 ? v / 100 : v;
    }

    function pct(v: real): string {
        return `${Math.round(root.norm(v) * 100)}%`;
    }

    function bytes(n: real): string {
        if (!n || n < 0)
            return "0 B";
        const u = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (n >= 1024 && i < u.length - 1) {
            n /= 1024;
            i++;
        }
        return `${n < 10 && i > 0 ? n.toFixed(1) : Math.round(n)} ${u[i]}`;
    }

    function rate(n: real): string {
        return `${bytes(n)}/s`;
    }

    readonly property real netDownScale: 12 * 1024 * 1024 // full ring at ~12 MB/s
    readonly property real netUpScale: 4 * 1024 * 1024

    // Ceilings for the gauges that report an absolute quantity rather than a
    // percentage. Rough by nature - they only decide where "full" sits on a
    // ring, and each is user-overridable from the widget's Warn/Gain knobs.
    readonly property real cpuPowerScale: 90   // W, package
    readonly property real gpuPowerScale: 140  // W, board
    readonly property real fanScale: 5500      // RPM

    // Every metric a widget can bind to. Rebuilt whenever any source changes,
    // which is what makes `Sys.metric(key)` reactive inside a binding.
    readonly property var metrics: ({
            cpu: {
                key: "cpu",
                label: "CPU",
                icon: "memory",
                value: root.norm(root.cpuPercent),
                text: root.pct(root.cpuPercent),
                sub: root.cpuName
            },
            cpuTemp: {
                key: "cpuTemp",
                label: "CPU temp",
                icon: "thermostat",
                value: Math.min(1, (root.cpuTemp) / 100),
                text: `${Math.round(root.cpuTemp)}°`,
                sub: "core"
            },
            memory: {
                key: "memory",
                label: "RAM",
                icon: "memory_alt",
                value: root.norm(root.memPercent),
                text: root.pct(root.memPercent),
                sub: `${root.bytes(root.memUsedBytes)} / ${root.bytes(root.memTotalBytes)}`
            },
            swap: {
                key: "swap",
                label: "Swap",
                icon: "swap_horiz",
                value: root.swapFraction,
                text: root.swapTotal > 0 ? root.pct(root.swapFraction) : "none",
                sub: root.swapTotal > 0 ? `${root.bytes(root.swapUsed)} / ${root.bytes(root.swapTotal)}` : ""
            },
            gpu: {
                key: "gpu",
                label: "GPU",
                icon: "developer_board",
                value: root.norm(root.gpuPercent),
                text: root.pct(root.gpuPercent),
                sub: root.gpuName
            },
            gpuTemp: {
                key: "gpuTemp",
                label: "GPU temp",
                icon: "mode_heat",
                value: Math.min(1, (root.gpuTemp) / 100),
                text: `${Math.round(root.gpuTemp)}°`,
                sub: root.gpuName
            },
            vram: {
                key: "vram",
                label: "VRAM",
                icon: "view_in_ar",
                // Real memory use where nvidia-smi can tell us; otherwise fall
                // back to GPU busy% rather than showing a confident zero.
                value: root.vramTotalMib > 0 ? root.vramUsedMib / root.vramTotalMib : root.norm(root.gpuPercent),
                text: root.vramTotalMib > 0 ? `${(root.vramUsedMib / 1024).toFixed(1)} / ${(root.vramTotalMib / 1024).toFixed(1)} GB` : root.pct(root.gpuPercent),
                sub: root.gpuName
            },
            disk: {
                key: "disk",
                label: "Disk",
                icon: "hard_disk",
                value: root.norm(root.storagePercent),
                text: root.pct(root.storagePercent),
                sub: root.storagePrimary?.mount ?? "/"
            },
            battery: {
                key: "battery",
                label: "Battery",
                icon: "battery_full",
                value: root.batteryLevel,
                text: root.hasBattery ? `${Math.round(root.batteryLevel * 100)}%` : "—",
                sub: root.batteryState
            },
            netDown: {
                key: "netDown",
                label: "Down",
                icon: "download",
                value: Math.min(1, root.netDown / root.netDownScale),
                text: root.rate(root.netDown),
                sub: root.bytes(root.netDownTotal)
            },
            cpuPower: {
                key: "cpuPower",
                label: "CPU power",
                icon: "bolt",
                value: Math.min(1, root.cpuWatts / root.cpuPowerScale),
                text: `${root.cpuWatts.toFixed(1)} W`,
                sub: "package"
            },
            gpuPower: {
                key: "gpuPower",
                label: "GPU power",
                icon: "electric_bolt",
                value: Math.min(1, root.gpuWatts / root.gpuPowerScale),
                text: `${root.gpuWatts.toFixed(1)} W`,
                sub: root.gpuName
            },
            gpuClock: {
                key: "gpuClock",
                label: "GPU clock",
                icon: "speed",
                value: Math.min(1, root.gpuClockMhz / 3000),
                text: `${Math.round(root.gpuClockMhz)} MHz`,
                sub: ""
            },
            cpuFreq: {
                key: "cpuFreq",
                label: "CPU clock",
                icon: "speed",
                value: Math.min(1, root.cpuGhz / 6),
                text: `${root.cpuGhz.toFixed(2)} GHz`,
                sub: "avg"
            },
            fanCpu: {
                key: "fanCpu",
                label: "CPU fan",
                icon: "mode_fan",
                value: Math.min(1, root.fanCpuRpm / root.fanScale),
                text: root.fanCpuRpm > 0 ? `${root.fanCpuRpm} rpm` : "off",
                sub: ""
            },
            fanGpu: {
                key: "fanGpu",
                label: "GPU fan",
                icon: "mode_fan",
                value: Math.min(1, root.fanGpuRpm / root.fanScale),
                text: root.fanGpuRpm > 0 ? `${root.fanGpuRpm} rpm` : "off",
                sub: ""
            },
            diskRead: {
                key: "diskRead",
                label: "Disk read",
                icon: "download",
                value: Math.min(1, root.diskReadRate / (500 * 1024 * 1024)),
                text: root.rate(root.diskReadRate),
                sub: ""
            },
            diskWrite: {
                key: "diskWrite",
                label: "Disk write",
                icon: "upload",
                value: Math.min(1, root.diskWriteRate / (500 * 1024 * 1024)),
                text: root.rate(root.diskWriteRate),
                sub: ""
            },
            netUp: {
                key: "netUp",
                label: "Up",
                icon: "upload",
                value: Math.min(1, root.netUp / root.netUpScale),
                text: root.rate(root.netUp),
                sub: root.bytes(root.netUpTotal)
            }
        })

    function metric(key: string): var {
        return root.metrics[key] ?? root.metrics.cpu;
    }

    // --- history ----------------------------------------------------------
    // Sampled once a second for every metric, so a SparkGraph added later
    // already has a curve to draw instead of starting from a flat line.
    readonly property int historyLength: 240
    property var history: ({})
    property int tick: 0

    function historyFor(key: string): var {
        // Reads `history` itself rather than a separate counter: assigning the
        // same object back to a var property emits no change signal, so the old
        // version leaned on a discarded `void root.tick` read to register the
        // dependency - which only works while the compiler leaves it in place.
        const all = root.history;
        return all[key] ?? [];
    }

    Timer {
        interval: 1000
        running: Demand.needed("sys.history")
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // A fresh map each tick so historyChanged actually fires. The
            // arrays inside are shared, not copied - this is one shallow object
            // copy per second, not a copy of the samples.
            const h = Object.assign({}, root.history);
            for (const key of Object.keys(root.metrics)) {
                const arr = (h[key] ?? []).slice();
                arr.push(root.metrics[key].value);
                if (arr.length > root.historyLength)
                    arr.shift();
                h[key] = arr;
            }
            root.history = h;
            root.tick++;
        }
    }

    // --- swap ---------------------------------------------------------------
    //
    // The Memory service reports RAM only, so swap was previously showing RAM's
    // own percentage - a metric that looked plausible and was simply wrong.

    property real memTotalKb: 0
    property real memAvailKb: 0
    property real swapTotal: 0
    property real swapFree: 0
    readonly property real swapUsed: Math.max(0, root.swapTotal - root.swapFree)
    readonly property real swapFraction: root.swapTotal > 0 ? root.swapUsed / root.swapTotal : 0

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        printErrors: false

        onLoaded: {
            for (const line of text().split("\n")) {
                const m = /^(SwapTotal|SwapFree|MemTotal|MemAvailable):\s+(\d+)/.exec(line);
                if (!m)
                    continue;
                // kB in the file; bytes everywhere in this service.
                if (m[1] === "SwapTotal")
                    root.swapTotal = parseInt(m[2]) * 1024;
                else if (m[1] === "SwapFree")
                    root.swapFree = parseInt(m[2]) * 1024;
                else if (m[1] === "MemTotal")
                    root.memTotalKb = parseInt(m[2]);
                else
                    root.memAvailKb = parseInt(m[2]);
            }
        }
    }

    Timer {
        interval: 4000
        // Feeds the memory fallback as well as swap.
        running: Demand.needed("sys.swap") || (!root.caelestia && Demand.needed("sys.memory"))
        repeat: true
        triggeredOnStart: true
        onTriggered: meminfo.reload()
    }

    // --- temperatures -------------------------------------------------------
    //
    // Every hwmon chip that exposes a temp*_input, with its label where there
    // is one. Read through a shell rather than a pile of FileViews because the
    // set of files is not known ahead of time.

    property var temperatures: []

    Process {
        id: tempProc

        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do n=$(cat $d/name 2>/dev/null); for f in $d/temp*_input; do [ -e \"$f\" ] || continue; l=$(cat ${f%_input}_label 2>/dev/null); v=$(cat $f 2>/dev/null); echo \"$n|${l:-$(basename ${f%_input})}|$v\"; done; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const f = line.split("|");
                    if (f.length < 3)
                        continue;
                    const c = parseInt(f[2]);
                    if (isNaN(c))
                        continue;
                    out.push({
                        chip: f[0],
                        label: f[1],
                        celsius: c / 1000
                    });
                }
                out.sort((a, b) => b.celsius - a.celsius);
                root.temperatures = out;
            }
        }
    }

    Timer {
        interval: 4000
        // The CPU temperature fallback picks the package sensor out of this.
        running: Demand.needed("sys.temps") || (!root.caelestia && Demand.needed("sys.cpu"))
        repeat: true
        triggeredOnStart: true
        onTriggered: tempProc.running = true
    }

    // --- network interfaces -------------------------------------------------

    property var interfaces: []

    Process {
        id: ipProc

        command: ["ip", "-j", "addr"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const out = [];
                    for (const iface of data) {
                        if (iface.ifname === "lo")
                            continue;
                        const v4 = (iface.addr_info ?? []).find(a => a.family === "inet");
                        const v6 = (iface.addr_info ?? []).find(a => a.family === "inet6" && a.scope === "global");
                        out.push({
                            name: iface.ifname,
                            up: (iface.operstate ?? "").toUpperCase() === "UP",
                            state: iface.operstate ?? "unknown",
                            v4: v4 ? `${v4.local}/${v4.prefixlen}` : "",
                            v6: v6 ? v6.local : "",
                            mac: iface.address ?? ""
                        });
                    }
                    // Connected first, then by name.
                    out.sort((a, b) => (b.up ? 1 : 0) - (a.up ? 1 : 0) || a.name.localeCompare(b.name));
                    root.interfaces = out;
                } catch (e) {
                    root.interfaces = [];
                }
            }
        }
    }

    Timer {
        interval: 8000
        running: Demand.needed("sys.netif")
        repeat: true
        triggeredOnStart: true
        onTriggered: ipProc.running = true
    }

    // --- per-core load ----------------------------------------------------
    //
    // /proc/stat gives cumulative jiffies per core; busy fraction is the delta
    // of (total - idle) over the delta of total. Absolute values are useless on
    // their own, which is why the previous sample is kept.

    property var cores: []
    property var lastCoreRaw: []
    property var lastAggRaw: null
    property real procCpuPercent: 0

    FileView {
        id: procStat

        path: "/proc/stat"
        printErrors: false

        onLoaded: {
            const rows = [];
            for (const line of text().split("\n")) {
                if (line.startsWith("cpu ")) {
                    // The aggregate line. Only needed when caelestia is absent
                    // and nothing else is reporting total CPU, but it is free
                    // here - the file is already open and parsed.
                    const a = line.trim().split(/\s+/).slice(1).map(n => parseInt(n) || 0);
                    if (a.length >= 5) {
                        const idle = a[3] + a[4];
                        const total = a.reduce((x, y) => x + y, 0);
                        const prevA = root.lastAggRaw;
                        if (prevA) {
                            const dT = total - prevA.total;
                            const dI = idle - prevA.idle;
                            if (dT > 0)
                                root.procCpuPercent = Math.max(0, Math.min(100, (dT - dI) / dT * 100));
                        }
                        root.lastAggRaw = {
                            idle: idle,
                            total: total
                        };
                    }
                    continue;
                }
                if (!line.startsWith("cpu"))
                    continue;
                const f = line.trim().split(/\s+/);
                const nums = f.slice(1).map(n => parseInt(n) || 0);
                if (nums.length < 5)
                    continue;
                const idle = nums[3] + nums[4];
                const total = nums.reduce((a, b) => a + b, 0);
                rows.push({
                    idle: idle,
                    total: total
                });
            }

            const prev = root.lastCoreRaw;
            const out = [];
            for (let i = 0; i < rows.length; i++) {
                const p = prev[i];
                if (!p) {
                    out.push(0);
                    continue;
                }
                const dTotal = rows[i].total - p.total;
                const dIdle = rows[i].idle - p.idle;
                out.push(dTotal > 0 ? Math.max(0, Math.min(1, (dTotal - dIdle) / dTotal)) : 0);
            }
            root.lastCoreRaw = rows;
            if (out.length)
                root.cores = out;
        }
    }

    Timer {
        interval: 1500
        // Also the total-CPU source when caelestia is absent, so it has to
        // run for "sys.cpu" too - the per-core view was its only consumer
        // while the C++ service was reporting the aggregate.
        running: Demand.needed("sys.cores") || (!root.caelestia && Demand.needed("sys.cpu"))
        repeat: true
        triggeredOnStart: true
        onTriggered: procStat.reload()
    }

    // --- core parking -------------------------------------------------------
    //
    // Linux has no Windows-style core parking; the equivalent on this machine
    // is sched_ext core compaction (scx_lavd --autopilot, legion-core-parking
    // .service), which keeps tasks on a small set of CPUs and simply does not
    // dispatch to the rest, so those sit in a deep C-state. That is invisible
    // to /proc/stat's notion of idle, which cannot tell a core that is asleep
    // from one that is merely unloaded - so this reads cpuidle residency, the
    // same source and the same rules as `legion-power status`.
    //
    // One awk over every cpuidle/state*/{name,time} rather than ~128 cats:
    // the sample has to be cheap enough to take every few seconds.

    readonly property string parkingCmd: "cat /sys/kernel/sched_ext/state 2>/dev/null | sed 's/^/sched /'; cat /sys/kernel/sched_ext/root/ops 2>/dev/null | sed 's/^/ops /'; awk '{ split(FILENAME, a, \"/\"); c = a[6]; st = a[8]; if (a[9] == \"name\") nm[c \"/\" st] = $0; else tm[c \"/\" st] = $0 } END { for (k in tm) { split(k, b, \"/\"); n = nm[k]; tot[n] += tm[k]; if (n == \"POLL\") poll[b[1]] += tm[k]; else idle[b[1]] += tm[k] } for (c in idle) printf \"cpu %s %d %d\\n\", substr(c, 4), idle[c], poll[c] + 0; for (n in tot) printf \"state %s %d\\n\", n, tot[n] }' /sys/devices/system/cpu/cpu*/cpuidle/state*/name /sys/devices/system/cpu/cpu*/cpuidle/state*/time"

    // A core taking nothing but the occasional timer tick still reads ~99%
    // idle, so "parked" is a threshold, not equality. Same 95% as the knob.
    readonly property real parkedIdlePct: 0.95

    // cpus: per-core idle fraction over the window, 0..1, indexed by cpu
    // number. parked: how many cleared the threshold. states: residency
    // percentages by C-state name. scheduler: "" when nothing is attached.
    property var parking: ({
            cpus: [],
            parked: 0,
            busyPct: 0,
            deepPct: 0,
            windowS: 0,
            scheduler: "",
            valid: false
        })

    property var lastParkingRaw: null

    Process {
        id: parkingProc

        command: ["sh", "-c", root.parkingCmd]
        stdout: StdioCollector {
            onStreamFinished: root.readParking(text)
        }
    }

    function readParking(text: string): void {
        const cpus = ({});
        const states = ({});
        let enabled = false;
        let ops = "";

        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            if (f[0] === "sched")
                enabled = f[1] === "enabled";
            else if (f[0] === "ops")
                ops = f.slice(1).join(" ");
            else if (f[0] === "cpu" && f.length >= 4)
                cpus[parseInt(f[1])] = {
                    idle: parseInt(f[2]) || 0,
                    poll: parseInt(f[3]) || 0
                };
            else if (f[0] === "state" && f.length >= 3)
                states[f[1]] = parseInt(f[2]) || 0;
        }

        const ids = Object.keys(cpus);
        if (!ids.length)
            return;

        // scx_lavd reports itself as e.g. "lavd_1.1.3_x86_64-...". The version
        // and triple are noise on a widget that is 100px wide.
        const name = enabled ? (ops.split("_")[0] || "sched_ext") : "";

        const now = Date.now();
        const prev = root.lastParkingRaw;
        root.lastParkingRaw = {
            t: now,
            cpus: cpus,
            states: states
        };

        if (!prev) {
            // Two samples make a reading, so a widget that has just appeared
            // would otherwise sit blank for a whole interval. Take the second
            // one shortly after the first; the window is narrower but true.
            parkingPrime.restart();
            return;
        }

        const windowUs = (now - prev.t) * 1000;

        // Date.now() counts time across a suspend and the cpuidle counters do
        // not, so a resume produces an enormous window against tiny deltas and
        // every core would read as pinned. Anything far longer than the poll
        // interval is that, or a stalled sampler; re-base instead of lying.
        if (windowUs <= 0 || now - prev.t > 4 * root.parkingInterval)
            return;

        const out = [];
        let parked = 0;
        const stateSum = ({});

        for (const id of ids) {
            const i = parseInt(id);
            const p = prev.cpus[id];
            if (!p) {
                out[i] = 0;
                continue;
            }
            let idle = cpus[id].idle - p.idle;
            let poll = cpus[id].poll - p.poll;
            if (idle < 0 || poll < 0) {
                root.lastParkingRaw = null;   // counters went backwards: hotplug
                return;
            }

            // cpuidle credits a whole sleep at the moment the core wakes, so a
            // core already asleep when the window opened books time from
            // before it - up to ~121% of the window. Left alone that pushes
            // the total past 100% exactly when most cores are parked, which is
            // when the number is worth reading. No core can have slept longer
            // than the window, so scale the overshoot back into it.
            const spent = idle + poll;
            if (spent > windowUs) {
                const scale = windowUs / spent;
                idle *= scale;
                poll *= scale;
            }

            // POLL is a spin, not a sleep: counting it as idle would report a
            // busy-waiting core as parked.
            const frac = Math.max(0, Math.min(1, idle / windowUs));
            out[i] = frac;
            if (frac >= root.parkedIdlePct)
                parked++;
        }

        const n = ids.length;
        for (const label of Object.keys(states)) {
            const d = states[label] - (prev.states[label] ?? states[label]);
            if (d >= 0)
                stateSum[label] = Math.max(0, Math.min(100, 100 * d / (windowUs * n)));
        }
        const deep = Object.keys(stateSum).filter(k => k !== "POLL" && k !== "C1").reduce((a, k) => a + stateSum[k], 0);
        const allIdle = Object.keys(stateSum).reduce((a, k) => a + stateSum[k], 0);

        root.parking = {
            cpus: out,
            parked: parked,
            count: n,
            busyPct: Math.max(0, 100 - allIdle),
            deepPct: Math.min(100, deep),
            states: stateSum,
            windowS: (now - prev.t) / 1000,
            scheduler: name,
            valid: true
        };
    }

    readonly property int parkingInterval: 3000

    Timer {
        interval: root.parkingInterval
        running: Demand.needed("sys.parking")
        repeat: true
        triggeredOnStart: true
        onTriggered: parkingProc.running = true
    }

    Timer {
        id: parkingPrime

        interval: 400
        repeat: false
        onTriggered: {
            if (Demand.needed("sys.parking"))
                parkingProc.running = true;
        }
    }

    // A baseline kept across a period of no demand would be measured against a
    // window of arbitrary length, so drop it on the way out rather than report
    // an average of however long the widget was hidden.
    Connections {
        target: Demand

        function onHoldersChanged(): void {
            if (!Demand.needed("sys.parking"))
                root.lastParkingRaw = null;
        }
    }

    // --- top processes ------------------------------------------------------

    property var processes: []

    Process {
        id: psProc

        command: ["sh", "-c", "ps -eo pcpu,pmem,comm --sort=-pcpu --no-headers | head -n 12"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const f = line.trim().split(/\s+/);
                    if (f.length < 3)
                        continue;
                    const cpu = parseFloat(f[0]);
                    const mem = parseFloat(f[1]);
                    if (isNaN(cpu))
                        continue;
                    out.push({
                        cpu: cpu,
                        mem: mem,
                        name: f.slice(2).join(" ")
                    });
                }
                root.processes = out;
            }
        }
    }

    Timer {
        interval: 3000
        running: Demand.needed("sys.procs")
        repeat: true
        triggeredOnStart: true
        onTriggered: psProc.running = true
    }

    // --- disk throughput ----------------------------------------------------
    //
    // /proc/diskstats counts sectors, not bytes; a sector is 512 bytes for this
    // interface regardless of the drive's real block size.

    property real diskReadRate: 0
    property real diskWriteRate: 0
    property var lastDiskRaw: null

    FileView {
        id: diskStats

        path: "/proc/diskstats"
        printErrors: false

        onLoaded: {
            let read = 0;
            let written = 0;
            for (const line of text().split("\n")) {
                const f = line.trim().split(/\s+/);
                if (f.length < 10)
                    continue;
                const name = f[2];
                // Whole devices only - counting a disk and its partitions would
                // double everything.
                if (!/^(nvme\d+n\d+|sd[a-z]|mmcblk\d+|vd[a-z])$/.test(name))
                    continue;
                read += parseInt(f[5]) || 0;
                written += parseInt(f[9]) || 0;
            }

            const now = Date.now();
            const prev = root.lastDiskRaw;
            if (prev && now > prev.at) {
                const dt = (now - prev.at) / 1000;
                root.diskReadRate = Math.max(0, (read - prev.read) * 512 / dt);
                root.diskWriteRate = Math.max(0, (written - prev.written) * 512 / dt);
            }
            root.lastDiskRaw = {
                read: read,
                written: written,
                at: now
            };
        }
    }

    Timer {
        interval: 1500
        running: Demand.needed("sys.diskio")
        repeat: true
        triggeredOnStart: true
        onTriggered: diskStats.reload()
    }

    // --- extra sensors ----------------------------------------------------
    //
    // The shell's own telemetry corner reads these; Forge reads the same
    // sources directly so a Forge layout can replace it without losing
    // anything. All of them degrade quietly to zero when the hardware or the
    // helper isn't there.

    property real cpuWatts: 0
    property real gpuWatts: 0
    property real gpuClockMhz: 0
    property real vramUsedMib: 0
    property real vramTotalMib: 0
    property real cpuGhz: 0
    property int fanCpuRpm: 0
    property int fanGpuRpm: 0
    readonly property string refreshRate: {
        const hz = Hyprland.focusedMonitor?.lastIpcObject?.refreshRate;
        return hz ? `${Math.round(hz)} Hz` : "";
    }

    readonly property bool hasFans: root.fanCpuRpm > 0 || root.fanGpuRpm > 0
    readonly property bool hasGpuPower: root.gpuWatts > 0

    // RAPL exposes a monotonic energy counter in microjoules; power is its
    // derivative. The counter wraps, hence the negative-delta guard.
    property real lastEnergyUj: -1
    property real lastEnergyAt: 0

    FileView {
        id: rapl

        path: "/sys/class/powercap/intel-rapl:0/energy_uj"
        printErrors: false

        onLoaded: {
            const uj = parseFloat(text().trim());
            const now = Date.now();
            if (root.lastEnergyUj >= 0 && now > root.lastEnergyAt) {
                const dj = (uj - root.lastEnergyUj) / 1e6;
                const dt = (now - root.lastEnergyAt) / 1000;
                if (dj >= 0 && dt > 0)
                    root.cpuWatts = dj / dt;
            }
            root.lastEnergyUj = uj;
            root.lastEnergyAt = now;
        }
    }

    Process {
        id: nvidia

        command: ["nvidia-smi", "--query-gpu=power.draw,clocks.gr,memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",").map(s => parseFloat(s));
                if (parts.length < 4 || isNaN(parts[0]))
                    return;
                root.gpuWatts = parts[0];
                root.gpuClockMhz = parts[1];
                root.vramUsedMib = parts[2];
                root.vramTotalMib = parts[3];
            }
        }
    }

    Process {
        id: fans

        command: ["legion-fan-rpms"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/).map(s => parseInt(s));
                if (parts.length >= 1 && !isNaN(parts[0]))
                    root.fanCpuRpm = parts[0];
                if (parts.length >= 2 && !isNaN(parts[1]))
                    root.fanGpuRpm = parts[1];
            }
        }
    }

    Process {
        id: cpuFreqProc

        command: ["sh", "-c", "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const khz = text.trim().split("\n").map(s => parseInt(s)).filter(n => !isNaN(n));
                if (khz.length)
                    root.cpuGhz = khz.reduce((a, b) => a + b, 0) / khz.length / 1e6;
            }
        }
    }

    Timer {
        interval: 2000
        running: Demand.needed("sys.power")
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            rapl.reload();
            cpuFreqProc.running = true;
            fans.running = true;
        }
    }

    // nvidia-smi costs more than a sysfs read, so it gets a slower beat.
    Timer {
        interval: 4000
        running: Demand.needed("sys.power") || Demand.needed("sys.gpu")
        repeat: true
        triggeredOnStart: true
        onTriggered: nvidia.running = true
    }

    // --- battery ----------------------------------------------------------


    // --- working without caelestia -----------------------------------------
    //
    // Every metric below has two sources: caelestia-shell's C++ services when
    // they are installed, and a plain reader when they are not. The accessors
    // are what the rest of the file uses, so nothing downstream knows or cares
    // which one answered.
    //
    // The fallbacks are deliberately the cheap, boring versions - /proc and one
    // df - and they are gated on the same Demand keys, so an absent caelestia
    // costs the same nothing when the widgets are off-screen.

    readonly property bool caelestia: Cae.available

    // Units: every percentage accessor below is a 0..1 fraction, because that
    // is what the caelestia services report and it was the incumbent. The
    // /proc side speaks in 0..100, so it is divided here rather than left to
    // norm(), whose "bigger than 1 must be a percentage" guess cannot tell a
    // 0.5% reading from a 50% one.

    readonly property real cpuPercent: root.caelestia ? (Cae.metrics?.cpuPercent ?? 0) : root.procCpuPercent / 100
    readonly property string cpuName: root.caelestia ? (Cae.metrics?.cpuName ?? "") : root.procCpuName
    readonly property real cpuTemp: root.caelestia ? (Cae.metrics?.cpuTemp ?? 0) : root.procCpuTemp

    readonly property real memTotalBytes: root.caelestia ? (Cae.metrics?.memTotal ?? 0) * 1024 : root.memTotalKb * 1024
    readonly property real memUsedBytes: root.caelestia ? (Cae.metrics?.memUsed ?? 0) * 1024 : Math.max(0, (root.memTotalKb - root.memAvailKb) * 1024)
    readonly property real memPercent: root.caelestia ? (Cae.metrics?.memPercent ?? 0) : (root.memTotalKb > 0 ? (root.memTotalKb - root.memAvailKb) / root.memTotalKb : 0)

    readonly property real gpuPercent: root.caelestia ? (Cae.metrics?.gpuPercent ?? 0) : root.procGpuPercent / 100
    readonly property string gpuName: root.caelestia ? (Cae.metrics?.gpuName ?? "") : root.procGpuName
    readonly property real gpuTemp: root.caelestia ? (Cae.metrics?.gpuTemp ?? 0) : root.procGpuTemp

    readonly property real storagePercent: root.caelestia ? (Cae.metrics?.storagePercent ?? 0) : root.procStoragePercent / 100
    readonly property var storagePrimary: root.caelestia ? Cae.metrics?.storagePrimary : root.procDisks[0]
    readonly property var disks: root.caelestia ? (Cae.metrics?.storageDisks ?? []) : root.procDisks

    readonly property real netUp: root.caelestia ? (Cae.metrics?.netUp ?? 0) : root.procNetUp
    readonly property real netDown: root.caelestia ? (Cae.metrics?.netDown ?? 0) : root.procNetDown
    readonly property real netUpTotal: root.caelestia ? (Cae.metrics?.netUpTotal ?? 0) : root.procNetUpTotal
    readonly property real netDownTotal: root.caelestia ? (Cae.metrics?.netDownTotal ?? 0) : root.procNetDownTotal

    // --- fallback sources ---------------------------------------------------

    property string procCpuName: ""
    property real procGpuPercent: 0
    property string procGpuName: ""
    property real procGpuTemp: 0
    property real procStoragePercent: 0
    property var procDisks: []
    property real procNetUp: 0
    property real procNetDown: 0
    property real procNetUpTotal: 0
    property real procNetDownTotal: 0
    property var lastNetRaw: null

    // The hottest package sensor, which is what "CPU temperature" means on
    // every machine that reports one. Reuses the hwmon sweep already running.
    readonly property real procCpuTemp: {
        let best = 0;
        for (const t of root.temperatures ?? []) {
            const n = `${t.chip} ${t.label}`.toLowerCase();
            if (n.includes("package") || n.includes("tctl") || n.includes("tdie") || t.chip === "coretemp" || t.chip === "k10temp")
                best = Math.max(best, t.celsius);
        }
        return best;
    }

    // Read once: the model name does not change while the machine is up.
    FileView {
        path: "/proc/cpuinfo"
        printErrors: false
        // Read once, explicitly: nothing else would ever ask it to.
        Component.onCompleted: reload()

        onLoaded: {
            const m = /^model name\s*:\s*(.+)$/m.exec(text());
            if (m)
                root.procCpuName = m[1].trim();
        }
    }

    // amdgpu and intel both expose a busy percentage in sysfs; nvidia needs
    // nvidia-smi, which the caelestia-less path asks for separately because
    // the existing nvidia Process here is about power and VRAM.
    Process {
        id: gpuFallback

        running: false
        command: ["sh", "-c", "for d in /sys/class/drm/card*/device; do [ -r \"$d/gpu_busy_percent\" ] || continue; echo \"busy $(cat $d/gpu_busy_percent)\"; [ -r \"$d/uevent\" ] && grep -m1 '^DRIVER=' \"$d/uevent\"; break; done; command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,name --format=csv,noheader,nounits | head -1 | sed 's/^/nv /'"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const nv = /^nv\s+(\d+)\s*,\s*(\d+)\s*,\s*(.+)$/.exec(line);
                    if (nv) {
                        root.procGpuPercent = parseInt(nv[1]);
                        root.procGpuTemp = parseInt(nv[2]);
                        root.procGpuName = nv[3].trim();
                        continue;
                    }
                    const busy = /^busy\s+(\d+)$/.exec(line);
                    if (busy && !root.procGpuName)
                        root.procGpuPercent = parseInt(busy[1]);
                    const drv = /^DRIVER=(.+)$/.exec(line);
                    if (drv && !root.procGpuName)
                        root.procGpuName = drv[1].trim();
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: !root.caelestia && Demand.needed("sys.gpu")
        repeat: true
        triggeredOnStart: true
        onTriggered: gpuFallback.running = true
    }

    // One df for every real filesystem. Percentages come straight from it
    // rather than being recomputed, so they match what the shell would say.
    Process {
        id: dfFallback

        running: false
        command: ["sh", "-c", "df -B1 --output=target,size,used,pcent -x tmpfs -x devtmpfs -x efivarfs -x overlay 2>/dev/null | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    const f = line.trim().split(/\s+/);
                    if (f.length < 4)
                        continue;
                    const total = parseInt(f[1]);
                    const used = parseInt(f[2]);
                    if (!Number.isFinite(total) || total <= 0)
                        continue;
                    out.push({
                        mount: f[0],
                        total: total,
                        used: used,
                        free: total - used,
                        percentage: parseFloat(f[3])
                    });
                }
                root.procDisks = out;
                const rootFs = out.find(d => d.mount === "/");
                root.procStoragePercent = rootFs ? rootFs.percentage : (out[0]?.percentage ?? 0);
            }
        }
    }

    Timer {
        interval: 20000
        running: !root.caelestia && Demand.needed("sys.storage")
        repeat: true
        triggeredOnStart: true
        onTriggered: dfFallback.running = true
    }

    // /proc/net/dev is cumulative, so speed is a delta over the interval.
    // Loopback is excluded; everything else is summed, which is what the
    // caelestia service reports too.
    FileView {
        id: procNetDev

        path: "/proc/net/dev"
        printErrors: false

        onLoaded: {
            let rx = 0;
            let tx = 0;
            for (const line of text().split("\n")) {
                const m = /^\s*([\w.-]+):\s*(.*)$/.exec(line);
                if (!m || m[1] === "lo")
                    continue;
                const f = m[2].trim().split(/\s+/).map(n => parseInt(n) || 0);
                if (f.length < 9)
                    continue;
                rx += f[0];
                tx += f[8];
            }
            root.procNetDownTotal = rx;
            root.procNetUpTotal = tx;

            const now = Date.now();
            const prev = root.lastNetRaw;
            if (prev) {
                const dt = (now - prev.t) / 1000;
                if (dt > 0.05) {
                    root.procNetDown = Math.max(0, (rx - prev.rx) / dt);
                    root.procNetUp = Math.max(0, (tx - prev.tx) / dt);
                }
            }
            root.lastNetRaw = {
                t: now,
                rx: rx,
                tx: tx
            };
        }
    }

    Timer {
        interval: 2000
        running: !root.caelestia && Demand.needed("sys.net")
        repeat: true
        triggeredOnStart: true
        onTriggered: procNetDev.reload()
    }

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool hasBattery: batteryDevice?.isLaptopBattery ?? false
    readonly property real batteryLevel: root.norm(batteryDevice?.percentage ?? 0)
    readonly property bool charging: (batteryDevice?.state ?? 0) === UPowerDeviceState.Charging
    // "Plugged in" is broader than "charging": a laptop sitting at a charge
    // limit reports PendingCharge, and one that is full reports FullyCharged.
    // Treating those as "on battery" is how you get a card claiming it is
    // discharging while the cable is in.
    readonly property bool plugged: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(batteryDevice?.state ?? 0)
    readonly property real changeRate: batteryDevice?.changeRate ?? 0
    readonly property string batteryState: {
        const d = root.batteryDevice;
        if (!d || !root.hasBattery)
            return "No battery";
        if (root.charging)
            return d.timeToFull > 0 ? `${root.duration(d.timeToFull)} to full` : "Charging";
        if (d.state === UPowerDeviceState.FullyCharged)
            return "Fully charged";
        if (d.state === UPowerDeviceState.PendingCharge)
            return "Plugged in, holding";
        if (d.state === UPowerDeviceState.PendingDischarge)
            return "Pending discharge";
        return d.timeToEmpty > 0 ? `${root.duration(d.timeToEmpty)} left` : "On battery";
    }

    function duration(seconds: real): string {
        if (!seconds || seconds <= 0)
            return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    // --- host info --------------------------------------------------------

    readonly property string user: Quickshell.env("USER") || "user"
    readonly property string shellName: (Quickshell.env("SHELL") || "").split("/").pop()
    property string hostname: ""
    property string kernel: ""
    property string osPretty: ""
    property string osId: ""
    property string uptime: ""
    property string packages: ""

    function infoRow(key: string): var {
        switch (key) {
        case "host":
            return {
                label: "Host",
                value: `${root.user}@${root.hostname}`,
                icon: "person"
            };
        case "kernel":
            return {
                label: "Kernel",
                value: root.kernel,
                icon: "memory"
            };
        case "uptime":
            return {
                label: "Uptime",
                value: root.uptime,
                icon: "schedule"
            };
        case "shell":
            return {
                label: "Shell",
                value: root.shellName,
                icon: "terminal"
            };
        case "os":
            return {
                label: "OS",
                value: root.osPretty,
                icon: "desktop_windows"
            };
        case "packages":
            return {
                label: "Packages",
                value: root.packages,
                icon: "inventory_2"
            };
        case "wm":
            return {
                label: "WM",
                value: Quickshell.env("XDG_CURRENT_DESKTOP") || "Hyprland",
                icon: "grid_view"
            };
        case "cpu":
            return {
                label: "CPU",
                value: root.cpuName,
                icon: "developer_board"
            };
        case "gpu":
            return {
                label: "GPU",
                value: root.gpuName,
                icon: "view_in_ar"
            };
        case "fans":
            return {
                label: "Fans",
                value: root.hasFans ? `${root.fanCpuRpm} / ${root.fanGpuRpm} rpm` : "idle",
                icon: "mode_fan"
            };
        case "power":
            return {
                label: "Power",
                value: `${root.cpuWatts.toFixed(0)} W CPU · ${root.gpuWatts.toFixed(0)} W GPU`,
                icon: "bolt"
            };
        case "refresh":
            return {
                label: "Refresh",
                value: root.refreshRate,
                icon: "monitor"
            };
        default:
            return {
                label: key,
                value: "",
                icon: "chevron_right"
            };
        }
    }






    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const lines = text().split("\n");
            const fd = key => lines.find(l => l.startsWith(`${key}=`))?.split("=").slice(1).join("=").replace(/"/g, "") ?? "";
            root.osPretty = fd("PRETTY_NAME") || fd("NAME");
            root.osId = fd("ID");
        }
    }

    FileView {
        path: "/proc/sys/kernel/hostname"
        onLoaded: root.hostname = text().trim()
    }

    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim()
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        onLoaded: {
            const secs = parseFloat(text().split(" ")[0]);
            const d = Math.floor(secs / 86400);
            const h = Math.floor((secs % 86400) / 3600);
            const m = Math.floor((secs % 3600) / 60);
            root.uptime = d > 0 ? `${d}d ${h}h ${m}m` : h > 0 ? `${h}h ${m}m` : `${m}m`;
        }
    }

    Timer {
        interval: 30000
        running: Demand.needed("sys.host")
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            uptimeFile.reload();
            pkgCount.running = true;
        }
    }

    Process {
        id: pkgCount

        command: ["sh", "-c", "pacman -Qq 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                root.packages = isNaN(n) || n === 0 ? "" : `${n}`;
            }
        }
    }
}
