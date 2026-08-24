#!/bin/bash
# =============================================================================
# make-macos-app.sh — assemble a self-contained DRAW.app bundle for macOS.
#
# Why this is needed: on macOS the Dock/app icon can ONLY come from a .app
# bundle's Info.plist + .icns — GLFW's window-icon call (QB64-PE's _ICON) and
# $EXEICON are both no-ops there. A bare DRAW.run shows the generic executable
# icon. This wraps the built binary + its runtime assets into DRAW.app so the
# icon shows and a double-click Just Works.
#
# DRAW loads ASSETS/ via RELATIVE paths and does not self-chdir, and a
# double-clicked .app launches with CWD "/". So the bundle ships a tiny launcher
# that cd's into Contents/Resources (where the assets live) before exec'ing the
# binary. User data still goes to ~/Library/Application Support/DRAW (see
# CORE/PATHS.BM), so the read-only bundle is fine.
#
# END USERS do nothing manual: they get DRAW.app, drag it to /Applications, and
# run it. This script is the maintainer/release step that produces that bundle.
#
# Run ON macOS from anywhere after building DRAW.run (make). Produces ./DRAW.app
# in the repo root. Override the output dir with:  OUT_DIR=dist ./DEV/make-macos-app.sh
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BIN="DRAW.run"
ICNS="ASSETS/ICONS/icon.icns"
PLIST_SRC="ASSETS/ICONS/Info.plist"
OUT_DIR="${OUT_DIR:-.}"
APP="$OUT_DIR/DRAW.app"

[ "$(uname -s)" = "Darwin" ] || { echo "This script must run on macOS (Darwin)."; exit 1; }
[ -f "$BIN" ]       || { echo "Build $BIN first:  make"; exit 1; }
[ -f "$ICNS" ]      || { echo "Missing $ICNS"; exit 1; }
[ -f "$PLIST_SRC" ] || { echo "Missing $PLIST_SRC"; exit 1; }

# Version from _COMMON.BI (CONST APP_VERSION$ = "X.Y.Z")
VER="$(grep -oE 'APP_VERSION\$[[:space:]]*=[[:space:]]*"[0-9.]+"' _COMMON.BI | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
VER="${VER:-1.0.0}"

echo "Assembling $APP (DRAW $VER)…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# --- Launcher: cd into Resources so DRAW finds ./ASSETS, then run the binary ---
cat > "$APP/Contents/MacOS/DRAW" <<'LAUNCH'
#!/bin/bash
# DRAW.app launcher — run the bundled binary from its Resources dir so relative
# ASSETS/ paths resolve. Forwards any Finder/CLI arguments (e.g. an opened .draw).
cd "$(cd "$(dirname "$0")/../Resources" && pwd)"
exec "./DRAW.run" "$@"
LAUNCH
chmod +x "$APP/Contents/MacOS/DRAW"

# --- Payload (read-only; user data goes to ~/Library) ---
cp "$BIN" "$APP/Contents/Resources/DRAW.run"
cp -R "ASSETS" "$APP/Contents/Resources/ASSETS"
[ -f "DRAW.cfg.default" ] && cp "DRAW.cfg.default" "$APP/Contents/Resources/"
[ -f "DRAW.macOS.cfg" ]   && cp "DRAW.macOS.cfg"   "$APP/Contents/Resources/"
cp "$ICNS" "$APP/Contents/Resources/icon.icns"

# --- Info.plist (from the template, with the executable name + version fixed) ---
cp "$PLIST_SRC" "$APP/Contents/Info.plist"
PB=/usr/libexec/PlistBuddy
if [ -x "$PB" ]; then
    "$PB" -c "Set :CFBundleExecutable DRAW"            "$APP/Contents/Info.plist" 2>/dev/null || true
    "$PB" -c "Set :CFBundleIconFile icon"              "$APP/Contents/Info.plist" 2>/dev/null || true
    "$PB" -c "Set :CFBundleVersion $VER"               "$APP/Contents/Info.plist" 2>/dev/null || true
    "$PB" -c "Set :CFBundleShortVersionString $VER"    "$APP/Contents/Info.plist" 2>/dev/null || true
fi

# --- Nudge Finder/LaunchServices to pick up the new icon ---
touch "$APP"
/usr/bin/touch "$APP/Contents/Info.plist"
if command -v /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister >/dev/null 2>&1; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" 2>/dev/null || true
fi

echo "Done: $APP"
echo "  • Double-click it, or drag to /Applications."
echo "  • If the icon looks stale in Finder, it's a LaunchServices cache — re-login or run:"
echo "      killall Finder Dock"
