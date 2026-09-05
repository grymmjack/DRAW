#!/bin/bash
# =============================================================================
# mouse-wheel-tilt-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards the horizontal wheel-TILT feature (2B.2 C-tilt): the mouse's left/right
# tilt is sampled via _WHEEL(MOUSE_TILT_WHEEL), emitted as a dispatched wheel
# event (wheelDir ±2), fires brush-size by default, is rebindable + persisted in
# Customize Controls, and is configurable per-mouse. Tilt can't be driven
# offscreen (synthetic wheel events don't reach the GLFW device API under Xvfb),
# so these pin the wiring; controls-tilt-row.sh covers the visible rows.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== Wheel-tilt source guards ==="

# Shared state + direction encoding.
assert_grep "STATE" "INPUT/INPUT.BI" 'CONST WHEEL_TILT_RIGHT'                 "tilt-right direction constant (+2)"
assert_grep "STATE" "INPUT/INPUT.BI" 'CONST WHEEL_TILT_LEFT'                  "tilt-left direction constant (-2)"
assert_grep "STATE" "INPUT/INPUT.BI" 'DIM SHARED MOUSE_TILT '                 "per-frame tilt state"
assert_grep "STATE" "INPUT/INPUT.BI" 'DIM SHARED MOUSE_DEV '                  "[MOUSE] device number cache"
assert_grep "STATE" "INPUT/INPUT.BI" 'DIM SHARED MOUSE_TILT_WHEEL '          "tilt wheel index"

# Sampling: device pump + tilt read, bounded by _LASTWHEEL, CFG override honored.
assert_grep "SAMPLE" "INPUT/MOUSE.BM" '_DEVICEINPUT\(MOUSE_DEV%\)'             "device queue pumped for _WHEEL"
assert_grep "SAMPLE" "INPUT/MOUSE.BM" 'SGN\(_WHEEL\(MOUSE_TILT_WHEEL%\)\)'       "tilt sampled via _WHEEL (plain-trigger SGN)"
assert_grep "SAMPLE" "INPUT/MOUSE.BM" '_LASTWHEEL\(mdv%\)'                      "tilt index bounded by _LASTWHEEL (no ERR 5)"
assert_grep "SAMPLE" "INPUT/MOUSE.BM" 'CFG.MOUSE_TILT_WHEEL%'                 "CFG override applied to tilt index"

# Dispatch: tilt emitted as wheel event, default binds dispatched, def snapshot.
assert_grep "DISPATCH" "INPUT/INPUT.BM" 'MOUSE_TILT% \* 2'                    "tilt encoded as wheelDir +/-2 in the event"
assert_grep "DISPATCH" "INPUT/INPUT.BM" 'WHEEL_TILT_RIGHT, 0, MOD_CTRL OR MOD_SHIFT OR MOD_ALT, 0, CTX_TEXT_ACTIVE, 602, TRUE' "tilt-right default = brush+ (dispatched)"
assert_grep "DISPATCH" "INPUT/INPUT.BM" 'WHEEL_TILT_LEFT,  0, MOD_CTRL OR MOD_SHIFT OR MOD_ALT, 0, CTX_TEXT_ACTIVE, 601, TRUE' "tilt-left default = brush- (dispatched)"
assert_grep "DISPATCH" "INPUT/INPUT.BM" 'defWheelDir    = wheelDir%'         "wheelDir default snapshot for reset"

# Persistence: wheel override set/apply/save/parse/restore.
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'SUB BINDINGS_set_wheel_override'    "wheel override setter"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'INPUT_BINDS\(i%\).wheelDir.*= BINDING_OVERRIDES\(o%\).wheelDir' "apply re-points wheel bind"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'BINDING_OVERRIDES\(o%\).wheelDir'     "wheelDir written to DRAW.bindings"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'wheelDir AS INTEGER, eventType AS INTEGER' "parse_row reads wheelDir+eventType (8-field)"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'INPUT_BINDS\(i%\).wheelDir.*= INPUT_BINDS\(i%\).defWheelDir' "RESET restores default wheelDir"

# Rebind UI: capture a tilt in the modal, persist, label it.
assert_grep "UI" "GUI/CONTROLS.BM" 'isWheel% = \(INPUT_BINDS\(bindIdx%\).eventType = EVT_MOUSE_WHEEL\)' "modal detects a wheel row"
assert_grep "UI" "GUI/CONTROLS.BM" 'SGN\(_WHEEL\(MOUSE_TILT_WHEEL%\)\)'          "modal captures a live tilt gesture"
assert_grep "UI" "GUI/CONTROLS.BM" 'BINDINGS_set_wheel_override actId%, capWheel%, mods%' "OK persists the wheel override"
assert_grep "UI" "GUI/CONTROLS.BM" 'CTRL_wheel_dir_name\$'                   "wheel direction name helper"
assert_grep "UI" "GUI/CONTROLS.BM" 'eventType = EVT_MOUSE_WHEEL _ANDALSO INPUT_BINDS\(i%\).dispatched' "dispatched wheel rows are visible"

# Config: per-mouse tilt index key exists + documented.
assert_grep "CONFIG" "CFG/CONFIG.BI"  'MOUSE_TILT_WHEEL'                      "CFG TYPE field"
assert_grep "CONFIG" "DRAW.cfg.default" 'MOUSE_TILT_WHEEL=4'                  "default cfg entry (drives --options-list)"

guard_footer "a wheel-tilt guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
