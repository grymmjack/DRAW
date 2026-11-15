#!/bin/bash
# =============================================================================
# picker-loupe-chrome-alt.sh — QA test: the eyedropper loupe over GUI chrome
# only while Alt is held (BUGS.md 2026-11-15: "Zoom Loupe is showing up even
# when not holding ALT when hovering over tool box buttons").
#
# With the Picker tool selected (I), hovering a toolbox button shows no loupe:
# the area around the pointer looks the same as with the Brush selected.
# Dump: BTN toolbox i kind id name x y w h (viewport px).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Picker loupe: chrome only with Alt ==="
dk_begin

# a toolbox button low in the box (the Brush / Picker buttons stay out of the snap): the 25th
read -r _ _ _ _ _ _ BX BY BW BH <<< "$(awk '$1=="BTN" && $2=="toolbox" && $9>0' "$DK_DUMP" | sed -n 25p)"
if [[ -z "$BW" ]]; then fail "no toolbox button in the dump"; assert_no_crash; exit 0; fi
HX=$(( BX + BW / 2 )); HY=$(( BY + BH / 2 ))
# the loupe sits at +24, -24 from the pointer, ~96 px square, text beside it
area() { snap_region $(( HX + 8 )) $(( HY - 40 )) 140 140 "$1"; }

canvas_focus b; wait_for 0.3 "brush"
hover "$HX" "$HY"; wait_for 0.6 "over a toolbox button (brush)"; dk_settle
area "loupe-brush"; A_BRUSH="$SNAP_RESULT"
park_mouse; key i; wait_for 0.4 "picker"
hover "$HX" "$HY"; wait_for 0.6 "over a toolbox button (picker)"; dk_settle
area "loupe-picker"; A_PICK="$SNAP_RESULT"
screenshot "picker-over-toolbox"
assert_regions_same "$A_BRUSH" "$A_PICK" "Picker selected, no Alt: no loupe over the toolbox" 40
park_mouse; key b
assert_no_crash
