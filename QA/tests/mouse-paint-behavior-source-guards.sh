#!/bin/bash
# =============================================================================
# mouse-paint-behavior-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards 2B.2 Slice B: Paint FG/BG is a REBINDABLE mouse behavior. The metadata
# behavior binds (MB_PAINT_FG/BG) carry which button paints each colour, and
# MOUSE_update_draw_color queries them — so swapping the buttons in Customize
# Controls really flips which button paints FG vs BG (the stroke-start gates fire
# on either button, so only the colour choice needs the query).
#
# WHY source-level: verifying a paint STROKE's colour needs a real drag on real
# hardware (offscreen can't). This pins the wiring so it can't silently revert to
# the hardcoded B2-is-BG check.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== Paint FG/BG rebindable behavior (2B.2 B) source guards ==="

# Behavior ids + metadata binds.
assert_grep "MODEL" "INPUT/INPUT.BI" 'CONST MB_PAINT_FG'                       "MB_PAINT_FG behavior id"
assert_grep "MODEL" "INPUT/INPUT.BI" 'CONST MB_PAINT_BG'                       "MB_PAINT_BG behavior id"
assert_grep "MODEL" "INPUT/INPUT.BM" 'MB_PAINT_FG, FALSE, "Paint with foreground color"' "FG paint behavior bind (button 1, not dispatched)"
assert_grep "MODEL" "INPUT/INPUT.BM" 'MB_PAINT_BG, FALSE, "Paint with background color"' "BG paint behavior bind (button 2, not dispatched)"

# Query API + the single central wiring site.
assert_grep "QUERY" "INPUT/MOUSE.BM" 'FUNCTION MOUSE_intent_button%'           "button-intent query"
assert_grep "QUERY" "INPUT/MOUSE.BM" 'FUNCTION MOUSE_button_down%'             "button-down helper (1-N)"
assert_grep "WIRE"  "INPUT/MOUSE.BM" 'MOUSE_intent_button%\(MB_PAINT_BG, 2\)'  "draw-colour uses the BG-paint button"
assert_absent "WIRE" "INPUT/MOUSE.BM" 'IF MOUSE.B2% OR MOUSE.OLD_B2% THEN'     "old hardcoded B2-is-BG check removed"

# Surfacing: non-dispatched behavior binds appear (eventType gate, not dispatched).
assert_grep "SURFACE" "GUI/CONTROLS.BM" 'eventType = EVT_MOUSE_DOWN'           "visibility gates on button-DOWN (shows behaviors)"
# SET... is enabled + clickable for non-dispatched mouse behaviors (else fake rows).
assert_grep "SURFACE" "GUI/CONTROLS.BM" 'FUNCTION CTRL_bind_rebindable%'       "rebindable helper (mouse behaviors count)"
assert_grep "SURFACE" "GUI/CONTROLS.BM" '"SET...", CTRL_bind_rebindable%'      "SET button enabled via rebindable helper"
# Persistence applies to non-dispatched behavior binds too.
assert_absent "PERSIST" "CFG/BINDINGS.BM" 'device = DEVICE_MOUSE _\n.*AND INPUT_BINDS(i%).dispatched' "mouse override apply not gated on dispatched"

guard_footer "a paint-behavior guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
