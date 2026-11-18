#!/bin/bash
# =============================================================================
# key-glyphs.sh — QA test: a lane key's glyph shows its ease.
#
# Rick 2026-11-16: "for keyframes that have ease an indicator on the keyframe
# type: diamond = normal keyframe, ease in = [> , ease out = <], ease both =
# ( ) circle? possible?" (hold: a square - my pick).
#
#   - an armed layer, X keys (all X = 1) on frames 1-5; the key menu sets
#     frame 2 Ease In, 3 Ease Out, 4 Ease In-Out, 5 Hold: LLN carries the eases
#   - the five glyphs on the X row all differ from each other (pixel snaps at
#     each key), and a zoomed screenshot to judge the shapes by eye
#
# Dump: LLN (lane=frame:value:ease), ANIMXSF (frames: f x w), ANIMXSLN slot
# lane y, ANIMXS (layH), ANIMXLM (the open lane menu: x y w, value y ...), ANIM.
# Fixture: a 96x16 sheet of 16x16 frames, 6 frames, one layer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LAYER_THUMBNAILS=0 XSHEET_FIT_ALL=TRUE
# =============================================================================
info "=== Animation: key glyphs by ease ==="

KG_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
KG_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
KG_DIR="/tmp/draw-qa-kglyph-$$"
mkdir -p "$KG_DIR"
magick -size 96x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$KG_DIR/plain.png"
python3 "$KG_PY" put "$KG_DIR/plain.png" "$KG_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

kg_line() { grep -m1 "^$1 " "$KG_DUMPF" 2>/dev/null; }
kg_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(kg_line ANIM)"
    LLN="$(kg_line LLN | cut -d' ' -f5-)"
    XF=($(kg_line ANIMXSF))
    XM=($(kg_line ANIMXLM))
    XLY=$(grep -m1 "^ANIMXSLN [0-9]* 1 " "$KG_DUMPF" | cut -d' ' -f4)
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(kg_line ANIMXS)"
    read -r _ XRX _ <<< "$(kg_line ANIMXSRC)"
    XRY=$(grep -m1 "^ANIMXSR 1 " "$KG_DUMPF" | cut -d' ' -f4)
}
kg_fx() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
kg_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
kg_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
kg_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
kg_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
kg_ease() { # FRAME EASE - the X key's menu on that frame, pick the ease
    local iy
    right_click "$(kg_fx "$1")" $(( XLY + XLH / 2 )); wait_for 0.6 "key menu"; kg_read
    iy=$(kg_item $(( 31001 + $2 )))
    if [[ -z "$iy" ]]; then echo "no ease item in [${XM[*]}]" >&2; kg_key Escape; return 1; fi
    kg_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); kg_read
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$KG_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
kg_key ctrl+0
kg_key KP_8
kg_read
if [[ "$A_COUNT" != 6 || -z "$XRX" ]]; then
    fail "start: $A_COUNT frames, X-sheet dot '${XRX:-}'"
else
    kg_cmd "arm layer for recording"
    kg_key v
    kg_key Right                                   # frame 1: X = 1
    for _ in 2 3 4 5; do kg_key KP_5; kg_key Right; kg_key Left; done # frames 2-5: a key, X = 1
    kg_read
    [[ -n "$XLY" ]] || { kg_hclick $(( XRX + 10 )) $(( XRY + XLH / 2 )); kg_read; }
    kg_ease 2 1 && kg_ease 3 2 && kg_ease 4 3 && kg_ease 5 4
    if [[ "$LLN" != *"1=0:1:0,1:1:1,2:1:2,3:1:3,4:1:4"* ]]; then
        fail "keys with eases 0-4 on frames 1-5: [$LLN]"
    else
        pass "X keys on frames 1-5 with eases linear / in / out / in-out / hold"
        kg_cmd "disarm all layers" # (the picked-row highlight off the keys)
        kg_read
        declare -a G
        for f in 1 2 3 4 5; do
            snap_region $(( $(kg_fx $f) - 5 )) $(( XLY + XLH / 2 - 5 )) 11 11 "kglyph-$f"; G[$f]=$SNAP_RESULT
        done
        screenshot "key-glyphs"
        names=(x linear in out in-out hold)
        for a in 1 2 3 4; do
            for (( b = a + 1; b <= 5; b++ )); do
                assert_regions_differ "${G[$a]}" "${G[$b]}" "the ${names[$a]} and ${names[$b]} keys look different" 0
            done
        done
    fi
fi
assert_no_crash
rm -rf "$KG_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
