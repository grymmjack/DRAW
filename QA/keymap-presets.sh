#!/bin/bash
# =============================================================================
# keymap-presets.sh — standalone check of every shipped keymap preset
# (ASSETS/PRESETS/*.bindings). NOT a GUI-harness test: like cli-smoke.sh it runs
# DRAW's console operations and reads what they write.
#
# For each preset, on a private Xvfb with a private XDG_CONFIG_HOME (the user's
# config is never read or written):
#   DRAW --load-preset NAME           -> writes DRAW.bindings
#   DRAW --export-controls DIR        -> CONTROLS.md from the LIVE registry
# and checks:
#   - every row was saved and applied (one changed key per row)
#   - the keys the app is known for land on the right DRAW action
#   - keys the preset must leave alone keep their DRAW action
#
# (Rick, 2026-11-15: "make the other keyboard presets please" - they were empty
# or one row each, so loading Photoshop / GIMP / Aseprite / ... changed nothing.)
#
# Usage:  QA/keymap-presets.sh [BINARY]   (default ./DRAW-swm.run, else ./DRAW.run)
# Exit:   0 = all pass, 1 = a failure
# =============================================================================
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${1:-}"
[[ -z "$BIN" ]] && { [[ -x "$ROOT/DRAW-swm.run" ]] && BIN="$ROOT/DRAW-swm.run" || BIN="$ROOT/DRAW.run"; }
[[ -x "$BIN" ]] || { echo "no binary: $BIN"; exit 1; }
W=$(mktemp -d /tmp/draw-keymaps.XXXXXX)
DISP=:$(( 150 + RANDOM % 80 ))
Xvfb "$DISP" -screen 0 1920x1080x24 >/dev/null 2>&1 & XPID=$!
trap 'kill $XPID 2>/dev/null; rm -rf "$W"' EXIT
sleep 1.5
PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ✓ $*"; }
bad() { FAIL=$((FAIL + 1)); echo "  ✗ $*"; }

# load NAME: CONTROLS.md of DRAW with that preset -> $OUT
load() {
    rm -rf "$W/cfg" "$W/out"; mkdir -p "$W/cfg/DRAW" "$W/out"
    : > "$W/cfg/DRAW/MIGRATED_TO_NATIVE.txt"   # (no first-run "settings moved" dialog)
    ( cd "$ROOT" && DISPLAY=$DISP XDG_CONFIG_HOME="$W/cfg" timeout 60 "$BIN" --load-preset "$1" </dev/null >/dev/null 2>&1
      cd "$ROOT" && DISPLAY=$DISP XDG_CONFIG_HOME="$W/cfg" timeout 60 "$BIN" --export-controls "$W/out" </dev/null >/dev/null 2>&1 )
    OUT="$W/out/CONTROLS.md"
}
# key KEY "label part": the live table has KEY on an action whose label contains it
key() {
    if grep -F "| \`$1\`" "$OUT" | grep -qiF -- "$2"; then ok "$1 -> $2"
    else bad "$1 should be '$2', is: $(grep -F "| \`$1\`" "$OUT" | sed 's/ | central |//; s/^| //' | tr '\n' ';')"; fi
}

check() { # NAME then pairs KEY LABEL ...
    local p=$1; shift
    echo "== $p"
    load "$p"
    [[ -s "$OUT" ]] || { bad "$p: no CONTROLS.md (did DRAW start?)"; return; }
    local rows saved starred
    rows=$(grep -cvE '^\s*(#|$)' "$ROOT/ASSETS/PRESETS/$p.bindings")
    saved=$(grep -cvE '^\s*(#|$)' "$W/cfg/DRAW/DRAW.bindings" 2>/dev/null || echo 0)
    starred=$(( $(grep -c '★' "$OUT") - 1 ))   # (one is the legend line)
    (( saved == rows && starred == rows )) && ok "$rows rows saved and applied" || bad "rows $rows, saved $saved, applied $starred"
    while (( $# >= 2 )); do key "$1" "$2"; shift 2; done
}

check photoshop  G "Fill tool" L "Freehand Select" P "Bezier" U "Rectangle" C "Crop Canvas" D "Default Colors" \
                 Ctrl+J "Copy to New Layer" Ctrl+E "Merge layer down" Ctrl+T "Transform" Ctrl+K "Settings" \
                 Alt+Backspace "Fill with FG" Ctrl+Backspace "Fill with BG" F7 "Layer Panel" Tab "toggle all UI" \
                 "Ctrl+]" "Layer move up" "Ctrl+Shift+]" "Layer to top" B "Brush tool" Ctrl+Z "Undo"
check gimp       R "Marquee" E "Ellipse Select" F "Freehand Select" U "Magic wand" P "Brush tool" N "Brush tool" \
                 O "Picker" M "Move tool" Shift+B "Fill tool" Shift+E "Eraser" "Ctrl+," "Fill with FG" "Ctrl+." "Fill with BG" \
                 Ctrl+Shift+A "Deselect" Ctrl+I "Invert Selection" Ctrl+M "Merge all visible" 1 "Reset Zoom" Ctrl+B "toggle toolbar"
check krita      P "Picker" T "Move tool" Ctrl+T "Transform" C "Crop Canvas" Ctrl+R "Marquee" J "Ellipse Select" \
                 Shift+R "Rectangle tool" Shift+J "Ellipse tool" Insert "New Layer" Ctrl+J "Duplicate Layer" \
                 Ctrl+E "Merge layer down" Shift+Backspace "Fill with FG" Backspace "Fill with BG" Tab "toggle all UI" \
                 Ctrl+Shift+A "Deselect" F2 "Rename Layer" Shift+Delete "Delete Layer" B "Brush tool" F "Fill tool" \
                 "Ctrl+Shift+'" "grid visibility" "Ctrl+Shift+;" "snap-to-grid"
check aseprite   G "Fill tool" Shift+B "Spray" U "Rectangle" Shift+U "Ellipse" Q "Freehand Select" Shift+L "Bezier" \
                 Shift+H "Flip horizontal" Shift+V "Flip vertical" Alt+N "Duplicate Frame" Alt+C "Delete Frame" \
                 , "Previous frame" . "Next frame" Home "First frame" Tab "Animation Panel" F3 "Onion" "[" "Previous FG Color" \
                 "]" "Next FG Color" = "Brush size +" - "Brush size -" Ctrl+E "Sprite Sheet" B "Brush tool" Shift+N "New Layer" \
                 "Ctrl+'" "grid visibility" "Ctrl+Shift+'" "pixel grid"
check illustrator P "Bezier" '\' "Line tool" M "Rectangle tool" L "Ellipse tool" Shift+E "Eraser" R "Rotate" \
                 Y "Magic wand" Q "Freehand Select" Ctrl+Shift+A "Deselect" Ctrl+Shift+V "Paste in Place" \
                 "Ctrl+]" "Layer move up" "Ctrl+Shift+]" "Layer to top" "Ctrl+Shift+[" "Layer to bottom" "Ctrl+Shift+'" "snap-to-grid"
check mspaint    Ctrl+PgUp "Zoom In" Ctrl+PgDn "Zoom Out" Ctrl+G "pixel grid" Ctrl+W "Resize Image" \
                 Ctrl+Shift+X "Crop Canvas" F12 "Save As" "]" "Brush size +" "Ctrl+=" "Brush size +"
check promotion  D "Brush tool" S "Dot tool" V "Line tool" B "Brush Selector" , "Picker" F3 "Eraser" \
                 1 "Previous frame" 2 "Next frame" 4 "Play Looped" L "Lightbox" Ctrl+L "Open Project" \
                 Ctrl+Shift+L "Open Image" Insert "Duplicate Frame" . "One-Pixel Brush" Shift+A "Swap FG/BG"
check procreate  S "Marquee" L "Layer Panel" C "Color Mixer" "{" "Brush size -" "}" "Brush size +" \
                 Ctrl+J "Duplicate Layer" "Ctrl+Shift+]" "Layer to top" Ctrl+K "Command palette" B "Brush tool" E "Eraser"
check deluxepaint U "Undo" Shift+U "Redo" B "Brush Selector" , "Picker"

echo
echo "keymap presets: $PASS passed, $FAIL failed"
(( FAIL == 0 ))
