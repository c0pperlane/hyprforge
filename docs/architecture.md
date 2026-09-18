# How Hyprforge is built

Two halves in one process, how it decides what to draw, and why an
off-screen widget costs nothing.


[← back to the README](../README.md)


## How it is put together

Two halves, one process (`qs -c hyprforge`):

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


## Files

| Path | What it is |
| --- | --- |
| `~/.config/caelestia/forge/layout.json` | the document: every placed widget |
| `~/.config/caelestia/forge/settings.json` | grid, snapping, editor prefs |
| `~/.local/state/caelestia/scheme.json` | *read only* — the live M3 palette |
| `samples/` | bundled layouts, see `hyprforge sample` |

Both JSON files are yours to hand-edit. `hyprforge reload` re-reads the
layout; settings are watched and apply live.


## Running it

The daemon is started with `qs -c hyprforge -n -d`. **The `-n` matters**:
without it a second launch starts another daemon, both draw their own
layer-shell surface on the same output, and every widget appears twice —
slightly offset if one of them has a stale layout. Stopping likewise goes
through `qs kill -c hyprforge` rather than matching on
`/proc/PID/cmdline`, because a daemonised instance rewrites its argv and a
cmdline grep silently finds nothing.

### Autostart

A systemd user unit, `~/.config/systemd/user/hyprforge.service`, is what
starts it at login:

    systemctl --user enable --now hyprforge.service

It is `WantedBy=graphical-session.target`, which under uwsm is the only thing
that reliably knows a compositor exists and has published `WAYLAND_DISPLAY`
into the user environment. `PartOf=` takes it down with the session, and
`Restart=on-failure` brings it back after a crash — Quickshell deliberately
will not respawn itself — capped at four tries in two minutes so a broken
config stops instead of spinning.

Under systemd the unit runs `qs -c hyprforge -n` **without** `-d`:
systemd supervises the process directly, and daemonising would hand it a pid
that exits immediately.

There is deliberately no second mechanism. An `hl.on("hyprland.start")` hook in
`hypr-user.lua` would race the unit and can end up with two daemons; that file
now only carries the `SUPER + ALT + D` keybind. `hyprforge start|stop|
restart` detect the unit and defer to `systemctl --user` so the CLI and systemd
cannot disagree about whether it is running.


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
hyprforge status
```

which prints every service currently held awake and by how many widgets, or
`(idle - nothing held)` with the reason why, since "the gating is working" and
"the widgets are broken" otherwise look identical from outside:

```
$ hyprforge status
unit: enabled, active
running
(idle - nothing held: desktop is covered by windows)
```

With a window covering the desktop that list should be empty; with the desktop
in view it should name the services the placed widgets actually use.
