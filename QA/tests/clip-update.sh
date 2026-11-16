#!/bin/bash
# =============================================================================
# clip-update.sh — QA test: Update Clip from Bin / from AnimBrush (TOOLS/CLIP,
# phase 2 K2) - the way to change a clip's cels.
#
#   - Update from Bin on a clip whose cels were picked up (no bin): refused
#   - the AnimBrush stored in bin 3, picked from it: Update from AnimBrush gives
#     the clip a new source that remembers bin 3 (CLIPS ... bin 3)
#   - Duplicate Layer: both clip layers share that source
#   - a 2-cel AnimBrush stored over bin 3: Update from Bin gives both clips the
#     2 cels (.12121), every frame's pixels; one Ctrl+Z puts both back (.12341)
#   - Update from AnimBrush with the 2-cel AnimBrush: .12121; Ctrl+Z back
#
# Dump: CLIP / CLIPC / CLIPX / CLIPS (clip-lib.sh), ABBIN slot:n:cw:ch:crc,
# DRAWERL / DRAWERR (the bin grid).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0 ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: Update Clip from Bin / from AnimBrush ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
cu_srcs() { grep '^CLIP ' "$CL_DUMPF" | awk '{print $3}' | tr '\n' ' ' | sed 's/ $//'; } # every clip layer's source
cu_cels() { grep '^CLIPC ' "$CL_DUMPF" | awk '{print $3}' | tr '\n' ' ' | sed 's/ $//'; }
cu_src_line() { grep -m1 "^CLIPS $1 " "$CL_DUMPF" | cut -d' ' -f3-; } # n cw ch bin name
cu_bin() { grep -m1 '^ABBIN' "$CL_DUMPF" | tr ' ' '\n' | grep "^$1:" ; }
cu_bin_xy() { # centre of bin N (BX BY); 1 = not showing
    local cols vis cx cy bw bh gx gy row0 i r c
    read -r _ cols _ vis _ _ _ cx cy bw bh gx gy _ <<< "$(cl_line DRAWERL)"
    read -r _ row0 _ <<< "$(cl_line DRAWERR)"
    [[ -n "$cols" ]] || return 1
    i=$(( $1 - 1 )); r=$(( i / cols - row0 )); c=$(( i % cols ))
    (( r >= 0 && r < vis )) || return 1
    BX=$(( cx + c * (bw + gx) + bw / 2 )); BY=$(( cy + r * (bh + gy) + bh / 2 ))
}
cu_pickup2() { # a 2-cel AnimBrush from Layer 1's frames 3-4
    click 60 "$(cl_row_y "$1")"; wait_for 0.5 "Layer 1"
    cl_strip 4; cl_strip 3 shift; cl_read
    cl_key m
    mouse_down "$(cl_px 6)" "$(cl_py 6)"; hover "$(cl_px 8)" "$(cl_py 8)"; sleep 0.2; hover "$(cl_px 9)" "$(cl_py 9)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    cl_cmd "animbrush: pick up (the"; cl_key ctrl+d; cl_read
}

cl_setup
if (( CL_OK )); then
    pass "a clip of 4 picked-up cels in frame 2"
    [[ "$(cu_src_line 1)" == "4 4 4 0 "* ]] && pass "its source remembers no bin" || fail "CLIPS 1 [$(cu_src_line 1)]"

    # -- from Bin with no bin: refused --
    cl_cmd "clip layer: update clip from bin"; cl_read
    [[ "$C_SRC" == 1 && "$C_CELS" == ".12341" ]] && pass "Update from Bin on picked-up cels: refused, nothing changed" || fail "no-bin update: $(cl_s)"

    # -- store the AnimBrush in bin 3, pick it from there, Update from AnimBrush --
    if cu_bin_xy 3; then
        with_mods shift click "$BX" "$BY"; wait_for 0.6 "store"
        click "$BX" "$BY"; wait_for 0.6 "pick bin 3"; cl_read
        [[ "$(cu_bin 3)" == 3:4:4:4:* && "$AB_N" == 4 ]] && pass "the AnimBrush stored in bin 3 and picked from it" || fail "bin 3 [$(cu_bin 3)], brush n $AB_N"
        click 60 "$(cl_row_y 1)"; wait_for 0.5 "the clip layer"
        cl_cmd "clip layer: update clip from animbrush"; cl_read
        [[ "$C_SRC" == 2 && "$C_CELS" == ".12341" && "$(cu_src_line 2)" == "4 4 4 3 "* ]] \
            && pass "Update from AnimBrush: a new source that remembers bin 3, same cels" \
            || fail "update from the bin's AnimBrush: $(cl_s); CLIPS 2 [$(cu_src_line 2)]"

        # -- a second clip layer on the same source --
        cl_cmd "duplicate layer"; cl_read
        [[ "$(cu_srcs)" == "2 2" ]] && pass "Duplicate Layer: two clip layers on source 2" || fail "after duplicate: sources [$(cu_srcs)]"

        # -- a 2-cel AnimBrush over bin 3, Update from Bin --
        cu_pickup2 3
        [[ "$AB_N" == 2 ]] || fail "2-cel pick up: brush n $AB_N"
        cu_bin_xy 3 && { with_mods shift click "$BX" "$BY"; wait_for 0.6 "store over bin 3"; }
        cl_read
        [[ "$(cu_bin 3)" == 3:2:4:4:* ]] && pass "bin 3 now holds the 2-cel AnimBrush" || fail "bin 3 [$(cu_bin 3)]"
        click 60 "$(cl_row_y 1)"; wait_for 0.5 "a clip layer"
        cl_cmd "clip layer: update clip from bin"; cl_read
        [[ "$(cu_srcs)" == "3 3" && "$(cu_cels)" == ".12121 .12121" && "$(cu_src_line 3)" == "2 4 4 3 "* ]] \
            && pass "Update from Bin: both clip layers show the bin's 2 cels" \
            || fail "update from bin: sources [$(cu_srcs)] cels [$(cu_cels)] CLIPS 3 [$(cu_src_line 3)]"
        cl_expect ".12121" 6 6 0 "Update from Bin: the pixels in every frame"
        screenshot "clip-update-from-bin"
        cl_key ctrl+z; cl_read
        [[ "$(cu_srcs)" == "2 2" && "$(cu_cels)" == ".12341 .12341" ]] && pass "one Ctrl+Z puts both clip layers back" \
            || fail "undo update from bin: sources [$(cu_srcs)] cels [$(cu_cels)]"
        cl_expect ".12341" 6 6 0 "Ctrl+Z: the pixels back"

        # -- Update from AnimBrush with the 2-cel AnimBrush --
        cl_key b
        cl_cmd "clip layer: update clip from animbrush"; cl_read
        [[ "$(cu_cels)" == ".12121 .12121" ]] && pass "Update from AnimBrush: the 2 cels" || fail "update from the 2-cel AnimBrush: cels [$(cu_cels)] $(cl_s)"
        cl_key ctrl+z; cl_read
        [[ "$(cu_cels)" == ".12341 .12341" ]] && pass "Ctrl+Z: 4 cels again" || fail "undo update from AnimBrush: cels [$(cu_cels)]"
    else
        fail "bin 3 is not showing: $(cl_line DRAWERL) | $(cl_line DRAWERR)"
    fi
fi
cl_done
info "=== Clip layers: Update Clip: done ==="
