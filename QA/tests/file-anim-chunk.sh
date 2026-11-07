#!/bin/bash
# =============================================================================
# file-anim-chunk.sh — QA test: a document's frame layout is saved in its own
# PNG chunk ("drAn") and survives open + save; the picture is unchanged.
#
# Animation 1.2 (PLANS/ANIMATION.md): the canvas is the sprite sheet, and the
# animation data (frame W x H, gutter, margin, count, current, FPS, loop mode,
# holds - ANIM_serialize$) rides beside the drAw project chunk, so a DRAW
# without animation still opens the file (it reads drAw and skips drAn).
#
# No UI sets a frame layout yet, so the test writes the chunk itself
# (QA/fixtures/png-chunk.py) and has DRAW open the file and export a .draw
# (CLI, throwaway HOME). Checks: the chunk comes back byte for byte from a
# .draw and from a plain PNG sprite sheet; a layout that does not fit the
# canvas is dropped; a document without frames gets no chunk; the picture is
# the same. On a DRAW without animation the picture checks pass and the
# chunk checks fail.
# =============================================================================
info "=== Animation data: the drAn chunk round trip ==="

AN_PNG="$DRAW_ROOT/QA/fixtures/aseprite-frames-f1.png" # 16 x 8: 4 x 2 cells of 4 x 4
AN_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
[[ -f "$AN_PNG" && -f "$AN_PY" ]] || { fail "fixture missing ($AN_PNG / $AN_PY)"; return 0 2>/dev/null || exit 0; }

AN_T="$(mktemp -d /tmp/draw-qa-anim-XXXXXX)"
mkdir -p "$AN_T/home"
an_export() { # IN OUT: DRAW opens IN and saves it as the .draw OUT
    ( cd "$DRAW_ROOT" && HOME="$AN_T/home" XDG_CONFIG_HOME="$AN_T/home/.config" XDG_DATA_HOME="$AN_T/home/.local/share" \
      XDG_CACHE_HOME="$AN_T/home/.cache" timeout --foreground -k 5 60 "$DRAW_BIN" "$1" --export "$2" \
      </dev/null >>"$AN_T/log.txt" 2>&1 )
    [[ -s "$2" ]] || fail "DRAW wrote no export for $(basename "$1"): $(tail -3 "$AN_T/log.txt" | tr '\n' ' ')"
}
an_hex() { python3 - "$@" <<'EOF'
import struct, sys
print(struct.pack("<%dh" % (len(sys.argv) - 1), *map(int, sys.argv[1:])).hex())
EOF
}
an_same_picture() { # A B LABEL
    local ae; ae=$(magick compare -metric AE "$1" "$2" null: 2>&1 | awk '{print $1}')
    [[ "$ae" == 0 ]] && pass "$3" || fail "$3 ($ae pixels differ)"
}

cp "$AN_PNG" "$AN_T/sheet.png"
an_export "$AN_T/sheet.png" "$AN_T/base.draw"
[[ "$(python3 "$AN_PY" get "$AN_T/base.draw" drAn)" == none ]] && pass "a picture without frames saves no drAn chunk" \
    || fail "a picture without frames got a drAn chunk"

# version 1; 4x4 frames, gutter 0, margin 0; 7 of 8 cells; current 3; 12 fps; ping-pong; holds 1 1 3
AN_BLOB=$(an_hex 1 4 4 0 0 7 3 12 2 3 1 1 3)

# 1. a .draw with frames: open + save keeps the chunk
python3 "$AN_PY" put "$AN_T/base.draw" "$AN_T/anim.draw" drAn "$AN_BLOB"
an_export "$AN_T/anim.draw" "$AN_T/out.draw"
AN_GOT=$(python3 "$AN_PY" get "$AN_T/out.draw" drAn)
[[ "$AN_GOT" == "$AN_BLOB" ]] && pass "frames survive open + save of a .draw (byte for byte)" \
    || fail "frames lost or changed on open + save: got [$AN_GOT] want [$AN_BLOB]"
AN_TYPES=$(python3 "$AN_PY" types "$AN_T/out.draw")
[[ "$AN_TYPES" == *"drAw drAn IEND" ]] && pass "drAn sits after drAw, before IEND" || fail "chunk order: $AN_TYPES"
an_same_picture "$AN_T/base.draw" "$AN_T/out.draw" "the picture is unchanged"

# 2. a plain PNG sprite sheet carrying frames: they are picked up
python3 "$AN_PY" put "$AN_T/sheet.png" "$AN_T/anim.png" drAn "$AN_BLOB"
an_export "$AN_T/anim.png" "$AN_T/out2.draw"
AN_GOT=$(python3 "$AN_PY" get "$AN_T/out2.draw" drAn)
[[ "$AN_GOT" == "$AN_BLOB" ]] && pass "a plain PNG's frames are picked up" \
    || fail "a plain PNG's frames were lost: got [$AN_GOT] want [$AN_BLOB]"
an_same_picture "$AN_T/sheet.png" "$AN_T/out2.draw" "the plain PNG's picture is unchanged"

# 3. frames wider than the canvas: dropped, the file still opens
python3 "$AN_PY" put "$AN_T/base.draw" "$AN_T/wide.draw" drAn "$(an_hex 1 99 4 0 0 1 1 12 0 0)"
an_export "$AN_T/wide.draw" "$AN_T/out3.draw"
[[ "$(python3 "$AN_PY" get "$AN_T/out3.draw" drAn)" == none ]] && pass "frames that do not fit the canvas are dropped" \
    || fail "an unfitting frame layout was kept"
an_same_picture "$AN_T/base.draw" "$AN_T/out3.draw" "...and the picture still opens"

# 4. a count past the cells clamps to the cells there are (8)
python3 "$AN_PY" put "$AN_T/base.draw" "$AN_T/many.draw" drAn "$(an_hex 1 4 4 0 0 50 50 12 0 0)"
an_export "$AN_T/many.draw" "$AN_T/out4.draw"
AN_GOT=$(python3 "$AN_PY" get "$AN_T/out4.draw" drAn)
AN_WANT=$(an_hex 1 4 4 0 0 8 8 12 0 0)
[[ "$AN_GOT" == "$AN_WANT" ]] && pass "a frame count past the cells clamps to 8" || fail "count clamp: got [$AN_GOT] want [$AN_WANT]"

rm -rf "$AN_T"
assert_window_exists
