#!/bin/bash
# =============================================================================
# tool-options-more.sh — QA test: the Tool Options bar for the brush (mix), the eraser,
# MyPaint, move / transform, crop and zoom / pan (GUI/SEL-BAR; PLANS/TOOL-OPTIONS-BAR.md
# phase 3 - every tool you stay in has at least one option):
#   - brush: MIX brings SMUDGE / LENGTH / RADIUS (Brush > Mix Colors), TILE
#   - eraser: ALL LAYERS (sticky smart erase): erasing an empty layer with it on clears
#     the layer below; Shift then erases the current layer only
#   - move: FLIP H / V, ROTATE, SCALE (the Edit menu's): FLIP H flips the layer
#   - transform overlay: APPLY / CANCEL, whatever the tool
#   - crop: W / H of the box, APPLY / CANCEL / TRIM / WHOLE IMAGE; W set on the bar crops
#     the canvas to it
#   - zoom: ZOOM - / + / 100% / FIT / CENTER
#   - MyPaint: SIZE = BRUSH swaps DRAW's SIZE for the brush's own, OPAQUE / PRESSURE / TWIST
# Dump: SELBARM mix smudge length mixrad tile ersmart mpfrom mpsize mppress mptwist
# cropstate cropw croph transform zoom; CANVAS w h crop; SELBARC id x y w trackX.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_BAR=TRUE ANTIALIAS=FALSE BRUSH_MIX=FALSE BRUSH_MIX_SMUDGE=50 MYPAINT_SIZE_FROM_BRUSH=TRUE MYPAINT_TWIST=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14 # THEME.TEXT_BAR_ROW_HEIGHT (the stock theme)
ID_SIZE=24
ID_MIX=142; ID_SMUDGE=143; ID_LENGTH=144; ID_MIXRAD=145; ID_TILE=146; ID_ERSMART=147
ID_MPFROM=148; ID_MPSIZE=149; ID_MPOPAQUE=150; ID_MPPRESS=151; ID_MPTWIST=152; ID_MPBRUSHES=153; ID_MPSET=154
ID_FLIPH=155; ID_DOUBLE=160; ID_TRAPPLY=161; ID_TRCANCEL=162
ID_CRW=163; ID_CRH=164; ID_CRAPPLY=165; ID_CRCANCEL=166; ID_CRTRIM=167; ID_CRWHOLE=168
ID_ZOUT=169; ID_ZIN=170; ID_Z100=171; ID_ZFIT=172; ID_ZCENTER=173

sb_read() { read -r _ S_ON S_X S_Y S_W S_H S_LN _ _ _ _ _ _ _ _ _ _ _ _ S_TOOL _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; }
sm_read() { read -r _ M_MIX M_SMUDGE M_LENGTH M_RAD M_TILE M_ERS M_MPFROM M_MPSIZE M_MPPRESS M_MPTWIST M_CROP M_CW M_CH M_TR M_ZOOM _ <<< "$(grep -m1 '^SELBARM ' "$DK_DUMP")"; }
canvas() { read -r _ C_W C_H C_CROP _ <<< "$(grep -m1 '^CANVAS ' "$DK_DUMP")"; }
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
settle() { wait_for 0.4 "$1"; dk_park; dk_settle; sb_read; sm_read; canvas; }
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; settle "$1"; }
sb_click() { if sbc "$1"; then click $(( C_X + C_W / 2 )) $(( C_Y + ROW_H / 2 )); settle "$2"; else fail "no control $1 ($2) on the bar"; fi; }
sb_track() { if sbc "$1"; then click $(( C_TX + ($2 > 0 ? $2 : -1) )) $(( C_Y + ROW_H / 2 )); settle "$3"; else fail "no slider $1 ($3) on the bar"; fi; }
sb_middle() { if sbc "$1"; then middle_click $(( C_TX + 20 )) $(( C_Y + ROW_H / 2 )); settle "$2"; else fail "no slider $1 ($2) on the bar"; fi; }
sb_inside() {
    local why="" id x y w tx
    while read -r _ id x y w tx; do
        (( x >= S_X && x + w <= S_X + S_W && y >= S_Y && y + ROW_H <= S_Y + S_H )) || why+=" control $id at $x,$y w $w"
    done < <(grep '^SELBARC ' "$DK_DUMP")
    [[ -z "$why" ]] && pass "$1: every control inside the bar ($S_LN lines)" || fail "$1:$why"
}
has_all() {
    local miss="" id
    for id in "${@:2}"; do sbc "$id" || miss+=" $id"; done
    [[ -z "$miss" ]] && pass "$1" || fail "$1: missing$miss"
}
has_none() {
    local extra="" id
    for id in "${@:2}"; do sbc "$id" && extra+=" $id"; done
    [[ -z "$extra" ]] && pass "$1" || fail "$1: shown$extra"
}

info "=== Tool Options: brush, eraser, move, transform, crop, zoom, MyPaint ==="
dk_begin

# --- brush: MIX --------------------------------------------------------------------------
key b; settle "brush"
(( S_ON != 0 )) && pass "the brush shows the bar" || { fail "brush: no bar"; assert_no_crash; exit 0; }
has_all "brush: MIX and TILE" $ID_MIX $ID_TILE
has_none "brush: no mix sliders while MIX is off" $ID_SMUDGE $ID_LENGTH $ID_MIXRAD
sb_click $ID_MIX "MIX on"
(( M_MIX != 0 )) && pass "MIX: the mix brush on" || fail "MIX: mix $M_MIX"
has_all "MIX on: SMUDGE, LENGTH, RADIUS" $ID_SMUDGE $ID_LENGTH $ID_MIXRAD
sb_inside "brush + mix"
sb_track $ID_SMUDGE 4 "SMUDGE low"
(( M_SMUDGE < 50 )) && pass "SMUDGE track: $M_SMUDGE" || fail "SMUDGE track: $M_SMUDGE"
sb_middle $ID_SMUDGE "middle-click SMUDGE"
(( M_SMUDGE == 50 )) && pass "middle-click SMUDGE: 50" || fail "middle-click SMUDGE: $M_SMUDGE"
sb_click $ID_MIX "MIX off"
(( M_MIX == 0 )) || fail "MIX off: mix $M_MIX"

# a block on layer 1 for the eraser and the move tool
sb_track $ID_SIZE 40 "a wider brush"
drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 10 )); settle "a block, left of centre"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 14 )) 20 8 "topt-block"
BLOCK="$SNAP_RESULT"

# --- move: FLIP H ------------------------------------------------------------------------------
key v; settle "move"
has_all "move: FLIP H .. SCALE 2X" $ID_FLIPH $(( ID_FLIPH + 1 )) $(( ID_FLIPH + 2 )) $(( ID_FLIPH + 3 )) $(( ID_FLIPH + 4 )) $ID_DOUBLE
sb_inside "move"
sb_click $ID_FLIPH "FLIP H"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 14 )) 20 8 "topt-flipped"
assert_regions_differ "$BLOCK" "$SNAP_RESULT" "FLIP H flips the layer (the block leaves the left)"
key ctrl+z; settle "undo the flip"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 14 )) 20 8 "topt-flip-undone"
assert_regions_same "$BLOCK" "$SNAP_RESULT" "Ctrl+Z unflips" 3

# --- transform overlay: APPLY / CANCEL -----------------------------------------------------------
pcmd "Transform Scale"; settle "the transform overlay"
if (( M_TR != 0 )); then
    pass "Transform Scale: the overlay is up"
    has_all "transform: APPLY and CANCEL" $ID_TRAPPLY $ID_TRCANCEL
    sb_click $ID_TRCANCEL "CANCEL the transform"
    (( M_TR == 0 )) && pass "CANCEL: the overlay is gone" || fail "CANCEL: transform $M_TR"
else
    fail "Transform Scale: no overlay (SELBARM transform $M_TR)"
fi

# --- eraser: ALL LAYERS -----------------------------------------------------------------------
key ctrl+shift+n; settle "a new, empty layer"
key e; settle "eraser"
has_all "eraser: ALL LAYERS" $ID_ERSMART
drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 10 )); settle "erase the empty layer"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 14 )) 20 8 "topt-erase-one"
assert_regions_same "$BLOCK" "$SNAP_RESULT" "the eraser on an empty layer leaves the block below" 3
sb_click $ID_ERSMART "ALL LAYERS on"
(( M_ERS != 0 )) && pass "ALL LAYERS: smart erase sticks" || fail "ALL LAYERS: $M_ERS"
drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 10 )); settle "erase all layers"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 14 )) 20 8 "topt-erase-all"
assert_regions_differ "$BLOCK" "$SNAP_RESULT" "ALL LAYERS: the eraser clears the block on the layer below"
key ctrl+z; settle "undo the smart erase"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 14 )) 20 8 "topt-erase-undone"
assert_regions_same "$BLOCK" "$SNAP_RESULT" "Ctrl+Z puts the block back" 3
sb_click $ID_ERSMART "ALL LAYERS off"
(( M_ERS == 0 )) || fail "ALL LAYERS off: $M_ERS"

# --- zoom ---------------------------------------------------------------------------------------
key z; settle "zoom"
has_all "zoom: ZOOM - / + / 100% / FIT / CENTER" $ID_ZOUT $ID_ZIN $ID_Z100 $ID_ZFIT $ID_ZCENTER
Z0=$M_ZOOM
sb_click $ID_ZIN "ZOOM +"
(( M_ZOOM > Z0 )) && pass "ZOOM +: $Z0 -> $M_ZOOM" || fail "ZOOM +: $Z0 -> $M_ZOOM"
sb_click $ID_Z100 "100%"
(( M_ZOOM == 100 )) && pass "100%: zoom 100" || fail "100%: zoom $M_ZOOM"
sb_click $ID_ZFIT "FIT"; Z_FIT=$M_ZOOM
sb_click $ID_ZOUT "ZOOM -"
(( M_ZOOM < Z_FIT )) && pass "ZOOM -: $Z_FIT -> $M_ZOOM" || fail "ZOOM -: $Z_FIT -> $M_ZOOM"
sb_click $ID_ZFIT "FIT"
sb_click $ID_ZCENTER "CENTER"

# --- crop ----------------------------------------------------------------------------------------
W0=$C_W
pcmd "Crop Canvas"; settle "crop, the whole image boxed"
(( M_CROP == 1 )) && pass "Crop Canvas: crop mode" || fail "Crop Canvas: crop $M_CROP"
has_all "crop: W, H, APPLY, CANCEL, TRIM, WHOLE IMAGE" $ID_CRW $ID_CRH $ID_CRAPPLY $ID_CRCANCEL $ID_CRTRIM $ID_CRWHOLE
sb_inside "crop"
(( M_CW == W0 )) && pass "W reads the box: $M_CW" || fail "W: $M_CW (canvas $W0)"
sb_click $ID_CRCANCEL "CANCEL the crop"
(( M_CROP == 0 && C_W == W0 )) && pass "CANCEL: out of crop, the canvas as it was" || fail "CANCEL: crop $M_CROP canvas $C_W"
pcmd "Crop Canvas"; settle "crop again"
sb_track $ID_CRW 10 "W small"
NW=$M_CW
(( NW > 0 && NW < W0 )) && pass "W track: the box $NW wide" || fail "W track: $NW (canvas $W0)"
sb_click $ID_CRAPPLY "APPLY the crop"
(( M_CROP == 0 && C_W == NW )) && pass "APPLY: the canvas is $NW wide" || fail "APPLY: crop $M_CROP canvas $C_W (wanted $NW)"
key ctrl+z; settle "undo the crop"
(( C_W == W0 )) && pass "Ctrl+Z: the canvas back to $W0" || fail "undo the crop: canvas $C_W"

# --- MyPaint -------------------------------------------------------------------------------------
pcmd "MyPaint Brush Tool"; settle "MyPaint"
has_all "MyPaint: SIZE, SIZE = BRUSH, OPAQUE, PRESSURE, TWIST, BRUSHES, SETTINGS" $ID_SIZE $ID_MPFROM $ID_MPOPAQUE $ID_MPPRESS $ID_MPTWIST $ID_MPBRUSHES $ID_MPSET
has_none "MyPaint: the brush's own SIZE hidden while SIZE = BRUSH" $ID_MPSIZE
sb_click $ID_MPFROM "SIZE = BRUSH off"
(( M_MPFROM == 0 )) && pass "SIZE = BRUSH off" || fail "SIZE = BRUSH: $M_MPFROM"
has_all "off: the brush's own SIZE" $ID_MPSIZE
has_none "off: no DRAW SIZE" $ID_SIZE
sb_click $ID_MPFROM "SIZE = BRUSH on"
(( M_MPFROM != 0 )) || fail "SIZE = BRUSH back on: $M_MPFROM"
sb_track $ID_MPTWIST 30 "TWIST"
(( M_MPTWIST > 0 )) && pass "TWIST track: $M_MPTWIST" || fail "TWIST track: $M_MPTWIST"
sb_middle $ID_MPTWIST "middle-click TWIST"
(( M_MPTWIST == 0 )) && pass "middle-click TWIST: 0" || fail "middle-click TWIST: $M_MPTWIST"
sb_inside "MyPaint"

assert_no_crash
assert_window_exists
info "=== Tool Options: brush, eraser, move, transform, crop, zoom, MyPaint PASSED ==="
