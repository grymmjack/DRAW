#!/bin/bash
# =============================================================================
# clip-guards.sh — QA test: clip layers are never changed as pixels, and move
# as clips (TOOLS/CLIP, phase 2 K1).
#
#   - Image > Desaturate on a clip layer: refused, its pixels unchanged
#   - two layers selected (the clip + a pixel layer): Desaturate changes the
#     pixel layer only (IMAGE_ADJ_collect_targets skips clip layers)
#   - sheet view (lightbox off): V + drag + Enter moves the clip, every frame (the
#     press lands on the box's corner handle: a clip moves, never scales);
#     Ctrl+Z puts it back
#   - both layers selected, V + drag + Enter: the pixel layer's drawing moves
#     and the clip moves as a clip; one Ctrl+Z puts both back
#
# Dump: CLIP / CLIPX (clip-lib.sh), ANIMC (the pixel layer's cells), VIEW, ANIM (dx dy).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: guards and moves ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
cl_animc() { cl_line ANIMC | cut -d' ' -f2-; }

cl_setup
if (( CL_OK )); then
    pass "a clip placed in frame 2"
    cl_read; P0="$C_PIX"; B0=$(cl_animc)

    # -- an Image command on the clip layer: refused --
    cl_cmd "desaturate"; cl_read
    [[ "$C_PIX" == "$P0" && "$(cl_animc)" == "$B0" ]] && pass "Desaturate on a clip layer: refused, nothing changed" \
        || fail "desaturate on the clip: pixels [$C_PIX] (were [$P0]), base [$(cl_animc)] (was [$B0])"

    # -- the clip + Layer 1 selected: only Layer 1 changes --
    with_mods ctrl click 60 "$(cl_row_y 2)"; wait_for 0.5 "multi-select"
    cl_cmd "desaturate"; cl_read
    B1=$(cl_animc)
    [[ "$C_PIX" == "$P0" && "$B1" != "$B0" ]] && pass "two layers selected: Desaturate changed the pixel layer, not the clip" \
        || fail "desaturate on both: clip [$C_PIX] (want [$P0]); base changed: $([[ "$B1" != "$B0" ]] && echo yes || echo no)"
    cl_key ctrl+z; cl_read
    [[ "$(cl_animc)" == "$B0" ]] && pass "Ctrl+Z: Layer 1 back" || fail "undo desaturate: base [$(cl_animc)] want [$B0]"

    # -- sheet view: the clip layer alone, V + drag + Enter --
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "select the clip layer"
    cl_key KP_0; cl_read
    [[ "$CP_CUR" != 0 ]] || fail "the clip layer is not current: $(cl_s)"
    cl_key v
    mouse_down "$(cl_cx 23)" "$(cl_cy 7)"; hover "$(cl_cx 24)" "$(cl_cy 8)"; sleep 0.2; hover "$(cl_cx 25)" "$(cl_cy 8)"; sleep 0.4
    mouse_up; wait_for 0.5 "dragged"
    cl_key Return; cl_read
    [[ "$C_PX $C_PY" == "8 7" ]] && pass "sheet view: V + drag + Enter moved the clip 2 right, 1 down" || fail "sheet-view move: $(cl_s)"
    cl_expect ".12341" 8 7 0 "sheet view: its pixels moved in every frame"
    cl_key ctrl+z; cl_read
    [[ "$C_PX $C_PY" == "6 6" ]] && pass "Ctrl+Z: back at (6, 6)" || fail "undo sheet-view move: $(cl_s)"
    cl_expect ".12341" 6 6 0 "Ctrl+Z: its pixels back"

    # -- both layers selected: a linked move --
    cl_key b
    with_mods ctrl click 60 "$(cl_row_y 2)"; wait_for 0.5 "multi-select"
    cl_key v
    mouse_down "$(cl_cx 23)" "$(cl_cy 7)"; hover "$(cl_cx 24)" "$(cl_cy 7)"; sleep 0.2; hover "$(cl_cx 26)" "$(cl_cy 7)"; sleep 0.4
    mouse_up; wait_for 0.5 "dragged"
    cl_key Return; cl_read
    B2=$(cl_animc)
    [[ "$C_PX $C_PY" == "9 6" && "$B2" != "$B0" ]] && pass "both selected: the clip moved as a clip (x 9) and Layer 1's drawing moved" \
        || fail "linked move: $(cl_s); base changed: $([[ "$B2" != "$B0" ]] && echo yes || echo no)"
    cl_expect ".12341" 9 6 0 "linked move: the clip's pixels in every frame"
    cl_key ctrl+z; cl_read
    [[ "$C_PX $C_PY" == "6 6" && "$(cl_animc)" == "$B0" ]] && pass "one Ctrl+Z puts both back" \
        || fail "undo linked move: $(cl_s); base [$(cl_animc)] want [$B0]"
    screenshot "clip-guards-end"
fi
cl_done
info "=== Clip layers: guards and moves: done ==="
