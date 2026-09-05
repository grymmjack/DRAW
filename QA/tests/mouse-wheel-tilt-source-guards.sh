#!/bin/bash
# =============================================================================
# mouse-wheel-tilt-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards the horizontal wheel-TILT feature (2B.2 C-tilt): the mouse's left/right
# tilt is sampled via _MOUSEWHEEL(MOUSE_TILT_AXIS) in the normal _MOUSEINPUT drain,
# then dispatched through the SAME intent-query as the vertical wheel
# (WHEEL_action_for% + WHEEL_dispatch_canvas in MOUSE_handle_wheel) — NOT the central
# event dispatcher. That unification is what lets a rebound tilt (e.g. tilt -> Pan)
# win over the compiled tilt->brush default with override-with-fallback semantics.
# Fires brush-size by default, is rebindable + persisted in Customize Controls, and is
# configurable per-mouse. Tilt can't be driven offscreen (synthetic wheel events don't
# reach the GLFW device API under Xvfb), so these pin the wiring; controls-tilt-row.sh
# covers the visible rows.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== Wheel-tilt source guards ==="

# Shared state + direction encoding.
assert_grep "STATE" "INPUT/INPUT.BI" 'CONST WHEEL_TILT_RIGHT'                 "tilt-right direction constant (+2)"
assert_grep "STATE" "INPUT/INPUT.BI" 'CONST WHEEL_TILT_LEFT'                  "tilt-left direction constant (-2)"
assert_grep "STATE" "INPUT/INPUT.BI" 'DIM SHARED MOUSE_TILT '                 "per-frame tilt state"
assert_grep "STATE" "INPUT/INPUT.BI" 'DIM SHARED MOUSE_TILT_AXIS '            "tilt axis index"

# Sampling: read _MOUSEWHEEL(axis) inside the normal _MOUSEINPUT drain (no device API).
assert_grep "SAMPLE" "INPUT/MOUSE.BM" '_MOUSEWHEEL\(MOUSE_TILT_AXIS%\)'        "tilt sampled via _MOUSEWHEEL(axis)"
assert_grep "SAMPLE" "INPUT/MOUSE.BM" 'MOUSE_TILT% = SGN\(tilt_accum%\)'       "plain -1/0/+1 trigger (accumulated over the drain)"
assert_absent "SAMPLE" "INPUT/MOUSE.BM" '_DEVICEINPUT\('                       "no _DEVICEINPUT device-API call (obsolete path removed)"
assert_grep "SAMPLE" "INPUT/MOUSE.BM" 'CFG.MOUSE_TILT_AXIS%'                   "CFG override applied to tilt axis"

# Dispatch: tilt is NOT a central event — it resolves through the intent-query in
# MOUSE_handle_wheel, region-scoped to the canvas + suppressed while editing text, so a
# rebound tilt (Pan) beats the compiled brush default. Default binds are metadata-only
# (dispatched=FALSE), exactly like the vertical wheel binds.
assert_grep  "DISPATCH" "INPUT/MOUSE.BM" 'WHEEL_dispatch_canvas WHEEL_action_for%\(MOUSE_TILT% \* 2' "tilt dispatched via intent-query (override-with-fallback)"
assert_grep  "DISPATCH" "INPUT/MOUSE.BM" 'REGION_hit_test%\(rawX%, rawY%\) = REGION_CANVAS' "tilt region-scoped to the canvas floor"
assert_grep  "DISPATCH" "INPUT/MOUSE.BM" 'NOT TEXT.ACTIVE AND'               "tilt suppressed while editing text"
assert_grep  "DISPATCH" "INPUT/INPUT.BM" 'WHEEL_TILT_RIGHT, 0, MOD_CTRL OR MOD_SHIFT OR MOD_ALT, 0, CTX_TEXT_ACTIVE, 602, FALSE' "tilt-right default = brush+ (metadata; rebindable)"
assert_grep  "DISPATCH" "INPUT/INPUT.BM" 'WHEEL_TILT_LEFT,  0, MOD_CTRL OR MOD_SHIFT OR MOD_ALT, 0, CTX_TEXT_ACTIVE, 601, FALSE' "tilt-left default = brush- (metadata; rebindable)"
assert_absent "DISPATCH" "INPUT/INPUT.BM" 'INPUT_enqueue_event EVT_MOUSE_WHEEL, region%, 0, 0, MOUSE_TILT%' "no central tilt event emission (unified into intent-query)"
assert_grep  "DISPATCH" "INPUT/INPUT.BM" 'defWheelDir    = wheelDir%'         "wheelDir default snapshot for reset"

# Persistence: wheel override set/apply/save/parse/restore.
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'SUB BINDINGS_set_wheel_override'    "wheel override setter"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'INPUT_BINDS\(i%\).wheelDir.*= BINDING_OVERRIDES\(o%\).wheelDir' "apply re-points wheel bind"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'BINDING_OVERRIDES\(o%\).wheelDir'     "wheelDir written to DRAW.bindings"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'wheelDir AS INTEGER, eventType AS INTEGER' "parse_row reads wheelDir+eventType (8-field)"
assert_grep "PERSIST" "CFG/BINDINGS.BM" 'INPUT_BINDS\(i%\).wheelDir.*= INPUT_BINDS\(i%\).defWheelDir' "RESET restores default wheelDir"

# Rebind UI: capture a tilt in the modal, persist, label it.
assert_grep "UI" "GUI/CONTROLS.BM" 'isWheel% = \(INPUT_BINDS\(bindIdx%\).eventType = EVT_MOUSE_WHEEL\)' "modal detects a wheel row"
# The modal reads the tilt/wheel that DIALOG_poll_mouse already drained into aCtx
# (a second _MOUSEINPUT drain in the modal would find the queue empty — the old bug).
assert_grep  "UI" "GUI/DIALOG.BI"   'mtilt        AS INTEGER'                   "DIALOG_CTX carries a tilt accumulator"
assert_grep  "UI" "GUI/DIALOG.BM"   'ctx.mtilt = ctx.mtilt \+ _MOUSEWHEEL\(MOUSE_TILT_AXIS%\)' "poll drain captures the tilt axis"
assert_grep  "UI" "GUI/CONTROLS.BM" 'aCtx.mtilt <> 0'                           "modal reads the captured tilt gesture"
assert_absent "UI" "GUI/CONTROLS.BM" '_MOUSEWHEEL\('                            "modal no longer double-drains _MOUSEINPUT for the wheel"
assert_grep "UI" "GUI/CONTROLS.BM" 'BINDINGS_set_wheel_override actId%, capWheel%, mods%' "OK persists the wheel override"
assert_grep "UI" "GUI/CONTROLS.BM" 'CTRL_wheel_dir_name\$'                   "wheel direction name helper"
assert_grep "UI" "GUI/CONTROLS.BM" 'actionId <> 0 _ANDALSO INPUT_BINDS\(i%\).eventType = EVT_MOUSE_WHEEL THEN' "wheel rows (tilt + vertical) are visible/rebindable"

# Config: tilt-axis key exists + documented.
assert_grep "CONFIG" "CFG/CONFIG.BI"  'MOUSE_TILT_AXIS'                       "CFG TYPE field"
assert_grep "CONFIG" "DRAW.cfg.default" 'MOUSE_TILT_AXIS=1'                   "default cfg entry (drives --options-list)"

guard_footer "a wheel-tilt guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
