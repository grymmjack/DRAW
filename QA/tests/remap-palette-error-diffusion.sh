#!/bin/bash
# =============================================================================
# remap-palette-error-diffusion.sh — QA test: Palette > Remap to Palette with
# an error-diffusion dither (Rick, 2026-11-15).
#
# The dialog offered Floyd-Steinberg ... Shiau-Fan but treated them as no
# dither at all (the per-pixel threshold gave 0.5 for them), so picking one
# gave the same flat bands as OFF. Now each pixel's miss is carried on to the
# pixels after it by the algorithm's own kernel (PALETTE_LOADER_remap_image%).
#
# A smooth gray ramp is remapped to the palette three times - OFF, FLOYD-
# STEINBERG, FAN - and each result is compared.
# =============================================================================
info "=== Remap to Palette: error-diffusion dithers ==="
RM_DIR="$(mktemp -d /tmp/draw-qa-remap-XXXXXX)"
magick -size 200x320 gradient:'#202020-#e8e8e8' -rotate -90 "PNG32:$RM_DIR/ramp.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$RM_DIR/ramp.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash

# the dialog: 256 x 254, centred; its D: button at (8, 166) 240 x 18
DLG_X=$(( (VIEWPORT_W - 256) / 2 )); DLG_Y=$(( (VIEWPORT_H - 254) / 2 ))
DBX=$(( DLG_X + 128 )); DBY=$(( DLG_Y + 166 + 9 ))
remap() { # clicks on the dither button (0 = OFF, 5 = FLOYD-STEINBERG, 13 = FAN)
    key question; wait_for 0.6 "command palette"
    type_text "Remap to Palette"; wait_for 0.5 "filtered"
    key Return; wait_for 0.8 "remap dialog"
    local i; for (( i = 0; i < $1; i++ )); do click "$DBX" "$DBY"; sleep 0.15; done
    wait_for 0.5 "preview"
    screenshot "remap-dialog-$2"
    key Return; wait_for 1.0 "remapped"
    park_mouse
    snap_region $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 40 )) 240 80 "remap-$2"
    NC=$(magick "$SNAP_RESULT" -format '%k' info: 2>/dev/null)
}

park_mouse
snap_region $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 40 )) 240 80 "ramp"; RAMP="$SNAP_RESULT"
remap 0 off; OFF="$SNAP_RESULT"; OFF_NC=$NC
info "OFF: $OFF_NC colors"
cmp -s "$RAMP" "$OFF" && fail "Remap to Palette (OFF) left the ramp as it was" || pass "Remap to Palette (OFF) remapped the ramp ($OFF_NC colors)"
key ctrl+z; wait_for 0.5 "undo"

remap 5 fs; FS="$SNAP_RESULT"; FS_NC=$NC
info "FLOYD-STEINBERG: $FS_NC colors"
cmp -s "$OFF" "$FS" && fail "FLOYD-STEINBERG gave the same flat bands as OFF" || pass "FLOYD-STEINBERG dithers (not the same as OFF)"
(( FS_NC <= OFF_NC + 4 )) && pass "FLOYD-STEINBERG uses palette colors only ($FS_NC colors, OFF $OFF_NC)" || fail "FLOYD-STEINBERG left $FS_NC colors (OFF $OFF_NC) - not palette colors?"
key ctrl+z; wait_for 0.5 "undo"

remap 13 fan; FAN="$SNAP_RESULT"
cmp -s "$FS" "$FAN" && fail "FAN looks the same as FLOYD-STEINBERG" || pass "FAN dithers its own way (not FLOYD-STEINBERG)"
cmp -s "$OFF" "$FAN" && fail "FAN gave the same flat bands as OFF"
screenshot "remap-fan"
assert_no_crash
rm -rf "$RM_DIR"
