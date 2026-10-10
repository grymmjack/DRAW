#!/bin/bash
# =============================================================================
# dock-lock-layout.sh — QA test: View > Lock Layout (Ctrl+Shift+L,
# CFG.LAYOUT_LOCKED). For drawing with a shaky tablet pen: while locked, a
# panel's handle drag and a floating window's title drag change nothing; after
# unlocking the same drag moves the panel again.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: Lock Layout Test ==="
dk_begin
dk_check "start"
T0=$(dk_tree)

info "Lock the layout (Ctrl+Shift+L)"
key ctrl+shift+l; sleep 0.4

# a docked panel's handle drag: nothing moves
dk_grab_point drawer && dk_point edge-left && dk_drag "$GX" "$GY" "$TX" "$TY"
dk_park; dk_settle
if [[ "$(dk_tree)" == "$T0" ]]; then pass "locked: dragging the drawer's handle left the layout as it was"; else fail "locked, yet the layout changed: [$T0] -> [$(dk_tree)]"; fi

# the floating Preview's title drag: it stays put
read -r _ _ PX PY PW PH _ <<< "$(grep '^WIN preview ' "$DK_DUMP")"
if [[ -n "$PX" ]]; then
    dk_drag $(( PX + PW / 2 )) $(( PY + 6 )) $(( PX + PW / 2 - 120 )) $(( PY + 60 ))
    dk_park; dk_settle
    read -r _ _ QX QY _ <<< "$(grep '^WIN preview ' "$DK_DUMP")"
    if [[ "$QX,$QY" == "$PX,$PY" ]]; then pass "locked: the floating Preview stayed at $PX,$PY"; else fail "locked, yet the Preview moved $PX,$PY -> $QX,$QY"; fi
else
    skip "no floating Preview in the dump"
fi

info "Unlock (Ctrl+Shift+L again)"
key ctrl+shift+l; sleep 0.4
dk_move drawer edge-left
dk_expect_side drawer 1
dk_check "unlocked: the drawer moves again"
assert_no_crash
info "=== Dock: Lock Layout Test PASSED ==="
