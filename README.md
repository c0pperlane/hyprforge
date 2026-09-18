# Caelestia Forge

A desktop designer for the caelestia dots. It runs as its own Quickshell
config, draws whatever you place on every monitor, and opens a full-screen
editor on demand so you can drag, snap and fine-tune those widgets in place.

```
Desktop Designer        in the launcher / start menu
SUPER + ALT + D         toggle the editor
caelestia-forge         same thing, from a terminal
```

## How it is put together

Two halves, one process (`qs -c caelestia-forge`):

- **The widget layer** (`layer/`) — one layer-shell surface per monitor on
  `WlrLayer.Bottom`, rendering everything in your layout. Input is masked down
  to just the widgets that asked to be interactive, so the rest of the desktop
  stays clickable as if nothing were there.
- **The editor** (`editor/`) — an overlay that takes over the screen with an
  artboard, a grid, snapping, and floating tool palettes. Only one editor
  window exists even with several monitors: *which* monitor you are designing
  is a choice in the toolbar, so you can lay out a headless or AR output from
  the laptop panel.

Design coordinates are the target monitor's real pixels. What you place at
(140, 170) lands at (140, 170) — no unit conversion anywhere.

## Displays

Each widget records the display it belongs to as both a connector name
(`eDP-1`) and a stable identity taken from the monitor description
(`Samsung Display Corp. ATNA60HU02-0`).

The name alone is not enough: this laptop's internal panel enumerates as
`eDP-1` on one boot and `eDP-2` on the next — caelestia's own telemetry code
carries a comment saying exactly that — and a layout authored against the old
name renders on no display at all, with the daemon running and its layer
surface present. Nothing looks broken; the widgets are simply assigned to a
monitor that no longer exists.

So the layout is reconciled against the connected displays on load, and again
whenever the display list changes, in three steps:

1. a display whose description matches the widget's recorded identity;
2. failing that, the same connector family — `eDP-2` and `eDP-1` are the same
   laptop panel under a different index, which is the case this exists for and
   the one that layouts written before identities were recorded will hit;
3. failing that, if only one display is connected, that one.

It is idempotent, logs what it moved, and saves the result, so a rename costs
one startup and never recurs.

## Idle cost

A desktop widget spends most of its life invisible — covered by a window,
hidden, or on a display you are not looking at — and there is no reason for it
to keep a `nvidia-smi` poll or a weather request alive while it is.

Three things make that true rather than aspirational:

1. **Nothing unplaced is ever constructed.** `Catalog.qml` only *declares*
   Components; a widget type that no layout references costs one QML type
   registration and nothing else.
2. **Nothing invisible is constructed either.** `WidgetHost`'s Loader is
   `active` only for widgets belonging to this output and not marked hidden, so
   a hidden element is torn down, not merely transparent.
3. **Services are ref-counted.** Each widget declares the service keys it needs;
   the host acquires them only while the widget is genuinely being displayed
   and releases them otherwise. Services bind their timers to
   `Demand.needed(key)`. Demand follows props, so a Stat Ring switched from CPU
   to GPU moves its demand with it.

"Being displayed" means the layer is enabled, the editor is not eclipsing it,
and the desktop is actually visible — so tiling a window over the desktop stops
the polling, not just the drawing.

There is exactly one exception, and it is deliberate: a widget with a
[visibility condition](#visibility-conditions) that reads a service holds that
service while it is *placed*, not while it is built. "Show when lyrics exist"
cannot ever come true if nothing is fetching lyrics. Only rules that need one
do this, the Inspector names the service when you add such a rule, and the
hold still ends with the layer — a covered desktop answers no conditions
either, since nothing could appear on it anyway.

Check it at any time:

```
caelestia-forge status
```

which prints every service currently held awake and by how many widgets, or
`(idle - nothing held)` with the reason why, since "the gating is working" and
"the widgets are broken" otherwise look identical from outside:

```
$ caelestia-forge status
unit: enabled, active
running
(idle - nothing held: desktop is covered by windows)
```

With a window covering the desktop that list should be empty; with the desktop
in view it should name the services the placed widgets actually use.

## Running it

The daemon is started with `qs -c caelestia-forge -n -d`. **The `-n` matters**:
without it a second launch starts another daemon, both draw their own
layer-shell surface on the same output, and every widget appears twice —
slightly offset if one of them has a stale layout. Stopping likewise goes
through `qs kill -c caelestia-forge` rather than matching on
`/proc/PID/cmdline`, because a daemonised instance rewrites its argv and a
cmdline grep silently finds nothing.

### Autostart

A systemd user unit, `~/.config/systemd/user/caelestia-forge.service`, is what
starts it at login:

    systemctl --user enable --now caelestia-forge.service

It is `WantedBy=graphical-session.target`, which under uwsm is the only thing
that reliably knows a compositor exists and has published `WAYLAND_DISPLAY`
into the user environment. `PartOf=` takes it down with the session, and
`Restart=on-failure` brings it back after a crash — Quickshell deliberately
will not respawn itself — capped at four tries in two minutes so a broken
config stops instead of spinning.

Under systemd the unit runs `qs -c caelestia-forge -n` **without** `-d`:
systemd supervises the process directly, and daemonising would hand it a pid
that exits immediately.

There is deliberately no second mechanism. An `hl.on("hyprland.start")` hook in
`hypr-user.lua` would race the unit and can end up with two daemons; that file
now only carries the `SUPER + ALT + D` keybind. `caelestia-forge start|stop|
restart` detect the unit and defer to `systemctl --user` so the CLI and systemd
cannot disagree about whether it is running.

## Files

| Path | What it is |
| --- | --- |
| `~/.config/caelestia/forge/layout.json` | the document: every placed widget |
| `~/.config/caelestia/forge/settings.json` | grid, snapping, editor prefs |
| `~/.local/state/caelestia/scheme.json` | *read only* — the live M3 palette |
| `samples/` | bundled layouts, see `caelestia-forge sample` |

Both JSON files are yours to hand-edit. `caelestia-forge reload` re-reads the
layout; settings are watched and apply live.

## The editor

| | |
| --- | --- |
| Drag | move (Shift constrains to one axis) |
| Handles | resize (Shift keeps aspect on the corners) |
| Drag on empty canvas | marquee select |
| Middle-drag / Space-drag | pan |
| Ctrl + wheel | zoom to cursor |
| Arrows / Shift+Arrows | nudge 1px / 10px |
| Ctrl+Z / Ctrl+Shift+Z | undo / redo |
| Ctrl+D, Ctrl+C/V, Ctrl+A | duplicate, copy/paste, select all |
| G / S | toggle grid / snapping |
| L / H | lock / hide selection |
| Tab | preview — hides every panel |
| F1 | the full cheatsheet |
| Esc | deselect, then close |

**Snapping.** Every edge of the box you are moving or resizing — left, right,
centre, top, bottom — is tested against every candidate line: grid lines, the
usable-area bounds, and other elements' edges and centres. Nearest wins, with
grid lines weighted slightly weaker so lining up with a sibling beats lining up
with the grid when they are equally close. Guides show which line caught, in
the colour of what it was.

Grid lines are ordinary candidates rather than a special case, which is what
makes *resizing* snap to the grid at all — previously only the top-left corner
was quantised, so the dragged edge landed wherever the mouse was and widths
were never whole cells. Whole-cell widths and heights are offered as size
candidates too, so a resize can lock onto "three cells" as readily as onto
"the same width as that one".

**Cell mode** (`C`, or the ▦ toolbar button) turns the grid from a hint into
the layout: position *and* size always land on a cell boundary, with no magnet
threshold to drag past, and the arrow keys move by one cell instead of one
pixel. A gutter setting insets each element inside its cells. **Snap to grid**
in the Canvas palette quantises a selection — or everything on the display — in
one go, which is the tidy-up for a layout placed by eye before the grid was
turned on. It rounds each element's far edge rather than its width, so things
keep the cells they visually occupy instead of drifting a cell narrower.

**Matching sizes.** Position snapping lines edges up; it cannot make two
widgets the same width unless they happen to start in the same place. So
resizing also snaps to *dimensions*: drag an edge to within the magnet distance
of another element's width or height and it locks on, with the readout showing
`= w 380`. The usable area's full, half and third widths are candidates too.
For an exact match without dragging, select several elements and use the
toolbar's ↔ / ↕ / ⧉ buttons — they size everything to the element you selected
**last**, the same reference every design tool uses.

**The usable area** (`B`, or the ▣ toolbar button) draws what the screen
actually leaves you. Hyprland reports a `reserved` inset per output — on this
setup `[60, 10, 10, 10]`: caelestia's bar down the left edge, its border on the
other three sides. Forge reads that rather than guessing a uniform margin,
draws corner brackets at the real usable corners, hatches the reserved bands,
and labels each inset. Edge snapping and "align to screen" both work against
this rectangle, so aligning left puts an element beside the bar rather than
underneath it. If Hyprland reports nothing for an output, the overlay says so
instead of drawing a full-screen rectangle that looks like a valid answer.

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

## Visibility conditions

Any element can carry rules that decide whether it is on the desktop at all:
a battery card that only appears on battery, a lyrics panel that only appears
once there are lyrics, a media card that goes away when the music stops.

Set them in the Inspector under **Visibility**. Each rule can be inverted (the
⊘ button), and with more than one you choose whether **all** or **any** must
hold. An element with rules gets a marker in the Layers panel — hovering it
spells the rules out in the status bar — because a widget that is simply
absent otherwise looks like a bug rather than a rule someone wrote.

| Group | Rules |
|---|---|
| Power | on battery, on AC, charging, battery below *n*% |
| Media | media playing, media paused, a player is open, lyrics available, output muted |
| Screen | desktop is clear, a window is fullscreen, workspace is *n* |
| Time | after *hh:mm*, before *hh:mm* |
| System | bluetooth device connected, parked cores above *n* |

An unmet condition **un-builds** the element rather than hiding it: the layer
drops the Loader entirely, so something waiting on a condition costs nothing
while it waits. That is the same mechanism as the visibility toggle, and the
reason conditions are cheap enough to use freely.

Screen rules answer for the output the widget is on, not the focused one — a
widget on the internal panel should not appear because something went
fullscreen on an external monitor.

Two deliberate fail-open choices, both so that a widget never disappears for a
reason nothing can explain: a rule key this build does not recognise (a layout
written by a newer version) counts as met, and a malformed time is rejected at
the point of entry rather than stored.

Conditions live in the layout file as a `cond` object per widget, and its
absence means "always", so layouts written before they existed load unchanged.

## Corners and joining

Corner radius is one value while **linked**, and four when it is not — the
Inspector lays the fields out at the actual corners of a preview rectangle,
because "top left / top right / bottom left / bottom right" as a list is a
puzzle to map onto the shape in front of you. Unlinking seeds all four from the
shared value so nothing jumps.

**Joining** is automatic rather than another setting to maintain. When two
surfaces are snapped flush — a daylight arc sitting directly on a now-playing
card — the corners where they meet square off, and the pair reads as one panel
instead of two cards with a seam. Move either one away and the corners come
back. It is derived from geometry on every document change, so there is nothing
to remember to undo.

Only surfaces take part: an element with no background has no corner to square,
and letting it join would square its neighbour against nothing. Two widgets
meeting at a single corner point do not count as joined — the shared edge has to
actually overlap. Per-widget, *Join to touching neighbours* turns it off.

## Styles

The **Styles** palette (`T`) holds presets for the shared Surface/Colour props.
"Caelestia Modal" is the anchor: it reproduces how this shell draws its own
drawers right now — opaque `m3surfaceContainer`, extra-large corners, no border
— which reads as opaque because `appearance.transparency.enabled` is off in
`shell.json`. "Caelestia Translucent" is the same shape for when that is turned
back on. The rest run from Glass and Elevated through to Bare, which drops the
surface entirely and turns on the legibility shadow.

Picking a preset makes it the active style for newly placed elements and, if
something is selected, restyles the selection immediately. The two buttons
underneath cover the bulk cases: the selection, or every element on the display.

## Typography

The **Typography** palette (`F`) picks a font once and pushes it out as far as
you want it to go — each target independently switchable:

| Target | What it writes |
| --- | --- |
| Forge widgets | Forge's own `settings.json` |
| Caelestia shell | `appearance.font.*.family` in `shell.json` |
| System default | `~/.config/fontconfig/conf.d/99-caelestia-forge-fonts.conf` |
| GTK apps | `gsettings` + `gtk-3.0`/`gtk-4.0` `settings.ini` |
| Discord | the Vencord `quickCss.css` of Equibop/Vesktop |

**Force** goes further: instead of only redefining the generic sans/serif/mono,
it puts your family in front of whatever an app explicitly asked for. Two
categories are excluded automatically, because forcing them is what breaks a
desktop:

- **Icon and symbol faces** — Material Symbols, every Nerd Font, Font Awesome,
  emoji. Remap these and the status bar becomes a row of rectangles.
- **Monospaced faces** — an editor asking for a specific mono font wants *a*
  monospace; handing it a proportional one wrecks every aligned column. Generic
  `monospace` requests are still redirected.

Wine, Proton and Steam processes are skipped by `prgname`, since games ship
their own UI fonts and look wrong without them.

Everything is reversible. **Revert all** restores the backups the tool made
(`*.pre-forge-fonts`), deletes the fontconfig file, strips the Discord CSS block
and puts the GTK settings back. The same thing from a terminal:

```
caelestia-forge fonts apply --sans "Rubik" --mono "JetBrainsMono Nerd Font" --force
caelestia-forge fonts revert
caelestia-forge fonts status
```

The shell and Forge apply a font change live; other apps pick it up on restart.

## Lyrics

The Lyrics element reads caelestia's own pipeline rather than fetching
anything itself: the shell resolves a track and leaves the result on disk as
`~/.local/state/caelestia/lyrics/lyrics_map.json` (`"Artist - Title"` ->
backend, id, offset) plus a cached `.lrc` under
`~/.cache/caelestia/lyrics/<BACKEND>/<id>.lrc`. Forge watches both and parses
the LRC timestamps itself.

It still calls `Lyrics.setTrack(...)`, which is what makes the shell's pipeline
go for a track nobody has opened the dashboard on — but the display follows the
files, whoever wrote them. Driving the C++ service from Forge's own process and
reading its `lyrics` property did not work: it sat on "loading" indefinitely
while the shell's copy resolved the same track fine, and two processes racing
to fetch and rewrite one cache is not a design worth having.

Three layouts — scrolling, three-line, or just the current line — and the empty
state is configurable: a message, a bare icon, or hide the element entirely.
"Hide" is ignored inside the editor, since an invisible element cannot be
selected or moved.

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

## CLI

```
caelestia-forge            open the designer
caelestia-forge toggle     open/close it
caelestia-forge widgets    show/hide the desktop layer
caelestia-forge reload     re-read layout.json
caelestia-forge sample     list bundled layouts
caelestia-forge sample starter
caelestia-forge start|stop the daemon
```
