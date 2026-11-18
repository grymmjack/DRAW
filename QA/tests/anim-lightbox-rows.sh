#!/bin/bash
# =============================================================================
# anim-lightbox-rows.sh — QA test: the lightbox (strip / X-sheet band, the
# transport bar, the panes) keeps clear of top and bottom dock rows.
# Rick 2026-11-16: "the xsheet and the sequencer frames when xsheet is hidden
# and lightbox is there, are not being pushed down under the top most bars".
# ANIM_LB_area now starts under the top rows (DOCK_ROWS_Y1) and ends over the
# bottom rows (DOCK_ROWS_Y2), so the whole lightbox lays out in what is left.
#   - lightbox on, X-sheet off: the toolbox docked along the top -> the area's
#     top is under that row; the drawer along the bottom -> its bottom is above
#   - X-sheet on: the same for the X-sheet band
# Dump: ANIMLB shown x1 y1 x2 y2 stripY ...; ROWS full y1 y2 toph both.
# Fixture: a 256x128 sheet of 64x64 frames (7).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LIGHTBOX=1 XSHEET=0 LIGHTBOX_PANES=1 TOOLTIPS_DISABLED=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Animation: the lightbox under / over the dock rows ==="

LR_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LR_DIR="/tmp/draw-qa-lbrows-$$"
mkdir -p "$LR_DIR"
magick -size 256x128 xc:'#303040' -fill '#e06060' -draw 'rectangle 8,8 40,40' "$LR_DIR/plain.png"
LR_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,64,64,0,0,7,0,12,0,0).hex())")
python3 "$LR_PY" put "$LR_DIR/plain.png" "$LR_DIR/sheet.png" drAn "$LR_BLOB"

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LR_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
dk_begin

lb_read() { read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY _ <<< "$(grep -m1 '^ANIMLB ' "$DK_DUMP")"; }
lb_read
info "lightbox shown=$LB_SHOWN area y $LB_Y1..$LB_Y2, strip at $LB_SY"
[[ -n "$LB_SHOWN" && "$LB_SHOWN" != 0 ]] && pass "the lightbox is showing" || fail "the lightbox is not showing (ANIMLB: $(grep -m1 '^ANIMLB ' "$DK_DUMP"))"

check_rows() { # LABEL
    lb_read; dk_rows
    info "$1: rows y1 $R_Y1 y2 $R_Y2 (top $R_TOPH, bottom $R_BOTH); lightbox y $LB_Y1..$LB_Y2, strip at $LB_SY"
    if (( R_TOPH > 0 )); then
        (( LB_Y1 >= R_Y1 && LB_SY >= R_Y1 )) && pass "$1: the strip / sheet starts under the top rows ($LB_SY >= $R_Y1)" || fail "$1: the lightbox starts at $LB_Y1 (strip $LB_SY), the top rows end at $R_Y1"
    fi
    if (( R_BOTH > 0 )); then
        (( LB_Y2 <= R_Y2 )) && pass "$1: the lightbox ends over the bottom rows ($LB_Y2 <= $R_Y2)" || fail "$1: the lightbox ends at $LB_Y2, the bottom rows start at $(( R_Y2 + 1 ))"
    fi
}

dk_move toolbox band-top
check_rows "toolbox along the top"
screenshot "lightbox-rows-top"
dk_move drawer band-bottom
check_rows "drawer along the bottom too"
screenshot "lightbox-rows-both"

# the X-sheet band: the same area
key KP_8; dk_park; dk_settle
lb_read
info "after Num 8: $(grep -m1 '^ANIMLB ' "$DK_DUMP" | cut -c1-80)"
check_rows "with the X-sheet"
screenshot "lightbox-rows-xsheet"

assert_window_exists
rm -rf "$LR_DIR"
info "=== Animation: lightbox and dock rows done ==="
