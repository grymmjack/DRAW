#!/bin/bash
# =============================================================================
# sel-soft-clear.sh — QA test: soft selections (PLANS/AA-SELECTIONS.md). A
# feathered selection's Delete leaves a soft edge (the partly selected pixels
# keep the unselected share of their alpha); with no feather the edge stays
# hard - the pixel-art default is unchanged.
#   1. fill the layer, a rectangle selection with FEATHER 0, Delete: across the
#      hole's edge only the fill and the checkerboard's two greys
#   2. refill, FEATHER 6, the same rectangle, Delete: in-between colours across the
#      edge (the fill blended over the checkerboard)
#   3. an empty layer, FEATHER 6, the rectangle: the fill tool inside it, then a
#      filled rectangle over it - both leave a soft edge (fill / rect honour the
#      selection's coverage: SEL_put_px)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_FEATHER=0 SELECTION_MODE=REPLACE SELECTION_BAR=TRUE ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
sb_track() { if sbc "$1"; then click $(( C_TX + $2 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$3"; dk_park; dk_settle; else fail "no slider $1 ($3)"; fi; }
feather() { read -r _ _ _ _ _ _ _ _ F _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; echo "$F"; }
colours() { magick "$1" -format '%k' info: 2>/dev/null; }

info "=== Soft selection: Delete through a feathered selection ==="
dk_begin

# a filled layer
canvas_focus f
wait_for 0.3 "fill tool"
key grave
click $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 50 )); wait_for 0.5 "filled"
assert_no_crash

edge_strip() { # $1 label: a strip across the hole's left edge, pointer and ants out of the way
    key ctrl+d; wait_for 0.4 "deselect"; park_mouse; wait_for 0.3 "settle"
    snap_region $(( CANVAS_CX - 52 )) $(( CANVAS_CY - 3 )) 24 6 "$1"
}

# --- hard: FEATHER 0 -------------------------------------------------------------
key m; wait_for 0.6 "marquee"; dk_park; dk_settle
(( $(feather) == 0 )) && pass "FEATHER starts at 0" || fail "FEATHER $(feather)"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 )); wait_for 0.5 "selection"
key Delete; wait_for 0.5 "cleared"
edge_strip "soft-hard-edge"; HARD="$SNAP_RESULT"; NH=$(colours "$HARD")
(( NH > 0 && NH <= 4 )) && pass "no feather: a hard edge ($NH colours across it)" || fail "no feather: $NH colours across the edge (want <= 4)"
screenshot "soft-hard"
# refill the hole (an undo would bring back the deselected selection first)
key f; wait_for 0.4 "fill tool"
click "$CANVAS_CX" "$CANVAS_CY"; wait_for 0.5 "refilled"
key m; wait_for 0.6 "marquee"

# --- soft: FEATHER 6 --------------------------------------------------------------
dk_park; dk_settle
sb_track 5 4 "feather ~6"
F=$(feather); (( F >= 4 && F <= 8 )) && pass "FEATHER set ($F)" || fail "FEATHER $F"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 )); wait_for 0.5 "selection"
key Delete; wait_for 0.5 "cleared"
edge_strip "soft-soft-edge"; SOFT="$SNAP_RESULT"; NS=$(colours "$SOFT")
(( NS > NH + 2 )) && pass "feathered: a soft edge ($NS colours across it, hard $NH)" || fail "feathered: $NS colours across the edge (hard $NH)"
assert_regions_differ "$HARD" "$SOFT" "the feathered hole's edge differs from the hard one"
screenshot "soft-soft"

# --- the fill tool and a filled rectangle inside a feathered selection --------------
# an empty layer: select all, Delete
key ctrl+a; wait_for 0.4 "select all"; key Delete; wait_for 0.5 "cleared"; key ctrl+d; wait_for 0.4 "deselect"
key m; wait_for 0.6 "marquee"; dk_park; dk_settle
F=$(feather); (( F >= 4 )) || { sb_track 5 4 "feather ~6"; F=$(feather); }
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 )); wait_for 0.5 "selection"
key f; wait_for 0.4 "fill tool"
click "$CANVAS_CX" "$CANVAS_CY"; wait_for 0.6 "filled inside"
edge_strip "soft-fill-edge"; NF=$(colours "$SNAP_RESULT")
(( NF > NH + 2 )) && pass "fill in a feathered selection: a soft edge ($NF colours, hard $NH)" || fail "fill in a feathered selection: $NF colours across the edge (hard $NH)"
screenshot "soft-fill"
key ctrl+z; wait_for 0.6 "undo the fill"
key m; wait_for 0.6 "marquee"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 )); wait_for 0.5 "selection"
key shift+r; wait_for 0.4 "filled rectangle"
drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 40 )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY + 40 )); wait_for 0.6 "rectangle over the selection"
edge_strip "soft-rect-edge"; NR=$(colours "$SNAP_RESULT")
(( NR > NH + 2 )) && pass "a filled rectangle in a feathered selection: a soft edge ($NR colours, hard $NH)" || fail "filled rectangle in a feathered selection: $NR colours across the edge (hard $NH)"
screenshot "soft-rect"
key m; wait_for 0.6 "marquee"; dk_park; dk_settle
sb_track 5 0 "feather 0"

assert_no_crash
assert_window_exists
info "=== Soft selection test done ==="
