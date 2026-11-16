#!/bin/bash
# =============================================================================
# file-anim-ase-import.sh — QA test: opening an animated Aseprite file makes a
# sheet with frames (Animation 5.2, INPUT/FILE-ASE FILE_ASE_load +
# TOOLS/ANIM-IMPORT ANIM_ASE_apply).
#
# Two or more frames open as frames of the sprite's size on a sheet: each
# layer gets every frame's cel in its cell (a cel's offset kept); the frame
# durations become the FPS and holds; the tags become tags; linked cels become
# linked cells (per layer); a tag over every frame sets the loop. A one-frame
# file still opens as a plain picture.
#
# Fixtures are written here (Python): 12x10, layers "bg" + "ink", 5 frames
# with durations 100 200 100 50 150 ms (= 20 fps, holds 2 4 2 1 3); tags
# walk = frames 1-3, jump = 4-5; bg of frames 2 and 3 linked to frame 1, ink
# of frame 5 linked to frame 3; frame 4's ink a 4x3 cel at (3,2).
# Read back: the dump (ANIM, ANIMTG, ANIMLK for the current layer = bg) and
# the batch CLI's PNG sequence (one PNG per tick), compared with the expected
# frames pixel for pixel.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: Aseprite import ==="

AI_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
AI_T="$(mktemp -d /tmp/draw-qa-aseimp-XXXXXX)"
mkdir -p "$AI_T/home" "$AI_T/o" "$AI_T/x"
python3 - "$AI_T" <<'PY'
import struct, zlib, os, sys
out = sys.argv[1]
W, H = 12, 10
def chunk(t, d): return struct.pack('<IH', 6 + len(d), t) + d
def layer(name):
    n = name.encode()
    return chunk(0x2004, struct.pack('<HHHHHHB3s', 3, 0, 0, 0, 0, 0, 255, b'\0' * 3) + struct.pack('<H', len(n)) + n)
def cel(li, x, y, w, h, px):
    return chunk(0x2005, struct.pack('<HhhBHh5s', li, x, y, 255, 2, 0, b'\0' * 5) + struct.pack('<HH', w, h) + zlib.compress(bytes(px)))
def linked(li, fr):
    return chunk(0x2005, struct.pack('<HhhBHh5s', li, 0, 0, 255, 1, 0, b'\0' * 5) + struct.pack('<H', fr))
def tags(ts):
    d = struct.pack('<H8s', len(ts), b'\0' * 8)
    for a, b, dr, nm in ts:
        n = nm.encode()
        d += struct.pack('<HHBH6s3sB', a, b, dr, 0, b'\0' * 6, b'\0\0\0', 0) + struct.pack('<H', len(n)) + n
    return chunk(0x2018, d)
def frame(chs, dur):
    body = b''.join(chs)
    return struct.pack('<IHHH2sI', 16 + len(body), 0xF1FA, len(chs), dur, b'\0\0', len(chs)) + body
def ase(path, frames):
    body = b''.join(frames)
    hdr = struct.pack('<IHHHHHIHII', 128 + len(body), 0xA5E0, len(frames), W, H, 32, 1, 100, 0, 0)
    hdr += struct.pack('<B3sH', 0, b'\0' * 3, 0) + struct.pack('<BBhhHH', 1, 1, 0, 0, 0, 0)
    open(path, 'wb').write(hdr + b'\0' * (128 - len(hdr)) + body)
def img(w, h, rgba=(0, 0, 0, 0)): return list(rgba) * (w * h)
def put(im, iw, x, y, w, h, rgba):
    for j in range(h):
        for i in range(w):
            o = ((y + j) * iw + x + i) * 4; im[o:o + 4] = rgba
bg1 = img(W, H, (20, 40, 90, 255)); put(bg1, W, 0, 0, W, 1, (200, 200, 200, 255))
bg4 = img(W, H, (90, 20, 40, 255)); bg5 = img(W, H, (30, 90, 30, 255))
inks = []
for k in range(3):
    im = img(W, H); put(im, W, 1 + 3 * k, 4, 3, 3, (250, 220, 0, 255)); put(im, W, 1 + 3 * k, 8, 2, 1, (255, 0, 0, 128)); inks.append(im)
ink4 = img(4, 3, (0, 200, 255, 255))                       # a 4x3 cel at (3,2)
T = [(0, 2, 0, 'walk'), (3, 4, 0, 'jump')]
fr = [
    frame([layer('bg'), layer('ink'), tags(T), cel(0, 0, 0, W, H, bg1), cel(1, 0, 0, W, H, inks[0])], 100),
    frame([linked(0, 0), cel(1, 0, 0, W, H, inks[1])], 200),
    frame([linked(0, 0), cel(1, 0, 0, W, H, inks[2])], 100),
    frame([cel(0, 0, 0, W, H, bg4), cel(1, 3, 2, 4, 3, ink4)], 50),
    frame([cel(0, 0, 0, W, H, bg5), linked(1, 2)], 150),
]
ase(os.path.join(out, 'walk.aseprite'), fr)
# the same frames, one tag over all of them, ping-pong
ase(os.path.join(out, 'ping.aseprite'), [frame([layer('bg'), layer('ink'), tags([(0, 4, 2, 'all')]), cel(0, 0, 0, W, H, bg1)], 100)] + fr[1:])
# one frame: a plain picture
ase(os.path.join(out, 'one.aseprite'), [frame([layer('bg'), cel(0, 0, 0, W, H, bg1)], 100)])
# the expected frames: ink over bg, normal blending
def comp(b, s):
    o = []
    for p in range(W * H):
        a = s[p * 4 + 3] / 255
        o += [round(s[p * 4 + k] * a + b[p * 4 + k] * (1 - a)) for k in range(3)] + [255]
    return o
i4 = img(W, H)
for j in range(3):
    for i in range(4): i4[((2 + j) * W + 3 + i) * 4:((2 + j) * W + 3 + i) * 4 + 4] = ink4[(j * 4 + i) * 4:(j * 4 + i) * 4 + 4]
exp = [comp(bg1, inks[0]), comp(bg1, inks[1]), comp(bg1, inks[2]), comp(bg4, i4), comp(bg5, inks[2])]
for k, e in enumerate(exp):
    raw = os.path.join(out, 'x', f'e{k}.rgba'); open(raw, 'wb').write(bytes(e))
    os.system(f"magick -size {W}x{H} -depth 8 rgba:'{raw}' 'PNG32:{os.path.join(out, 'x', f'e{k}.png')}'"); os.remove(raw)
PY

ai_line() { grep -m1 "^$1 " "$AI_DUMP" 2>/dev/null; }
ai_read() { # A_ACT A_COUNT A_FW A_FH A_FPS A_LOOP, TG_LIST, LK_N LK_MAP
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ A_ACT A_COUNT _ A_FW A_FH _ _ _ _ A_FPS A_LOOP _ <<< "$(ai_line ANIM)"
    TG_LIST=""; read -r _ _ _ TG_LIST <<< "$(ai_line ANIMTG)"; TG_LIST="${TG_LIST% _}"
    LK_N=""; LK_MAP=""; read -r _ LK_N LK_MAP _ <<< "$(ai_line ANIMLK)"
}
ai_s() { echo "active ${A_ACT:-?} frames ${A_COUNT:-?} of ${A_FW:-?}x${A_FH:-?} at ${A_FPS:-?} fps, loop ${A_LOOP:-?}, tags '${TG_LIST:-}', links ${LK_N:-?} '${LK_MAP:-}'"; }
ai_open() { # FILE
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$1"
    draw_launch 15
    wait_for 1.5 "Aseprite file loaded"
    assert_no_crash
    ai_read
}

info "Opening a 5-frame Aseprite file"
ai_open "$AI_T/walk.aseprite"
[[ "$A_ACT" == -1 && "$A_COUNT" == 5 && "$A_FW" == 12 && "$A_FH" == 10 && "$A_FPS" == 20 && "$A_LOOP" == 0 ]] \
    && pass "walk.aseprite: 5 frames of 12x10 at 20 fps (durations 100 200 100 50 150 ms), looping forward" || fail "walk.aseprite: $(ai_s) (wanted 5 frames of 12x10 at 20 fps, loop 0)"
[[ "$TG_LIST" == "walk 1 3 jump 4 5" ]] && pass "its tags: walk = frames 1-3, jump = 4-5" || fail "tags: $(ai_s) (wanted 'walk 1 3 jump 4 5')"
[[ "$LK_N" == 5 && "$LK_MAP" == "Aaa.." ]] && pass "linked cels: bg of frames 2-3 show frame 1's (Aaa..), 5 linked cells over both layers" || fail "links: $(ai_s) (wanted 5 'Aaa..')"

# every frame's pixels + the holds (2 4 2 1 3 ticks at 20 fps)
AI_OUT=$( cd "$DRAW_ROOT" && HOME="$AI_T/home" XDG_CONFIG_HOME="$AI_T/home/.config" XDG_DATA_HOME="$AI_T/home/.local/share" \
  XDG_CACHE_HOME="$AI_T/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$AI_T/walk.aseprite" --export-anim "$AI_T/o/w.png" </dev/null 2>>"$AI_T/err.txt" )
AI_RC=$?
AI_WHY=""; k=1
for f in 0 0 1 1 1 1 2 2 3 4 4 4; do
    png="$AI_T/o/w_$(printf %04d $k).png"
    [[ -s "$png" ]] || { AI_WHY="missing $(basename "$png")"; break; }
    ae=$(magick compare -metric AE -fuzz 1% "$png" "$AI_T/x/e$f.png" null: 2>&1 | awk '{print $1}')
    [[ "$ae" == 0 ]] || { AI_WHY="$(basename "$png") vs frame $(( f + 1 )): '$ae' pixels differ"; cp -f "$png" "$SCREENSHOTS_DIR/ase-import-got.png" 2>/dev/null; break; }
    k=$(( k + 1 ))
done
[[ -z "$AI_WHY" && ! -e "$AI_T/o/w_0013.png" ]] || AI_WHY="${AI_WHY:-more PNGs than ticks}"
[[ "$AI_RC" == 0 && -z "$AI_WHY" ]] \
    && pass "its PNG sequence: frames 1 1 2 2 2 2 3 3 4 5 5 5 (the holds), each exactly the file's frame (offset cel, linked cels)" \
    || fail "walk.aseprite frames: exit $AI_RC, $AI_WHY, '$(tr '\n' '|' <<< "$AI_OUT")'"

info "A tag over every frame, ping-pong"
ai_open "$AI_T/ping.aseprite"
[[ "$A_COUNT" == 5 && "$A_LOOP" == 2 && "$TG_LIST" == "all 1 5" ]] && pass "ping.aseprite: 5 frames, loop ping-pong (2), tag all = 1-5" || fail "ping.aseprite: $(ai_s) (wanted loop 2, tag 'all 1 5')"

info "A one-frame Aseprite file"
ai_open "$AI_T/one.aseprite"
[[ "$A_ACT" == 0 ]] && pass "one.aseprite: a plain picture, no frames" || fail "one.aseprite: $(ai_s)"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$AI_T"
assert_window_exists
