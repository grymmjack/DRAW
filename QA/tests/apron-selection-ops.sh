#!/bin/bash
# =============================================================================
# apron-selection-ops.sh — every action that USES a selection must hit the pixels
# the selection covers on a layer a Move has promoted to an apron-extended buffer.
#
# Selection tools keep a promoted layer promoted; selection coords are CANVAS
# coords and canvas (x,y) is buffer (x+apronW, y+apronH) - gotcha #14. These
# actions read / wrote the buffer at raw canvas coords, i.e. up-left by the apron
# (off the canvas, or onto some other spot): Fill FG (box + mask), Stroke
# Selection, Capture Custom Brush, wand Delete / E+click erase / F+click fill,
# Scale 2x H / V, Copy / Copy Merged (+ paste). Companion of
# apron-select-after-move.sh (the selection shape itself + Delete / Cut).
#
# Each action works at its own spot; a WITNESS mark must survive all of them.
#
# Also covers two non-apron wand bugs found here: E / F were registered as plain
# Eraser / Fill tool switches, so with the wand in hand E+click / F+click switched
# tools instead of flood-erasing / flood-filling (the dump's VIEW line carries
# CURRENT_TOOL% - it must stay TOOL_MARQUEE = 5); and wand Delete cleared the
# pixels without invalidating the layer, so the screen kept showing them.
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================

info "=== Selection actions on an apron-promoted layer ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Promote the layer: draw, select all, Move the content past the right edge --
info "Draw content and move it past the right edge (promotes the apron)"
drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.3 "Stroke"
key ctrl+a
wait_for 0.5 "Select all"
key v
wait_for 0.3 "Move tool"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 120 )) $CANVAS_CY
wait_for 0.5 "Moved right past the edge"
key b
wait_for 0.3 "Brush (commits move)"
key ctrl+d
wait_for 0.2 "Deselect"
key grave
wait_for 0.1 "Pointer hidden"
assert_no_crash

BOX=28
# spot NAME DX DY -> sets NAME_X / NAME_Y (viewport) from the canvas centre
spot() { printf -v "${1}_X" '%s' $(( CANVAS_CX + $2 )); printf -v "${1}_Y" '%s' $(( CANVAS_CY + $3 )); }
spot A -130 -70; spot B  -90 -70; spot C  -50 -70          # fill box, fill mask, stroke
spot D -130 -30; spot D2 -90 -30; spot E  -50 -30          # brush src, brush stamp, wand Delete
spot F -130  10; spot H  -90  10; spot I  -50  10          # wand erase, scale 2x H, scale 2x V
spot J -130  50; spot K  -90  50; spot G  -50  50          # copy merged src, copy src, wand fill
spot Z   40 -70; spot W   40  60; spot P    0   0          # far blank, witness, paste centre
# snap NAME LABEL -> SNAP_RESULT is the BOX around spot NAME
snap() { local x="${1}_X" y="${1}_Y"; snap_region $(( ${!x} - BOX/2 )) $(( ${!y} - BOX/2 )) $BOX $BOX "$2"; }
# mark NAME -> a short horizontal brush stroke at the spot
mark() { local x="${1}_X" y="${1}_Y"; drag $(( ${!x} - 5 )) ${!y} $(( ${!x} + 5 )) ${!y}; wait_for 0.25 "mark $1"; }
# rsel NAME R -> rectangle-select +-R around the spot (marquee tool)
rsel() { local x="${1}_X" y="${1}_Y"; key m; wait_for 0.25 "Rect marquee"; drag $(( ${!x} - $2 )) $(( ${!y} - $2 )) $(( ${!x} + $2 )) $(( ${!y} + $2 )); wait_for 0.35 "select $1"; }
# tool_is N LABEL -> the dock dump's VIEW line reports CURRENT_TOOL% = N
tool_is() {
    local t=""; sleep 0.2
    read -r _ _ _ _ t <<< "$(grep -m1 '^VIEW ' "$DRAW_ROOT/QA/.dock-dump.txt" 2>/dev/null)"
    if [[ "$t" == "$1" ]]; then pass "$2 (CURRENT_TOOL=$t)"; else fail "$2 - CURRENT_TOOL=${t:-?}, expected $1"; fi
}
palette_run() { key question; wait_for 0.5 "Command palette"; type_text "$1"; wait_for 0.3 "Filter"; key Return; wait_for 0.5 "$1"; }

park_mouse
for s in A B C D D2 E F H I J K G Z W; do snap $s "ops-$s-blank"; printf -v "BLANK_$s" '%s' "$SNAP_RESULT"; done
PBOX=64   # paste lands centred on the CANVAS (a few px off CANVAS_CX/CY) - wider box
snap_p() { snap_region $(( P_X - PBOX/2 )) $(( P_Y - PBOX/2 )) $PBOX $PBOX "$1"; }
snap_p "ops-P-blank"; BLANK_P="$SNAP_RESULT"

info "Paint the marks"
for s in D E F H I J K G W; do mark $s; done
park_mouse
for s in D E F H I J K G W; do snap $s "ops-$s-marked"; printf -v "MARKED_$s" '%s' "$SNAP_RESULT"; done
assert_regions_differ "$BLANK_W" "$MARKED_W" "the witness mark was painted"

# -- Fill FG: rectangle selection (Backspace) --------------------------------
info "Fill FG through a rectangle selection"
rsel A 10
key BackSpace; wait_for 0.4 "Fill FG"
key ctrl+d; wait_for 0.2 "Deselect"; park_mouse
snap A "ops-A-after"
assert_regions_differ "$BLANK_A" "$SNAP_RESULT" "Fill FG filled the rectangle selection where it was drawn"

# -- Fill FG: mask selection (polygon select) --------------------------------
info "Fill FG through a polygon (mask) selection"
palette_run "polygon select"
click $(( B_X - 10 )) $(( B_Y - 10 )); wait_for 0.15 "v1"
click $(( B_X + 10 )) $(( B_Y - 10 )); wait_for 0.15 "v2"
click $(( B_X + 10 )) $(( B_Y + 10 )); wait_for 0.15 "v3"
click $(( B_X - 10 )) $(( B_Y + 10 )); wait_for 0.15 "v4"
right_click $(( B_X - 10 )) $(( B_Y + 10 )); wait_for 0.4 "close polygon"
key BackSpace; wait_for 0.4 "Fill FG"
key ctrl+d; wait_for 0.2 "Deselect"; park_mouse
snap B "ops-B-after"
assert_regions_differ "$BLANK_B" "$SNAP_RESULT" "Fill FG filled the polygon selection where it was drawn"

# -- Stroke Selection (dialog defaults, OK) ----------------------------------
info "Stroke Selection around a rectangle selection"
rsel C 9
palette_run "Stroke Selection"
wait_for 0.5 "Stroke dialog"
click 414 337; wait_for 0.8 "OK"
key ctrl+d; wait_for 0.2 "Deselect"; park_mouse
snap C "ops-C-after"
assert_regions_differ "$BLANK_C" "$SNAP_RESULT" "Stroke Selection drew around the selection where it was drawn"
assert_no_crash

# -- Capture Custom Brush (Ctrl+B) from a selection, stamp it elsewhere -------
info "Capture a custom brush from the mark, stamp it on a blank spot"
rsel D 10
key ctrl+b; wait_for 0.4 "Capture custom brush"
key ctrl+d; wait_for 0.2 "Deselect (a live selection would clip the stamp)"
drag $D2_X $D2_Y $(( D2_X + 1 )) $D2_Y; wait_for 0.4 "Stamp (Ctrl+B switched to the brush)"
key ctrl+b; wait_for 0.3 "Clear custom brush"
park_mouse
snap D2 "ops-D2-after"
assert_regions_same "$MARKED_D" "$SNAP_RESULT" \
    "the stamped custom brush is the captured mark (captured where the selection was)" 120
assert_no_crash

# -- Magic wand: click the mark, Delete --------------------------------------
info "Wand-select a mark, Delete"
key w; wait_for 0.3 "Magic wand"
click $E_X $E_Y; wait_for 0.5 "wand selection"
park_mouse; screenshot "ops-wand-selected"
key Delete; wait_for 0.4 "Delete"
screenshot "ops-wand-deleted"
key ctrl+d; wait_for 0.2 "Deselect"; park_mouse
snap E "ops-E-after"
assert_regions_same "$BLANK_E" "$SNAP_RESULT" "wand Delete removed the mark it selected" 30

# -- Magic wand: hold E + click = flood erase --------------------------------
info "Wand E+click flood erase"
key w; wait_for 0.3 "Magic wand"
hover $F_X $F_Y
raw_key down e; sleep 0.15
click $F_X $F_Y; wait_for 0.4 "E+click"
tool_is 5 "E with the wand in hand is the flood-erase modifier, not a switch to the Eraser"
raw_key up e; sleep 0.15
park_mouse
snap F "ops-F-after"
assert_regions_same "$BLANK_F" "$SNAP_RESULT" "wand E+click erased the mark it was clicked on" 30
key ctrl+d; wait_for 0.2 "Deselect"

# -- Scale 2x Horizontal / Vertical (Ctrl+Home / Ctrl+End) -------------------
info "Scale 2x horizontal / vertical through a rectangle selection"
rsel H 12
key ctrl+Home; wait_for 0.5 "Scale 2x H"
key ctrl+d; wait_for 0.2 "Deselect"; park_mouse
snap H "ops-H-after"
assert_regions_differ "$MARKED_H" "$SNAP_RESULT" "Scale 2x Horizontal widened the selected mark in place"
rsel I 12
key ctrl+End; wait_for 0.5 "Scale 2x V"
key ctrl+d; wait_for 0.2 "Deselect"; park_mouse
snap I "ops-I-after"
assert_regions_differ "$MARKED_I" "$SNAP_RESULT" "Scale 2x Vertical stretched the selected mark in place"
assert_no_crash

# -- Copy Merged / Copy + Paste (paste is centred on the canvas) -------------
for pair in "J ctrl+shift+c Copy-Merged" "K ctrl+c Copy"; do
    read -r S COMBO NAME <<< "$pair"
    info "$NAME the mark, paste it (centred), commit"
    rsel "$S" 10
    key "$COMBO"; wait_for 0.3 "$NAME"
    key ctrl+d; wait_for 0.2 "Deselect"
    key ctrl+v; wait_for 0.5 "Paste (float at the centre)"
    key b; wait_for 0.3 "Brush (commits paste)"
    key ctrl+d; wait_for 0.2 "Deselect"
    key grave; wait_for 0.1 "Pointer hidden"
    park_mouse
    snap_p "ops-P-after-$NAME"
    assert_regions_differ "$BLANK_P" "$SNAP_RESULT" \
        "$NAME + paste put the selected mark on the canvas (copied where the selection was, not empty)"
    # clean up for the next pass (undo would re-float the committed paste, by design)
    rsel P 26
    key Delete; wait_for 0.3 "Delete the paste"
    key ctrl+d; wait_for 0.2 "Deselect"
    park_mouse
    snap_p "ops-P-cleared-$NAME"
    assert_regions_same "$BLANK_P" "$SNAP_RESULT" "the $NAME paste was cleared again" 30
done
assert_no_crash

# -- Magic wand: hold F + click = flood fill (FG green) -----------------------
info "Wand F+click flood fill (green FG) on a mark"
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y"; wait_for 0.2 "Green FG"
key w; wait_for 0.3 "Magic wand"
hover $G_X $G_Y
raw_key down f; sleep 0.15
click $G_X $G_Y; wait_for 0.4 "F+click"
tool_is 5 "F with the wand in hand is the flood-fill modifier, not a switch to the Fill tool"
raw_key up f; sleep 0.15
key ctrl+d; wait_for 0.2 "Deselect"
park_mouse
snap G "ops-G-after"
assert_regions_differ "$MARKED_G" "$SNAP_RESULT" "wand F+click recoloured the mark it was clicked on"
snap Z "ops-Z-after"
assert_regions_same "$BLANK_Z" "$SNAP_RESULT" "wand F+click did not flood the empty area (seeded on the mark, not off-canvas)" 30

# -- The witness survived everything -----------------------------------------
snap W "ops-W-after"
assert_regions_same "$MARKED_W" "$SNAP_RESULT" "the witness mark survived every selection action" 30

key b; wait_for 0.2 "Brush"
screenshot "apron-selection-ops"
assert_no_crash
assert_window_exists
info "=== apron selection actions test COMPLETE ==="
