#!/bin/bash
# =============================================================================
# file-anim-sheet-import.sh — QA test: slicing a sprite sheet into frames
# (Animation 5.3, TOOLS/ANIM-IMPORT ANIM_SHEET_import% / ANIM_DT_action).
#
# 1. Opening a PNG with its frame data beside it (name.json: Aseprite's Export
#    Sprite Sheet, TexturePacker, DRAW's own sheet export) brings the frames
#    back. A regular grid is sliced where it is (gutter, margin); a packed atlas
#    (trimmed, rotated) is laid out again on a grid of its source size.
#    Durations -> FPS + holds, frameTags -> tags. A .json naming another image
#    is not used.
# 2. ANIM > Detect Frames finds the grid of a plain sheet from its gaps (gutter
#    0; gutter + margin; the frames run to the last cell drawn in), one undo
#    step; sprites that touch give no grid.
# Read back: the dump (ANIM, ANIMTG) and the batch CLI (--export = the canvas,
# --export-anim = one PNG per tick), against images written here.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: sprite sheet slicing ==="

SI_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
SI_T="$(mktemp -d /tmp/draw-qa-sheetimp-XXXXXX)"
mkdir -p "$SI_T/home" "$SI_T/o" "$SI_T/x" "$SI_T/rt" "$SI_T/oth"
python3 - "$SI_T" <<'PY'
import json, os, sys
T = sys.argv[1]
def save(path, w, h, px):
    raw = path + '.rgba'; open(raw, 'wb').write(bytes(px))
    os.system(f"magick -size {w}x{h} -depth 8 rgba:'{raw}' 'PNG32:{path}'"); os.remove(raw)
def blank(w, h): return [0] * (w * h * 4)
def put(px, w, x, y, rgba): o = (y * w + x) * 4; px[o:o + 4] = rgba
COL = [(200, 60, 60, 255), (60, 200, 60, 255), (60, 60, 200, 255), (200, 200, 60, 255), (200, 60, 200, 255)]

# 1. a regular grid: 3 x 2 cells of 10x8, gutter 2, margin 1 (36x20); 5 frames, cell 6 empty
W, H, CW, CH, G, M = 36, 20, 10, 8, 2, 1
px = blank(W, H); frames = []
for k in range(5):
    cx = M + (k % 3) * (CW + G); cy = M + (k // 3) * (CH + G)
    for y in range(CH):
        for x in range(CW):
            if (x + y + k) % 3: put(px, W, cx + x, cy + y, COL[k])
    frames.append({"filename": f"grid {k}.ase", "frame": {"x": cx, "y": cy, "w": CW, "h": CH}, "rotated": False, "trimmed": False,
                   "spriteSourceSize": {"x": 0, "y": 0, "w": CW, "h": CH}, "sourceSize": {"w": CW, "h": CH}, "duration": [100, 100, 200, 100, 100][k]})
    fpx = blank(CW, CH)
    for y in range(CH):
        for x in range(CW): fpx[(y * CW + x) * 4:(y * CW + x) * 4 + 4] = px[((cy + y) * W + cx + x) * 4:((cy + y) * W + cx + x) * 4 + 4]
    save(os.path.join(T, 'x', f'g{k}.png'), CW, CH, fpx)
save(os.path.join(T, 'grid.png'), W, H, px)
json.dump({"frames": frames, "meta": {"app": "http://www.aseprite.org/", "image": "grid.png", "size": {"w": W, "h": H},
           "frameTags": [{"name": "run", "from": 0, "to": 2, "direction": "forward"}]}}, open(os.path.join(T, 'grid.json'), 'w'), indent=1)
# the same picture, its .json about another image
save(os.path.join(T, 'oth', 'grid.png'), W, H, px)
json.dump({"frames": frames, "meta": {"image": "other.png"}}, open(os.path.join(T, 'oth', 'grid.json'), 'w'))

# 2. a packed atlas (TexturePacker hash): 4 sprites of 8x8, trimmed; sprite 3 stored rotated
SW = SH = 8
spr = []
for k in range(4):
    s = blank(SW, SH)
    for y in range(1 + k % 2, 6 + k % 2):
        for x in range(2, 5 + k):
            if x < SW: put(s, SW, x, y, COL[k] if (x + y) % 2 else (255, 255, 255, 255))
    spr.append(s)
    save(os.path.join(T, 'x', f'p{k}.png'), SW, SH, s)
def trim(s):
    xs = [x for x in range(SW) for y in range(SH) if s[(y * SW + x) * 4 + 3]]; ys = [y for x in range(SW) for y in range(SH) if s[(y * SW + x) * 4 + 3]]
    return min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
AW, AH = 24, 10
atlas = blank(AW, AH); fr = {}; x0 = 0
for k in range(4):
    tx, ty, tw, th = trim(spr[k]); rot = (k == 2)
    for y in range(th):
        for x in range(tw):
            c = spr[k][((ty + y) * SW + tx + x) * 4:((ty + y) * SW + tx + x) * 4 + 4]
            if rot: put(atlas, AW, x0 + th - 1 - y, 1 + x, c)   # a quarter turn clockwise
            else:   put(atlas, AW, x0 + x, 1 + y, c)
    fr[f"walk_{k}.png"] = {"frame": {"x": x0, "y": 1, "w": tw, "h": th}, "rotated": rot, "trimmed": True,
                           "spriteSourceSize": {"x": tx, "y": ty, "w": tw, "h": th}, "sourceSize": {"w": SW, "h": SH}}
    x0 += (th if rot else tw) + 1
assert x0 <= AW
save(os.path.join(T, 'atlas.png'), AW, AH, atlas)
json.dump({"frames": fr, "meta": {"app": "https://www.codeandweb.com/texturepacker", "image": "atlas.png", "size": {"w": AW, "h": AH}}},
          open(os.path.join(T, 'atlas.json'), 'w'), indent=1)

# 3. plain sheets for Detect Frames
#   a: 4 sprites in a row of 16x16 cells, no gutter (64x16), each clear of its cell edges
a = blank(64, 16)
for k in range(4):
    for y in range(4, 12):
        for x in range(3 + k, 11 + k): put(a, 64, k * 16 + x, y, COL[k])
    put(a, 64, k * 16 + 2, 13, COL[k]); put(a, 64, k * 16 + 12, 13, COL[k])   # two feet (gaps: still one sprite's extent)
for y in range(11, 13):                                                       # legs join the feet to the body
    put(a, 64, 0 * 16 + 2, y + 1 - 1, COL[0])
save(os.path.join(T, 'row.png'), 64, 16, a)
#   b: 3 x 2 cells of 12x12 drawn edge to edge, gutter 1, margin 1 (40x27); 5 frames, cell 6 empty
b = blank(40, 27)
for k in range(5):
    cx = 1 + (k % 3) * 13; cy = 1 + (k // 3) * 13
    for y in range(12):
        for x in range(12): put(b, 40, cx + x, cy + y, COL[k])
save(os.path.join(T, 'gut.png'), 40, 27, b)
#   c: touching sprites (one blob)
c = blank(32, 8)
for x in range(32):
    for y in range(2, 6): put(c, 32, x, y, COL[x // 8])
save(os.path.join(T, 'touch.png'), 32, 8, c)
PY

si_line() { grep -m1 "^$1 " "$SI_DUMP" 2>/dev/null; }
si_read() { # A_ACT A_COUNT A_CUR A_FW A_FH A_G A_M A_FPS A_LOOP, TG_LIST
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ A_ACT A_COUNT A_CUR A_FW A_FH A_G A_M _ _ A_FPS A_LOOP _ <<< "$(si_line ANIM)"
    TG_LIST=""; read -r _ _ _ TG_LIST <<< "$(si_line ANIMTG)"; TG_LIST="${TG_LIST% _}"
}
si_s() { echo "active ${A_ACT:-?} frames ${A_COUNT:-?} of ${A_FW:-?}x${A_FH:-?} gutter ${A_G:-?} margin ${A_M:-?} at ${A_FPS:-?} fps, loop ${A_LOOP:-?}, tags '${TG_LIST:-}'"; }
si_open() { # FILE
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$1"
    draw_launch 15
    wait_for 1.5 "sheet loaded"
    assert_no_crash
    si_read
}
si_batch() { # IN ARGS... -> SI_RC, SI_OUT
    local in=$1; shift
    SI_OUT=$( cd "$DRAW_ROOT" && HOME="$SI_T/home" XDG_CONFIG_HOME="$SI_T/home/.config" XDG_DATA_HOME="$SI_T/home/.local/share" \
      XDG_CACHE_HOME="$SI_T/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$in" "$@" </dev/null 2>>"$SI_T/err.txt" )
    SI_RC=$?
}
si_seq() { # PREFIX EXPECTED... -> 0 when PREFIX_0001.png.. are exactly those PNGs, in that order, and no more
    local pre=$1 k=1 e ae png; shift
    for e in "$@"; do
        png="$SI_T/o/${pre}_$(printf %04d $k).png"
        [[ -s "$png" ]] || { SI_WHY="missing $(basename "$png")"; return 1; }
        ae=$(magick compare -metric AE "$png" "$SI_T/x/$e.png" null: 2>&1 | awk '{print $1}')
        [[ "$ae" == 0 ]] || { SI_WHY="$(basename "$png") vs $e: '$ae' pixels differ"; cp -f "$png" "$SCREENSHOTS_DIR/sheet-import-got.png" 2>/dev/null; return 1; }
        k=$(( k + 1 ))
    done
    [[ ! -e "$SI_T/o/${pre}_$(printf %04d $k).png" ]] || { SI_WHY="more PNGs than ticks"; return 1; }
}
si_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}

# ---- 1. frame data beside the sheet ----
info "Opening a sheet with an Aseprite .json (3 x 2 cells of 10x8, gutter 2, margin 1)"
si_open "$SI_T/grid.png"
[[ "$A_ACT" == -1 && "$A_COUNT" == 5 && "$A_FW" == 10 && "$A_FH" == 8 && "$A_G" == 2 && "$A_M" == 1 && "$A_FPS" == 10 && "$TG_LIST" == "run 1 3" ]] \
    && pass "grid.png + grid.json: 5 frames of 10x8, gutter 2, margin 1, 10 fps, tag run = 1-3" || fail "grid.png: $(si_s) (wanted 5 of 10x8 g2 m1, 10 fps, 'run 1 3')"
si_batch "$SI_T/grid.png" --export "$SI_T/o/grid-canvas.png" --export-anim "$SI_T/o/g.png"
SI_AE=$(magick compare -metric AE "$SI_T/o/grid-canvas.png" "$SI_T/grid.png" null: 2>&1 | awk '{print $1}')
SI_WHY=""
[[ "$SI_RC" == 0 && "$SI_AE" == 0 ]] && si_seq g g0 g1 g2 g2 g3 g4 \
    && pass "sliced where it is (the canvas = the file) and its PNG sequence = the 5 cells, frame 3 held 2 (200 ms)" \
    || fail "grid frames: exit $SI_RC, canvas differs by '$SI_AE', $SI_WHY, '$(tr '\n' '|' <<< "$SI_OUT")'"

info "A packed TexturePacker atlas (trimmed, one sprite rotated)"
si_batch "$SI_T/atlas.png" --export "$SI_T/o/atlas-canvas.png" --export-anim "$SI_T/o/a.png"
SI_SZ=$(magick identify -format '%wx%h' "$SI_T/o/atlas-canvas.png" 2>/dev/null)
SI_WHY=""
[[ "$SI_RC" == 0 && "$SI_SZ" == 16x16 ]] && si_seq a p0 p1 p2 p3 \
    && pass "laid out again on 2 x 2 cells of 8x8 (16x16): each frame its whole sprite at its source offset, the rotated one turned back" \
    || fail "atlas: exit $SI_RC, canvas '$SI_SZ' (want 16x16), $SI_WHY, '$(tr '\n' '|' <<< "$SI_OUT")'"

info "DRAW's own sheet export opens with its frames"
si_batch "$SI_T/grid.png" --export-anim "$SI_T/rt/rt.json"
SI_RT_RC=$SI_RC
si_open "$SI_T/rt/rt.png"
[[ "$SI_RT_RC" == 0 && "$A_COUNT" == 5 && "$A_FW" == 10 && "$A_FH" == 8 && "$A_G" == 2 && "$A_M" == 1 && "$A_FPS" == 10 && "$A_LOOP" == 0 && "$TG_LIST" == "run 1 3" ]] \
    && pass "rt.png + rt.json from Export Sprite Sheet: the same 5 frames, gutter, margin, FPS, loop and tag" || fail "round trip: export exit $SI_RT_RC, $(si_s)"

info "A .json about another image is not used"
si_open "$SI_T/oth/grid.png"
[[ "$A_ACT" == 0 ]] && pass "oth/grid.png (its .json names other.png): a plain picture" || fail "other image's json: $(si_s)"

# ---- 2. Detect Frames ----
info "Detect Frames: 4 sprites in a row, no gutter"
si_open "$SI_T/row.png"
si_palette "detect frames"; si_read
[[ "$A_ACT" == -1 && "$A_COUNT" == 4 && "$A_FW" == 16 && "$A_FH" == 16 && "$A_G" == 0 && "$A_M" == 0 && "$A_CUR" == 1 ]] \
    && pass "row.png: 4 frames of 16x16 (the feet gaps did not split a sprite)" || fail "detect row: $(si_s)"
park_mouse; key ctrl+z; wait_for 0.6 "undo"; si_read
[[ "$A_ACT" == 0 ]] && pass "undo: no frames again" || fail "undo detect: $(si_s)"

info "Detect Frames: cells edge to edge, gutter 1, margin 1, the last cell empty"
si_open "$SI_T/gut.png"
si_palette "detect frames"; si_read
[[ "$A_COUNT" == 5 && "$A_FW" == 12 && "$A_FH" == 12 && "$A_G" == 1 && "$A_M" == 1 ]] \
    && pass "gut.png: 5 frames of 12x12, gutter 1, margin 1 (the empty sixth cell is not a frame)" || fail "detect gutter: $(si_s)"

info "Detect Frames: sprites that touch"
si_open "$SI_T/touch.png"
si_palette "detect frames"; si_read
[[ "$A_ACT" == 0 ]] && pass "touch.png: no grid found, no frames" || fail "detect touching: $(si_s)"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$SI_T"
assert_window_exists
