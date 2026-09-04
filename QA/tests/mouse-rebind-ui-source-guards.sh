#!/bin/bash
# =============================================================================
# mouse-rebind-ui-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards 2B.2 Slice A2: mouse bindings are surfaced + rebindable in the Customize
# Controls dialog, and mouse overrides persist (device-discriminated) in
# DRAW.bindings.
#
# WHY source-level: the capture path needs real mouse-button presses (synthetic
# X11 buttons don't map to GLFW physical indices offscreen), and persistence round-
# trips a file; both are hard to drive in the offscreen harness. The row RENDER is
# screenshot-verified separately. This pins the implementation.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== Mouse rebind UI + persistence (2B.2 A2) source guards ==="

# Surfacing: mouse binds appear as rows (visibility helper + render).
assert_grep "SURFACE" "GUI/CONTROLS.BM" 'FUNCTION CTRL_bind_visible%'          "row-visibility helper"
assert_grep "SURFACE" "GUI/CONTROLS.BM" 'CTRL_bind_visible%\(i\)'             "rebuild_vis uses the helper"
assert_absent "SURFACE" "GUI/CONTROLS.BM" 'category = cat AND INPUT_BINDS(i).keycode <> 0' "old keyboard-only filter removed"
assert_grep "SURFACE" "GUI/CONTROLS.BM" 'FUNCTION CTRL_mouse_bind_str\$'       "mouse binding display string"
assert_grep "SURFACE" "GUI/CONTROLS.BM" 'device = DEVICE_MOUSE THEN'          "CTRL_current_key\$ branches on mouse"

# Capture: rebind modal has a mouse-button capture path.
assert_grep "CAPTURE" "GUI/CONTROLS.BM" 'isMouse%'                            "assign modal knows mouse binds"
assert_grep "CAPTURE" "GUI/CONTROLS.BM" 'BINDINGS_set_mouse_override actId%'  "OK applies a mouse override"
assert_grep "CAPTURE" "GUI/CONTROLS.BM" 'FOR rb% = 1 TO MOUSE_BTN_AVAIL%'     "button capture bounded (ERR-5 safe)"

# Persistence: device-discriminated overrides + button field.
assert_grep "PERSIST" "CFG/BINDINGS.BI" 'device      AS INTEGER'             "override carries a device"
assert_grep "PERSIST" "CFG/BINDINGS.BI" 'button      AS INTEGER'             "override carries a button"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'SUB BINDINGS_set_mouse_override'    "mouse override setter"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'device = DEVICE_MOUSE THEN'         "apply handles mouse overrides"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'device AS INTEGER, button AS INTEGER' "parse_row reads device+button"
assert_grep "PERSIST" "INPUT/INPUT.BI"  'defButton'                          "bind snapshots default button (for reset)"

guard_footer "a mouse-rebind-UI guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
