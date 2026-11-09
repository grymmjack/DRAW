#!/bin/bash
# =============================================================================
# anim-lightbox-overlays.sh — QA test: the marquee stays drawn in its frame's
# pane when the pointer moves to another pane (field kit R-27, 2026-11-09:
# "when i hover the pointer off the frame the marquee disappears"), and the
# grids show in the panes (R-32: "I cannot see the grid").
#
# The marching ants were drawn only through the pane under the pointer; they
# now go through every pane (each clips to its own picture). The grids were
# never drawn in the lightbox; VIEW > GRID / the pixel grid now draw over
# every pane, lined up with the sheet.
#
# Dump: ANIMLBP (per pane: frame dx dy dw dh), ANIM.
# Fixture: 4 frames of 16x16 (a square in each), current 2, 3 panes (1 2 3).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 XSHEET=0 LIGHTBOX_PANES=3
# =============================================================================
info "=== Animation: the marquee and the grids in the lightbox panes ==="

LV_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LV_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LV_DIR="/tmp/draw-qa-lboverlays-$$"
mkdir -p "$LV_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 3,3 12,12' -fill '#40c040' -draw 'rectangle 19,3 28,12' \
    -fill '#4040c0' -draw 'rectangle 35,3 44,12' -fill '#c0c040' -draw 'rectangle 51,3 60,12' "PNG32:$LV_DIR/plain.png"
LV_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,2,12,0,0).hex())")
python3 "$LV_PY" put "$LV_DIR/plain.png" "$LV_DIR/sheet.png" drAn "$LV_BLOB"

lv_line() { grep -m1 "^$1 " "$LV_DUMP" 2>/dev/null; }
lv_panes() { # P1X.. P2X..: the panes of frames 1 and 2
    local p k; p=($(lv_line ANIMLBP)); P1X=""; P2X=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == 1 ]] && { P1X=${p[$((k + 1))]}; P1Y=${p[$((k + 2))]}; P1W=${p[$((k + 3))]}; P1H=${p[$((k + 4))]}; }
        [[ "${p[$k]}" == 2 ]] && { P2X=${p[$((k + 1))]}; P2Y=${p[$((k + 2))]}; P2W=${p[$((k + 3))]}; P2H=${p[$((k + 4))]}; }
    done
}
lv_on1() { hover $(( P1X + P1W / 2 )) $(( P1Y + P1H / 2 )); sleep 0.3; hover $(( P1X + P1W / 2 + 2 )) $(( P1Y + P1H / 2 + 2 )); wait_for 0.4 "pointer on frame 1's pane"; }
lv_snap2() { snap_region "$P2X" "$P2Y" "$P2W" "$P2H" "$1"; }
lv_px() { echo $(( P2X + (2 * $1 + 1) * P2W / 32 )); }
lv_py() { echo $(( P2Y + (2 * $1 + 1) * P2H / 32 )); }
lv_palette() { park_mouse; key question; wait_for 1.0 "Command palette"; type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LV_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key b; wait_for 0.3 "Brush"
{ hover 300 250; wait_for 0.2 "render"; } >&2
read -r _ LB_SHOWN _ <<< "$(lv_line ANIMLB)"
[[ "${LB_SHOWN:-}" == -1 ]] || { park_mouse; key KP_0; wait_for 0.8 "Lightbox"; }
{ hover 300 250; wait_for 0.2 "render"; } >&2
lv_panes
if [[ -z "$P1X" || -z "$P2X" ]]; then
    fail "panes for frames 1 and 2: '$(lv_line ANIMLBP)'"
else
    pass "panes: frame 1 at $P1X,$P1Y, frame 2 (current) at $P2X,$P2Y"
    # -- the grids: frame 2's pane with the pixel grid off, then VIEW > GRID on --
    lv_palette "toggle pixel grid"
    lv_on1; lv_snap2 "lbov-nogrid" && cp "$SNAP_RESULT" "$LV_DIR/nogrid.png"
    lv_palette "toggle grid"
    lv_on1; lv_snap2 "lbov-grid" && cp "$SNAP_RESULT" "$LV_DIR/grid.png"
    [[ -f "$LV_DIR/nogrid.png" && -f "$LV_DIR/grid.png" ]] && assert_regions_differ "$LV_DIR/nogrid.png" "$LV_DIR/grid.png" "VIEW > GRID on: the grid shows in the pane"
    lv_palette "toggle grid"

    # -- a marquee in frame 2's pane, the pointer then on frame 1's pane --
    lv_on1; lv_snap2 "lbov-nosel" && cp "$SNAP_RESULT" "$LV_DIR/nosel.png"
    park_mouse; key m; wait_for 0.4 "Marquee tool"
    hover "$(lv_px 2)" "$(lv_py 2)"; sleep 0.5
    mouse_down "$(lv_px 2)" "$(lv_py 2)"; sleep 0.2
    hover "$(lv_px 6)" "$(lv_py 6)"; sleep 0.2
    hover "$(lv_px 13)" "$(lv_py 13)"; sleep 0.5
    mouse_up; wait_for 0.8 "marquee released"
    lv_on1; lv_snap2 "lbov-sel" && cp "$SNAP_RESULT" "$LV_DIR/sel.png"
    [[ -f "$LV_DIR/nosel.png" && -f "$LV_DIR/sel.png" ]] && assert_regions_differ "$LV_DIR/nosel.png" "$LV_DIR/sel.png" "a marquee in frame 2, the pointer on frame 1's pane: frame 2's pane still shows it"
fi
screenshot "anim-lightbox-overlays"
assert_no_crash
rm -rf "$LV_DIR"
