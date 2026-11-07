#!/bin/bash
# =============================================================================
# file-aseprite-frames.sh — QA test: an animated .aseprite opens as its FIRST
# frame, with part-transparent pixels kept as they are.
#
# Found 2026-11-07 while planning animation (PLANS/ANIMATION.md, Q-30): the
# Aseprite loader (QB64_GJ_LIB load_specific_layer_image&) painted a layer's
# cel from EVERY frame into one image, so a multi-frame file opened with all
# its frames on top of each other; and it blended each pixel onto the cleared
# image, so 50%-alpha pixels came out darker.
#
# Fixture: QA/fixtures/aseprite-frames.aseprite (make-aseprite-frames.py): two
# layers, three frames; frame 1 has opaque black and 50%-alpha red / white
# blocks, frames 2 and 3 draw a green top row / yellow bottom row (frame 3's bg
# is a linked cel). Expected: QA/fixtures/aseprite-frames-f1.png.
# DRAW opens it from the command line and exports a .draw (a PNG whose picture
# is the flattened document), in a throwaway HOME so no config is touched.
# =============================================================================
info "=== Aseprite import: first frame only ==="

ASE_FX="$DRAW_ROOT/QA/fixtures/aseprite-frames.aseprite"
ASE_EXP="$DRAW_ROOT/QA/fixtures/aseprite-frames-f1.png"
[[ -f "$ASE_FX" && -f "$ASE_EXP" ]] || { fail "fixture missing ($ASE_FX / $ASE_EXP)"; return 0 2>/dev/null || exit 0; }

ASE_T="$(mktemp -d /tmp/draw-qa-ase-XXXXXX)"
mkdir -p "$ASE_T/home"
cp "$ASE_FX" "$ASE_T/in.aseprite"
( cd "$DRAW_ROOT" && HOME="$ASE_T/home" XDG_CONFIG_HOME="$ASE_T/home/.config" XDG_DATA_HOME="$ASE_T/home/.local/share" \
  XDG_CACHE_HOME="$ASE_T/home/.cache" timeout --foreground -k 5 60 "$DRAW_BIN" "$ASE_T/in.aseprite" --export "$ASE_T/out.draw" \
  </dev/null >"$ASE_T/log.txt" 2>&1 )
ASE_RC=$?
if [[ ! -s "$ASE_T/out.draw" ]]; then
    fail "DRAW wrote no export (exit $ASE_RC): $(tail -3 "$ASE_T/log.txt" | tr '\n' ' ')"
    rm -rf "$ASE_T"; return 0 2>/dev/null || exit 0
fi

read -r ASE_W ASE_H < <(magick identify -format '%w %h' "$ASE_T/out.draw" 2>/dev/null)
[[ "$ASE_W" == 16 && "$ASE_H" == 8 ]] && pass "opened at the file's size (16x8)" || fail "opened at ${ASE_W}x$ASE_H, not 16x8"

# a whole-picture match: frame 1 only (no green top row / yellow bottom row
# from frames 2-3) and the 50% blocks blended once, not darkened
ASE_AE=$(magick compare -metric AE -fuzz 1% "$ASE_EXP" "$ASE_T/out.draw" null: 2>&1 | awk '{print $1}')
if [[ "$ASE_AE" == 0 ]]; then
    pass "the picture is frame 1, pixel for pixel"
else
    cp -f "$ASE_T/out.draw" "$SCREENSHOTS_DIR/aseprite-frames-got.png" 2>/dev/null
    fail "$ASE_AE pixels differ from frame 1 (got: screenshots/aseprite-frames-got.png)"
fi

px() { magick "$ASE_T/out.draw" -format "%[hex:p{$1,$2}]" info: 2>/dev/null | cut -c1-6; }
ASE_TOP=$(px 5 0); ASE_BOT=$(px 5 7); ASE_RED=$(px 7 3); ASE_BLK=$(px 2 3)
info "pixels: top row $ASE_TOP, bottom row $ASE_BOT, 50% red $ASE_RED, black $ASE_BLK"
[[ "$ASE_TOP" == 102060 && "$ASE_BOT" == 102060 ]] && pass "frames 2 and 3 left nothing behind" || fail "frames 2/3 painted over frame 1 (top $ASE_TOP, bottom $ASE_BOT; want 102060)"
[[ "$ASE_BLK" == 000000 ]] && pass "opaque black stays black" || fail "opaque black came out $ASE_BLK"
ASE_WANT=$(magick "$ASE_EXP" -format "%[hex:p{7,3}]" info: | cut -c1-6)
near() { local a=$1 b=$2 i d; for i in 0 2 4; do d=$(( 16#${a:i:2} - 16#${b:i:2} )); (( d < -2 || d > 2 )) && return 1; done; return 0; }
near "$ASE_RED" "$ASE_WANT" && pass "50% red blends once ($ASE_RED)" || fail "50% red came out $ASE_RED, want $ASE_WANT"
rm -rf "$ASE_T"
assert_window_exists
