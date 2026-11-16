#!/bin/bash
# =============================================================================
# file-anim-sheet.sh — QA test: PNG sequence and sprite sheet + frame data
# exports (Animation 3.2, TOOLS/ANIM-EXPORT ANIM_PNGSEQ_export% /
# ANIM_SHEET_export%).
#
# PNG sequence: what plays, one PNG per tick at the FPS - a frame held 3 is 3
# files, ping-pong written out - named out_0001.png ...; a shorter export over
# a longer one removes the numbered files left after it. Sprite sheet: out.png
# (the sheet, layers flattened), out.json (Aseprite "array": frames[] with
# frame {x,y,w,h} + duration ms, meta size / fps / frameTags direction), out.bi
# (QB64 CONSTs + DATA x, y, w, h, ms - compiled and run here when qb64pe is
# found). Both follow ANIM_EXPORT_SCALE; the sheet refuses to write over the
# open document.
#
# Exported through the batch CLI (`--export-anim out.png | out.json`, throwaway
# HOME, no window), read back with ImageMagick / python.
# Fixtures: a 64x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour; 4 frames at 10 fps, frame 2 held 3. A 30x20 sheet of 8x8
# frames, gutter 2, margin 1: 3 columns, 5 frames.
# =============================================================================
info "=== Animation: PNG sequence, sprite sheet + frame data ==="

AS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AS_T="$(mktemp -d /tmp/draw-qa-animsheet-XXXXXX)"
mkdir -p "$AS_T/home" "$AS_T/out"
AS_DRAW=()
AS_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 3 + n ))
    AS_DRAW+=(-fill "#${AS_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 64x16 xc:none "${AS_DRAW[@]}" "PNG32:$AS_T/plain.png"
as_blob() { python3 -c "import struct,sys;print(struct.pack('<12h',1,16,16,0,0,4,1,10,int(sys.argv[1]),2,1,3).hex())" "$1"; } # LOOPMODE
as_sheet() { python3 "$AS_PY" put "$AS_T/plain.png" "$AS_T/$2.png" drAn "$(as_blob "$1")"; } # LOOPMODE NAME
as_export() { # IN OUT [ARGS...] -> DRAW's exit code in AS_RC
    local in=$1 out=$2; shift 2
    ( cd "$DRAW_ROOT" && HOME="$AS_T/home" XDG_CONFIG_HOME="$AS_T/home/.config" XDG_DATA_HOME="$AS_T/home/.local/share" \
      XDG_CACHE_HOME="$AS_T/home/.cache" timeout --foreground -k 5 60 "$DRAW_BIN" "$in" "$@" --export-anim "$out" \
      </dev/null >>"$AS_T/log.txt" 2>&1 )
    AS_RC=$?
}
as_files() { ls "$AS_T/out" 2>/dev/null | grep -c "^$1_[0-9]*\.png$"; } # NAME -> how many numbered PNGs
as_same_cell() { # PNG CELL(1-4) SCALE -> 0 when the PNG is exactly that cell of plain.png (alpha too)
    local ae
    magick "$AS_T/plain.png" -crop "16x16+$(( ($2 - 1) * 16 ))+0" +repage -scale "$(( $3 * 100 ))%" "PNG32:$AS_T/want.png"
    [[ "$(magick identify -format '%wx%h' "$1" 2>/dev/null)" == "$(magick identify -format '%wx%h' "$AS_T/want.png")" ]] || return 1
    ae=$(magick compare -metric AE "$1" "$AS_T/want.png" null: 2>&1 | awk '{print $1}')
    [[ "$ae" == 0 ]]
}
as_seq() { # NAME SCALE "C1 C2 ..." -> 0 when NAME_000k.png shows cell Ck for every k, and no file after the last
    local w=($3) k
    for (( k = 0; k < ${#w[@]}; k++ )); do
        as_same_cell "$AS_T/out/$(printf '%s_%04d.png' "$1" $(( k + 1 )))" "${w[$k]}" "$2" || return 1
    done
    [[ ! -e "$AS_T/out/$(printf '%s_%04d.png' "$1" $(( ${#w[@]} + 1 )))" ]]
}

# -- PNG sequence: forward, one PNG per tick (frame 2 held 3) --
as_sheet 0 fwd
as_export "$AS_T/fwd.png" "$AS_T/out/seq.png"
if [[ "$AS_RC" != 0 || "$(as_files seq)" == 0 ]]; then
    fail "PNG sequence: DRAW exit $AS_RC, $(as_files seq) files: $(tail -3 "$AS_T/log.txt" | tr '\n' ' ')"
else
    [[ "$(as_files seq)" == 6 ]] && as_seq seq 1 "1 2 2 2 3 4" \
        && pass "PNG sequence: 6 PNGs at 10 fps, frame 2 three times (seq_0001 .. seq_0006), exact pixels" || fail "forward sequence: $(as_files seq) files ($(ls "$AS_T/out" | tr '\n' ' '))"
    AS_A=$(magick "$AS_T/out/seq_0001.png" -format '%[fx:minima.a]' info: 2>/dev/null)
    [[ "$AS_A" == 0 ]] && pass "and the empty pixels are transparent" || fail "seq_0001's lowest alpha: '$AS_A' (wanted 0)"
    [[ ! -e "$AS_T/out/seq.png" ]] && pass "no seq.png itself, only the numbered files" || fail "seq.png was written"
fi

# -- ping-pong written out; then a shorter export removes the leftovers --
as_sheet 2 ping
as_export "$AS_T/ping.png" "$AS_T/out/pp.png"
[[ "$(as_files pp)" == 10 ]] && as_seq pp 1 "1 2 2 2 3 4 3 2 2 2" \
    && pass "ping-pong: 10 PNGs, 1 2 2 2 3 4 3 2 2 2" || fail "ping-pong sequence: $(as_files pp) files"
as_export "$AS_T/fwd.png" "$AS_T/out/pp.png"
[[ "$(as_files pp)" == 6 ]] && as_seq pp 1 "1 2 2 2 3 4" \
    && pass "exported again shorter (forward, 6): pp_0007 .. pp_0010 removed" || fail "re-export over the ping-pong one: $(as_files pp) files"

# -- 2x --
as_export "$AS_T/fwd.png" "$AS_T/out/x2.png" --option ANIM_EXPORT_SCALE=2
[[ "$(as_files x2)" == 6 ]] && as_seq x2 2 "1 2 2 2 3 4" \
    && pass "ANIM_EXPORT_SCALE 2: 32x32 PNGs, every pixel doubled" || fail "2x sequence: $(as_files x2) files, $(magick identify -format '%wx%h' "$AS_T/out/x2_0001.png" 2>/dev/null)"

# -- sprite sheet: PNG + JSON + BI --
as_sheet 2 ping
as_export "$AS_T/ping.png" "$AS_T/out/ss.json"
if [[ "$AS_RC" != 0 || ! -s "$AS_T/out/ss.png" || ! -s "$AS_T/out/ss.json" || ! -s "$AS_T/out/ss.bi" ]]; then
    fail "sprite sheet: DRAW exit $AS_RC, wrote: $(ls "$AS_T/out" | grep '^ss' | tr '\n' ' ')"
else
    AS_AE=$(magick compare -metric AE "$AS_T/out/ss.png" "PNG32:$AS_T/plain.png" null: 2>&1 | awk '{print $1}')
    [[ "$AS_AE" == 0 && "$(magick identify -format '%wx%h' "$AS_T/out/ss.png")" == 64x16 ]] \
        && pass "ss.png is the sheet, 64x16, exact pixels" || fail "ss.png: $(magick identify -format '%wx%h' "$AS_T/out/ss.png"), $AS_AE pixels differ"
    AS_J=$(python3 - "$AS_T/out/ss.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
fr = d["frames"]; m = d["meta"]
print(len(fr), " ".join("%d,%d,%d,%d" % (f["frame"]["x"], f["frame"]["y"], f["frame"]["w"], f["frame"]["h"]) for f in fr),
      " ".join(str(f["duration"]) for f in fr), "%dx%d" % (m["size"]["w"], m["size"]["h"]), m["image"], m["fps"],
      m["frameTags"][0]["direction"], m["frameTags"][0]["from"], m["frameTags"][0]["to"])
PY
)
    [[ "$AS_J" == "4 0,0,16,16 16,0,16,16 32,0,16,16 48,0,16,16 100 300 100 100 64x16 ss.png 10 pingpong 0 3" ]] \
        && pass "ss.json (Aseprite array): 4 frame rects, durations 100 300 100 100 ms, size, fps 10, tag direction pingpong" || fail "ss.json reads: '$AS_J'"
    AS_QB="${QB64PE:-$HOME/git/qb64pe/qb64pe}"
    if [[ -x "$AS_QB" ]]; then
        printf "'\$INCLUDE:'ss.bi'\n\$CONSOLE:ONLY\nDIM i AS INTEGER, x AS LONG, y AS LONG, w AS LONG, h AS LONG, ms AS LONG\nPRINT SS_FRAMES; SS_FRAME_W; SS_FRAME_H; SS_FPS; SS_LOOP\nRESTORE SS_FRAME_DATA\nFOR i = 1 TO SS_FRAMES: READ x, y, w, h, ms: PRINT x; y; w; h; ms: NEXT i\nSYSTEM\n" > "$AS_T/out/use.bas"
        ( cd "$AS_T/out" && "$AS_QB" -x -w use.bas -o use.run >"$AS_T/qb.log" 2>&1 )
        AS_B=$( ( cd "$AS_T/out" && timeout 10 ./use.run 2>/dev/null ) | tr -s ' \n' ' ' | sed 's/^ //; s/ $//')
        [[ "$AS_B" == "4 16 16 10 2 0 0 16 16 100 16 0 16 16 300 32 0 16 16 100 48 0 16 16 100" ]] \
            && pass "ss.bi compiles in a QB64 program and READs the same rects + ms" || fail "ss.bi: program printed '$AS_B' ($(tail -2 "$AS_T/qb.log" | tr '\n' ' '))"
    else
        info "qb64pe not found at $AS_QB: ss.bi not compiled"
    fi
fi

# -- sprite sheet at 2x --
as_export "$AS_T/fwd.png" "$AS_T/out/s2.json" --option ANIM_EXPORT_SCALE=2
AS_J2=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(' '.join('%d,%d,%d,%d'%(f['frame']['x'],f['frame']['y'],f['frame']['w'],f['frame']['h']) for f in d['frames']),'%dx%d'%(d['meta']['size']['w'],d['meta']['size']['h']))" "$AS_T/out/s2.json" 2>/dev/null)
magick "$AS_T/plain.png" -scale 200% "PNG32:$AS_T/want2.png"
AS_AE2=$(magick compare -metric AE "$AS_T/out/s2.png" "$AS_T/want2.png" null: 2>&1 | awk '{print $1}')
[[ "$AS_J2" == "0,0,32,32 32,0,32,32 64,0,32,32 96,0,32,32 128x32" && "$AS_AE2" == 0 ]] \
    && pass "2x sheet: 128x32 every pixel doubled, the rects doubled" || fail "2x sheet: rects '$AS_J2', $AS_AE2 pixels differ"

# -- gutter and margin: the rects skip them --
magick -size 30x20 xc:none -fill "#c04040" -draw "rectangle 1,1 8,8" -fill "#40c040" -draw "rectangle 11,11 18,18" "PNG32:$AS_T/g.png"
python3 "$AS_PY" put "$AS_T/g.png" "$AS_T/gut.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,8,8,2,1,5,1,12,0,0).hex())")"
as_export "$AS_T/gut.png" "$AS_T/out/gut.json"
AS_JG=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(' '.join('%d,%d'%(f['frame']['x'],f['frame']['y']) for f in d['frames']))" "$AS_T/out/gut.json" 2>/dev/null)
[[ "$AS_JG" == "1,1 11,1 21,1 1,11 11,11" ]] && pass "gutter 2, margin 1: 5 rects at 1,1 11,1 21,1 1,11 11,11" || fail "gutter / margin rects: '$AS_JG'"

# -- never over the open document --
AS_SUM=$(md5sum < "$AS_T/fwd.png")
as_export "$AS_T/fwd.png" "$AS_T/fwd.json"
[[ "$AS_RC" != 0 && "$(md5sum < "$AS_T/fwd.png")" == "$AS_SUM" && ! -e "$AS_T/fwd.json" ]] \
    && pass "a sheet named like the document (fwd.json beside fwd.png): refused, fwd.png untouched" || fail "sheet over the document: exit $AS_RC, fwd.png $( [[ "$(md5sum < "$AS_T/fwd.png")" == "$AS_SUM" ]] && echo same || echo CHANGED )"

rm -rf "$AS_T"
assert_window_exists
