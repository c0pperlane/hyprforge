# caelestia-shell

Hyprforge works with or without it. This is what changes either way.


[← back to the README](../README.md)


## What it needs

| | |
|---|---|
| **Quickshell** | Required. This is a Quickshell config, not a standalone app. Built against 0.3.1 / Qt 6.11. |
| **Hyprland** | Required. Monitor enumeration, the `reserved` insets behind the usable-area guides, the Workspaces widget and the screen-based visibility conditions all go through `Quickshell.Hyprland`. The layer-shell half is generic wlroots and would run on Sway, river or niri; these queries would not. |
| **[caelestia-shell](https://github.com/caelestia-dots/shell)** | **Optional.** Forge is caelestia-top-up compatible: it uses caelestia's services where they exist and its own readers where they do not. |

### Running without caelestia

Forge grew up inside the caelestia dots and used its C++ services directly,
which made caelestia a hard requirement for reasons that had nothing to do
with the designer — a QML `import` of a missing module is a *compile* error,
so one absent plugin took the whole config down rather than one widget.

Everything that touches `Caelestia.*` now lives in `services/cae/`, loaded at
runtime. `Cae.available` is the answer to "is caelestia-shell installed", and
every consumer reads through an accessor with a plain-QML fallback behind it.
Same accessors, same units, same demand gating, so nothing downstream knows
which source answered — and the idle cost with caelestia absent is the same
nothing.

| Metric | With caelestia | Without |
|---|---|---|
| CPU load, temperature, model | `Cpu` service | `/proc/stat` aggregate, hwmon package sensor, `/proc/cpuinfo` |
| Memory | `Memory` service | `/proc/meminfo` |
| GPU load, temperature, name | `Gpu` service | `gpu_busy_percent` in sysfs, or `nvidia-smi` |
| Disks | `Storage` service | one `df` |
| Network throughput | `NetworkUsage` service | `/proc/net/dev` deltas |
| Wavy line | `Caelestia.Components` | dropped — reimplemented as plain QML, so that module is no longer used at all |
| Colours | `scheme.json` | the palette baked into `Theme.qml` |
| Audio level (WaveLine) | — | `PwNodePeakMonitor`, straight off the default sink. This one is not really a caelestia fallback: it is what Volume.qml already relies on unconditionally, so it works identically with or without caelestia and always has. |
| Audio **spectrum** (Visualiser's bars) | `CavaProvider` | the real [`cava`](https://github.com/karlstav/cava) CLI, run with `method = pipewire` and told to print raw values instead of drawing a terminal UI — see [docs/widgets.md](widgets.md#audio). A per-band spectrum needs an actual FFT of the stream, which PipeWire's own client API does not expose, only a peak level (the row above). Neither caelestia nor cava present, Visualiser says so rather than faking bars from that peak level. |
| Lyrics | caelestia's fetcher | [lrclib.net](https://lrclib.net) — a free, keyless public API. Both write the same map + `.lrc` files to disk, so the reading side (parsing, timing, seeking) is one code path regardless of which one filled the cache. |
| Keyboard layout detail | `HyprExtras` | falls back to the configured layout list |

Verified both ways: the caelestia path and the fallback path report the same
numbers for the same machine, checked against `free`, `df` and `sensors`. The
no-caelestia path is tested by masking the module out with
`bwrap --tmpfs /usr/lib/qt6/qml/Caelestia`.

The lyrics fetcher was checked against the real LRCLIB API rather than
assumed - including the one genuine surprise it turned up: `/api/get`
refuses the request outright without a `duration`, so a track whose length
is not yet known goes straight to `/api/search` instead.

The audio row split in two after it turned out to be less final than the
first pass of this table claimed: "no substitute" was true of a full
spectrum, but overstated for level-driven reactivity — PipeWire answers that
part directly, no caelestia and no extra package, and Volume.qml was already
proof of it. What was missing was *bars*, not audio.

`qs -c hyprforge ipc call diag backend` prints which source is live and
what it currently reads.


## Replacing caelestia's built-in desktop widgets

This shell's patched `Background.qml` used to draw a big clock, a playback card
and two telemetry clusters at fixed anchors. Those are now switched off and
rebuilt as movable Forge elements — the `desktop` sample is that layout:

| Was | Is now |
| --- | --- |
| `DesktopBigClock` | `HeroClock`, centred |
| `DesktopBottomLeftCluster` | `StatStack` — cpu / memory / gpu / vram / disk |
| `DesktopTelemetry` | `BatteryCard` + `StatStack` — fans, package power |
| `DesktopBottomCenter` | `NowPlaying` |
| `Config.background.visualiser` | `Visualiser` |
| `Config.background.desktopClock` | any of the clock elements |

Forge reads the same sensors the originals did — RAPL for CPU package power,
`nvidia-smi` for GPU power/clock and real VRAM, `legion-fan-rpms` for fan speed
— so nothing was lost in the move.

**To put the originals back:**

```bash
sudo cp /etc/xdg/quickshell/caelestia/modules/background/Background.qml.pre-forge-patch \
        /etc/xdg/quickshell/caelestia/modules/background/Background.qml
cp ~/.config/caelestia/shell.json.pre-forge ~/.config/caelestia/shell.json
```

(or just flip the four `active: false // forge-patch` lines back to `true`).
