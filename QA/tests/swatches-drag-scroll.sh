#!/bin/bash
# =============================================================================
# swatches-drag-scroll.sh — QA test: dragging swatches in a long set and in a
# docked panel:
#   - held below the grid, the drag scrolls it; the swatch drops on a cell
#     that was not showing when the drag began
#   - docked above the layers, a drag moves swatches the same way
# Fixture swatches-ramps.gpl: 161 entries (8 columns), a SPACE at 6.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
hex_of() { sw_cell "$1"; echo "$C_HEX"; }

info "=== Swatches: drag while scrolling / docked ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-ramps.gpl
dk_begin
sw_read; sw_expect "entries" "$SW_N" 161
if (( SW_MAXS > 0 )); then pass "the grid scrolls (max $SW_MAXS)"; else fail "the grid does not scroll"; fi
HX1=$(hex_of 1); HX2=$(hex_of 2)

# A. drag Red-ish 1 below the grid: it scrolls; drop on a cell that was hidden
sw_click 1; sw_geo; sw_cell 1
FX=$(( C_X + C_W / 2 )); FY=$(( C_Y + C_H / 2 ))
mouse_down "$FX" "$FY"; sleep 0.2
hover "$FX" $(( FY + 8 )); sleep 0.1
hover $(( G_X + G_W / 2 )) $(( G_Y + G_H + 4 )); sleep 1.5      # below the grid: scrolls
hover $(( G_X + G_W / 2 )) $(( G_Y + G_H / 2 )); dk_settle
sw_read
if (( SW_SCROLL > 0 )); then pass "held below the grid, the drag scrolled it ($SW_SCROLL px)"; else fail "the drag did not scroll the grid"; fi
# a cell well inside the grid now, past what showed at the start
T=$(awk -v gy="$G_Y" -v gh="$G_H" '$1=="SWATC" && $2 > 60 && $4 > gy + 4 && $4 + $6 < gy + gh - 4 && $7 == 0 {print $2; exit}' "$DK_DUMP")
if [[ -z "$T" ]]; then fail "no target cell showing past entry 60 (scroll $SW_SCROLL)"; mouse_up; dk_settle
else
    HT=$(hex_of "$T"); HB=$(hex_of $(( T - 1 )))
    sw_left_of "$T"; hover "$TX" "$TY"; dk_settle; sw_dragstate
    sw_expect "the drop is before $T" "$SD_DROP" "$T"
    screenshot "swatches-drag-scrolled"
    mouse_up; dk_settle; sw_read; sw_sel
    sw_expect "entries after the move" "$SW_N" 161
    sw_expect "the moved swatch lands at $(( T - 1 ))" "$(hex_of $(( T - 1 )))" "$HX1"
    sw_expect "... after the one that was before $T" "$(hex_of $(( T - 2 )))" "$HB"
    sw_expect "... before the one it was dropped on" "$(hex_of "$T")" "$HT"
    sw_expect "it is the selection" "$SS_LIST" "$(( T - 1 ))"
fi
sw_hover_panel; scroll_up $(( G_X + 4 )) $(( G_Y + 4 )); for k in 1 2 3 4 5 6 7 8 9 10; do scroll_up $(( G_X + 4 )) $(( G_Y + 4 )); done
dk_settle; sw_read
sw_expect "entry 1 is the old 2" "$(hex_of 1)" "$HX2"
sw_hover_panel; key ctrl+z; dk_settle; sw_read
sw_expect "Ctrl+Z: entry 1 back" "$(hex_of 1)" "$HX1"

# B. docked above the layers
dk_move_expect swatches above layers; dk_check "swatches above the layers"
sw_read; sw_expect "docked: entries" "$SW_N" 161
H3=$(hex_of 3); H5=$(hex_of 5)
sw_click 3; sw_right_of 5; sw_drag_entry 3
sw_expect "docked: the drop is before 6" "$SD_DROP" 6
sw_read
sw_expect "docked: 3 moved to 5" "$(hex_of 5)" "$H3"
sw_expect "docked: the old 5 is now 4" "$(hex_of 4)" "$H5"
dk_check "after the docked drag"
assert_window_exists
info "=== Swatches: drag while scrolling / docked PASSED ==="
