#!/usr/bin/env bash
# Hyprforge installer.
#
#   curl -fsSL https://raw.githubusercontent.com/REPO_SLUG/main/install.sh | bash
#
# or, if you would rather read it first (you should):
#
#   git clone https://github.com/REPO_SLUG ~/Projects/hyprforge
#   ~/Projects/hyprforge/install.sh
#
# Installs to ~/.config/quickshell/hyprforge, ~/.local/bin and a systemd user
# unit. Everything is per-user; nothing here needs root, and it will refuse to
# run as root because a desktop widget layer installed system-wide belongs to
# nobody.
set -euo pipefail

REPO="${HYPRFORGE_REPO:-https://github.com/REPO_SLUG}"
BRANCH="${HYPRFORGE_BRANCH:-main}"
NAME=hyprforge

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
DEST="$CONFIG_HOME/quickshell/$NAME"
BIN="$HOME/.local/bin"
UNITS="$CONFIG_HOME/systemd/user"
STATE="$CONFIG_HOME/$NAME"
LEGACY_STATE="$CONFIG_HOME/caelestia/forge"

say()  { printf '\033[1;36m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "do not run this as root - Hyprforge installs per-user"

# --- uninstall -------------------------------------------------------------
if [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "-u" ]; then
    say "removing Hyprforge"
    systemctl --user disable --now "$NAME.service" >/dev/null 2>&1 || true
    command -v qs >/dev/null 2>&1 && qs kill -c "$NAME" >/dev/null 2>&1 || true
    rm -f "$UNITS/$NAME.service" "$BIN/$NAME" "$BIN/$NAME-fonts" \
          "$DATA_HOME/applications/$NAME.desktop"
    rm -rf "$DEST"
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    if [ "${2:-}" = "--purge" ]; then
        rm -rf "$STATE"
        say "removed everything, including your layout in $STATE"
    else
        say "removed. Your layout is still in $STATE - pass --purge to delete it too"
    fi
    exit 0
fi

# --- dependencies ----------------------------------------------------------
command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1 \
    || die "Quickshell is required and was not found. Install it first: https://quickshell.org"

if ! command -v hyprctl >/dev/null 2>&1; then
    warn "Hyprland was not found. Hyprforge needs it for monitor geometry, the"
    warn "usable-area guides, the Workspaces widget and the screen conditions."
    warn "Continuing, but expect those to be inert."
fi

if [ -d /usr/lib/qt6/qml/Caelestia ] || [ -d "$HOME/.local/lib/qt6/qml/Caelestia" ]; then
    say "caelestia-shell detected - using its services for system metrics"
else
    say "no caelestia-shell - system metrics will come from /proc; the audio"
    say "   spectrum and lyrics widgets will say they need it"
fi

# --- fetch -----------------------------------------------------------------
# Running from a clone installs that clone; piped from curl, it fetches one.
SRC=""
SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/shell.qml" ]; then
    SRC="$SELF_DIR"
    say "installing from $SRC"
else
    command -v git >/dev/null 2>&1 || die "git is required to fetch Hyprforge"
    SRC="$(mktemp -d)"
    trap 'rm -rf "$SRC"' EXIT
    say "fetching $REPO ($BRANCH)"
    git clone --depth 1 --branch "$BRANCH" "$REPO" "$SRC" >/dev/null 2>&1 \
        || die "could not clone $REPO"
fi

[ -f "$SRC/shell.qml" ] || die "$SRC does not look like a Hyprforge checkout"

# --- install ---------------------------------------------------------------
# The config directory is a copy rather than a symlink into the checkout, so
# that a git operation in the repo cannot hot-reload the running desktop out
# from under you.
say "installing the shell to $DEST"
mkdir -p "$DEST"
rm -rf "$DEST.new"
mkdir -p "$DEST.new"
for item in shell.qml components config editor layer services widgets samples assets; do
    [ -e "$SRC/$item" ] && cp -a "$SRC/$item" "$DEST.new/"
done
rm -rf "$DEST.old"
[ -d "$DEST" ] && mv "$DEST" "$DEST.old"
mv "$DEST.new" "$DEST"
rm -rf "$DEST.old"

say "installing the CLI to $BIN"
install -Dm755 "$SRC/bin/$NAME" "$BIN/$NAME"
install -Dm755 "$SRC/bin/$NAME-fonts" "$BIN/$NAME-fonts"

say "installing the systemd user unit"
install -Dm644 "$SRC/systemd/$NAME.service" "$UNITS/$NAME.service"

# --- migrate ---------------------------------------------------------------
mkdir -p "$STATE"
if [ ! -f "$STATE/layout.json" ] && [ -f "$LEGACY_STATE/layout.json" ]; then
    say "migrating your layout from $LEGACY_STATE"
    cp -a "$LEGACY_STATE/." "$STATE/"
    say "   the originals are left in place; delete them once you are happy"
fi

# --- desktop entry ---------------------------------------------------------
install -d "$DATA_HOME/applications"
cat > "$DATA_HOME/applications/$NAME.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Desktop Designer
GenericName=Widget designer
Comment=Design your Hyprland desktop: widgets, layout, snapping
Exec=$BIN/$NAME toggle
Icon=preferences-desktop-theme
Terminal=false
Categories=Utility;DesktopSettings;
Keywords=widget;desktop;hyprforge;quickshell;
DESKTOP
command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database -q "$DATA_HOME/applications" 2>/dev/null || true

# --- start -----------------------------------------------------------------
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    say "enabling $NAME.service"
    systemctl --user enable "$NAME.service" >/dev/null
    # Only start now if a compositor is actually up; at first login the unit
    # comes up with graphical-session.target on its own.
    if systemctl --user is-active graphical-session.target >/dev/null 2>&1; then
        systemctl --user restart "$NAME.service" || warn "could not start $NAME.service"
    fi
else
    warn "no systemd user session - start it yourself with: $NAME start"
fi

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) warn "$BIN is not on your PATH - add it, or call $BIN/$NAME directly" ;;
esac

cat <<DONE

  Hyprforge is installed.

    $NAME            open the designer
    $NAME status     what it is running and what it is keeping awake
    $NAME --help     everything else

  Bind it to a key in your Hyprland config, for example:

    bind = SUPER ALT, D, exec, $NAME toggle

DONE
