#!/bin/bash
# =============================================================================
# brush-palette.sh — QA test: the brush palette (GUI/BRUSH-PANEL; Rick 2026-11-18: "a
# brush size palette now, with slider? with shapes like square, round, slant, soft/hard
# edge, in various sizes" / "that can be docked down to 1 column, 2 columns, tall, wide,
# whatever ... with thumbnail for each size").
#   1. View > Brush Palette shows a docked panel: 4 shape chips, SIZE / SOFT, 25 cells
#   2. a cell click sets the size; the SIZE slider's wheel steps it (+1, Shift +10)
#   3. the shape chips set the shape; a slant / dab is the mirror of a slant \ dab,
#      and neither is the round dab
#   4. SOFT (Shift + the wheel: 30) softens the dab (more colour levels); a middle-click
#      puts SOFT back to 0
#   5. the command hides it
# Dump: BSP vis x y w h cell cols rowsFit rowsAll scroll gridX gridY hover shape soft size;
# BSPC id x y w (chips); BSPS id x y w lw vw (sliders).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BRUSH_PANEL=TRUE BRUSH_PANEL_SCALE=0 BRUSH_PANEL_CELL=28 BRUSH_SOFT=0 ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14
bsp_read() { dk_settle; read -r _ P_VIS P_X P_Y P_W P_H P_CELL P_COLS P_RF P_RA P_SC P_GX P_GY P_HOV P_SHAPE P_SOFT P_SIZE <<< "$(grep -m1 '^BSP ' "$DK_DUMP")"; }
bsp_chip() { read -r _ _ C_X C_Y C_W <<< "$(grep -m1 "^BSPC $1 " "$DK_DUMP")"; click $(( C_X + C_W / 2 )) $(( C_Y + ROW_H / 2 )); wait_for 0.5 "chip $1"; dk_park; }
bsp_track() { # ID FRAC -> TX TY (the slider's track, one row or stacked)
    local sx sy sw lw vw tx tw ty
    read -r _ _ sx sy sw lw vw <<< "$(grep -m1 "^BSPS $1 " "$DK_DUMP")"
    if (( sw < lw + vw + 40 )); then tx=$(( sx + 2 )); tw=$(( sw - 4 )); ty=$(( sy + ROW_H + 2 + 3 ))
    else tx=$(( sx + lw )); tw=$(( sw - lw - vw )); ty=$(( sy + 6 )); fi
    TX=$(( tx + 1 + (tw - 3) * $2 / 100 )); TY=$ty
}
bsp_cell() { # K (0-based size index)
    bsp_read
    local c=$(( $1 % P_COLS )) r=$(( $1 / P_COLS - P_SC ))
    click $(( P_GX + c * (P_CELL + 2) + P_CELL / 2 )) $(( P_GY + r * (P_CELL + 2) + P_CELL / 2 )); wait_for 0.5 "cell $1"; dk_park
}
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; dk_park; dk_settle; }
dab() { # NAME X Y -> SNAP_RESULT: a dab of the brush at canvas-view (X, Y), then undone
    click "$2" "$3"; wait_for 0.4 "dab $1"; dk_park
    snap_region $(( $2 - 30 )) $(( $3 - 30 )) 61 61 "bsp-dab-$1"; DAB="$SNAP_RESULT"
    key ctrl+z; wait_for 0.4 "undo dab $1"
}
ae() { magick compare -metric AE "$1" "$2" null: 2>&1 | awk '$1 ~ /^[0-9.e+]+$/ {print int($1); exit} {print 99999; exit}'; } # (99999: sizes differ)
# the dab alone: where it differs from the blank canvas (BLANK), trimmed to its box - the
# checkerboard behind would not mirror
dmask() { magick "$BLANK" "$1" -compose difference -composite -colorspace gray -threshold 1% -trim +repage "$2"; }

info "=== Brush palette ==="
dk_begin

# --- 1. the panel ---------------------------------------------------------------------
bsp_read
(( P_VIS != 0 && P_W > 0 )) && pass "the palette shows (${P_W}x$P_H at $P_X,$P_Y)" || fail "the palette is not shown (BSP '$P_VIS')"
(( $(grep -c '^BSPC ' "$DK_DUMP") == 4 && $(grep -c '^BSPS ' "$DK_DUMP") == 2 )) && pass "4 shape chips, 2 sliders" || fail "chips $(grep -c '^BSPC ' "$DK_DUMP"), sliders $(grep -c '^BSPS ' "$DK_DUMP")"
(( P_COLS >= 1 && P_COLS * P_RA >= 25 && P_GX + P_COLS * (P_CELL + 2) <= P_X + P_W + 2 )) && pass "25 cells in $P_COLS columns, inside the panel" || fail "grid: $P_COLS cols x $P_RA rows, gridX $P_GX cell $P_CELL, panel $P_X w $P_W"
screenshot "brush-palette"

# --- 2. size: a cell, the wheel ------------------------------------------------------------
key b; wait_for 0.3 "brush tool"
bsp_cell 6; bsp_read
(( P_SIZE == 7 )) && pass "a click on the 7th cell: size 7 (13 px)" || fail "after the cell click: size $P_SIZE (want 7)"
bsp_track 10 50
scroll_up "$TX" "$TY"; wait_for 0.4 "wheel up"; bsp_read
(( P_SIZE == 8 )) && pass "the wheel up on SIZE: 8" || fail "SIZE wheel up: $P_SIZE (want 8)"
shift_scroll_down "$TX" "$TY"; wait_for 0.4 "shift wheel down"; bsp_read
(( P_SIZE == 1 )) && pass "Shift + the wheel down: 10 steps (clamped at 1)" || fail "SIZE shift wheel down: $P_SIZE (want 1)"
bsp_cell 6; bsp_read

# --- 3. shapes -----------------------------------------------------------------------------
DX=$(( CANVAS_CX )); DY=$(( CANVAS_CY ))
park_mouse; wait_for 0.3 "settle"
snap_region $(( DX - 30 )) $(( DY - 30 )) 61 61 "bsp-blank"; BLANK="$SNAP_RESULT"
bsp_chip 1; bsp_read
(( P_SHAPE == 0 )) && pass "ROUND chip: shape 0" || fail "ROUND chip: shape $P_SHAPE"
dab round "$DX" "$DY"; ROUND="$DAB"
bsp_chip 3; bsp_read
(( P_SHAPE == 2 )) && pass "SLANT / chip: shape 2" || fail "SLANT / chip: shape $P_SHAPE"
dab slash "$DX" "$DY"; SLASH="$DAB"
bsp_chip 4; bsp_read
(( P_SHAPE == 3 )) && pass "SLANT \\ chip: shape 3" || fail "SLANT \\ chip: shape $P_SHAPE"
dab backslash "$DX" "$DY"; BACK="$DAB"
TMPD="${QA_TMP_DIR:-/tmp}"
dmask "$SLASH" "$TMPD/bsp-ms.$$.png"; dmask "$BACK" "$TMPD/bsp-mb.$$.png"
magick "$TMPD/bsp-ms.$$.png" -flop "$TMPD/bsp-flop.$$.png"
info "dab boxes: / $(magick "$TMPD/bsp-ms.$$.png" -format '%wx%h' info:), \\ $(magick "$TMPD/bsp-mb.$$.png" -format '%wx%h' info:)"
DM=$(ae "$TMPD/bsp-flop.$$.png" "$TMPD/bsp-mb.$$.png"); DS=$(ae "$TMPD/bsp-ms.$$.png" "$TMPD/bsp-mb.$$.png"); DR=$(ae "$ROUND" "$SLASH")
rm -f "$TMPD"/bsp-{ms,mb,flop}.$$.png
info "slash vs backslash $DS px, mirrored $DM px, round vs slash $DR px"
(( DS > 20 && DM <= DS / 10 )) && pass "the \\ dab is the / dab mirrored ($DM px off, $DS apart)" || fail "slants: $DS px apart, mirrored $DM px off"
(( DR > 20 )) && pass "the slant dab is not the round one ($DR px)" || fail "round vs slant: $DR px"
screenshot "brush-palette-slant"

# --- 4. soft ---------------------------------------------------------------------------------
bsp_chip 1
NH=$(magick "$ROUND" -format '%k' info:)
bsp_track 11 50
for _ in 1 2 3; do shift_scroll_up "$TX" "$TY"; wait_for 0.3 "soft +10"; done
bsp_read
(( P_SOFT == 30 )) && pass "Shift + the wheel x3 on SOFT: 30" || fail "SOFT after 3 Shift-wheels: $P_SOFT (want 30)"
dab soft "$DX" "$DY"; SOFT="$DAB"
NS=$(magick "$SOFT" -format '%k' info:)
(( NS > NH + 4 )) && pass "the soft dab has more colour levels ($NS vs hard $NH)" || fail "soft dab: $NS colours (hard $NH)"
bsp_track 11 50
middle_click "$TX" "$TY"; wait_for 0.4 "middle click SOFT"; bsp_read
(( P_SOFT == 0 )) && pass "a middle-click puts SOFT back to 0" || fail "SOFT after middle-click: $P_SOFT"

# --- 5. hide ----------------------------------------------------------------------------------
pcmd "View: Brush Palette"
bsp_read
(( P_VIS == 0 )) && pass "the command hides the palette" || fail "still shown (BSP '$P_VIS')"
assert_no_crash
