#!/bin/bash
# =============================================================================
# picker-loupe-alpha.sh — QA test: the picker loupe shows the pixel's opacity, and
# reads the picture you see on a layer a Move promoted (TOOLS/PICKER-LOUPE, TOOLS/PICKER).
# Rick 2026-11-23: "we need to add opacity to the picker up of colors - i need to see
# what opacity this is and what color from the image". The loupe showed a checkerboard
# (see-through) over solid pixels: PICKER_compose_region read each layer at raw canvas
# coordinates, but a promoted layer's buffer is bigger than the canvas - canvas (x, y)
# is (x + apronW, y + apronH) in it - so it read the apron's empty pixels.
#   1. an opaque stroke and a 50% stroke; Select All + Move promotes the layer (apron > 0)
#   2. the loupe over the opaque stroke: alpha 255 (the stroke's colour, not see-through)
#   3. over the 50% stroke: alpha about half, and the colour it was painted in (QB64's
#      _BLEND onto a see-through pixel darkened it: white read #3F3F3F)
#   4. over empty canvas: alpha 0
#   5. a click picks the opaque stroke's colour as the FG (the same merged read; STCHIP)
# Dump: LOUPE snapOk x1 y1 x2 y2 RRGGBB alpha; LOUPEAP apronW apronH (the current layer);
# STCHIP x y fgTransparent AARRGGBB (the FG).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

lp() { read -r _ _ _ _ _ _ L_C L_A <<< "$(grep -m1 '^LOUPE ' "$DK_DUMP")"; }
ap() { read -r _ A_W A_H <<< "$(grep -m1 '^LOUPEAP ' "$DK_DUMP")"; }
look() { hover "$1" "$2"; sleep 0.15; hover $(( $1 + 1 )) "$2"; sleep 0.15; hover "$1" "$2"; wait_for 0.5 "$3"; dk_settle; lp; }

info "=== Picker loupe: opacity, and the picture on a promoted layer ==="
wait_for 1.0 "settle"
key Escape
canvas_focus b
wait_for 0.3 "Brush"
key bracketright; key bracketright; key bracketright; key bracketright
wait_for 0.2 "Brush size"

# --- 1. an opaque and a 50% stroke, then promote the layer ---------------------------------
key 0; wait_for 0.2 "paint opacity 100%"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY - 20 ))
wait_for 0.3 "opaque stroke"
key 5; wait_for 0.2 "paint opacity 50%"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 ))
wait_for 0.3 "50% stroke"
key 0; wait_for 0.2 "paint opacity back to 100%"

key ctrl+a; wait_for 0.5 "Select all"
key v; wait_for 0.3 "Move"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.5 "moved 20 px right"
key b; wait_for 0.3 "Brush (commits the move)"
key ctrl+d; wait_for 0.2 "Deselect"
dk_settle; ap
(( ${A_W:-0} > 0 || ${A_H:-0} > 0 )) && pass "the Move promoted the layer (apron $A_W x $A_H)" || fail "no apron after the Move (LOUPEAP '$A_W' '$A_H')"

# --- 2-4. the loupe ------------------------------------------------------------------------------
key i; wait_for 0.4 "Picker"
look $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 20 )) "over the opaque stroke"
screenshot "picker-loupe-opaque"
OPAQUE=$L_C
[[ "$L_A" == 255 ]] && pass "over the opaque stroke: A 255 (#$L_C)" || fail "over the opaque stroke: #$L_C alpha '$L_A' (want 255 - read the apron?)"
look $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 )) "over the 50% stroke"
screenshot "picker-loupe-half"
(( ${L_A:-0} >= 100 && ${L_A:-0} <= 160 )) && pass "over the 50% stroke: A $L_A (#$L_C)" || fail "over the 50% stroke: #$L_C alpha '$L_A' (want about 128)"
near() { local a=$1 b=$2 i d; for i in 0 2 4; do d=$(( 16#${a:i:2} - 16#${b:i:2} )); (( d < 0 )) && d=$(( -d )); (( d <= 4 )) || return 1; done; } # RRGGBB within 4 levels
near "$L_C" "$OPAQUE" && pass "... the colour it was painted in (#$L_C vs #$OPAQUE: brush rounding), only see-through, not darkened" || fail "the 50% stroke reads #$L_C (painted #$OPAQUE: _BLEND onto a see-through pixel darkens it)"
look $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 60 )) "over empty canvas"
[[ "$L_A" == 0 ]] && pass "over empty canvas: A 0" || fail "over empty canvas: #$L_C alpha '$L_A' (want 0)"

# --- 5. a click picks the merged colour --------------------------------------------------------------
fg() { awk '$1 == "STCHIP" {print substr($5, length($5) - 5); exit}' "$DK_DUMP"; } # FG RRGGBB
key x; wait_for 0.3 "swap FG / BG (the FG is something else now)"; dk_settle
F0=$(fg)
look $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 20 )) "back over the opaque stroke"
click $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 20 ))
wait_for 0.4 "picked"; dk_park; dk_settle
F1=$(fg)
[[ "$F1" == "$OPAQUE" && "$F0" != "$OPAQUE" ]] && pass "a click picks the stroke: FG #$F0 -> #$F1" || fail "after the pick FG #$F1 (was #$F0, the stroke #$OPAQUE)"

dk_park
assert_no_crash
