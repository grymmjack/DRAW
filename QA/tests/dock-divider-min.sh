#!/bin/bash
# =============================================================================
# dock-divider-min.sh — QA test: a divider can't squeeze a panel below its own
# minimum. Rick (2026-10-09): with the Preview docked above the layers, the
# divider dragged the layers down to the generic 24px floor - shorter than
# their header + a row + the button bar - so the buttons and the layers' own
# divider went under the status bar. The divider now stops at the panel's
# declared minimum (DOCK_panel_box / DOCK_slot_min_h%), and dk_check fails any
# slot below its minimum (dump SMIN lines) after every move of every dock test.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer DOCK_LEFT_2=AUTO;advbar DOCK_RIGHT_1=AUTO;preview|layers DOCK_RIGHT_2=AUTO;editbar
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

info "=== Dock: a divider stops at the panel's minimum ==="
dk_begin
dk_check "start"
dk_expect_stacked preview layers
dk_divider_extremes preview layers "preview | layers"
dk_p layers; dk_slot "$P_SLOT"; LH=$S_H; LS=$P_SLOT
MIN=$(awk -v s="$LS" '$1=="SMIN" && $2==s {print $3}' "$DK_DUMP")
info "layers slot after the divider went to the bottom: ${LH}px (minimum ${MIN}px)"
if [[ -n "$MIN" ]] && (( MIN > 24 && LH >= MIN )); then pass "the layers keep their minimum (${LH} >= ${MIN}, above the old 24px floor)"; else fail "layers slot ${LH}px, minimum '${MIN}'"; fi
dk_scr
if (( S_Y + LH <= DOCK_BOT + 1 )); then pass "the layers' divider and buttons stay above the status bar"; else fail "the layers run past the dock bottom ($(( S_Y + LH )) > $(( DOCK_BOT + 1 )))"; fi
assert_no_crash
