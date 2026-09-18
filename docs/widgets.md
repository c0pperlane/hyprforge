# Widgets

What ships, what each one needs, and how to write another.


[← back to the README](../README.md)


## Widgets

51 elements across Time, System, Media, Info, Shell and Decor. Every one of
them also gets the shared **Surface** controls (none / tonal / solid / glass /
outline, colour, opacity, radius, padding, border, shadow) and **Colour**
controls (accent, foreground, secondary text), so any element can be turned
into a card or stripped back to bare text.

Beyond the obvious clocks and meters: per-core CPU load (bars or a numbered
heat grid), top processes, hwmon temperatures, network interfaces, disk I/O,
an uptime ring, a pomodoro and a stopwatch, volume and brightness dials, the
keyboard layout, paired bluetooth devices, clipboard history (click an entry to
copy it back), an idle inhibitor, a live palette of the current scheme, a
daylight arc from sunrise to sunset, and a moon phase drawn from the date alone.

**Parked Cores** and **Idle Residency** read cpuidle rather than `/proc/stat`,
because the thing they are showing is invisible to `/proc/stat`. This machine
runs sched_ext core compaction (`scx_lavd --autopilot`, from
`legion-core-parking.service`): the scheduler keeps tasks on a small set of
CPUs and does not dispatch to the rest, so those drop into C2/C3. To
`/proc/stat` a sleeping core and a merely unloaded one are both "idle" and look
identical. Parked Cores draws all 32 threads as a grid — dark where the
scheduler has put a core away, amber where it is working, red past 80% — and
Idle Residency stacks the C-state breakdown behind it.

Both apply the same rules as `legion-power status`, and for the same reasons:
residency is a delta between polls rather than a since-boot total, POLL is a
spin and not counted as sleep, each core's contribution is capped at the window
(cpuidle credits a whole sleep at wake, so a core that slept across the
boundary books time from before it), and "parked" is a 95% threshold because a
core taking nothing but timer ticks still reads ~99% idle. A window far longer
than the poll interval is discarded rather than reported: `Date.now()` counts
time across a suspend and the cpuidle counters do not.

Swap, disk read/write throughput and per-core load are also metrics, so any
ring, meter or graph can show them. Swap used to report RAM's own percentage —
a figure that looked plausible and was simply wrong; it now reads
`/proc/meminfo`.

Colours are stored as *palette role names* ("primary", "fgSurface") by default,
so widgets follow the wallpaper scheme as it changes. Type a `#rrggbb` in the
colour picker to pin one instead.


## Adding a widget

1. Write `widgets/MyThing.qml`, deriving from `WidgetBase`. Read your props
   with `num()`, `str()`, `flag()`, `colour()`, `lines()`.
2. Add an entry to `config/Registry.qml` — name, icon, category, default size
   and a property schema. The Inspector builds its controls from that schema;
   there is no per-widget UI code.
3. Add two lines to `widgets/Catalog.qml` (the `map` entry and a `Component`).

Widgets that edit their own state (the note, the checklist) call
`writeProp(key, value)` and the host persists it against that instance.


## Lyrics

The Lyrics element reads a map file plus a cached `.lrc`, and parses the LRC
timestamps itself — it never fetches directly. What fills that cache depends
on whether caelestia-shell is installed:

- **With caelestia**, its own pipeline resolves the track and writes
  `~/.local/state/caelestia/lyrics/lyrics_map.json` (`"Artist - Title"` ->
  backend, id, offset) plus `~/.cache/caelestia/lyrics/<BACKEND>/<id>.lrc`.
  Forge still calls `Lyrics.setTrack(...)`, which is what makes the shell's
  pipeline go for a track nobody has opened the dashboard on yet — the
  display then follows the files, whoever wrote them. Driving the C++
  service from Forge's own process and reading its `lyrics` property did not
  work: it sat on "loading" indefinitely while the shell's own copy resolved
  the same track fine, and two processes racing to fetch and rewrite one
  cache is not a design worth having.
- **Without it**, `LrcFetch` (`services/LrcFetch.qml`) queries
  [lrclib.net](https://lrclib.net) — a free, keyless public API — and writes
  the *same shape* into `~/.cache/hyprforge/lyrics/`, so the reading side
  above is identical either way. An exact match goes through `/api/get`
  (which requires a track duration — Media reports one for anything with
  `mpris:length` set); a miss falls back to `/api/search`. A track with
  genuinely no synced lyrics on LRCLIB is cached as a negative result, so it
  is not re-queried every time it plays.

Three layouts — scrolling, three-line, or just the current line — and the empty
state is configurable: a message, a bare icon, or hide the element entirely.
"Hide" is ignored inside the editor, since an invisible element cannot be
selected or moved.


## Audio

Visualiser (a bar spectrum) and WaveLine (a wave that swells with the beat)
both read from `services/Cava.qml`, which keeps the two apart because they
need different data:

- **WaveLine only ever needs one number** - how loud is it right now - and
  PipeWire answers that directly with `PwNodePeakMonitor` on the default
  sink. This is not really a fallback: it is what Volume.qml already relies
  on unconditionally, so WaveLine has no empty state and no caveat, with or
  without caelestia.
- **Visualiser needs a real per-band spectrum** - distinct bars moving
  somewhat independently, which means an actual FFT of the stream. PipeWire's
  client API does not expose that, only the peak level above. Two things can
  supply it: caelestia's `CavaProvider`, or the real [`cava`](https://github.com/karlstav/cava)
  CLI (unrelated to caelestia beyond sharing a name) when it is installed.
  Forge runs it with `method = pipewire`, `output method = raw` and
  `data_format = ascii`, parsing its stdout with `SplitParser` rather than a
  one-shot collector, since it is a continuous stream, not a single result.
  A generated config lives at `~/.config/hyprforge/cava.conf`, rewritten and
  the process restarted whenever the requested bar count changes. Neither
  source present, the widget says so, naming what to install rather than
  animating silence.

## Weather

Locations are resolved per widget, so two weather elements can show two cities.
A blank location means "here", found by IP lookup (ip-api.com, falling back to
ipapi.co) and cached to disk so a restart doesn't re-ask. `52.5,13.4` works too.

A lookup that fails is retried with backoff — 8s, 20s, 45s, 2min, 5min — rather
than waiting for the quarter-hourly refresh. This matters more than it sounds:
the shell starts before the network is up, so the first attempt at login
usually fails, and without a retry the widget sat there showing an error until
the next tick. A name the geocoder has never heard of is *not* retried, since
the answer will not change. A wall-clock jump larger than the timer interval is
taken as a resume from suspend and queues a refresh a few seconds later, once
the network is back.
