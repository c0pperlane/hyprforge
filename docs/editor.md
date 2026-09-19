# The editor

Everything in the designer: tools, snapping, conditions, corners and
appearance.


[← back to the README](../README.md)


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


## Spacing snapping

Alignment snapping lines edges up; it says nothing about the space between
them. Drag a third card under two that sit 22px apart and the left edges go
flush while the gap lands wherever the pointer stopped.

So a dragged element also snaps to **gaps**: to a distance the layout already
uses, and to the exact middle between the two elements it is being dropped
between. When it lands, every gap on that axis that now measures the same is
marked, not just the one that snapped — the point is the rhythm, so showing one
measurement of it would be showing the wrong thing.

Three rules keep the magnets meaningful rather than noisy:

- Only siblings that **overlap on the other axis** count. A widget off in
  another column is not part of this column's rhythm, and treating it as one
  produces snaps that look like nothing at all.
- Only the gap between **neighbours** is a gap. Measured across something else,
  the distance from the first card to the third is a number the layout never
  intended.
- Gaps wider than `maxGap` (400px default) are not a rhythm, they are a gap.

Spacing competes with alignment on plain distance, at the same weight as a
sibling edge — matching an established gap is as deliberate as lining two edges
up — and both beat the grid, which stays the weakest magnet. Weighting spacing
*below* the grid was the obvious first guess and made it almost unreachable:
with a 32px grid, no point on the board is more than 16px from a line.

It applies to moving an element, not to the edge being pulled during a resize.
Turn it off with **To equal spacing** in the Canvas panel.


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


## Shadows and glows

Every element's **Surface** section (in the Inspector) has a **Shadow**
dropdown: None, Drop, or Glow.

- **Drop** is a directional shadow at any angle — **Angle** turns it around the
  full 360°, **Distance** sets how far it falls, **Blur** how soft the edge is.
  90° is straight down.
- **Glow** is the same blurred, coloured silhouette with the direction forced
  to zero, so it sits evenly behind every edge instead of being cast one way.
  **Spread** grows it past the element's own edges, which is what actually
  reads as a halo rather than a soft-edged rectangle. Colour is normally an
  accent rather than the near-black a drop shadow uses — that's what makes it
  read as a glow rather than a shadow with nowhere to fall.

Both are cast from the *whole element* — its card, if it has one, and
whatever it draws on top of that — not from the card alone. That distinction
matters for anything with **Surface: None**: a bare clock or a number with no
card behind it can still carry a shadow or a glow, cast from its own text.

A blur radius is a fixed number of pixels regardless of what it's blurring,
so it dilutes a lot more on a thin, small line of text than a thick, huge
one — a subtitle under a hero clock will always show a fainter shadow than
the clock itself at the same settings, the same way a pencil line's drop
shadow reads fainter than a block letter's at identical blur and opacity.
Not a fault in either element; **Blur** down or **Opacity** up reads more
clearly on thin strokes if that's not the effect you want.

A shadow never bleeds onto another element, joined or just placed close by,
and it still rounds out properly on every side that isn't touching one.
Qt's shadow effect auto-expands its own canvas by default so a big blur is
never clipped — right for one isolated card, wrong the moment a second
widget sits close by, since the same auto-expansion paints straight across
the gap onto whatever is there. Forge turns that off and gives the shadow
its own room to fall instead: generous on a side with nothing there, so it
still fades out looking complete rather than cut off mid-blur, and exactly
zero on a side with a neighbour immediately past it — corner-joined or
just placed close, the shadow does not care which; only a real neighbour
counts. An attached corner has no rounding to begin with (joining already
squares it off, above), so there is nothing there for a shadow to need
room for either. Push **Distance** or **Blur** far enough past what a
neighbour's own gap allows and the shadow is what gives there, not the
layout.

**Apply to every widget**, at the bottom of the Shadow controls, copies
just those seven values — mode, angle, distance, blur, spread, colour,
opacity — onto every other unlocked element on the same screen. Nothing
else about them changes: not surface, not colour, not radius. For a whole
look, including the card underneath, that's the Styles palette below,
not this.

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
| System default | `~/.config/fontconfig/conf.d/99-hyprforge-fonts.conf` |
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
hyprforge fonts apply --sans "Rubik" --mono "JetBrainsMono Nerd Font" --force
hyprforge fonts revert
hyprforge fonts status
```

The shell and Forge apply a font change live; other apps pick it up on restart.
