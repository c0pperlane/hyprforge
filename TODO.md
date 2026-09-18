# Caelestia Forge — task list

## Done

- **Desktop designer** — layer-shell widget layer + fullscreen editor, grid,
  snapping (position, edges, sibling sizes, whole grid cells), alignment,
  match-size, undo/redo, multi-select, marquee, layers, per-monitor artboards.
- **32 widgets** across Time / System / Media / Info / Shell / Decor.
- **Style presets** (`T`) — 10 surface/colour presets anchored on the shell's
  own modal styling.
- **Typography** (`F`) — one font pushed to Forge, the shell, fontconfig, GTK
  and Discord, with a force mode that excludes icon and monospace families, and
  a full revert.
- **Usable-area guides** (`B`) — real `reserved` insets from Hyprland.
- **Weather** — per-widget locations, IP geolocation with fallback + disk cache,
  retry with backoff, resume-from-suspend refresh.
- **Lyrics** — reads caelestia's own pipeline (`lyrics_map.json` + cached
  `.lrc`), three layouts, configurable empty state.
- **Sticky note typing** — layer takes keyboard focus on demand; click-away and
  focus-loss release it.
- Replaced caelestia's hardcoded desktop widgets (backups kept).
- **Idle cost** — ref-counted service demand: a widget only holds `nvidia-smi`,
  cava, weather and friends awake while it is genuinely on display. Unplaced
  widgets are never constructed; hidden ones and those on other outputs are torn
  down. `caelestia-forge status` prints what is currently held.
- **Single instance** — `qs -c caelestia-forge -n -d`; `qs kill` to stop. Two
  daemons were drawing the same widgets twice.
- **Seventeen more widgets** — core load, top processes, temperatures, network
  interfaces, disk I/O, uptime ring, pomodoro, stopwatch, volume, brightness,
  keyboard layout, bluetooth, clipboard history, idle inhibitor, palette,
  daylight arc, moon phase. All demand-gated.
- Fixed: swap reported RAM's percentage; weather registration raced its own
  demand gate and silently never fetched.

## Next

Nothing blocking. Ideas not yet built: system tray and a notification feed
(both would contend with the shell's own server), RSS, recording indicator,
workspace preview thumbnails, calendar agenda (needs a calendar backend — none
is present on this machine).

## Backlog

### Steam Millennium "Space Theme" → follow the caelestia scheme live
Make the Steam skin recolour itself when the wallpaper/scheme changes, the same
way the shell and Forge already do.

Everything needed is already on disk:

- Scheme source: `~/.local/state/caelestia/scheme.json` — 120 M3 roles, plus
  `mode` (light/dark). Already watched by Forge's `Theme` singleton.
- Active skin: `~/.config/millennium/config.json` → `themes.activeTheme` =
  `"Steam"`, with `themeColors.Steam` holding the palette as CSS custom
  properties in **`"R, G, B"` string form**, e.g.
  `"--st-accent-1": "102, 108, 255"`, `"--st-background": "10, 10, 10"`,
  `--st-color-1..6`, `--st-blue/green/red/yellow` and their `-hover` variants.
- Injection point: `~/.config/millennium/quick.css` (Millennium writes the
  header comment itself), with `general.injectCSS: true` already set.
- Theme dir: `~/.local/share/Steam/millennium/themes/Steam`.

Plan:
1. Map caelestia roles onto the `--st-*` set — `surface`/`surfaceContainer*`
   onto `--st-color-1..6` and `--st-background`, `primary` onto `--st-accent-*`,
   and `error`/`success` onto `--st-red`/`--st-green`. Convert `#rrggbb` to
   `"R, G, B"`.
2. Write them into `quick.css` as a marker-delimited `:root { … }` block —
   the same approach already used for Discord — rather than editing
   `config.json`, so Millennium's own theme editor is not fighting us.
   Fall back to patching `themeColors` if CSS specificity loses.
3. Hook it to scheme changes: a small writer invoked from the same place the
   font tool is, watching `scheme.json`.
4. Check whether Millennium live-reloads `quick.css`; if not, find its reload
   IPC, and otherwise accept "applies on next Steam start".
5. Extend `caelestia-forge-fonts`-style CLI, or add a sibling
   `caelestia-forge-colors`, with apply/revert and a backup of `quick.css`.

Open question: whether the user wants this to follow *every* scheme change
automatically or be a toggle.
