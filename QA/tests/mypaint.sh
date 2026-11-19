#!/bin/bash
# =============================================================================
# mypaint.sh — QA test: MyPaint brushes (PLANS/MYPAINT.md; Rick 2026-11-17: "add
# my paint brush engine and brush load/save etc. with a palette to choose those
# brushes" / "for now i don't have a toolbox tool so just add to tools menu").
#   - the palette (View > MyPaint Brushes, a dock panel: GUI/MYPAINT-PANEL) shows
#     the order.conf groups + MY BRUSHES, thumbnails in a grid inside it
#   - > / < change the group, so does the dropdown on its name; a click on a brush loads it and picks the tool
#   - a drag on the canvas paints through libmypaint; one Ctrl+Z takes it away
#   - picking a brush sets the brush size to the brush's own (its file's diameter, the
#     nearest size; Rick 2026-11-18 "the palette brush size should change to whatever
#     those use too, when they are selected")
#   - ] makes the brush bigger, the stroke wider: by default the MyPaint brush is DRAW's
#     brush size (MYPAINT_SIZE_FROM_BRUSH; Rick 2026-11-18 "the brush size should set the
#     mypaint brush size too"); the command turns that off and ] steps MYPAINT_SIZE instead
#   - inside a selection only the selected part changes
#   - View > MyPaint Brushes (command palette) hides the palette
# Dump: MYPP vis x y w h group nGroups n cell cols rowsFit rowsAll scroll gridX
# gridY hover cur groupName; MYPPB id x y w; MYP tool active ready strokes steps
# x1 y1 x2 y2 size name|set|path; MYPZ fromBrush brushPx radius*100 fileSizeIndex pressure*1000 penActive pdSource
# (units = viewport px at Auto).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE MYPAINT_PANEL=TRUE MYPAINT_PANEL_SCALE=0 MYPAINT_BRUSH= MYPAINT_SIZE=0 MYPAINT_SIZE_FROM_BRUSH=TRUE MYPAINT_SET=Classic MYPAINT_CELL=48 ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14
mp_read()  { read -r _ M_VIS M_X M_Y M_W M_H M_G M_NG M_N M_CELL M_COLS M_RF M_RA M_SC M_GX M_GY M_HOV M_CUR M_GNAME <<< "$(grep -m1 '^MYPP ' "$DK_DUMP")"; }
myz_read() { read -r _ Z_FOLLOW Z_PX Z_R Z_FILE Z_P Z_PEN Z_SRC _ <<< "$(grep -m1 '^MYPZ ' "$DK_DUMP")"; }
myp_read() { read -r _ T_TOOL T_ACT T_READY T_STROKES T_STEPS T_X1 T_Y1 T_X2 T_Y2 T_SIZE T_REST <<< "$(grep -m1 '^MYP ' "$DK_DUMP")"; T_NAME=${T_REST%%|*}; }
mpb() { B_ID=""; read -r _ B_ID B_X B_Y B_W <<< "$(grep -m1 "^MYPPB $1 " "$DK_DUMP")"; [[ -n "$B_ID" ]]; }
mp_btn() { if mpb "$1"; then click $(( B_X + B_W / 2 )) $(( B_Y + ROW_H / 2 )); wait_for 0.5 "$2"; dk_park; dk_settle; else fail "no palette button $1 ($2)"; fi; }
mp_cell() { # mp_cell K WHAT — the K-th brush of the shown group (0-based)
    mp_read
    local c=$(( $1 % M_COLS )) r=$(( $1 / M_COLS - M_SC ))
    click $(( M_GX + c * (M_CELL + 2) + M_CELL / 2 )) $(( M_GY + r * (M_CELL + 2) + M_CELL / 2 )); wait_for 0.8 "$2"; dk_park; dk_settle
}
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; dk_park; dk_settle; }
pg_colours() { magick "$1" -format '%k' info: 2>/dev/null; }

info "=== MyPaint brushes ==="
dk_begin

# --- the palette ------------------------------------------------------------------
mp_read
(( M_VIS != 0 )) && pass "the palette shows (${M_W}x$M_H at $M_X,$M_Y)" || fail "the palette is not shown (MYPP vis '$M_VIS')"
(( M_NG >= 8 )) && pass "$M_NG groups (order.conf + MY BRUSHES)" || fail "only '$M_NG' groups"
[[ "$M_GNAME" == "Classic" ]] && pass "the group from MYPAINT_SET: $M_GNAME ($M_N brushes)" || fail "group '$M_GNAME' (want Classic)"
(( M_COLS >= 1 && M_GX >= M_X && M_GX + M_COLS * (M_CELL + 2) <= M_X + M_W + 2 )) && pass "the grid fits the panel ($M_COLS columns of $M_CELL)" || fail "the grid: $M_COLS cols at $M_GX, cell $M_CELL, panel $M_X w $M_W"
screenshot "mypaint-palette"
G0=$M_G
mp_btn 2 "next group"; mp_read
(( M_G != G0 )) && pass "> shows the next group ($M_GNAME)" || fail "> did not change the group ($M_G)"
mp_btn 1 "previous group"; mp_read
(( M_G == G0 )) && pass "< goes back ($M_GNAME)" || fail "< left group $M_G (want $G0)"

# --- the group dropdown (a click on the name) -----------------------------------------
dmenu() { read -r _ D_OPEN D_PANEL _ D_X D_Y D_W D_N <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"; }
drow() { R_Y=""; read -r _ _ _ R_Y R_H R_CK <<< "$(awk -v v="$1" '$1 == "DMENUR" && $3 == v' "$DK_DUMP" | head -1)"; [[ -n "$R_Y" ]]; }
mp_btn 5 "the group dropdown"; dmenu
(( D_OPEN != 0 && D_PANEL == 11 )) && pass "the group name opens a dropdown" || fail "dropdown: DMENU open '$D_OPEN' panel '$D_PANEL' (want 11)"
NROWS=$(awk '$1 == "DMENUR" && $3 > 100' "$DK_DUMP" | wc -l)
(( NROWS == M_NG )) && pass "it lists every group ($NROWS)" || fail "it lists $NROWS groups (want $M_NG)"
drow $(( 100 + G0 )) && (( R_CK != 0 )) && pass "the shown group is checked" || fail "group $G0's row: checked '$R_CK'"
screenshot "mypaint-group-dropdown"
G2=$(( G0 + 2 ))
if drow $(( 100 + G2 )); then
    click $(( D_X + D_W / 2 )) $(( R_Y + R_H / 2 )); wait_for 0.6 "pick group $G2"; dk_park; dk_settle
    mp_read; dmenu
    (( M_G == G2 && D_OPEN == 0 )) && pass "picking a row shows that group ($M_GNAME) and closes it" || fail "after the pick: group $M_G (want $G2), menu open '$D_OPEN'"
else
    fail "no row for group $G2"
fi
mp_btn 5 "the dropdown again"; dmenu
if drow $(( 100 + G0 )); then
    click $(( D_X + D_W / 2 )) $(( R_Y + R_H / 2 )); wait_for 0.6 "back to group $G0"; dk_park; dk_settle
fi
mp_read
(( M_G == G0 )) && pass "the dropdown goes back to $M_GNAME" || fail "back: group $M_G (want $G0)"

# --- pick a brush -------------------------------------------------------------------
mp_cell 1 "pick the 2nd brush"
mp_read; myp_read
(( M_CUR == 1 )) && pass "the 2nd brush is the one in use ($T_NAME)" || fail "in use: cell '$M_CUR' ($T_NAME)"
(( T_TOOL != 0 )) && pass "picking a brush picked the MyPaint tool" || fail "tool not MyPaint (MYP tool '$T_TOOL')"
key bracketright; wait_for 0.3 "bigger"; key bracketright; wait_for 0.3 "bigger"; key bracketright; wait_for 0.4 "bigger"
dk_settle; myz_read; PX_UP=$Z_PX
# back to the 1st (the pencil: a thin hard line, easy to see)
mp_cell 0 "pick the pencil"; myp_read
[[ "$T_NAME" == "pencil" ]] && pass "the pencil picked" || info "1st Classic brush: $T_NAME"
myz_read
(( Z_PX == 2 * Z_FILE - 1 && Z_PX != PX_UP )) && pass "picking it sets the brush size to its own ($PX_UP -> $Z_PX px, size $Z_FILE)" || fail "brush $PX_UP -> $Z_PX px after the pick (the file's: size $Z_FILE = $(( 2 * Z_FILE - 1 )) px)"

# --- paint ------------------------------------------------------------------------
RX=$(( CANVAS_CX - 70 )); RY=$(( CANVAS_CY - 30 )); RW=140; RH=60
snap_region "$RX" "$RY" "$RW" "$RH" "mp-before"; BEFORE="$SNAP_RESULT"
myp_read; S0=$T_STROKES
dk_drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 60 )) $(( CANVAS_CY + 10 )) 10; dk_park; dk_settle
myp_read
(( T_STROKES == S0 + 1 )) && pass "one stroke ($T_STEPS events)" || fail "strokes $S0 -> $T_STROKES"
H_X1=$T_X1 # where a stroke from CANVAS_CX - 60 starts (buffer px)
(( T_X2 > T_X1 && T_Y2 >= T_Y1 )) && pass "it changed a box ($T_X1,$T_Y1 - $T_X2,$T_Y2)" || { myz_read; fail "no changed box ($T_X1,$T_Y1 - $T_X2,$T_Y2) [last pressure x1000 $Z_P, pen $Z_PEN, source $Z_SRC]"; }
snap_region "$RX" "$RY" "$RW" "$RH" "mp-stroke"; STROKE="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$STROKE" "the stroke shows on the canvas"
screenshot "mypaint-stroke"
key ctrl+z; wait_for 0.8 "undo"; dk_park; dk_settle
snap_region "$RX" "$RY" "$RW" "$RH" "mp-undone"
assert_regions_same "$BEFORE" "$SNAP_RESULT" "one Ctrl+Z takes the whole stroke away"

# --- size: ] (the brush size) -----------------------------------------------------
dk_settle; myz_read; PX0=$Z_PX
(( Z_FOLLOW != 0 )) && pass "by default the MyPaint brush follows the brush size ($PX0 px)" || fail "MYPZ fromBrush '$Z_FOLLOW' (want on)"
(( Z_R == Z_PX * 50 )) && pass "its radius is half the brush size (${Z_R}/100 px for $Z_PX px)" || fail "radius*100 '$Z_R' for brush $Z_PX px (want $(( Z_PX * 50 )))"
key bracketright; wait_for 0.3 "bigger"; key bracketright; wait_for 0.3 "bigger"; key bracketright; wait_for 0.3 "bigger"; key bracketright; wait_for 0.4 "bigger"
dk_settle; myp_read; myz_read
(( Z_PX == PX0 + 8 && Z_R == Z_PX * 50 )) && pass "] x4: the brush size and the MyPaint brush grow together ($PX0 -> $Z_PX px)" || fail "] x4: brush $PX0 -> '$Z_PX' px, radius*100 '$Z_R' (want $(( PX0 + 8 )) px)"
(( T_SIZE == 0 )) && pass "MYPAINT_SIZE is left alone ($T_SIZE)" || fail "MYPAINT_SIZE '$T_SIZE' changed while following the brush size"
dk_drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 60 )) $(( CANVAS_CY + 10 )) 10; dk_park; dk_settle
myp_read; H_BIG=$(( T_Y2 - T_Y1 ))
key ctrl+z; wait_for 0.6 "undo"
key bracketleft; wait_for 0.3 "smaller"; key bracketleft; wait_for 0.3 "smaller"; key bracketleft; wait_for 0.3 "smaller"; key bracketleft; wait_for 0.4 "smaller"
dk_settle; myz_read
(( Z_PX == PX0 )) && pass "[ x4: back to $PX0 px" || fail "brush '$Z_PX' px after [ x4 (want $PX0)"
dk_drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 60 )) $(( CANVAS_CY + 10 )) 10; dk_park; dk_settle
myp_read; H_SMALL=$(( T_Y2 - T_Y1 ))
(( H_BIG > H_SMALL )) && pass "the bigger brush paints a taller box ($H_BIG > $H_SMALL px)" || fail "bigger brush box $H_BIG, smaller $H_SMALL"
key ctrl+z; wait_for 0.6 "undo"; dk_park; dk_settle

# --- size: the brush's own (Size From Brush Size off) --------------------------------
pcmd "size from brush size"
myz_read; myp_read
(( Z_FOLLOW == 0 )) && pass "the command turns following the brush size off" || fail "MYPZ fromBrush '$Z_FOLLOW' after the command (want 0)"
R_OWN=$Z_R
key bracketright; wait_for 0.3 "bigger"; key bracketright; wait_for 0.4 "bigger"
dk_settle; myp_read; myz_read
(( T_SIZE == 4 && Z_PX == PX0 && Z_R > R_OWN )) && pass "] x2 steps the brush's own size (MYPAINT_SIZE 4, radius $R_OWN -> $Z_R), not the brush size" || fail "] x2: MYPAINT_SIZE '$T_SIZE', brush $Z_PX px, radius $R_OWN -> $Z_R"
key bracketleft; wait_for 0.3 "smaller"; key bracketleft; wait_for 0.4 "smaller"
pcmd "size from brush size"
myz_read
(( Z_FOLLOW != 0 && Z_R == Z_PX * 50 )) && pass "the command turns it back on" || fail "MYPZ fromBrush '$Z_FOLLOW' radius '$Z_R' after the second command"

# --- a selection clips it ---------------------------------------------------------
key m; wait_for 0.6 "marquee"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 40 )) "$CANVAS_CX" $(( CANVAS_CY + 40 )); wait_for 0.5 "selection"
mp_cell 0 "the pencil again"
snap_region $(( CANVAS_CX + 8 )) $(( CANVAS_CY - 20 )) 60 40 "mp-out-before"; OUT0="$SNAP_RESULT"
dk_drag $(( CANVAS_CX - 60 )) "$CANVAS_CY" $(( CANVAS_CX + 60 )) "$CANVAS_CY" 10; dk_park; dk_settle
key ctrl+d; wait_for 0.5 "deselect"; dk_park; dk_settle
snap_region $(( CANVAS_CX + 8 )) $(( CANVAS_CY - 20 )) 60 40 "mp-out-after"
# exact: a thin pencil line is far under the default 1500 px tolerance (it hid a leak once)
N_OUT=$(magick compare -metric AE "$OUT0" "$SNAP_RESULT" null: 2>&1 | awk '$1 ~ /^[0-9.]+$/ {print int($1); exit} {print "ERR"; exit}')
[[ "$N_OUT" =~ ^[0-9]+$ ]] || N_OUT=-1
(( N_OUT == 0 )) && pass "outside the selection: untouched (0 px)" || fail "outside the selection: $N_OUT px changed"
myp_read
# the stroke ran past the selection's right edge (CANVAS_CX); with no selection its box would
# reach ~60 canvas px further. Box in buffer px (no apron here), the same mapping as the strokes above.
(( T_X2 > T_X1 && T_X2 < H_X1 + 70 )) && pass "the changed box stops at the selection (x $T_X1 - $T_X2)" || fail "changed box x $T_X1 - $T_X2 (the stroke starts at $H_X1)"
screenshot "mypaint-selection"

# the clipped stroke off again (Ctrl+D's deselect is a step of its own): the lock test
# needs the layer empty - with the line there, a locked stroke crossing it rightly paints
snap_region "$RX" "$RY" "$RW" "$RH" "mp-sel-left"
key ctrl+z; wait_for 0.5 "undo the deselect"; key ctrl+z; wait_for 0.6 "undo the clipped stroke"; key ctrl+d; wait_for 0.4 "deselect"; dk_park; dk_settle
snap_region "$RX" "$RY" "$RW" "$RH" "mp-sel-undone"
N_E=$(magick compare -metric AE "$BEFORE" "$SNAP_RESULT" null: 2>&1 | awk '$1 ~ /^[0-9.]+$/ {print int($1); exit} {print "ERR"; exit}')
[[ "$N_E" == 0 ]] && pass "the clipped stroke undone: the layer is empty again" || fail "after undoing the clipped stroke: $N_E px differ from the empty canvas"

# --- opacity lock: the layer is empty, so a locked stroke changes nothing ----------
# the lock zone of a layer row: local x 14..23 (GUI/LAYERS.BM), rows 20 px under a 16 px header
dk_p layers
LK_X=$(( P_X + 18 )); LK_Y=$(( P_Y + 16 + 10 ))
click "$LK_X" "$LK_Y"; wait_for 0.5 "opacity lock on"; dk_park; dk_settle
snap_region "$RX" "$RY" "$RW" "$RH" "mp-lock-before"; LK0="$SNAP_RESULT"
myp_read; S0=$T_STROKES
dk_drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 60 )) $(( CANVAS_CY + 10 )) 10; dk_park; dk_settle
myp_read
(( T_STROKES == S0 + 1 )) && pass "a stroke on the opacity-locked layer ran" || fail "locked: strokes $S0 -> $T_STROKES"
(( T_X1 > T_X2 )) && pass "opacity lock on an empty layer: nothing changed (no box)" || fail "opacity lock: changed box $T_X1,$T_Y1 - $T_X2,$T_Y2"
snap_region "$RX" "$RY" "$RW" "$RH" "mp-lock-after"
assert_regions_same "$LK0" "$SNAP_RESULT" "opacity lock: the canvas is as it was"
click "$LK_X" "$LK_Y"; wait_for 0.5 "opacity lock off"; dk_park; dk_settle

# --- hide it ----------------------------------------------------------------------
pcmd "View: MyPaint Brushes"
mp_read
(( M_VIS == 0 )) && pass "View > MyPaint Brushes hides the palette" || fail "the palette still shows (vis '$M_VIS')"
pcmd "View: MyPaint Brushes"
mp_read
(( M_VIS != 0 )) && pass "and shows it again" || fail "the palette did not come back"

assert_no_crash
assert_window_exists
info "=== MyPaint brushes test done ==="
