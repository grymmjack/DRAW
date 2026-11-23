#!/bin/bash
# =============================================================================
# canvas-recording-big.sh — QA test: canvas recording on a big canvas (TOOLS/CANVAS-REC).
# Each settled step captured a frame by flattening the whole picture and comparing it with
# the last frame; at 4096x4096 that is 64 MB a step. This test opens a 4096x4096 picture
# with three layers (CB_LAYERS=N for more), paints dabs and reads what each capture cost (dump CRECT capMs flatMs
# diffMs), and checks the frames stay small (a dab's rect, not the picture) and right:
#   1. dabs on the big canvas: one frame each, a few KB each, the capture under budget
#   2. undo / redo: a frame each, same budget
#   3. Ctrl+S, then --export-recording f.png: the last frame is the saved picture
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=FALSE CANVAS_RECORDING=TRUE CANVAS_RECORDING_MB=256
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Canvas recording: a 4096x4096 canvas ==="

CB_DIR="$(mktemp -d /tmp/draw-qa-crecbig-XXXXXX)"
magick -size 4096x4096 "xc:#808080" "PNG32:$CB_DIR/big.png"
CB_BUDGET=${CB_BUDGET:-400} # ms a capture may take here (Xvfb, software GL)

cb_read() { hover 300 250; wait_for 0.3 "render"; hover 306 252; dk_settle
    read -r _ C_ON C_PAU C_N C_B _ <<< "$(grep -m1 '^CREC ' "$DK_DUMP")"
    read -r _ T_CAP T_FLAT T_DIFF <<< "$(grep -m1 '^CRECT ' "$DK_DUMP")"; }
DX=$CANVAS_CX; DY=$CANVAS_CY
dab() { click $(( DX + $1 )) "$DY"; wait_for 0.9 "dab $1"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$CB_DIR/big.png"
draw_launch 20
wait_for 2.0 "big picture loaded"
assert_no_crash
cb_read
if [[ -z "$C_N" || -z "$T_CAP" ]]; then
    fail "no CREC / CRECT line in the dump"
else
    (( C_N == 1 )) && pass "4096x4096 opened: one frame" || fail "at open: $C_N frames"
    info "first frame (whole picture): ${T_CAP} ms (flatten $T_FLAT, compare $T_DIFF), $C_B bytes"
    for (( l = 2; l <= ${CB_LAYERS:-3}; l++ )); do key ctrl+shift+n; wait_for 0.8 "layer $l"; done
    key b; wait_for 0.3 "brush"
    cb_read; N0=$C_N; B0=$C_B; WORST=0
    for x in -40 0 40; do
        dab "$x"; cb_read
        info "dab $x: frame $C_N, capture ${T_CAP} ms (flatten $T_FLAT, compare $T_DIFF)"
        (( T_CAP > WORST )) && WORST=$T_CAP
    done
    (( C_N == N0 + 3 )) && pass "three dabs: three frames" || fail "three dabs: $N0 -> $C_N frames"
    (( C_B - B0 < 3 * 20000 )) && pass "the dab frames are small ($(( C_B - B0 )) bytes for three: a dab's rect, not the picture)" || fail "three dab frames take $(( C_B - B0 )) bytes"
    key ctrl+z; wait_for 0.9 "undo"; cb_read; (( T_CAP > WORST )) && WORST=$T_CAP
    key ctrl+y; wait_for 0.9 "redo"; cb_read; (( T_CAP > WORST )) && WORST=$T_CAP
    (( C_N == N0 + 5 )) && pass "undo / redo: a frame each" || fail "undo / redo: $C_N frames (want $(( N0 + 5 )))"
    (( WORST <= CB_BUDGET )) && pass "the slowest capture: $WORST ms (budget $CB_BUDGET)" || fail "a capture took $WORST ms (budget $CB_BUDGET)"

    key ctrl+s; wait_for 1.0 "saving"
    for (( w = 0; w < 60; w++ )); do # (a 4096x4096 PNG with its layers inside takes a while)
        [[ "$(python3 "$DRAW_ROOT/QA/fixtures/png-chunk.py" get "$CB_DIR/big.png" drRc 2>/dev/null)" =~ ^01 ]] && break
        wait_for 0.5 "still saving"
    done
    wait_for 1.0 "saved"
    info "saved after $w waits: chunks $(python3 "$DRAW_ROOT/QA/fixtures/png-chunk.py" types "$CB_DIR/big.png" 2>&1 | tr '\n' ' ' | cut -c1-200)"
    draw_quit
    draw_settle
    mkdir -p "$CB_DIR/home" "$CB_DIR/seq"
    ( cd "$DRAW_ROOT" && HOME="$CB_DIR/home" XDG_CONFIG_HOME="$CB_DIR/home/.config" XDG_DATA_HOME="$CB_DIR/home/.local/share" \
        XDG_CACHE_HOME="$CB_DIR/home/.cache" timeout --foreground -k 5 180 "$DRAW_BIN" "$CB_DIR/big.png" --export-recording "$CB_DIR/seq/f.png" </dev/null >"$CB_DIR/cli.txt" 2>&1 )
    CB_FILES=( "$CB_DIR"/seq/f_*.png )
    CB_NF=${#CB_FILES[@]}; [[ -f "${CB_FILES[0]}" ]] || CB_NF=0
    (( CB_NF == C_N )) && pass "--export-recording: $CB_NF frames" || fail "PNG sequence: $CB_NF files for $C_N frames ($(tail -2 "$CB_DIR/cli.txt" | tr '\n' ' '))"
    if (( CB_NF > 1 )); then
        ae=$(magick compare -metric AE "${CB_FILES[$(( CB_NF - 1 ))]}" "$CB_DIR/big.png" null: 2>&1 | awk '{print $1}')
        [[ "$ae" == 0 ]] && pass "the last frame is the saved picture, pixel for pixel" || fail "the last frame differs from the picture ($ae pixels)"
    fi
    draw_launch 15
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$CB_DIR"
assert_window_exists
