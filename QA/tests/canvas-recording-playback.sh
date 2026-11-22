#!/bin/bash
# =============================================================================
# canvas-recording-playback.sh — QA test: a drawing session recorded and played back
# (TOOLS/CANVAS-REC; Rick 2026-11-22: "make a recording of yourself drawing something -
# make it a test for playback").
#   1. paint a little scene step by step on a blank 160x100 picture: sky (fill), ground,
#      sun, a house (walls, a roof of three lines + fill, door, windows), a tree, birds,
#      grass - fill, filled rectangle / ellipse, line and brush; one frame each
#   2. Ctrl+S: the recording rides in the PNG (drRc)
#   3. DRAW pic.png --export-recording out.png (a PNG sequence): one file per frame; the
#      first is the blank picture, the last is the saved picture pixel for pixel, and every
#      frame differs from the one before (each is one step of the drawing)
#   4. --export-recording out.apng --recording-fps 8 --recording-scale 2: an animated PNG
#      (acTL frame count = the recording's, IHDR 320x200, plays once)
# The time-lapse is kept beside the screenshots (canvas-recording-playback.apng / .gif).
# Dump: CREC (see canvas-recording.sh), VIEW zoom offX offY tool.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=FALSE CANVAS_RECORDING=TRUE CANVAS_RECORDING_MB=64
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Canvas recording: draw a scene, play it back ==="

CP_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
CP_DIR="$(mktemp -d /tmp/draw-qa-crecplay-XXXXXX)"
CW=160; CH=100
magick -size ${CW}x${CH} xc:white "PNG32:$CP_DIR/pic.png"

cp_read() { hover 300 250; wait_for 0.3 "render"; hover 306 252; dk_settle
    read -r _ C_ON C_PAU C_N C_B _ <<< "$(grep -m1 '^CREC ' "$DK_DUMP")"
    read -r _ V_ZOOM V_OX V_OY _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; }
# canvas pixel -> viewport (the canvas sits centred in its area, VIEW zoom %)
px() { echo $(( CANVAS_CX + V_OX + ($1 * 2 + 1 - CW) * V_ZOOM / 200 )); }
py() { echo $(( CANVAS_CY + V_OY + ($1 * 2 + 1 - CH) * V_ZOOM / 200 )); }
fg() { click $(( 16 + $1 * 17 + 8 )) $(( VIEWPORT_H - STATUS_H - 6 )); wait_for 0.25 "colour $1"; }
at() { click "$(px "$1")" "$(py "$2")"; wait_for 0.5 "click $1,$2"; }
box() { drag "$(px "$1")" "$(py "$2")" "$(px "$3")" "$(py "$4")"; wait_for 0.5 "drag $1,$2-$3,$4"; }
STEPS=0
step() { STEPS=$(( STEPS + 1 )); }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$CP_DIR/pic.png"
draw_launch 15
wait_for 1.5 "blank picture loaded"
assert_no_crash
cp_read
if [[ -z "$C_N" || -z "$V_ZOOM" ]]; then
    fail "no CREC / VIEW line in the dump (a DRAW without canvas recording?)"
else
    (( C_N == 1 )) && pass "a blank picture: one frame" || fail "at open: $C_N frames"
    # the whole canvas on screen (the fit can overshoot the area's height): zoom out until it is
    for _z in 1 2 3; do
        (( CH * V_ZOOM / 100 <= 420 && CW * V_ZOOM / 100 <= 880 )) && break
        key ctrl+minus; wait_for 0.5 "zoom out"; cp_read
    done
    info "zoom ${V_ZOOM}% offset $V_OX,$V_OY, canvas centre $CANVAS_CX,$CANVAS_CY"

    # --- 1. the drawing ------------------------------------------------------------------------
    # (nothing is drawn under the floating Preview, bottom right of the canvas)
    key f; wait_for 0.3 "fill"
    fg 4; at 80 30; step                                  # sky
    key shift+r; wait_for 0.3 "filled rectangle"
    fg 10; box 159 80 0 99; step                          # ground (from its top right, clear of the Preview)
    key shift+c; wait_for 0.3 "filled ellipse"
    fg 21; box 122 6 146 30; step                         # sun
    key shift+r; wait_for 0.3 "filled rectangle"
    fg 20; box 40 48 86 82; step                          # walls
    key l; wait_for 0.3 "line"
    fg 23; box 34 48 63 28; step; box 63 28 92 48; step; box 34 48 92 48; step   # roof outline
    key f; wait_for 0.3 "fill"
    at 63 40; step                                        # roof
    key shift+r; wait_for 0.3 "filled rectangle"
    fg 24; box 58 62 68 82; step                          # door
    fg 6; box 45 54 53 62; step; box 74 54 82 62; step    # windows
    fg 19; box 114 58 120 82; step                        # trunk
    key shift+c; wait_for 0.3 "filled ellipse"
    fg 9; box 101 32 133 66; step                         # crown
    key l; wait_for 0.3 "line"
    fg 0; box 18 22 22 26; step; box 22 26 26 22; step; box 32 14 35 17; step; box 35 17 38 14; step   # birds
    key b; wait_for 0.3 "brush"
    fg 11
    for gx in 8 16 24 96 104 126; do box $gx 94 $(( gx + 2 )) 88; step; done   # grass
    park_mouse; wait_for 0.6 "settle"
    screenshot "canvas-recording-playback-drawn"
    cp_read
    (( C_N == STEPS + 1 )) && pass "$STEPS steps drawn: $C_N frames (the start + one a step)" || fail "$STEPS steps, but $C_N frames"

    # --- 2. saved --------------------------------------------------------------------------------
    key ctrl+s; wait_for 1.5 "saved"
    CP_HEX=$(python3 "$CP_PY" get "$CP_DIR/pic.png" drRc 2>/dev/null | cut -c1-4)
    [[ "$CP_HEX" == 0100 ]] && pass "Ctrl+S: the recording is in the PNG (drRc v1)" || fail "no drRc chunk ('$CP_HEX')"
    draw_quit
    draw_settle

    # --- 3. a PNG sequence from the command line -------------------------------------------------
    cp_cli() { ( cd "$DRAW_ROOT" && HOME="$CP_DIR/home" XDG_CONFIG_HOME="$CP_DIR/home/.config" XDG_DATA_HOME="$CP_DIR/home/.local/share" \
        XDG_CACHE_HOME="$CP_DIR/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$CP_DIR/pic.png" "$@" </dev/null >>"$CP_DIR/cli.txt" 2>&1 ); }
    mkdir -p "$CP_DIR/home" "$CP_DIR/seq"
    cp_cli --export-recording "$CP_DIR/seq/f.png"
    CP_FILES=( "$CP_DIR"/seq/f_*.png )
    CP_NF=${#CP_FILES[@]}
    [[ -f "${CP_FILES[0]}" ]] || CP_NF=0
    (( CP_NF == C_N )) && pass "--export-recording f.png: $CP_NF files, one a frame" || fail "PNG sequence: $CP_NF files for $C_N frames ($(tail -2 "$CP_DIR/cli.txt" | tr '\n' ' '))"
    if (( CP_NF > 1 )); then
        magick -size ${CW}x${CH} xc:white "PNG32:$CP_DIR/blank.png"
        ae=$(magick compare -metric AE "${CP_FILES[0]}" "$CP_DIR/blank.png" null: 2>&1 | awk '{print $1}')
        [[ "$ae" == 0 ]] && pass "frame 1 is the blank picture" || fail "frame 1 differs from the blank picture ($ae pixels)"
        ae=$(magick compare -metric AE "${CP_FILES[$(( CP_NF - 1 ))]}" "$CP_DIR/pic.png" null: 2>&1 | awk '{print $1}')
        [[ "$ae" == 0 ]] && pass "the last frame is the saved picture, pixel for pixel" || fail "the last frame differs from the picture ($ae pixels)"
        same=0
        for (( i = 1; i < CP_NF; i++ )); do
            ae=$(magick compare -metric AE "${CP_FILES[$(( i - 1 ))]}" "${CP_FILES[$i]}" null: 2>&1 | awk '{print $1}')
            [[ "$ae" == 0 ]] && same=$(( same + 1 ))
        done
        (( same == 0 )) && pass "every frame changes the one before (a step of the drawing each)" || fail "$same frames are the same as the one before"
    fi

    # --- 4. an animated PNG ----------------------------------------------------------------------
    cp_cli --export-recording "$CP_DIR/rec.apng" --recording-fps 8 --recording-scale 2
    CP_APNG=$(python3 - "$CP_DIR/rec.apng" <<'EOF'
import struct, sys
try:
    d = open(sys.argv[1], 'rb').read()
except OSError:
    print("none"); sys.exit()
p, w, h, n, plays, fc = 8, 0, 0, -1, -1, 0
while p + 8 <= len(d):
    ln, = struct.unpack('>I', d[p:p+4]); t = d[p+4:p+8]; b = d[p+8:p+8+ln]
    if t == b'IHDR': w, h = struct.unpack('>II', b[:8])
    if t == b'acTL': n, plays = struct.unpack('>II', b[:8])
    if t == b'fcTL': fc += 1
    p += 12 + ln
print(w, h, n, plays, fc)
EOF
)
    read -r A_W A_H A_N A_PLAYS A_FC <<< "$CP_APNG"
    [[ "$A_W" == $(( CW * 2 )) && "$A_H" == $(( CH * 2 )) && "$A_N" == "$C_N" && "$A_FC" == "$C_N" && "$A_PLAYS" == 1 ]] \
        && pass "--export-recording rec.apng (8 fps, 2x): ${A_W}x$A_H, $A_N frames, plays once" \
        || fail "APNG: '$CP_APNG' (want $(( CW * 2 )) $(( CH * 2 )) $C_N 1 $C_N)"

    # keep the time-lapse beside the screenshots
    if [[ -s "$CP_DIR/rec.apng" ]]; then
        cp "$CP_DIR/rec.apng" "$SCREENSHOTS_DIR/canvas-recording-playback.apng"
        (( CP_NF > 1 )) && magick -delay 12 -loop 0 "${CP_FILES[@]}" -delay 200 "${CP_FILES[$(( CP_NF - 1 ))]}" -scale 300% "$SCREENSHOTS_DIR/canvas-recording-playback.gif" 2>/dev/null
        info "time-lapse: $SCREENSHOTS_DIR/canvas-recording-playback.apng (+ .gif)"
    fi
    draw_launch 15
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$CP_DIR"
assert_window_exists
