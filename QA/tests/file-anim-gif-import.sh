#!/bin/bash
# =============================================================================
# file-anim-gif-import.sh — QA test: opening an animated GIF makes a sheet with
# frames (Animation 5.1, TOOLS/ANIM-IMPORT ANIM_GIF_import%).
#
# A GIF with two or more images opens as frames of the GIF's size on a sheet;
# each frame is the picture a viewer shows after that image (disposal and
# transparency honoured - checked against ImageMagick's -coalesce); delays
# become the FPS and holds; the NETSCAPE block = loop forward, none = play
# once. A single-image GIF still opens as a plain picture.
#
# Frames are read back two ways: the dump (ANIM: frame size, count, FPS, loop)
# and the batch CLI's PNG sequence export (one PNG per tick, so holds show as
# repeated frames), compared pixel for pixel.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: animated GIF import ==="

GI_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
GI_T="$(mktemp -d /tmp/draw-qa-gifimp-XXXXXX)"
mkdir -p "$GI_T/home" "$GI_T/o" "$GI_T/src"
# four 16x12 frames: a moving square over a transparent ground, delays 10 20 10 10 cs
GI_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    magick -size 16x12 xc:none -fill "#${GI_COLORS[$n]}" -draw "rectangle $(( 2 + n * 3 )),3 $(( 6 + n * 3 )),8" "PNG32:$GI_T/src/f$n.png"
done
magick -dispose background -delay 10 "$GI_T/src/f0.png" -delay 20 "$GI_T/src/f1.png" -delay 10 "$GI_T/src/f2.png" "$GI_T/src/f3.png" -loop 0 "$GI_T/plain.gif"
# opaque frames optimised: sub-rectangle images after the first
for n in 0 1 2 3; do
    magick -size 16x12 xc:"#202830" -fill "#${GI_COLORS[$n]}" -draw "rectangle $(( 2 + n * 3 )),3 $(( 6 + n * 3 )),8" "PNG32:$GI_T/src/g$n.png"
done
magick -delay 10 "$GI_T/src/g0.png" -delay 20 "$GI_T/src/g1.png" -delay 10 "$GI_T/src/g2.png" "$GI_T/src/g3.png" -loop 0 -layers Optimize "$GI_T/opt.gif"
# disposal: a 4x4 image kept then put back (previous), one cleared to transparent (background)
magick -size 4x4 xc:"#40c040" "PNG32:$GI_T/src/d1.png"; magick -size 4x4 xc:"#4040c0" "PNG32:$GI_T/src/d2.png"; magick -size 3x3 xc:"#c0c040" "PNG32:$GI_T/src/d3.png"
magick \( -dispose none -delay 10 "$GI_T/src/f0.png" -repage 16x12+0+0 \) \( -dispose previous "$GI_T/src/d1.png" -repage 16x12+10+6 \) \
    \( -dispose background "$GI_T/src/d2.png" -repage 16x12+1+1 \) \( -dispose none "$GI_T/src/d3.png" -repage 16x12+6+6 \) -loop 0 "$GI_T/disp.gif"
# no NETSCAPE block: plays once
python3 - "$GI_T/plain.gif" "$GI_T/once.gif" <<'PY'
import sys
d = open(sys.argv[1], 'rb').read()
i = d.find(b'\x21\xff\x0bNETSCAPE2.0')
if i >= 0:
    j = i + 14
    while d[j] != 0: j += 1 + d[j]
    d = d[:i] + d[j + 1:]
open(sys.argv[2], 'wb').write(d)
PY
magick "$GI_T/src/f0.png" "$GI_T/single.gif"

gi_line() { grep -m1 "^$1 " "$GI_DUMP" 2>/dev/null; }
gi_read() { # A_ACT A_COUNT A_FW A_FH A_FPS A_LOOP
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ A_ACT A_COUNT _ A_FW A_FH _ _ _ _ A_FPS A_LOOP _ <<< "$(gi_line ANIM)"
}
gi_s() { echo "active ${A_ACT:-?} frames ${A_COUNT:-?} of ${A_FW:-?}x${A_FH:-?} at ${A_FPS:-?} fps, loop ${A_LOOP:-?}"; }
gi_open() { # FILE
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$1"
    draw_launch 15
    wait_for 1.5 "GIF loaded"
    assert_no_crash
    gi_read
}
gi_batch() { # IN ARGS... -> GI_RC, GI_OUT
    local in=$1; shift
    GI_OUT=$( cd "$DRAW_ROOT" && HOME="$GI_T/home" XDG_CONFIG_HOME="$GI_T/home/.config" XDG_DATA_HOME="$GI_T/home/.local/share" \
      XDG_CACHE_HOME="$GI_T/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$in" "$@" </dev/null 2>>"$GI_T/err.txt" )
    GI_RC=$?
}
gi_seq_matches() { # GIF PREFIX FRAMES... -> 0 when PREFIX_0001.png.. are exactly the GIF's coalesced frames in that order
    local gif=$1 pre=$2 k=1 f ae; shift 2
    rm -rf "$GI_T/co"; mkdir -p "$GI_T/co"
    magick "$gif" -coalesce -background none -alpha background "PNG32:$GI_T/co/c_%d.png" # (fully transparent = transparent black)
    for f in "$@"; do
        local png="$GI_T/o/${pre}_$(printf %04d $k).png"
        [[ -s "$png" ]] || { GI_WHY="missing $(basename "$png")"; return 1; }
        magick "$png" -background none -alpha background "PNG32:$GI_T/co/d.png"
        ae=$(magick compare -metric AE "$GI_T/co/d.png" "$GI_T/co/c_$f.png" null: 2>&1 | awk '{print $1}')
        [[ "$ae" == 0 ]] || { GI_WHY="$(basename "$png") vs GIF frame $f: '$ae' pixels differ"; return 1; }
        k=$(( k + 1 ))
    done
    [[ ! -e "$GI_T/o/${pre}_$(printf %04d $k).png" ]] || { GI_WHY="more PNGs than ticks"; return 1; }
}

info "Opening a 4-frame animated GIF"
gi_open "$GI_T/plain.gif"
[[ "$A_ACT" == -1 && "$A_COUNT" == 4 && "$A_FW" == 16 && "$A_FH" == 12 && "$A_FPS" == 10 && "$A_LOOP" == 0 ]] \
    && pass "plain.gif: 4 frames of 16x12 at 10 fps, looping forward" || fail "plain.gif: $(gi_s) (wanted 4 frames of 16x12 at 10 fps, loop 0)"

# every frame's pixels + the holds (delay 20 = two ticks at 10 fps)
gi_batch "$GI_T/plain.gif" --export-anim "$GI_T/o/p.png"
GI_WHY=""
[[ "$GI_RC" == 0 ]] && gi_seq_matches "$GI_T/plain.gif" p 0 1 1 2 3 \
    && pass "its PNG sequence: frames 1 2 2 3 4 (frame 2 held 2), each exactly the GIF's" || fail "plain.gif frames: exit $GI_RC, $GI_WHY, '$(tr '\n' '|' <<< "$GI_OUT")'"

# an optimised GIF: sub-rectangle images, transparency, disposal
GI_OPT_RECTS=$(magick identify -format '%W:%H:%w:%h ' "$GI_T/opt.gif" 2>/dev/null)
gi_batch "$GI_T/opt.gif" --export-anim "$GI_T/o/q.png"
GI_WHY=""
[[ "$GI_RC" == 0 ]] && gi_seq_matches "$GI_T/opt.gif" q 0 1 1 2 3 \
    && pass "an optimised GIF (images $GI_OPT_RECTS): composed frames exactly as ImageMagick's -coalesce" || fail "opt.gif frames: exit $GI_RC, $GI_WHY, images '$GI_OPT_RECTS', '$(tr '\n' '|' <<< "$GI_OUT")'"
GI_D_RECTS=$(magick identify -format '%w:%h%X%Y:%D ' "$GI_T/disp.gif" 2>/dev/null)
gi_batch "$GI_T/disp.gif" --export-anim "$GI_T/o/d.png"
GI_WHY=""
[[ "$GI_RC" == 0 ]] && gi_seq_matches "$GI_T/disp.gif" d 0 1 2 3 \
    && pass "disposal previous / background over transparency (images $GI_D_RECTS): frames exactly as -coalesce" || fail "disp.gif frames: exit $GI_RC, $GI_WHY, images '$GI_D_RECTS', '$(tr '\n' '|' <<< "$GI_OUT")'"

info "Ctrl+S with Save .draw Beside Images off writes the GIF back"
cp "$GI_T/plain.gif" "$GI_T/back.gif"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$GI_T/back.gif --option SAVE_DRAW_SIDECAR=FALSE"
draw_launch 15
wait_for 1.5 "GIF loaded"
assert_no_crash
park_mouse; key ctrl+s; wait_for 1.5 "saved"
GI_BACK_N=$(magick identify "$GI_T/back.gif" 2>/dev/null | wc -l)
GI_BACK_D=$(magick identify -format '%T ' "$GI_T/back.gif" 2>/dev/null)
rm -rf "$GI_T/o"/*; mkdir -p "$GI_T/bk"; magick "$GI_T/back.gif" -coalesce "PNG32:$GI_T/o/b_%04d.png" 2>/dev/null
for k in 1 2 3 4; do [[ -e "$GI_T/o/b_$(printf %04d $(( k - 1 ))).png" ]] && mv "$GI_T/o/b_$(printf %04d $(( k - 1 ))).png" "$GI_T/bk/b_$(printf %04d $k).png"; done
mv "$GI_T"/bk/* "$GI_T/o/" 2>/dev/null
GI_WHY=""
[[ "$GI_BACK_N" == 4 && "$GI_BACK_D" == "10 20 10 10 " ]] && gi_seq_matches "$GI_T/plain.gif" b 0 1 2 3 \
    && pass "back.gif after Ctrl+S: still 4 frames, delays 10 20 10 10, the same pixels" || fail "Ctrl+S on a GIF with frames: $GI_BACK_N images, delays '$GI_BACK_D', $GI_WHY"

info "Opening the GIF without a NETSCAPE block"
gi_open "$GI_T/once.gif"
[[ "$A_COUNT" == 4 && "$A_LOOP" == 3 ]] && pass "once.gif (no loop block): 4 frames, play once" || fail "once.gif: $(gi_s) (wanted loop 3 = once)"

info "Opening a single-image GIF"
gi_open "$GI_T/single.gif"
[[ "$A_ACT" == 0 ]] && pass "single.gif: a plain picture, no frames" || fail "single.gif: $(gi_s)"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$GI_T"
assert_window_exists
