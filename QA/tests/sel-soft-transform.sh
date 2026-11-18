#!/bin/bash
# =============================================================================
# sel-soft-transform.sh — QA test: a feathered selection through Transform
# (PLANS/AA-SELECTIONS.md; TOOLS/TRANSFORM lifts by the selection's coverage).
#   1. a filled layer, a rectangle with FEATHER 6, Transform, Enter with no edit:
#      the layer is exactly as it was (no soft-edge halo: TRANSFORM_commit cancels
#      an unedited soft lift instead of clearing and re-blitting it)
#   2. FEATHER 0, the rectangle moved right in Transform: the hole it leaves has a
#      hard edge (only the fill and the checkerboard)
#   3. FEATHER 6, the same move: the hole's edge is soft (the unselected share of
#      each edge pixel stays behind)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_FEATHER=0 SELECTION_MODE=REPLACE SELECTION_BAR=TRUE ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
sb_track() { if sbc "$1"; then click $(( C_TX + $2 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$3"; dk_park; dk_settle; else fail "no slider $1 ($3)"; fi; }
feather() { read -r _ _ _ _ _ _ _ _ F _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; echo "$F"; }
colours() { magick "$1" -format '%k' info: 2>/dev/null; }
palette_run() { dk_park; key question; wait_for 0.6 "palette"; type_text "$1"; wait_for 0.4 "filter"; key Return; wait_for 1.0 "$1"; }
select_rect() { key m; wait_for 0.5 "marquee"; drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 )); wait_for 0.5 "selection"; }
area() { # $1 label: the selection's area and around it, pointer and ants out of the way
    key ctrl+d; wait_for 0.4 "deselect"; park_mouse; wait_for 0.3 "settle"
    snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 34 )) 120 68 "$1"
}
edge_strip() { # $1 label: across the hole's left edge
    snap_region $(( CANVAS_CX - 52 )) $(( CANVAS_CY - 3 )) 24 6 "$1"
}
undo_move() { # $1 label: area() deselected (its own undo step), so Ctrl+Z twice: the deselect, the move
    key ctrl+z; wait_for 0.6 "undo the deselect"; key ctrl+z; wait_for 0.8 "undo the move"
    area "$1"
}
move_in_transform() { # the selection's body 50 px right, then Enter
    palette_run "transform scale"
    dk_drag "$CANVAS_CX" "$CANVAS_CY" $(( CANVAS_CX + 50 )) "$CANVAS_CY" 6
    key Return; wait_for 0.8 "applied"
}

info "=== Soft selection through Transform ==="
dk_begin
canvas_focus f
wait_for 0.3 "fill tool"
click $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 50 )); wait_for 0.5 "filled"
area "xf-soft-filled"; FILLED="$SNAP_RESULT"

# --- 1. Enter with no edit ----------------------------------------------------------
key m; wait_for 0.6 "marquee"; dk_park; dk_settle
sb_track 5 4 "feather ~6"
F=$(feather); (( F >= 4 && F <= 8 )) && pass "FEATHER set ($F)" || fail "FEATHER $F"
select_rect
palette_run "transform scale"
park_mouse; wait_for 0.3 "park"
screenshot "xf-soft-handles"
key Return; wait_for 0.8 "Enter, no edit"
area "xf-soft-noedit"
assert_regions_same "$FILLED" "$SNAP_RESULT" "Transform + Enter with no edit leaves a feathered selection's pixels as they were"

# --- 2. hard: FEATHER 0, moved ------------------------------------------------------
key m; wait_for 0.5 "marquee"; dk_park; dk_settle
sb_track 5 0 "feather 0"
select_rect
move_in_transform
area "xf-hard-moved"; HARDM="$SNAP_RESULT"
assert_regions_differ "$FILLED" "$HARDM" "the hard selection moved"
edge_strip "xf-hard-edge"; NH=$(colours "$SNAP_RESULT")
(( NH > 0 && NH <= 4 )) && pass "no feather: the hole's edge is hard ($NH colours)" || fail "no feather: $NH colours across the hole's edge (want <= 4)"
screenshot "xf-hard-moved"
undo_move "xf-hard-undone"
assert_regions_same "$FILLED" "$SNAP_RESULT" "Ctrl+Z puts the hard move back"

# --- 3. soft: FEATHER 6, moved ------------------------------------------------------
key m; wait_for 0.5 "marquee"; dk_park; dk_settle
sb_track 5 4 "feather ~6"
select_rect
move_in_transform
area "xf-soft-moved"; SOFTM="$SNAP_RESULT"
edge_strip "xf-soft-edge"; NS=$(colours "$SNAP_RESULT")
(( NS > NH + 2 )) && pass "feathered: the hole's edge is soft ($NS colours, hard $NH)" || fail "feathered: $NS colours across the hole's edge (hard $NH)"
assert_regions_differ "$HARDM" "$SOFTM" "the feathered move differs from the hard one"
screenshot "xf-soft-moved"
undo_move "xf-soft-undone"
assert_regions_same "$FILLED" "$SNAP_RESULT" "Ctrl+Z puts the feathered move back"
key m; wait_for 0.5 "marquee"; dk_park; dk_settle
sb_track 5 0 "feather 0"

assert_no_crash
assert_window_exists
info "=== Soft selection through Transform test done ==="
