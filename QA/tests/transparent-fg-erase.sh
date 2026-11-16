#!/bin/bash
# =============================================================================
# transparent-fg-erase.sh — QA test: a transparent FG erases, live, in every tool
# (BUGS.md 2026-11-15, X1)
#
# FG made transparent with the status bar's X chip (as Rick does), on a red
# 320x200 image. For each tool, mid-drag (before the release commits):
#   - no black pixel shows (the old preview was a white line on a black
#     outline, which read as "it draws black"),
#   - the transparency checkerboard shows where the erase will be.
# After the release: the pixels are erased (not red, not black) - including a
# filled rectangle in gradient and pattern paint modes, which used to do nothing.
# The custom brush's cursor shows its footprint as the checkerboard.
#
# Dump: STCHIP chipX chipY fgTransparent fgHex
# =============================================================================
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== transparent FG erases (X1) ==="
PD="$(mktemp -d /tmp/draw-qa-tfg-XXXXXX)"
magick -size 320x200 xc:'#c00000' "PNG32:$PD/red.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$PD/red.png"
draw_launch 15; wait_for 1.5 "loaded"
dk_begin
read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
sx() { echo $(( OX + $1 * Z / 100 + Z / 200 )); }
sy() { echo $(( OY + $1 * Z / 100 + Z / 200 )); }
RW=$(( 280 * Z / 100 )); RH=$(( 160 * Z / 100 ))

# --- the status bar's X chip makes the FG transparent ---
read -r _ CX CY FT _ <<< "$(grep -m1 '^STCHIP' "$DK_DUMP")"
(( FT == 0 )) && pass "FG starts opaque" || info "FG already transparent"
click $(( CX + 4 )) $(( CY + 4 )); wait_for 0.4 "chip"; dk_settle
read -r _ _ _ FT FH <<< "$(grep -m1 '^STCHIP' "$DK_DUMP")"
(( FT == -1 )) && [[ $FH == 0 ]] && pass "the X chip made the FG transparent" || fail "X chip: FG transparent=$FT color=$FH"

nblack() { magick "$1" -fill white +opaque black -fill black -opaque black -format '%[fx:int(w*h*(1-mean))]' info:; }
# QA cfg checkerboard colors: 707070 / 4C4C4C
nchk() { magick "$1" -fill white +opaque '#707070' -fill black -opaque '#707070' -format '%[fx:int(w*h*(1-mean))]' info:; }
nred() { magick "$1" -fuzz 10% -fill white +opaque '#c00000' -fill black -opaque '#c00000' -format '%[fx:int(w*h*(1-mean))]' info:; }

mid() { # name tool-key x2 y2
    key $2; sleep 0.3
    mouse_down "$(sx 40)" "$(sy 50)"; sleep 0.1; hover "$(sx 120)" "$(sy 90)"; sleep 0.1; hover "$(sx $3)" "$(sy $4)"; sleep 0.5
    snap_region "$(sx 20)" "$(sy 20)" $RW $RH "mid-$1"
    local nb nc; nb=$(nblack "$SNAP_RESULT"); nc=$(nchk "$SNAP_RESULT")
    screenshot "tfg-mid-$1"   # after the counts: screenshot replaces SNAP_RESULT
    (( nb == 0 )) && pass "$1 while dragging: no black" || fail "$1 while dragging: $nb black pixels"
    (( nc > 0 )) && pass "$1 while dragging: the checkerboard shows the erase ($nc px)" || fail "$1 while dragging: no checkerboard"
    mouse_up; sleep 0.5; dk_park; sleep 0.3
    snap_region "$(sx 20)" "$(sy 20)" $RW $RH "post-$1"
    local pa total; pa=$(nred "$SNAP_RESULT"); total=$(magick "$SNAP_RESULT" -format '%[fx:w*h]' info:)
    nb=$(nblack "$SNAP_RESULT")
    (( total - pa > 0 && nb == 0 )) && pass "$1 released: erased $(( total - pa )) px, no black" || fail "$1 released: erased $(( total - pa )) px, black $nb"
    key ctrl+z; sleep 0.4
}
mid brush b 260 100
mid line l 260 140
mid rect r 260 140
mid rectf shift+r 260 140
mid ell c 260 140
mid ellf shift+c 260 140
mid spray k 260 100

# --- gradient / pattern paint modes: a transparent FG still erases ---
for m in F2:gradient F3:pattern; do
    key ${m%%:*}; sleep 0.3; key shift+r; sleep 0.3
    dk_park; snap_region "$(sx 20)" "$(sy 20)" $RW $RH "pre-${m#*:}"; PRE=$SNAP_RESULT
    drag "$(sx 40)" "$(sy 40)" "$(sx 260)" "$(sy 140)"; sleep 0.5; dk_park; sleep 0.3
    snap_region "$(sx 20)" "$(sy 20)" $RW $RH "post-${m#*:}"
    nb=$(nblack "$SNAP_RESULT"); nc=$(nchk "$SNAP_RESULT")
    ! cmp -s "$PRE" "$SNAP_RESULT" && (( nc > 0 && nb == 0 )) && pass "${m#*:} mode filled rect erases" || fail "${m#*:} mode filled rect: checker $nc black $nb"
    key ctrl+z; sleep 0.4; key F1; sleep 0.2
done

# --- custom brush cursor: its footprint as the checkerboard ---
key m; sleep 0.3; drag "$(sx 100)" "$(sy 80)" "$(sx 130)" "$(sy 110)"; sleep 0.3; key ctrl+b; sleep 0.5
hover "$(sx 150)" "$(sy 100)"; sleep 0.2; hover "$(sx 152)" "$(sy 100)"; sleep 0.5
snap_region "$(sx 120)" "$(sy 70)" $(( 60 * Z / 100 )) $(( 60 * Z / 100 )) "cbrush-hover"
nb=$(nblack "$SNAP_RESULT"); nc=$(nchk "$SNAP_RESULT")
(( nc > 0 && nb == 0 )) && pass "custom brush cursor shows the erase ($nc px checkerboard)" || fail "custom brush cursor: checker $nc black $nb"
screenshot "tfg-cbrush-hover"
key ctrl+b; sleep 0.3

rm -rf "$PD"
assert_no_crash
