#!/bin/bash
# =============================================================================
# key-repeat-undo-shapes.sh — QA test: held keys repeat (BUGS.md 2026-11-15)
#
#  1. Holding Ctrl+Z steps back through the history - one step at once, then
#     one every INPUT_REPEAT_EVERY after INPUT_REPEAT_DELAY; Ctrl+Y the same way
#     forward. It used to take one step per press.
#     Letting go of Ctrl stops it (the held Z is not the Zoom key).
#  2. Holding an arrow while dragging a shape repeats its modifier: Right with
#     the Rectangle adds a division, again and again. It used to add one.
#
# Dump: HIST <current> <count> | SHAPEMOD <rectH> <rectV> <slices> <sides> |
#       VIEW zoom offX offY tool
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Held keys repeat: Undo / Redo, shape modifiers ==="
KR_DIR="$(mktemp -d /tmp/draw-qa-keyrep-XXXXXX)"
magick -size 320x200 xc:none "PNG32:$KR_DIR/blank.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$KR_DIR/blank.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash
dk_begin
CX=$CANVAS_CX; CY=$CANVAS_CY
hist() { sleep 0.3; read -r _ H_CUR H_CNT <<< "$(grep -m1 '^HIST ' "$DK_DUMP")"; }
tool() { read -r _ _ _ _ V_TOOL <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; }

# -- 1. Undo / Redo --
key b; wait_for 0.3 "brush"
key grave; wait_for 0.1 "pointer"
for i in 0 1 2 3 4 5 6 7; do
    drag $(( CX - 60 )) $(( CY - 40 + i * 10 )) $(( CX + 60 )) $(( CY - 40 + i * 10 )); sleep 0.35
done
dk_park; hist; C0=$H_CUR
info "8 strokes: history at $C0 of $H_CNT"
raw_key down ctrl; sleep 0.15
raw_key down z; sleep 0.15; raw_key up z; sleep 0.2
hist; C1=$H_CUR
(( C1 == C0 - 1 )) && pass "a Ctrl+Z tap undoes one step ($C0 -> $C1)" || fail "a Ctrl+Z tap: $C0 -> $C1 (want one step)"
raw_key down z; sleep 1.3; raw_key up z; sleep 0.2
raw_key up ctrl
hist; C2=$H_CUR
(( C1 - C2 >= 4 )) && pass "holding Ctrl+Z kept stepping back ($C1 -> $C2)" || fail "holding Ctrl+Z: $C1 -> $C2 (want 4+ steps in 1.3s)"
screenshot "repeat-undo-held"
raw_key down ctrl; sleep 0.15
raw_key down y; sleep 1.3; raw_key up y; sleep 0.2
raw_key up ctrl
hist; C3=$H_CUR
(( C3 - C2 >= 4 )) && pass "holding Ctrl+Y kept stepping forward ($C2 -> $C3)" || fail "holding Ctrl+Y: $C2 -> $C3 (want 4+ steps)"
# let go of Ctrl with Z still held: no more undo, no Zoom tool
raw_key down ctrl; sleep 0.15
raw_key down z; sleep 0.2; raw_key up ctrl
hist; C4=$H_CUR
sleep 1.0; hist; C5=$H_CUR
raw_key up z; sleep 0.3; dk_settle; tool
(( C5 == C4 )) && pass "letting go of Ctrl stops the repeat ($C4 -> $C5)" || fail "the undo kept going after Ctrl went up: $C4 -> $C5"
(( V_TOOL != 16 )) && pass "the held Z did not become the Zoom key (tool $V_TOOL)" || fail "the held Z switched to the Zoom tool"

# -- 2. Rectangle: hold Right while dragging --
key r; wait_for 0.3 "rectangle"
read -r _ R_H0 _ <<< "$(grep -m1 '^SHAPEMOD ' "$DK_DUMP")"
mouse_down $(( CX - 80 )) $(( CY - 50 )); sleep 0.1
hover $(( CX )) $(( CY )); hover $(( CX + 80 )) $(( CY + 50 )); sleep 0.2
raw_key down Right; sleep 1.3; raw_key up Right; sleep 0.3
read -r _ R_H1 _ <<< "$(grep -m1 '^SHAPEMOD ' "$DK_DUMP")"
screenshot "repeat-rect-divisions"
mouse_up; wait_for 0.4 "rect done"
info "rect H divisions: $R_H0 -> $R_H1"
(( R_H1 - R_H0 >= 4 )) && pass "holding Right while dragging the rectangle kept adding divisions ($R_H0 -> $R_H1)" || fail "holding Right: divisions $R_H0 -> $R_H1 (want 4+)"
assert_no_crash
rm -rf "$KR_DIR"
