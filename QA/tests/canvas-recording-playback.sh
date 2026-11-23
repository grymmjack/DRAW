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
#   5. --export-recording out.gif (8 fps, 2x): 320x200, a frame each (13/100 s, the last 2 s),
#      no loop; coalesced, every frame is the PNG sequence's frame scaled 2x, pixel for pixel
#   6. a gradient with a transparent half (> 256 colours): an adaptive GIF table, the
#      transparent half stays transparent, the last frame is the picture within the table
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

    # --- 5. an animated GIF -----------------------------------------------------------------------
    cp_cli --export-recording "$CP_DIR/rec.gif" --recording-fps 8 --recording-scale 2
    CP_GIF=$(python3 - "$CP_DIR/rec.gif" <<'EOF2'
import struct, sys
try:
    d = open(sys.argv[1], 'rb').read()
except OSError:
    print("none"); sys.exit()
if d[:6] != b'GIF89a':
    print("bad"); sys.exit()
w, h = struct.unpack('<HH', d[6:10]); pk = d[10]; p = 13
if pk & 0x80: p += 3 * (2 << (pk & 7))
frames, delays, loop = 0, [], 0
while p < len(d):
    b = d[p]
    if b == 0x3B: break
    if b == 0x21:
        lab = d[p + 1]; p += 2
        if lab == 0xF9: delays.append(struct.unpack('<H', d[p + 2:p + 4])[0])
        if lab == 0xFF and d[p + 1:p + 12] == b'NETSCAPE2.0': loop = 1
        while d[p]: p += d[p] + 1
        p += 1
    elif b == 0x2C:
        frames += 1; ipk = d[p + 9]; p += 10
        if ipk & 0x80: p += 3 * (2 << (ipk & 7))
        p += 1
        while d[p]: p += d[p] + 1
        p += 1
    else:
        print("junk"); sys.exit()
print(w, h, frames, loop, delays[0] if delays else -1, delays[-1] if delays else -1)
EOF2
)
    read -r G_W G_H G_N G_LOOP G_D1 G_DL <<< "$CP_GIF"
    [[ "$G_W" == $(( CW * 2 )) && "$G_H" == $(( CH * 2 )) && "$G_N" == "$C_N" && "$G_LOOP" == 0 && "$G_D1" == 13 && "$G_DL" == 200 ]] \
        && pass "--export-recording rec.gif (8 fps, 2x): ${G_W}x$G_H, $G_N frames 13/100 s each, the last 2 s, plays once" \
        || fail "GIF: '$CP_GIF' (want $(( CW * 2 )) $(( CH * 2 )) $C_N 0 13 200) $(tail -1 "$CP_DIR/cli.txt")"
    if [[ "$G_N" == "$C_N" ]] && (( CP_NF > 1 )); then
        magick "$CP_DIR/rec.gif" -coalesce "PNG32:$CP_DIR/g_%03d.png" 2>/dev/null
        bad=0; first=""
        for (( i = 0; i < CP_NF; i++ )); do
            magick "${CP_FILES[$i]}" -scale 200% "PNG32:$CP_DIR/s2.png"
            ae=$(magick compare -metric AE "$(printf '%s/g_%03d.png' "$CP_DIR" "$i")" "$CP_DIR/s2.png" null: 2>&1 | awk '{print $1}')
            [[ "$ae" == 0 ]] || { bad=$(( bad + 1 )); [[ -z "$first" ]] && first="frame $(( i + 1 )): $ae"; }
        done
        (( bad == 0 )) && pass "every GIF frame is its recording frame, pixel for pixel (exact colours, changed rects)" || fail "$bad GIF frames differ from the PNG sequence ($first)"
    fi

    # keep the time-lapse beside the screenshots
    if [[ -s "$CP_DIR/rec.apng" ]]; then
        cp "$CP_DIR/rec.apng" "$SCREENSHOTS_DIR/canvas-recording-playback.apng"
        [[ -s "$CP_DIR/rec.gif" ]] && cp "$CP_DIR/rec.gif" "$SCREENSHOTS_DIR/canvas-recording-playback.gif"
        info "time-lapse: $SCREENSHOTS_DIR/canvas-recording-playback.apng (+ .gif, DRAW's own)"
    fi
    # --- 6. a GIF of a picture with > 256 colours and transparent pixels ------------------------------
    # (an adaptive table + a transparent entry; whole frames, since a rect cannot clear pixels)
    magick -size 160x100 xc: -sparse-color bilinear '0,0 red 159,0 lime 0,99 blue 159,99 yellow' \( -size 160x100 xc:white -fill black -draw 'rectangle 80,0 159,99' \) -alpha off -compose copy_opacity -composite "PNG32:$CP_DIR/grad.png"
    DRAW_EXTRA_ARGS="$CP_DIR/grad.png"
    draw_launch 15
    wait_for 1.5 "gradient loaded"
    cp_read
    key b; wait_for 0.3 "brush"; fg 0
    at 20 50; step; at 120 50; step
    cp_read; G_FR=$C_N
    key ctrl+s; wait_for 1.5 "saved"
    draw_quit
    draw_settle
    ( cd "$DRAW_ROOT" && HOME="$CP_DIR/home" XDG_CONFIG_HOME="$CP_DIR/home/.config" XDG_DATA_HOME="$CP_DIR/home/.local/share" \
        XDG_CACHE_HOME="$CP_DIR/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$CP_DIR/grad.png" --export-recording "$CP_DIR/grad.gif" </dev/null >>"$CP_DIR/cli.txt" 2>&1 )
    G_LINE=$(grep -a "grad.gif" "$CP_DIR/cli.txt" | tail -1)
    G_NF=$(magick identify "$CP_DIR/grad.gif" 2>/dev/null | wc -l)
    if [[ "$G_NF" == "$G_FR" ]] && [[ "$G_LINE" == *adaptive* ]]; then
        pass "a gradient with transparency: $G_NF GIF frames, an adaptive table ($(echo "$G_LINE" | sed 's/.*grad.gif *(//; s/)$//'))"
        magick "$CP_DIR/grad.gif" -coalesce "PNG32:$CP_DIR/gg_%03d.png" 2>/dev/null
        LAST=$(printf '%s/gg_%03d.png' "$CP_DIR" $(( G_NF - 1 )))
        A_R=$(magick "$LAST" -format '%[fx:p{150,50}.a]' info: 2>/dev/null)
        A_L=$(magick "$LAST" -format '%[fx:p{5,50}.a]' info: 2>/dev/null)
        [[ "$A_R" == 0 && "$A_L" == 1 ]] && pass "the transparent half stays transparent in the last frame, the gradient opaque" || fail "alpha: right half $A_R (want 0), left $A_L (want 1)"
        ae=$(magick compare -metric AE -fuzz 6% "$LAST" "$CP_DIR/grad.png" null: 2>&1 | awk '{print $1}')
        (( ${ae%.*} < 160 * 100 / 50 )) && pass "the last frame is the saved picture within the 256 colours ($ae pixels off by more than 6%)" || fail "the last frame is far from the picture ($ae pixels off)"
    else
        fail "gradient GIF: $G_NF frames for $G_FR, '$G_LINE'"
    fi
    DRAW_EXTRA_ARGS="$CP_DIR/pic.png"
    draw_launch 15
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$CP_DIR"
assert_window_exists
