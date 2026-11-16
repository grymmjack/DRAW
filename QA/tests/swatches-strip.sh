#!/bin/bash
# =============================================================================
# swatches-strip.sh — QA test: Swatches <-> the palette strip.
#   ☰ → SELECTED TO STRIP: REPLACE makes the selected swatches the strip
#     (Ctrl+Z / Ctrl+Y over the canvas undo / redo it) - first, so the rest
#     works on any palette (the user profile's strip is a full 256)
#   ☰ → SELECTED TO STRIP: ADD puts the selected swatches at the strip's end
#     (a color the strip has is skipped; again = nothing added); Ctrl+Z over
#     the canvas takes it back (one palette undo step)
#   ☰ → ALL TO STRIP: REPLACE (nothing selected) makes the set's colors the
#     strip, in order; Ctrl+Z restores the strip
#   dragging selected swatches onto the strip inserts them after the chip
#     under the pointer (past the last chip = at the end); one undo step each
#   ☰ → NEW SET FROM STRIP: a set in My Swatches with the strip's colors
# The strip is read from the SWATP dump line (count, FG chip, every color).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
colors_only() { tr ' ' '\n' | grep -v '^[-|]$' | tr '\n' ' ' | sed 's/ $//'; }
undo_canvas() { hover "$CANVAS_CX" "$CANVAS_CY"; sleep 0.2; key ctrl+z; dk_settle; dk_park; dk_settle; }

info "=== Swatches <-> the palette strip ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-edit.gpl
dk_begin
sw_read; sw_strip
P0=$SP_HEX; N0=$SP_N
SET0=$(sw_hexes | colors_only)
info "strip: $N0 colors"
redo_canvas() { hover "$CANVAS_CX" "$CANVAS_CY"; sleep 0.2; key ctrl+y; dk_settle; dk_park; dk_settle; }

# --- REPLACE with the selected (9-21: greens, blues, gold; the empty cell and the break are skipped) ---
sw_click 9; sw_click 21 shift
sw_menu_edit; sw_menu_click 216; sw_strip
sw_expect "the item reads" "$SM_LABEL" "SELECTED TO STRIP: REPLACE"
S1="003C00 006E00 00A000 00D200 00003C 00005F 000082 0000A5 0000C8 0000EB FFC800"
sw_expect "REPLACE: the strip = the selected colors, in order" "$SP_HEX" "$S1"
if (( SP_FG >= 0 && SP_FG < SP_N )); then pass "the FG chip is on the strip ($SP_FG)"; else fail "FG chip $SP_FG of $SP_N"; fi
sw_read; sw_edit_state
sw_expect "the set is not edited by it" "$SE_MINE" 0
screenshot "swatches-strip-replaced"
undo_canvas; sw_strip
sw_expect "Ctrl+Z over the canvas: the strip as it was" "$SP_HEX" "$P0"
redo_canvas; sw_strip
sw_expect "Ctrl+Y: replaced again" "$SP_HEX" "$S1"

# --- ADD the selected (1-3) ---
sw_click 1; sw_click 3 shift
sw_menu_edit; sw_menu_click 217; sw_strip
sw_expect "ADD: the reds at the end" "$SP_HEX" "$S1 3C0000 550000 6E0000"
sw_menu_edit; sw_menu_click 217; sw_strip
sw_expect "ADD again: nothing added (colors the strip has)" "$SP_N" 14
undo_canvas; sw_strip
sw_expect "Ctrl+Z: one step back" "$SP_HEX" "$S1"

# --- REPLACE with all (nothing selected) ---
sw_hover_panel; key Escape; dk_settle; sw_sel
sw_expect "nothing selected" "$SS_N" 0
sw_menu_edit; sw_menu_click 216; sw_strip
sw_expect "the item reads" "$SM_LABEL" "ALL TO STRIP: REPLACE"
sw_expect "REPLACE all: the set's colors, in order" "$SP_HEX" "$SET0"
undo_canvas; sw_strip
sw_expect "Ctrl+Z: back" "$SP_HEX" "$S1"

# --- drag onto the strip: after chip 0 ---
sw_click 4; sw_strip_xy 0
sw_drag_entry 4 "swatches-strip-drag"
sw_expect "while dragging over chip 0: insert before strip index" "$SD_STRIP" 1
sw_strip
sw_expect "drag: Red 4 after chip 0" "$SP_HEX" "003C00 870000 ${S1#003C00 }"
sw_read; sw_expect "the set keeps its swatch (a drop on the strip is not a move)" "$SW_N" 21
# past the last chip: at the end
sw_click 5; sw_click 6 shift
sw_strip_xy end
sw_drag_entry 5
sw_expect "while dragging past the chips: the end" "$SD_STRIP" 12
sw_strip
sw_expect "drag to the end: the two reds last" "$(awk '{print $(NF-1), $NF}' <<< "$SP_HEX")" "A00000 B90000"
undo_canvas; undo_canvas; sw_strip
sw_expect "two Ctrl+Z: the strip as it was" "$SP_HEX" "$S1"

# --- a drop back on the grid still moves ---
sw_click 21; sw_left_of 1; sw_drag_entry 21; sw_read
sw_expect "a drop on the grid: still a move" "$(sw_hexes | cut -d' ' -f1)" "FFC800"

# --- NEW SET FROM STRIP ---
sw_menu_edit; sw_menu_click 218; sw_read
if [[ "$SW_KEY" == "$SW_MINE"/*.gpl ]]; then pass "NEW SET FROM STRIP: a set in My Swatches ($(basename "$SW_KEY"))"; else fail "NEW SET FROM STRIP: the set is $SW_KEY"; fi
sw_expect "... with the strip's colors" "$(sw_hexes | colors_only)" "$S1"
screenshot "swatches-strip-end"
assert_window_exists
info "=== Swatches <-> the palette strip PASSED ==="
