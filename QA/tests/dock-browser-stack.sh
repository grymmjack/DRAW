#!/bin/bash
# =============================================================================
# dock-browser-stack.sh — QA test: the Browser docked in a side column puts its
# preview UNDER the folder list (Rick 2026-11-16: "the preview when in this
# configuration should land under the folders on the bottom left"):
#   - in a left column: the preview as wide as the places, under them; the
#     file list takes the whole width right of them, full height
#   - the bar between the places and the preview drags the preview taller
#   - the preview toggled off: the places take the whole height; on again:
#     back under them
#   - in a top row: the preview beside the list again, on the right
# Dump (FD px): BROWSERL placesW listX listW prevX prevW prevOn dialogW
# placesMin prevMin toggleX toggleY navTiny; BROWSERV stack placesH previewY
# previewH contentY contentH; WIN browser x y w h.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: the Browser's preview under its folders in a side column ==="
dk_begin

bs_read() {
    read -r _ _ WX WY WW WH _ <<< "$(grep '^WIN browser ' "$DK_DUMP")"
    read -r _ NAVW LX LW PX PW PON DW _ _ BTNX BTNY _ <<< "$(grep '^BROWSERL' "$DK_DUMP")"
    read -r _ V_ST V_PLH V_PY V_PH V_CY V_CH <<< "$(grep '^BROWSERV' "$DK_DUMP")"
}
fx() { echo $(( WX + $1 * WW / DW )); }
fy() { echo $(( WY + $1 * WW / DW )); }

dk_move browser edge-left
dk_p browser; dk_slot "$P_SLOT"; dk_col "$S_COL"
(( C_SIDE == 1 )) && pass "the Browser in a left column (${C_W}px)" || fail "the Browser is not in a left column [$(dk_tree)]"
dk_park; dk_settle; bs_read
if [[ -z "$V_ST" || -z "$DW" ]]; then fail "no BROWSERV / BROWSERL line"; assert_no_crash; exit 0; fi
info "places ${NAVW} x $V_PLH; preview $PX,$V_PY ${PW}x$V_PH on=$PON; list $LX+$LW; content y $V_CY h $V_CH; dialog $DW"
[[ "$V_ST" == 1 ]] && pass "stacked in a side column" || fail "not stacked (BROWSERV $V_ST)"
if [[ "$PON" != 0 ]]; then
    (( PX == 0 && PW == NAVW )) && pass "the preview as wide as the places, at the left (x $PX w $PW)" || fail "preview x $PX w $PW, the places $NAVW wide"
    (( V_PY > V_CY + V_PLH && V_PY + V_PH <= V_CY + V_CH + 1 )) && pass "the preview under the places (y $V_PY, the places end $(( V_CY + V_PLH )))" || fail "preview y $V_PY h $V_PH, places to $(( V_CY + V_PLH )), content to $(( V_CY + V_CH ))"
    (( LX > NAVW && LX + LW >= DW - 1 )) && pass "the list takes the width right of the places ($LX+$LW of $DW)" || fail "list $LX+$LW in a $DW dialog (places $NAVW)"
else
    fail "the preview is off at start (BROWSERL prevOn $PON)"
fi
screenshot "browser-stack-left"

# --- the bar between the places and the preview drags --------------------------
H0=$V_PH
BY=$(( V_PY - 2 )); BX=$(( NAVW / 2 ))
dk_drag "$(fx "$BX")" "$(fy "$BY")" "$(fx "$BX")" "$(fy $(( BY - 40 )))" 6; dk_park; dk_settle; bs_read
(( V_PH >= H0 + 25 )) && pass "the bar drags the preview taller ($H0 -> $V_PH FD px)" || fail "the preview stayed $H0 -> $V_PH after dragging the bar up"
(( V_PLH + V_PH < V_CH )) && pass "the places shrink to make room ($V_PLH)" || fail "places $V_PLH + preview $V_PH > content $V_CH"
screenshot "browser-stack-dragged"

# --- preview off / on ---------------------------------------------------------
click "$(fx "$BTNX")" "$(fy "$BTNY")"; wait_for 0.5 "preview off"; dk_park; dk_settle; bs_read
(( PON == 0 && V_PLH == V_CH )) && pass "preview off: the places take the whole height ($V_PLH)" || fail "preview off: on=$PON places $V_PLH of $V_CH"
click "$(fx "$BTNX")" "$(fy "$BTNY")"; wait_for 0.5 "preview on"; dk_park; dk_settle; bs_read
(( PON != 0 && PX == 0 && V_PY > V_CY + V_PLH )) && pass "preview on: under the places again" || fail "preview on: on=$PON x $PX y $V_PY (places to $(( V_CY + V_PLH )))"
dk_check "the Browser stacked in a column"

# --- in a top row: beside the list again ----------------------------------------
dk_move browser band-top
dk_park; dk_settle; bs_read
info "row: places $NAVW; preview $PX ${PW}; list $LX+$LW; stack $V_ST"
[[ "$V_ST" == 0 ]] && pass "in a row: not stacked" || fail "still stacked in a row ($V_ST)"
(( PON == 0 || PX >= LX + LW )) && pass "in a row: the preview beside the list, on the right (x $PX)" || fail "in a row: preview x $PX, the list ends $(( LX + LW ))"
screenshot "browser-stack-row"
dk_check "the Browser in a row"
assert_window_exists
info "=== Dock: Browser stacked preview done ==="
