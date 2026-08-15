#!/bin/bash
# =============================================================================
# effect-texture-basics.sh — QA test / regression guard
#
# EFFECTS > TEXTURE > Wood / Marble / Brick Wall — the first three Eye Candy
# TEXTURE effects, painting a procedural surface onto the shape (masked to alpha).
# (Added 2026-08-15.) TEXTURE is the NEW EFFECTS category index 8; children are
# Wood(0), Marble(1), Brick Wall(2) -> open_effect 8 0 / 8 1 / 8 2. Also guards
# that the new category is navigable at all.
#
# Thick green blob on a transparent layer; apply each; assert the interior changed
# (blob recoloured into the texture).
# =============================================================================

info "=== Effect: TEXTURE basics (Wood/Marble/Brick) Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 40 )) "$CANVAS_CY" $(( CANVAS_CX + 40 )) "$CANVAS_CY"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 12 )); GW=80; GH=24

texture_case() {
    local child=$1 name=$2
    park_mouse
    snap_region "$GX" "$GY" "$GW" "$GH" "$name-before"
    local before="$SNAP_RESULT"
    open_effect 8 "$child" ; wait_for 0.5 "$name dialog open"
    screenshot "$name-dialog"
    key Return ; wait_for 0.7 "Applied (OK), dialog closed"
    assert_no_crash
    park_mouse
    snap_region "$GX" "$GY" "$GW" "$GH" "$name-after"
    assert_regions_differ "$before" "$SNAP_RESULT" \
        "TEXTURE>$name (open_effect 8 $child) must paint its surface onto the shape"
    key ctrl+z ; wait_for 0.4 "Undo texture"   # revert so the next texture starts clean
}

texture_case 0 "wood"
texture_case 1 "marble"
texture_case 2 "brick"

assert_no_crash
assert_window_exists
info "=== Effect: TEXTURE basics Test PASSED ==="
