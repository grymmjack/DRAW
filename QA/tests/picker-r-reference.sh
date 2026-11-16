#!/bin/bash
# =============================================================================
# picker-r-reference.sh — QA test: R with the Picker in hand (BUGS.md 2026-11-15:
# "HOLD R selects the rectangle tool, it doesn't select from reference at all").
#
# R is the Picker's "sample the reference" hold: tapping or holding it keeps the
# Picker (the Rectangle key is blocked by CTX_PICKER_ACTIVE). With another tool
# R still selects the Rectangle tool.
# Dump: TBED <edit> <tab> <sel> <n> <avN> <CURRENT_TOOL> <ws> (Picker 11, Rect 7).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Picker: R samples the reference ==="
dk_begin
tool() { awk '$1=="TBED" {print $7; exit}' "$DK_DUMP"; }

canvas_focus b; wait_for 0.3 "brush"
key i; wait_for 0.4 "picker"; dk_settle
[[ "$(tool)" == 11 ]] && pass "I selects the Picker" || fail "tool $(tool) after I"
key r; wait_for 0.4 "tap R"; dk_settle
[[ "$(tool)" == 11 ]] && pass "tapping R keeps the Picker" || fail "tapping R with the Picker: tool $(tool)"
driver_input_key_hold down r; sleep 0.8; dk_settle; T_HELD=$(tool); driver_input_key_hold up r; sleep 0.4; dk_settle
[[ "$T_HELD" == 11 && "$(tool)" == 11 ]] && pass "holding R keeps the Picker" || fail "holding R: tool $T_HELD, after $(tool)"
key b; wait_for 0.3 "brush"; key r; wait_for 0.4 "R with the brush"; dk_settle
[[ "$(tool)" == 7 ]] && pass "R still selects the Rectangle tool from another tool" || fail "R from the brush: tool $(tool)"
key b
assert_no_crash
