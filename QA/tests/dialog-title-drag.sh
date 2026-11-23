#!/bin/bash
# =============================================================================
# dialog-title-drag.sh — QA test: a modal dialog moves only from its own title bar
# (GUI/DIALOG DIALOG_poll_mouse).
# Rick 2026-11-23: "canvas recording dialog hitbox is wrong. my pointer is here [left of the
# dialog, at its title bar's height] but it lets me move the canvas recording dialog as if
# it was over it". The title grab tested the pointer's y alone, so a press anywhere across
# the screen at title-bar height dragged every DIALOG_ dialog.
#   1. View: Canvas Recording opens the viewer (a DIALOG_ dialog)
#   2. a drag that starts LEFT of the dialog at its title bar's height: the dialog stays
#   3. ... and RIGHT of it: stays
#   4. a drag from its title bar moves it by the drag
# Dump: DOCK_DUMP + ".crecv" (CRECV x y scale bw b2w btnY btn2Y frame); x y = the dialog's
# top-left (dialog px = viewport px at the display scale).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE CANVAS_RECORDING=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Modal dialogs move only from their own title bar ==="

pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; }
cv() { hover 5 $(( VIEWPORT_H / 2 )); sleep 0.2; hover 7 $(( VIEWPORT_H / 2 )); wait_for 0.4 "render"; read -r _ D_X D_Y _ D_BW _ _ D_B2Y _ < "$DK_DUMP.crecv"; }

wait_for 1.0 "settle"
key Escape
key b; wait_for 0.3 "brush"
click "$CANVAS_CX" "$CANVAS_CY"; wait_for 0.6 "a dab (a frame to show)"

# --- 1. the viewer -------------------------------------------------------------------------------
rm -f "$DK_DUMP.crecv"
pcmd "View: Canvas Recording"; wait_for 0.8 "viewer"
if [[ ! -s "$DK_DUMP.crecv" ]]; then
    fail "the viewer wrote no geometry ($DK_DUMP.crecv)"
else
    cv; X0=$D_X; Y0=$D_Y
    # the dialog's width: 8 px margins round its five 1st-row buttons (bw + 4 apart)
    DW=$(( 8 + 5 * D_BW + 4 * 4 + 8 ))
    pass "the viewer is open at $X0,$Y0 (about ${DW} px wide)"
    TY=$(( Y0 + 6 )) # inside the title bar's height
    screenshot "dialog-title-drag-open"

    # --- 2. left of the dialog, title-bar height ------------------------------------------------------
    if (( X0 > 30 )); then
        drag $(( X0 / 2 )) "$TY" $(( X0 / 2 )) $(( TY + 80 )); wait_for 0.6 "drag left of it"
        cv
        [[ "$D_X,$D_Y" == "$X0,$Y0" ]] && pass "a drag left of the dialog at its title's height leaves it ($D_X,$D_Y)" || fail "the dialog moved from $X0,$Y0 to $D_X,$D_Y (dragged from x $(( X0 / 2 )), outside it)"
    else
        warn "the dialog sits at x $X0: no room left of it"
    fi

    # --- 3. right of it -------------------------------------------------------------------------------
    RX=$(( X0 + DW + (VIEWPORT_W - X0 - DW) / 2 ))
    if (( RX > X0 + DW + 10 && RX < VIEWPORT_W - 5 )); then
        drag "$RX" "$TY" "$RX" $(( TY + 80 )); wait_for 0.6 "drag right of it"
        cv
        [[ "$D_X,$D_Y" == "$X0,$Y0" ]] && pass "... and right of it ($D_X,$D_Y)" || fail "the dialog moved from $X0,$Y0 to $D_X,$D_Y (dragged from x $RX, outside it)"
    else
        warn "no room right of the dialog (x $RX)"
    fi

    # --- 4. its own title bar ----------------------------------------------------------------------------
    drag $(( X0 + DW / 2 )) "$TY" $(( X0 + DW / 2 - 40 )) $(( TY + 30 )); wait_for 0.6 "drag the title"
    cv
    (( D_X == X0 - 40 && D_Y == Y0 + 30 )) && pass "a drag from its title bar moves it (-40, +30: $D_X,$D_Y)" || fail "title drag: $X0,$Y0 -> $D_X,$D_Y (want $(( X0 - 40 )),$(( Y0 + 30 )))"
    screenshot "dialog-title-drag-moved"
    key Escape; wait_for 0.6 "closed"
fi
rm -f "$DK_DUMP.crecv"
dk_park
assert_no_crash
