#!/bin/bash
# =============================================================================
# mouse-pan-behavior-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards 2B.2 Slice B2 (pan): the canvas pan-drag button is rebindable (MB_PAN,
# default middle=3). The whole pan lifecycle keys off allowB3Pan%, so wiring the
# single initiation site to the query makes a rebound pan button work start-to-end.
#
# WHY source-level: pan is a drag on real hardware (offscreen can't). Pins the wire.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== Pan rebindable behavior (2B.2 B2-pan) source guards ==="

assert_grep  "MODEL" "INPUT/INPUT.BI" 'CONST MB_PAN'                             "MB_PAN behavior id"
assert_grep  "MODEL" "INPUT/INPUT.BM" 'MB_PAN, FALSE, "Pan the canvas'          "pan behavior bind (button 3, not dispatched)"
assert_grep  "WIRE"  "INPUT/MOUSE.BM" 'allowB3Pan% = MOUSE_button_down%'         "pan initiation uses the rebindable button query"
assert_grep  "WIRE"  "INPUT/MOUSE.BM" 'MOUSE_intent_button%\(MB_PAN, 3\)'         "pan queries MB_PAN (default 3)"
assert_absent "WIRE" "INPUT/MOUSE.BM" 'allowB3Pan% = MOUSE.B3%'                  "old hardcoded MMB pan check removed"

guard_footer "a pan-behavior guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
