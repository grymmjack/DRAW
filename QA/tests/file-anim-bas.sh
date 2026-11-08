#!/bin/bash
# =============================================================================
# file-anim-bas.sh — QA test: a sheet with frames exports as a self-contained
# QB64 animation player (Animation 3.4, TOOLS/ANIM-EXPORT ANIM_BAS_export%).
#
# One .bas, the frames in DATA (deflate + base64), playing at the FPS with the
# holds and the loop mode, colour cycling along. The generated program is
# compiled with qb64pe and run: `--frames DIR` writes one loop as PNGs +
# frames.txt (step, frame, ms) - checked exactly against the sheet's cells -
# and, under Xvfb only, a live run must animate and quit 0 on Esc.
#
# Exported through the batch CLI (`--export-anim out.bas`, throwaway HOME).
# Fixture: a 64x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour; 4 frames at 10 fps, frame 2 held 3.
# =============================================================================
info "=== Animation: BAS animation player (frames in DATA) ==="

AB_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AB_QB="${QB64PE:-$HOME/git/qb64pe/qb64pe}"
AB_T="$(mktemp -d /tmp/draw-qa-animbas-XXXXXX)"
mkdir -p "$AB_T/home"
AB_DRAW=()
AB_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 3 + n ))
    AB_DRAW+=(-fill "#${AB_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 64x16 xc:none "${AB_DRAW[@]}" "PNG32:$AB_T/plain.png"
ab_blob() { python3 -c "import struct,sys;print(struct.pack('<12h',1,16,16,0,0,4,1,10,int(sys.argv[1]),2,1,3).hex())" "$1"; } # LOOPMODE
ab_sheet() { python3 "$AB_PY" put "$AB_T/plain.png" "$AB_T/$2.png" drAn "$(ab_blob "$1")"; } # LOOPMODE NAME
ab_export() { # IN OUT.bas [ARGS...]
    local in=$1 out=$2; shift 2
    rm -f "$out"
    ( cd "$DRAW_ROOT" && HOME="$AB_T/home" XDG_CONFIG_HOME="$AB_T/home/.config" XDG_DATA_HOME="$AB_T/home/.local/share" \
      XDG_CACHE_HOME="$AB_T/home/.cache" timeout --foreground -k 5 60 "$DRAW_BIN" "$in" "$@" --export-anim "$out" \
      </dev/null >>"$AB_T/log.txt" 2>&1 )
    [[ -s "$out" ]] || fail "DRAW wrote no .bas for $(basename "$in"): $(tail -3 "$AB_T/log.txt" | tr '\n' ' ')"
}
ab_build() { # NAME -> 0 when NAME.bas compiled to NAME.run
    ( cd "$AB_T" && "$AB_QB" -x -w "$1.bas" -o "$1.run" >"$AB_T/$1-qb.log" 2>&1 ) && [[ -x "$AB_T/$1.run" ]]
}
ab_frames() { # NAME -> writes $AB_T/NAME-fr/frame_*.png + frames.txt
    rm -rf "$AB_T/$1-fr"; mkdir -p "$AB_T/$1-fr"
    ( cd "$AB_T" && timeout --foreground -k 3 30 "./$1.run" --frames "$AB_T/$1-fr" </dev/null >/dev/null 2>&1 )
}
ab_txt() { tr -d '\r' < "$AB_T/$1-fr/frames.txt" 2>/dev/null | tr '\n' ' ' | sed 's/ $//'; }
ab_same() { # PNG WANT.png -> 0 when exactly the same pixels (alpha too)
    local ae
    ae=$(magick compare -metric AE "$1" "$2" null: 2>&1 | awk '{print $1}')
    [[ "$ae" == 0 ]]
}
ab_cell() { magick "$AB_T/plain.png" -crop "16x16+$(( ($1 - 1) * 16 ))+0" +repage "PNG32:$2"; } # CELL OUT
ab_steps() { # NAME "C1 C2 ..." -> 0 when step k's PNG is exactly cell Ck
    local w=($2) k
    for (( k = 0; k < ${#w[@]}; k++ )); do
        ab_cell "${w[$k]}" "$AB_T/want.png"
        ab_same "$AB_T/$1-fr/$(printf 'frame_%04d.png' $(( k + 1 )))" "$AB_T/want.png" || return 1
    done
    [[ ! -e "$AB_T/$1-fr/$(printf 'frame_%04d.png' $(( ${#w[@]} + 1 )))" ]]
}

if [[ ! -x "$AB_QB" ]]; then
    info "qb64pe not found at $AB_QB: the generated players cannot be compiled - only the export is checked"
fi

# -- ping-pong: compiles, one loop of 6 steps, each its cell, ms from the holds --
ab_sheet 2 ping
ab_export "$AB_T/ping.png" "$AB_T/ping.bas"
if [[ -s "$AB_T/ping.bas" ]]; then
    grep -q '^DATA `' <(tr '"' '`' < "$AB_T/ping.bas") && grep -q 'DANM' "$AB_T/ping.bas" \
        && pass "ping.bas written: a player with the frames in DATA" || fail "ping.bas has no DATA blob"
    if [[ -x "$AB_QB" ]]; then
        if ab_build ping; then
            pass "the generated player compiles"
            ab_frames ping
            [[ "$(ab_txt ping)" == "1 1 100 2 2 300 3 3 100 4 4 100 5 3 100 6 2 300" ]] \
                && pass "--frames: one loop, 1 2 3 4 3 2, on screen 100 300 100 100 100 300 ms" || fail "ping frames.txt: '$(ab_txt ping)'"
            ab_steps ping "1 2 3 4 3 2" && pass "and each step's PNG is exactly its cell (transparency kept)" || fail "ping --frames PNGs do not match the cells"

            # -- live, only on the harness's own X server --
            if [[ -n "${QA_IN_XVFB:-}" ]] && command -v xwd >/dev/null && command -v xdotool >/dev/null && [[ -x /usr/bin/convert ]]; then
                ( cd "$AB_T" && exec ./ping.run </dev/null >/dev/null 2>&1 ) & AB_P=$!
                sleep 2
                AB_W=$(xdotool search --pid "$AB_P" 2>/dev/null | tail -1)
                for i in 1 2 3 4 5 6 7 8; do xwd -id "${AB_W:-0}" -silent > "$AB_T/s$i.xwd" 2>/dev/null; sleep 0.13; done
                AB_N=$(for i in 1 2 3 4 5 6 7 8; do /usr/bin/convert "xwd:$AB_T/s$i.xwd" -scale 1x1! -format '%[pixel:p{0,0}]\n' info: 2>/dev/null; done | sort -u | wc -l)
                [[ -n "$AB_W" ]] && xdotool key --window "$AB_W" Escape 2>/dev/null
                for i in 1 2 3 4 5 6 7 8 9 10; do kill -0 "$AB_P" 2>/dev/null || break; sleep 0.2; done
                if kill -0 "$AB_P" 2>/dev/null; then
                    kill "$AB_P" 2>/dev/null; fail "the player did not quit on Esc"
                else
                    wait "$AB_P"; AB_RC=$?
                    [[ "$AB_RC" == 0 ]] && pass "live: Esc quits, exit 0" || fail "the player's exit code on Esc: $AB_RC"
                fi
                [[ "$AB_N" -ge 2 ]] && pass "live: it animates ($AB_N different screens in 1 s)" || fail "live: the screen did not change ($AB_N distinct)"
            else
                info "not under Xvfb (or no xwd / xdotool): the live run is skipped"
            fi
        else
            fail "ping.bas does not compile: $(tail -3 "$AB_T/ping-qb.log" | tr '\n' ' ')"
        fi
    fi
fi

# -- reverse --
ab_sheet 1 rev
ab_export "$AB_T/rev.png" "$AB_T/rev.bas"
if [[ -x "$AB_QB" && -s "$AB_T/rev.bas" ]]; then
    ab_build rev && ab_frames rev
    [[ "$(ab_txt rev)" == "1 4 100 2 3 100 3 2 300 4 1 100" ]] && ab_steps rev "4 3 2 1" \
        && pass "reverse: 4 3 2 1" || fail "reverse frames.txt: '$(ab_txt rev)'"
fi

# -- colour cycling runs along --
printf 'GIMP Palette\nName: qa-anim-bas\n#\n192  64  64 a\n 64 192  64 b\n 64  64 192 c\n192 192  64 d\n' > "$AB_T/p.gpl"
ab_sheet 0 fwd
ab_export "$AB_T/fwd.png" "$AB_T/cyc.bas" --palette "$AB_T/p.gpl" --cycle 0-3:10
if [[ -x "$AB_QB" && -s "$AB_T/cyc.bas" ]]; then
    ab_build cyc && ab_frames cyc
    ab_cell 1 "$AB_T/c1.png"
    ab_cell 2 "$AB_T/c2.png"
    magick "$AB_T/c2.png" -fill "#c04040" -opaque "#40c040" "PNG32:$AB_T/c2cyc.png" # 10 steps/s, 0.1 s in: colour b shows colour a
    if ab_same "$AB_T/cyc-fr/frame_0001.png" "$AB_T/c1.png" && ab_same "$AB_T/cyc-fr/frame_0002.png" "$AB_T/c2cyc.png"; then
        pass "with a colour cycle (10 steps/s): frame 1 as drawn at 0 s, frame 2 at 0.1 s with the cycle one step on"
    else
        fail "colour cycling in the player: the first two steps are not frame 1 as drawn + frame 2 cycled one step"
    fi
fi

rm -rf "$AB_T"
assert_window_exists
