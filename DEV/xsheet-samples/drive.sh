#!/bin/bash
# =============================================================================
# DEV/xsheet-samples/drive.sh - builds the X-sheet holds + lanes examples
# (SAMPLES/XSHEET/) in DRAW the way a user would: opens each NAME.draw (made by
# build.sh from make-art.py's Aseprite file - layers, groups, holds), then for
# every lane in NAME's spec opens the layer's lanes on the X-sheet, + LANE,
# double-clicks the frames to key them, types each value, sets each ease from
# the key's menu, adds a modulator (amount / period typed) - reads every lane
# back from the QA dump (LLN) - and saves (Ctrl+S).
#
# Copied into QA/tests as zz-xsheet-samples.sh by build.sh and run by the
# harness. Env: XS_DIR (the folder with the NAME.draw files), XS_NAMES.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
XS_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
xs_line() { grep -m1 "^$1 " "$XS_DUMPF" 2>/dev/null; }
xs_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.3 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(xs_line ANIM)"
    XF=($(xs_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(xs_line ANIMXS)"
    XM=($(xs_line ANIMXLM))
    mapfile -t XROWS < <(grep '^ANIMXSLO ' "$XS_DUMPF" 2>/dev/null | cut -d' ' -f2-)   # slot open x y, top row first
}
xs_key() { # (a chord to an idle DRAW can lose its Ctrl - one key a frame, Ctrl read live - so wake it first)
    park_mouse; [[ "$1" == *+* ]] && wake_draw; key "$1"; wait_for 0.6 "$1"
}
xs_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
xs_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
xs_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
xs_pick() { # VALUE - click that item of the open menu
    local iy; iy=$(xs_item "$1")
    [[ -z "$iy" ]] && { info "no item $1 in [${XM[*]}]"; xs_key Escape; return 1; }
    xs_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); xs_read
}
xs_row() { echo "${XROWS[$(( $1 - 1 ))]}"; }                   # ROW (1 = top) -> "slot open x y"
xs_lane_y() { grep -m1 "^ANIMXSLN $1 $2 " "$XS_DUMPF" 2>/dev/null | cut -d' ' -f4; }   # SLOT LANE
xs_add_y() { grep -m1 "^ANIMXSLA $1 " "$XS_DUMPF" 2>/dev/null | cut -d' ' -f3; }       # SLOT
xs_lln() { grep "^LLN " "$XS_DUMPF" 2>/dev/null | awk -v s="$1" '$4 == s' | head -1; } # SLOT
xs_lane_now() { xs_lln "$1" | tr ' ' '\n' | grep "^$2=" | sed "s/^$2=//"; }           # SLOT LANE -> keys[~]
xs_type() { # TEXT - into the open input box
    type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $1"; xs_read
}
xs_toggle() { # ROW WANT(0 closed / -1 open)
    local s o x y
    read -r s o x y <<< "$(xs_row "$1")"
    [[ "$o" == "$2" ]] && return 0
    xs_hclick $(( x + 4 )) $(( y + XLH / 2 )); xs_read
}

# xs_lane ROW LANE "f:value:ease ..." [MOD AMOUNT PERIOD] - one lane on the layer at X-sheet row ROW.
# ease 0 linear 1 in 2 out 3 in-out 4 hold; MOD 1-4 LFO sine / triangle / square / saw, 5 noise.
xs_lane() {
    local row=$1 L=$2 keys=$3 mod=${4:-0} amt=${5:-} per=${6:-}
    local s o x y k f v e ly ym ay want=""
    xs_read; xs_toggle "$row" -1
    read -r s o x y <<< "$(xs_row "$row")"
    ay=$(xs_add_y "$s")
    [[ -z "$ay" ]] && { fail "row $row (slot $s): no + LANE row"; return 1; }
    xs_hclick "$(xs_fmid 1)" $(( ay + XLH / 2 )); xs_read
    xs_pick $(( 31100 + L )) || { fail "slot $s: + LANE > $L"; return 1; }
    for k in $keys; do
        IFS=: read -r f v e <<< "$k"
        ly=$(xs_lane_y "$s" "$L"); ym=$(( ly + XLH / 2 ))
        [[ "$(xs_fmid "$f")" == 0 ]] && { fail "slot $s lane $L: frame $f not on the X-sheet"; return 1; }
        if [[ "$f" != 1 ]]; then double_click "$(xs_fmid "$f")" "$ym"; wait_for 0.7 "add key"; xs_read; fi
        double_click "$(xs_fmid "$f")" "$ym"; wait_for 0.9 "input box"
        xs_type "$v"
        right_click "$(xs_fmid "$f")" "$ym"; wait_for 0.6 "key menu"; xs_read
        xs_pick $(( 31001 + e )) || { fail "slot $s lane $L frame $f: ease $e"; return 1; }
        want+=",$(( f - 1 )):$v:$e"
    done
    want=${want#,}
    if (( mod > 0 )); then
        ly=$(xs_lane_y "$s" "$L"); ym=$(( ly + XLH / 2 ))
        right_click "$(xs_fmid 1)" "$ym"; wait_for 0.6 "lane menu"; xs_read
        xs_pick $(( 31020 + mod )) || { fail "slot $s lane $L: modulator $mod"; return 1; }
        if [[ -n "$amt" ]]; then
            right_click "$(xs_fmid 1)" "$ym"; wait_for 0.6 "lane menu"; xs_read
            xs_pick 31040 && { wait_for 0.6 "input box"; xs_type "$amt"; }
        fi
        if [[ -n "$per" ]]; then
            right_click "$(xs_fmid 1)" "$ym"; wait_for 0.6 "lane menu"; xs_read
            xs_pick 31041 && { wait_for 0.6 "input box"; xs_type "$per"; }
        fi
        want+="~"
    fi
    local got; got=$(xs_lane_now "$s" "$L")
    [[ "$got" == "$want" ]] && pass "slot $s lane $L: $got" || fail "slot $s lane $L: got '$got' want '$want'"
}
xs_close() { xs_read; xs_toggle "$1" 0; }

xs_open() { # NAME - open NAME.draw, the X-sheet on
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$XS_DIR/$1.draw"
    draw_launch 15
    wait_for 1.5 "$1 loaded"
    assert_no_crash
    xs_key ctrl+0
    xs_key KP_8
    xs_read
    [[ "$A_COUNT" == 12 && ${#XROWS[@]} -ge 2 ]] && pass "$1: 12 frames, ${#XROWS[@]} X-sheet rows" || { fail "$1: frames '$A_COUNT', rows '${XROWS[*]}'"; return 1; }
}
xs_save() { # NAME
    xs_key ctrl+s; wait_for 1.5 "saved"
    python3 "$DRAW_ROOT/QA/fixtures/png-chunk.py" get "$XS_DIR/$1.draw" drLL >/dev/null 2>&1 \
        && pass "$1: saved with its lanes (drLL)" || fail "$1: no drLL chunk after Ctrl+S"
    screenshot "xsheet-sample-$1"
}

for XS_NAME in ${XS_NAMES:-bounce parallax title}; do
    info "=== X-sheet sample: $XS_NAME ==="
    xs_open "$XS_NAME" || continue
    case "$XS_NAME" in
        bounce) # rows: ball, floor
            xs_lane 1 2 "1:-16:1 6:0:0 7:0:2 12:-14:0"         # Y: falls (ease in), floor, rises (ease out)
            xs_lane 1 3 "1:100:0 5:100:0 6:125:4 7:100:0"      # SCALE X: wide on the floor (a HOLD step)
            xs_lane 1 4 "1:100:0 5:100:0 6:70:4 7:100:0"       # SCALE Y: squashed on the floor
            xs_lane 1 9 "1:29:0"                               # PIVOT Y: the ball's bottom, so it squashes onto the floor
            xs_close 1
            ;;
        parallax) # rows: bird, scenery (group), trees, hills, sky
            xs_lane 1 1 "1:-14:3 12:12:0"                      # bird X: across, ease in-out
            xs_lane 1 2 "1:0:0" 1 2 6                          # bird Y: LFO sine, 2 px, 6 frames
            xs_close 1
            xs_lane 2 1 "1:0:0 12:-6:0"                        # the scenery group drifts left 6 px
            xs_close 2
            xs_lane 3 1 "1:0:0 12:-6:0"                        # the trees 6 more (12 in all: nearer, faster)
            xs_close 3
            ;;
        title) # rows: card (group), star, plate, bg
            xs_lane 1 6 "1:0:3 4:100:0 10:100:3 12:0:0"        # the card fades in and out (the whole group)
            xs_close 1
            xs_lane 2 5 "1:0:0 12:330:0"                       # the star spins
            xs_lane 2 3 "1:30:2 6:100:0"                       # and grows (ease out)
            xs_lane 2 4 "1:30:2 6:100:0"
            xs_close 2
            xs_lane 3 7 "1:30:0" 5 40 2                        # the plate flickers toward white (TINT noise)
            xs_close 3
            ;;
    esac
    xs_save "$XS_NAME"
done
assert_no_crash
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
