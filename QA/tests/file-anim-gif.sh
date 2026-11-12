#!/bin/bash
# =============================================================================
# file-anim-gif.sh — QA test: a sheet with frames exports as an animated GIF
# (Animation 3.1, TOOLS/ANIM-EXPORT ANIM_GIF_export%).
#
# One GIF frame per frame shown, in loop order: forward, reverse, ping-pong
# written out (1 2 3 4 3 2), play once (no NETSCAPE loop block). Each frame's
# delay is its hold at the FPS. Transparent pixels stay transparent (disposal
# "background"); ANIM_EXPORT_SCALE 2 doubles every pixel; colour cycling runs
# along (a GIF frame at every change of the frame or the colours).
#
# Exported through the batch CLI (`--export-anim out.gif`, throwaway HOME, no
# window), read back with ImageMagick: frame count, delays, size, disposal,
# and each frame's pixels against its cell of the sheet (exact colours).
# Over 256 colours: the adaptive (median cut) table keeps every frame close.
# Fixture: a 64x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour; 4 frames at 10 fps, frame 2 held 3.
# =============================================================================
info "=== Animation: animated GIF export ==="

AG_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AG_T="$(mktemp -d /tmp/draw-qa-animgif-XXXXXX)"
mkdir -p "$AG_T/home"
AG_DRAW=()
AG_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 3 + n ))
    AG_DRAW+=(-fill "#${AG_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 64x16 xc:none "${AG_DRAW[@]}" "PNG32:$AG_T/plain.png"
ag_blob() { python3 -c "import struct,sys;print(struct.pack('<12h',1,16,16,0,0,4,1,10,int(sys.argv[1]),2,1,3).hex())" "$1"; } # LOOPMODE
ag_sheet() { python3 "$AG_PY" put "$AG_T/plain.png" "$AG_T/$2.png" drAn "$(ag_blob "$1")"; } # LOOPMODE NAME
ag_export() { # IN OUT [ARGS...]: DRAW opens IN and writes the animated GIF OUT
    local in=$1 out=$2; shift 2
    rm -f "$out"
    ( cd "$DRAW_ROOT" && HOME="$AG_T/home" XDG_CONFIG_HOME="$AG_T/home/.config" XDG_DATA_HOME="$AG_T/home/.local/share" \
      XDG_CACHE_HOME="$AG_T/home/.cache" timeout --foreground -k 5 60 "$DRAW_BIN" "$in" "$@" --export-anim "$out" \
      </dev/null >>"$AG_T/log.txt" 2>&1 )
    [[ -s "$out" ]] || fail "DRAW wrote no GIF for $(basename "$in"): $(tail -3 "$AG_T/log.txt" | tr '\n' ' ')"
}
ag_n() { magick identify "$1" 2>/dev/null | wc -l; }
ag_delays() { magick identify -format '%T ' "$1" 2>/dev/null | sed 's/ $//'; }
ag_frames_png() { rm -f "$AG_T"/fr-*.png; magick "$1" -coalesce "PNG32:$AG_T/fr-%d.png" 2>/dev/null; } # GIF -> fr-0.png ...
ag_same_cell() { # FRAMEPNG CELL(1-4) SCALE -> 0 when the GIF frame shows exactly that cell
    local ae
    magick "$AG_T/plain.png" -crop "16x16+$(( ($2 - 1) * 16 ))+0" +repage -scale "$(( $3 * 100 ))%" -background magenta -flatten "PNG24:$AG_T/want.png"
    magick "$1" -background magenta -flatten "PNG24:$AG_T/got.png"
    ae=$(magick compare -metric AE "$AG_T/got.png" "$AG_T/want.png" null: 2>&1 | awk '{print $1}')
    [[ "$ae" == 0 ]]
}
ag_order() { # GIF SCALE "C1 C2 ..." -> 0 when GIF frame k shows cell Ck for every k
    local w=($3) k
    ag_frames_png "$1"
    for (( k = 0; k < ${#w[@]}; k++ )); do ag_same_cell "$AG_T/fr-$k.png" "${w[$k]}" "$2" || return 1; done
}
ag_loop_block() { grep -c "NETSCAPE2.0" "$1" 2>/dev/null; }

# -- forward: 4 frames, delays from the holds, transparent, looping --
ag_sheet 0 fwd
ag_export "$AG_T/fwd.png" "$AG_T/fwd.gif"
if [[ -s "$AG_T/fwd.gif" ]]; then
    [[ "$(ag_n "$AG_T/fwd.gif")" == 4 && "$(ag_delays "$AG_T/fwd.gif")" == "10 30 10 10" ]] \
        && pass "forward: 4 frames, delays 10 30 10 10 (10 fps, frame 2 held 3)" || fail "forward: $(ag_n "$AG_T/fwd.gif") frames, delays '$(ag_delays "$AG_T/fwd.gif")'"
    ag_order "$AG_T/fwd.gif" 1 "1 2 3 4" && pass "each GIF frame is its cell, exact colours" || fail "forward frames do not match the cells 1 2 3 4"
    [[ "$(magick identify -format '%wx%h ' "$AG_T/fwd.gif" | awk '{print $1}')" == 16x16 ]] && pass "16x16, the frame size" || fail "forward size: $(magick identify -format '%wx%h ' "$AG_T/fwd.gif")"
    [[ "$(magick identify -format '%D ' "$AG_T/fwd.gif" | sed 's/ $//')" == "Background Background Background Background" ]] \
        && pass "transparent background kept: each frame clears to it (disposal background)" || fail "disposal: '$(magick identify -format '%D ' "$AG_T/fwd.gif")'"
    AG_A=$(magick "$AG_T/fr-0.png" -format '%[fx:minima.a]' info: 2>/dev/null)
    [[ "$AG_A" == 0 ]] && pass "and the empty pixels are transparent" || fail "frame 1's lowest alpha: '$AG_A' (wanted 0)"
    [[ "$(ag_loop_block "$AG_T/fwd.gif")" -ge 1 ]] && pass "loops (NETSCAPE block)" || fail "forward GIF has no loop block"
fi

# -- reverse, ping-pong, once --
ag_sheet 1 rev
ag_export "$AG_T/rev.png" "$AG_T/rev.gif"
[[ "$(ag_delays "$AG_T/rev.gif")" == "10 10 30 10" ]] && ag_order "$AG_T/rev.gif" 1 "4 3 2 1" \
    && pass "reverse: frames 4 3 2 1, delays 10 10 30 10" || fail "reverse: delays '$(ag_delays "$AG_T/rev.gif")'"
ag_sheet 2 ping
ag_export "$AG_T/ping.png" "$AG_T/ping.gif"
[[ "$(ag_n "$AG_T/ping.gif")" == 6 && "$(ag_delays "$AG_T/ping.gif")" == "10 30 10 10 10 30" ]] && ag_order "$AG_T/ping.gif" 1 "1 2 3 4 3 2" \
    && pass "ping-pong written out: 1 2 3 4 3 2" || fail "ping-pong: $(ag_n "$AG_T/ping.gif") frames, delays '$(ag_delays "$AG_T/ping.gif")'"
ag_sheet 3 once
ag_export "$AG_T/once.png" "$AG_T/once.gif"
[[ "$(ag_n "$AG_T/once.gif")" == 4 && "$(ag_loop_block "$AG_T/once.gif")" == 0 ]] \
    && pass "play once: 4 frames, no loop block" || fail "once: $(ag_n "$AG_T/once.gif") frames, loop blocks $(ag_loop_block "$AG_T/once.gif")"

# -- 2x --
ag_export "$AG_T/fwd.png" "$AG_T/x2.gif" --option ANIM_EXPORT_SCALE=2
[[ "$(magick identify -format '%wx%h ' "$AG_T/x2.gif" | awk '{print $1}')" == 32x32 ]] && ag_order "$AG_T/x2.gif" 2 "1 2 3 4" \
    && pass "ANIM_EXPORT_SCALE 2: 32x32, every pixel doubled" || fail "2x: $(magick identify -format '%wx%h ' "$AG_T/x2.gif") / pixels"

# -- colour cycling runs along --
printf 'GIMP Palette\nName: qa-anim-gif\n#\n192  64  64 a\n 64 192  64 b\n 64  64 192 c\n192 192  64 d\n' > "$AG_T/p.gpl"
ag_export "$AG_T/fwd.png" "$AG_T/cyc.gif" --palette "$AG_T/p.gpl" --cycle 0-3:10
AG_CN=$(ag_n "$AG_T/cyc.gif"); AG_CD=$(ag_delays "$AG_T/cyc.gif")
AG_SUM=0; for d in $AG_CD; do AG_SUM=$(( AG_SUM + d )); done
if [[ "$AG_CN" -gt 4 && "$AG_SUM" == 120 ]]; then
    pass "with a colour cycle (10 steps/s over 4 colours): $AG_CN GIF frames over 1.2 s (the frames' 0.6 s and the cycle's 0.4 s line up)"
else
    fail "colour cycling: $AG_CN frames, delays '$AG_CD' (sum $AG_SUM, wanted > 4 frames over 120)"
fi
ag_frames_png "$AG_T/cyc.gif"
if ag_same_cell "$AG_T/fr-0.png" 1 1 && ! ag_same_cell "$AG_T/fr-1.png" 1 1; then
    pass "the first GIF frame is frame 1 as drawn, the next shows frame 1 with the colours moved on"
else
    fail "colour cycling frames: the first two GIF frames do not show frame 1 then frame 1 cycled"
fi

# -- more than 256 colours: an adaptive table of the frames' own colours --
# 4 frames of 16x16, 1024 colours in all (fades / tints / soft edges do this). The old
# export snapped every pixel to the document palette (RMSE ~0.13 here); a median-cut
# table of the frames' own colours keeps them close (~0.05).
python3 -c "
w,h=64,16
print('P3',w,h,255)
for j in range(h):
    print(' '.join('%d %d %d'%(i*4, j*17, ((i*7+j*3)%64)*4) for i in range(w)))" > "$AG_T/grad.ppm"
magick "$AG_T/grad.ppm" "PNG32:$AG_T/grad-plain.png"
python3 "$AG_PY" put "$AG_T/grad-plain.png" "$AG_T/grad.png" drAn "$(ag_blob 0)"
ag_export "$AG_T/grad.png" "$AG_T/grad.gif"
if [[ -s "$AG_T/grad.gif" ]]; then
    AG_WORST=0
    for k in 0 1 2 3; do
        magick "$AG_T/grad.gif[$k]" "PNG24:$AG_T/got.png"
        magick "$AG_T/grad-plain.png" -crop "16x16+$(( k * 16 ))+0" +repage "PNG24:$AG_T/want.png"
        AG_E=$(magick compare -metric RMSE "$AG_T/got.png" "$AG_T/want.png" null: 2>&1 | sed -n 's/.*(\([0-9.e-]*\)).*/\1/p')
        AG_WORST=$(python3 -c "print(max($AG_WORST, ${AG_E:-1}))")
    done
    python3 -c "import sys; sys.exit(0 if $AG_WORST < 0.07 else 1)" \
        && pass "1024 colours: an adaptive 256-colour table, every frame close to its cell (worst RMSE $AG_WORST)" \
        || fail "1024 colours: worst frame RMSE $AG_WORST (wanted < 0.07: the frames' own colours, not the palette's)"
    grep -q "the frames' own 256 nearest" "$AG_T/log.txt" && pass "the export says so (the frames' own 256 nearest)" || fail "export message: $(grep -a 'grad.gif' "$AG_T/log.txt" | tail -1)"
fi

rm -rf "$AG_T"
assert_window_exists
