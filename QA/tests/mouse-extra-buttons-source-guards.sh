#!/bin/bash
# =============================================================================
# mouse-extra-buttons-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards 2B.2 Slice A: extra mouse buttons (back/forward/etc.) sampled 1..N and
# routed through the central dispatcher so they can drive bound actions.
#
# WHY source-level: synthetic X11 button events (xdotool) do NOT map to GLFW's
# physical _MOUSEBUTTON indices under Xvfb, so extra buttons can't be driven in
# the offscreen harness — they're verified on real hardware (Rick's mouse). This
# test pins the implementation so a refactor can't silently break it, INCLUDING
# the ERR-5 safety bound (over-sampling _MOUSEBUTTON past the device button count
# faults every frame on a 3-button mouse) and the no-blocking-dialog rule.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== Extra mouse buttons (2B.2 Slice A) source guards ==="

# Data model: N-button constant + sampled state array + per-button arrays widened.
assert_grep "MODEL" "INPUT/INPUT.BI" 'CONST MOUSE_MAX_BTN'                 "MOUSE_MAX_BTN button-count constant"
assert_grep "MODEL" "INPUT/INPUT.BI" 'MOUSE_BTN\(1 TO MOUSE_MAX_BTN\)'     "per-frame MOUSE_BTN() state array"
assert_grep "MODEL" "INPUT/INPUT.BI" 'MOUSE_BTN_DOWN_LAST\(1 TO MOUSE_MAX_BTN\)' "edge array widened to N buttons"
assert_absent "MODEL" "INPUT/INPUT.BI" 'MOUSE_BTN_DOWN_LAST\(1 TO 3\)'     "no leftover (1 TO 3) edge array"

# Sampling: bounded by MOUSE_BTN_AVAIL (the ERR-5 safety fix), NOT MOUSE_MAX_BTN.
assert_grep  "SAMPLE" "INPUT/MOUSE.BM" 'FOR extraBtn% = 4 TO MOUSE_BTN_AVAIL%' "extra-button sampling bounded by detected count"
assert_absent "SAMPLE" "INPUT/MOUSE.BM" 'FOR extraBtn% = 4 TO MOUSE_MAX_BTN'   "NOT sampling past device count (ERR 5 trap)"
assert_grep  "SAMPLE" "INPUT/MOUSE.BM" '_LASTBUTTON\(mdv%\)'                    "_LASTBUTTON called WITH device number (bare form = ERR 5)"

# Dispatcher: loops all buttons + reads the sampled array.
assert_grep "DISPATCH" "INPUT/INPUT.BM" 'FOR btn = 1 TO MOUSE_MAX_BTN'      "dispatcher loops all buttons"
assert_grep "DISPATCH" "INPUT/INPUT.BM" 'bDown% = MOUSE_BTN\(btn\)'         "dispatcher reads sampled MOUSE_BTN()"

# Default binds: back (btn 4) -> Undo (301), forward (btn 5) -> Redo (302), dispatched.
assert_grep "BINDS" "INPUT/INPUT.BM" 'REGION_GLOBAL, 4, 0, 0, 0, CTX_TEXT_ACTIVE, 301, TRUE' "mouse button 4 (back) -> Undo, dispatched"
assert_grep "BINDS" "INPUT/INPUT.BM" 'REGION_GLOBAL, 5, 0, 0, 0, CTX_TEXT_ACTIVE, 302, TRUE' "mouse button 5 (forward) -> Redo, dispatched"

guard_footer "an extra-mouse-button guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
