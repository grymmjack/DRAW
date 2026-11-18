#!/bin/bash
# =============================================================================
# rec-live.sh — QA test: a lane being recorded shows it (TOOLS/ANIM-XLANE).
#
# Rick 2026-11-16: "any lane that is edited while editing can show a purple dot
# to indicate it's moving/etc. the bezier point should move with the value".
#
#   - an armed layer, its lanes open; a Move tool drag of 4 px in the
#     current lightbox pane, held:
#     recording (XLREC recOn 1), X live (bit 1), the X lane's row shows a
#     purple dot under the layer's red one (XLREC d:N dots drawn)
#   - its key moves with the value during the drag: the X row's picture changed
#   - released, 1.5 s later the dot is gone (live mask 0), the key stays
#
# Dump: XLREC recOn liveSlot liveMask slot:dot d:drawn, ANIMLBP (panes), LLN (keys), ANIMXSRC (record
# dot x), ANIMXSR r slot y (layer rows), ANIMXSLN slot lane y (lane rows).
# Fixture: a 64x16 sheet of 16x16 frames, 4 frames, one layer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LAYER_THUMBNAILS=0
# =============================================================================
info "=== Animation: a lane being recorded shows a purple dot ==="

RL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
RL_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
RL_DIR="/tmp/draw-qa-reclive-$$"
mkdir -p "$RL_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$RL_DIR/plain.png"
python3 "$RL_PY" put "$RL_DIR/plain.png" "$RL_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

rl_line() { grep -m1 "^$1 " "$RL_DUMPF" 2>/dev/null; }
rl_quick() { # the dump as it is now (no settle: the live dot is short-lived)
    hover 300 250; sleep 0.1; hover 305 252; sleep 0.15
    read -r _ REC_ON LIVE_SLOT LIVE_MASK _ <<< "$(rl_line XLREC)"
    LDRAWN=$(rl_line XLREC | tr ' ' '\n' | grep '^d:' | cut -d: -f2)
    LLN="$(rl_line LLN | cut -d' ' -f5-)"
    read -r _ XRX _ <<< "$(rl_line ANIMXSRC)"
    XRY=$(grep -m1 "^ANIMXSR 1 " "$RL_DUMPF" | cut -d' ' -f4)
    XLY=$(grep -m1 "^ANIMXSLN [0-9]* 1 " "$RL_DUMPF" | cut -d' ' -f4)
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(rl_line ANIMXS)"
    read -r _ _ A_COUNT A_CUR _ <<< "$(rl_line ANIM)"
    local p k; p=($(rl_line ANIMLBP)); PX=""; PW=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; }
    done
}
rl_read() { { wait_for 0.3 "render"; } >&2; rl_quick; }
rl_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
rl_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
rl_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
rl_s() { echo "rec $REC_ON live $LIVE_SLOT/$LIVE_MASK drawn ${LDRAWN:-?} lanes [$LLN] lane row y '${XLY:-}'"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$RL_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
rl_key ctrl+0
rl_key KP_8
rl_read
if [[ -z "$XRX" || -z "$XRY" ]]; then
    fail "start: no X-sheet record dot (x '${XRX:-}', row '${XRY:-}')"
else
    rl_cmd "arm layer for recording"
    rl_key v
    rl_key Right; rl_key Left # an X lane (a key at 0, X = 0) so the lanes have a row
    sleep 2
    # open the layer's lanes: the disclosure arrow right of the icons
    rl_read
    [[ -n "$XLY" ]] || { rl_hclick $(( XRX + 10 )) $(( XRY + XLH / 2 )); rl_read; }
    if [[ -z "$XLY" || -z "$PW" ]]; then
        fail "the X lane's row did not open / no pane for frame $A_CUR - $(rl_s)"
    else
        DOTX=$(( XRX - 4 )); DOTY=$(( XLY + XLH / 2 - 4 ))
        snap_region "$DOTX" "$DOTY" 9 9 "reclive-idle"; S0=$SNAP_RESULT
        snap_region $(( XRX + 40 )) "$XLY" 200 "$XLH" "reclive-row0"; R0=$SNAP_RESULT
        # a Move tool drag in frame 1's lightbox pane (16 px frames), held:
        # recording while the button is down. It starts on the drawing (the 4x10
        # block at 2,3 - its middle), not the pane's middle: an armed layer has
        # the transform widget, whose pivot crosshair sits at the frame's middle
        # and would take the drag (TOOLS/ANIM-XWIDGET)
        MX=$(( PX + 4 * PW / 16 )); MY=$(( PY + 8 * PH / 16 ))
        mouse_down "$MX" "$MY"; sleep 0.2
        hover $(( MX + 2 * PW / 16 )) "$MY"; sleep 0.2
        hover $(( MX + 4 * PW / 16 )) "$MY"; sleep 0.6
        snap_region "$DOTX" "$DOTY" 9 9 "reclive-live"; S1=$SNAP_RESULT
        snap_region $(( XRX + 40 )) "$XLY" 200 "$XLH" "reclive-row1"; R1=$SNAP_RESULT
        screenshot "rec-live-dot"
        HELD="$(rl_line XLREC)"; read -r _ REC_ON LIVE_SLOT LIVE_MASK _ <<< "$HELD"
        LDRAWN=$(tr ' ' '\n' <<< "$HELD" | grep '^d:' | cut -d: -f2)
        HLLN="$(rl_line LLN | cut -d' ' -f5-)"
        mouse_up; wait_for 0.4 "release"
        [[ "$REC_ON" == 1 && $(( LIVE_MASK & 2 )) != 0 && "${LDRAWN:-0}" -ge 1 ]] \
            && pass "a held Move drag on the armed layer: recording, X live, its row's dot drawn (keys [$HLLN])" \
            || fail "while held: rec '$REC_ON' live mask '$LIVE_MASK' dots drawn '${LDRAWN:-}' keys [$HLLN]"
        assert_regions_differ "$S0" "$S1" "the X lane's row shows a purple dot while it is recorded" 0
        assert_regions_differ "$R0" "$R1" "the X lane's key moves with the value during the drag" 0
        sleep 2.5
        rl_read
        snap_region "$DOTX" "$DOTY" 9 9 "reclive-after"; S2=$SNAP_RESULT
        [[ "${LIVE_MASK:-x}" == 0 && "${REC_ON:-x}" == 0 ]] && pass "released, 1.5 s on: nothing recording or live" || fail "later - $(rl_s)"
        assert_regions_same "$S0" "$S2" "1.5 s on: the dot is gone" 0
        [[ "$LLN" == *"1=0:4:"* ]] && pass "the recorded key stays (X = 4)" || fail "keys later - $(rl_s)"
    fi
fi
assert_no_crash
rm -rf "$RL_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
