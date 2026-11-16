#!/bin/bash
# =============================================================================
# fill-adjust-dither-opacity.sh — QA test: the fill's dither (Fill Adjust, D)
# dithers a gradient's OPACITY stops too (Rick, 2026-11-15: the rainbow in
# Grymmjacks Essential Gradients1, slot 14 - "part dither, part not smooth
# transparency, it's very strange").
#
# That gradient fades in from transparent (opacity stops 0 -> 204 -> 255) and
# out again at the right. The colors were dithered between their stops but the
# alpha stayed a smooth fade. Now a pixel takes one of the two stop opacities
# around it - for the per-pixel dithers and the error diffusions alike.
#
# Dump: FILLADJ active mode ... | VIEW zoom offX offY tool | CVORG x y | DRAWERL / DRAWERR (bins)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Fill Adjust: the dither dithers the opacity stops too ==="
FD_DIR="$(mktemp -d /tmp/draw-qa-fillop-XXXXXX)"
magick -size 320x200 xc:none "PNG32:$FD_DIR/blank.png"
# the launch line is split on spaces: the set goes in under a name without any
cp "$DRAW_ROOT/ASSETS/DSETS/GRADIENTS/Grymmjacks Essential Gradients1.dset" "$FD_DIR/essential1.dset"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="--option DEFAULT_DSET_GRADIENTS_FILE=$FD_DIR/essential1.dset $FD_DIR/blank.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash
dk_begin
read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
sx() { echo $(( OX + $1 * Z / 100 + Z / 200 )); }
sy() { echo $(( OY + $1 * Z / 100 + Z / 200 )); }
fa() { dk_settle; read -r _ F_ACT F_MODE F_AMT _ <<< "$(grep -m1 '^FILLADJ ' "$DK_DUMP")"; }
bn_line() { grep -m1 "^$1 " "$DK_DUMP" 2>/dev/null; }
bin_xy() {
    local DL_COLS DL_VIS DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY DL_ROW0 i r c
    read -r _ DL_COLS _ DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY _ <<< "$(bn_line DRAWERL)"
    read -r _ DL_ROW0 _ <<< "$(bn_line DRAWERR)"
    [[ -n "$DL_COLS" ]] || return 1
    i=$(( $1 - 1 )); r=$(( i / DL_COLS - DL_ROW0 )); c=$(( i % DL_COLS ))
    (( r >= 0 && r < DL_VIS )) || return 1
    BX=$(( DL_CX + c * (DL_BW + DL_GX) + DL_BW / 2 )); BY=$(( DL_CY + r * (DL_BH + DL_GY) + DL_BH / 2 ))
}
# the left fade: canvas x 22..40 of a fill 20..300 (opacity stops at 0, 7%, 11%)
edge() { dk_park; snap_region "$(sx 22)" "$(sy 40)" $(( 18 * Z / 100 )) $(( 100 * Z / 100 )) "$1"; NC=$(magick "$SNAP_RESULT" -format '%k' info: 2>/dev/null); }

key F2; wait_for 0.3 "gradient mode"
dk_settle
if ! bin_xy 14; then fail "gradient bin 14 not showing (DRAWERL: $(bn_line DRAWERL))"; draw_quit; exit 0; fi
click "$BX" "$BY"; wait_for 0.5 "pick the rainbow (bin 14)"
dk_settle
read -r _ G_SLOT G_N _ <<< "$(bn_line GRADSEL)"
(( G_SLOT == 14 && G_N == 6 )) && pass "the Essential rainbow is picked (slot 14, 6 stops)" || fail "picked slot $G_SLOT with $G_N stops (want 14 / 6)"
key F8; wait_for 0.3 "fill adjust on"
key shift+r; wait_for 0.3 "filled rectangle"
drag "$(sx 20)" "$(sy 20)" "$(sx 300)" "$(sy 180)"; wait_for 0.8 "filled rect"
fa
(( F_ACT == 1 )) && pass "the gradient fill enters Fill Adjust" || fail "Fill Adjust not active (active $F_ACT)"
n=0; while (( F_MODE != -1 && n < 24 )); do key d; wait_for 0.2 "D"; fa; n=$((n + 1)); done
edge "smooth"; SMOOTH_NC=$NC
info "the fade, no fill dither: $SMOOTH_NC colors"

key d; wait_for 0.4 "D: ORDERED 2x2"; fa
edge "ordered"; ORD_NC=$NC
screenshot "fill-dither-opacity-ordered"
info "the fade, ORDERED 2x2 (mode $F_MODE): $ORD_NC colors"
(( ORD_NC <= 12 && ORD_NC < SMOOTH_NC )) && pass "ordered: the fade is dithered too ($ORD_NC colors, smooth $SMOOTH_NC)" || fail "ordered: the fade has $ORD_NC colors (smooth $SMOOTH_NC) - its alpha is still a smooth blend"

while (( F_MODE != 4 && n < 60 )); do key d; wait_for 0.2 "D"; fa; n=$((n + 1)); done
edge "fs"; FS_NC=$NC
screenshot "fill-dither-opacity-fs"
info "the fade, FLOYD-STEINBERG (mode $F_MODE): $FS_NC colors"
(( FS_NC <= 12 && FS_NC < SMOOTH_NC )) && pass "Floyd-Steinberg: the fade is dithered too ($FS_NC colors)" || fail "Floyd-Steinberg: the fade has $FS_NC colors (smooth $SMOOTH_NC)"

key Escape; wait_for 0.4 "cancel"
assert_no_crash
rm -rf "$FD_DIR"
