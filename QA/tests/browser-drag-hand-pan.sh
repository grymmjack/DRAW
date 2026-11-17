#!/bin/bash
# =============================================================================
# browser-drag-hand-pan.sh — QA test: with the Hand tool, a file dragged out of
# the Browser across the canvas to the layer panel does not pan the canvas
# (Rick 2026-11-16: "it moves the canvas. this should not happen. the drag
# originated in the browser"). A left-button pan (Hand / Space+LMB) now starts
# only from a press that began on the canvas (MOUSE_note_b1_origin).
#   - Hand tool; press on a Browser thumbnail, drag it left over the canvas
#     (held): the view's offset is unchanged
#   - on to the layer panel and let go: still unchanged
#   - control: a Hand drag that starts on the canvas does pan
# Dump: VIEW zoom offsetX offsetY tool | BROWSERS ... drag | P layers | WIN browser
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BROWSER_VISIBLE=1 BROWSER_POS_X=440 BROWSER_POS_Y=60 BROWSER_WIDTH=260 BROWSER_HEIGHT=200 BROWSER_DEFAULT_FOLDER=ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX BROWSER_DEFAULT_PREVIEW_OPEN=0 BROWSER_DEFAULT_VIEW_MODE=2
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Hand tool: a file dragged from the Browser does not pan ==="
dk_begin

view() { read -r _ V_ZOOM V_OX V_OY V_TOOL _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; }
bs()   { read -r _ _ _ _ BS_ROWH BS_TOP BS_SCROLL BS_N _ _ _ BS_DRAG _ <<< "$(grep -m1 '^BROWSERS ' "$DK_DUMP")"; }
bwin() { read -r _ _ WX WY WW WH _ <<< "$(grep -m1 '^WIN browser ' "$DK_DUMP")"; read -r _ _ LX _ _ _ _ DW _ <<< "$(grep -m1 '^BROWSERL' "$DK_DUMP")"; }

read -r _ _ _ _ _ _ HBX HBY HBW HBH <<< "$(grep -m1 -E '^BTN toolbox [0-9]+ 1 [0-9]+ hand ' "$DK_DUMP")"
[[ -n "$HBH" ]] && click $(( HBX + HBW / 2 )) $(( HBY + HBH / 2 ))
wait_for 0.5 "Hand tool"; dk_park; dk_settle; view
(( V_TOOL == 13 )) && pass "Hand tool selected" || fail "tool $V_TOOL after the toolbox Hand button at $HBX,$HBY (want 13, TOOL_PAN)"
bwin; bs; dk_p layers
[[ -n "$WW" && -n "$P_W" ]] || { fail "no Browser window / layer panel [$(dk_tree)]"; assert_no_crash; exit 0; }
OX0=$V_OX; OY0=$V_OY
TX=$(( WX + (LX + 30) * WW / DW )); TY=$(( WY + (BS_TOP - BS_SCROLL + 30) * WW / DW ))
CX=$(( (P_X + P_W + WX) / 2 )); CY=$(( WY + WH / 2 )) # (the layer panel left, the Browser right)
LPX=$(( P_X + P_W / 2 )); LPY=$(( P_Y + P_H / 2 ))
info "browser $WX,$WY ${WW}x$WH, thumbnail at $TX,$TY; canvas point $CX,$CY; layer panel $LPX,$LPY; view offset $OX0,$OY0"

mouse_down "$TX" "$TY"; sleep 0.25
for (( x = TX - 20; x > CX; x -= 40 )); do hover "$x" $(( TY + (CY - TY) * (TX - x) / (TX - CX) )); sleep 0.06; done
hover "$CX" "$CY"; wait_for 0.5 "over the canvas, held"; dk_settle; view; bs
info "held over the canvas: offset $V_OX,$V_OY, file drag $BS_DRAG"
(( V_OX == OX0 && V_OY == OY0 )) && pass "dragging the file over the canvas: no pan" || fail "the canvas panned under the file drag ($OX0,$OY0 -> $V_OX,$V_OY)"
for (( x = CX - 40; x > LPX; x -= 40 )); do hover "$x" $(( CY + (LPY - CY) * (CX - x) / (CX - LPX) )); sleep 0.06; done
hover "$LPX" "$LPY"; wait_for 0.3 "over the layer panel"
mouse_up; wait_for 1.0 "the drop"; dk_park; dk_settle; view
(( V_OX == OX0 && V_OY == OY0 )) && pass "dropped on the layer panel: the canvas never moved" || fail "after the drop the view moved ($OX0,$OY0 -> $V_OX,$V_OY)"

# control: the Hand tool still pans from a press on the canvas
OX1=$V_OX; OY1=$V_OY
drag "$CX" "$CY" $(( CX + 60 )) $(( CY + 40 )); wait_for 0.5 "a Hand drag on the canvas"; dk_settle; view
(( V_OX != OX1 || V_OY != OY1 )) && pass "a Hand drag on the canvas pans ($OX1,$OY1 -> $V_OX,$V_OY)" || fail "a Hand drag on the canvas did not pan"
screenshot "browser-drag-hand-pan"
assert_no_crash
info "=== Hand tool + Browser file drag done ==="
