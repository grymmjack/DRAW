#!/bin/bash
# =============================================================================
# rec-dots.sh — QA test: arming a layer for recording (TOOLS/ANIM-XLANE).
#
# Rick 2026-11-16: "a red dot in the layer panel, which looks like a record
# button, for each layer in the x-sheet ... in DAW it's arming an automation
# lane ... only show on the main layer panel if there are more than 1 frame".
#
#   - an animation: each layer has a record dot on its X-sheet row and in the
#     Layers panel (a faint ring: not armed, no keys)
#   - a click on the X-sheet dot arms the layer (red); again disarms it
#   - a click on the Layers panel dot arms it too
#   - the Layers panel's right-click menu: ARM FOR RECORDING, checked when
#     armed; picking it disarms
#   - the command palette's "Arm Layer for Recording" toggles it
#   - a plain picture (one frame): no dots in the Layers panel
#
# Dump: XLREC recording liveSlot liveMask slot:dot (1 ring, 2 purple keyed,
# 3 red armed); ANIMXSRC recX; ANIMXSR r slot y; LPREC x; LPGEO top rowH;
# LPMENU / LPMENUR (the layer menu: value y h checked).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LAYER_THUMBNAILS=0
# =============================================================================
info "=== Animation: arming a layer for recording (record dots) ==="

RD_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
RD_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
RD_DIR="/tmp/draw-qa-recdots-$$"
mkdir -p "$RD_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,5' -fill '#40c040' -draw 'rectangle 21,3 24,5' "PNG32:$RD_DIR/plain.png"
python3 "$RD_PY" put "$RD_DIR/plain.png" "$RD_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

rd_line() { grep -m1 "^$1 " "$RD_DUMPF" 2>/dev/null; }
rd_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(rd_line ANIM)"
    DOT=$(rd_line XLREC | tr ' ' '\n' | grep '^1:' | cut -d: -f2)
    read -r _ XRX _ <<< "$(rd_line ANIMXSRC)"
    XRY=$(grep -m1 "^ANIMXSR 1 " "$RD_DUMPF" | cut -d' ' -f4)
    read -r _ XLH _ <<< "$(rd_line ANIMXS | awk '{print $1, $18}')"
    read -r _ LPX _ <<< "$(rd_line LPREC)"
    read -r _ LPTOP LPRH _ <<< "$(rd_line LPGEO)"
    read -r _ M_OPEN _ M_X M_Y M_W _ <<< "$(rd_line LPMENU)"
}
rd_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
rd_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
rd_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
rd_menu_item() { # VALUE -> "y h checked" of that layer-menu item
    grep "^LPMENUR " "$RD_DUMPF" | awk -v v="$1" '$3 == v { print $4, $5, $6; exit }'
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$RD_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
rd_key ctrl+0
rd_key KP_8
rd_read
if [[ "$A_COUNT" != 4 || -z "$XRX" || -z "$XRY" ]]; then
    fail "start: $A_COUNT frames, X-sheet dot x '${XRX:-}' row y '${XRY:-}' [$(rd_line XLREC)]"
else
    [[ "$DOT" == 1 && "${LPX:-0}" -gt 0 ]] && pass "an animation's layer: a record dot (a ring) on the X-sheet and in the Layers panel" \
        || fail "dots at start: state '${DOT:-}' Layers panel x '${LPX:-}'"
    screenshot "rec-dots-start"

    # -- the X-sheet dot --
    rd_hclick "$XRX" $(( XRY + XLH / 2 )); rd_read
    [[ "$DOT" == 3 ]] && pass "a click on the X-sheet's dot: armed (red)" || fail "X-sheet dot click: state '${DOT:-}'"
    screenshot "rec-dots-armed"
    rd_hclick "$XRX" $(( XRY + XLH / 2 )); rd_read
    [[ "$DOT" == 1 ]] && pass "again: disarmed" || fail "X-sheet dot click 2: state '${DOT:-}'"

    # -- the Layers panel dot --
    LY=$(( LPTOP + LPRH / 2 ))
    rd_hclick "$LPX" "$LY"; rd_read
    [[ "$DOT" == 3 ]] && pass "a click on the Layers panel's dot: armed" || fail "Layers panel dot click at ($LPX, $LY): state '${DOT:-}'"

    # -- the layer menu: checked; picking it disarms --
    right_click 60 "$LY"; wait_for 0.6 "the layer menu"; rd_read
    read -r MI_Y MI_H MI_C <<< "$(rd_menu_item 2670)"
    if [[ "$M_OPEN" == -1 && -n "$MI_Y" ]]; then
        [[ "$MI_C" == -1 ]] && pass "the layer menu has ARM FOR RECORDING, checked" || fail "layer menu item not checked ($MI_C)"
        rd_hclick $(( M_X + M_W / 2 )) $(( MI_Y + MI_H / 2 )); rd_read
        [[ "$DOT" == 1 ]] && pass "picking it disarms the layer" || fail "menu pick: state '${DOT:-}'"
    else
        fail "the layer menu: open '$M_OPEN', no ARM FOR RECORDING item [$(grep '^LPMENUR ' "$RD_DUMPF" | awk '{print $3}' | tr '\n' ' ')]"
        rd_key Escape
    fi

    # -- the command palette --
    rd_palette "arm layer for recording"; rd_read
    [[ "$DOT" == 3 ]] && pass "command palette: Arm Layer for Recording arms the current layer" || fail "palette: state '${DOT:-}'"
    rd_palette "disarm all layers"; rd_read
    [[ "$DOT" == 1 ]] && pass "command palette: Disarm All Layers" || fail "palette disarm: state '${DOT:-}'"
fi
assert_no_crash

# -- a plain picture: no dots in the Layers panel --
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$RD_DIR/plain.png"
draw_launch 15
wait_for 1.5 "Picture loaded"
rd_read
[[ "${LPX:-x}" == 0 ]] && pass "a plain picture (one frame): no record dots in the Layers panel" || fail "plain picture: LPREC '${LPX:-}'"
rm -rf "$RD_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
