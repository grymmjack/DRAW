#!/bin/bash
# =============================================================================
# layer-thumb-menu.sh — QA test: right-click a layer's thumbnail > its size
# (Rick, 2026-11-14: "Layer thumbnails: right-click a thumbnail > size").
#
# Thumbnails off: the layer menu ends with SHOW THUMBNAILS (small). On, a
# right-click ON a thumbnail opens the thumbnail menu - TINY / SMALL / MEDIUM
# (the current one checked), SHOW CONTENT / SHOW CANVAS, HIDE THUMBNAILS -
# and each pick is saved like Settings > Panels > Thumbnails. A right-click on
# the name beside it is still the layer menu.
#
# (the thumbnail keys are not pinned in QA-OPTIONS: --option keys are never saved)
# Dump: LPMENU open thumb x y w n; LPMENUR row value y h checked (values:
# 200 + size 0..3, 210 + fit 0..1); LPTHUMB x size; LPGEO header row bar.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Layers: right-click a thumbnail > size ==="

geo() { read -r _ G_HDR G_ROW G_BAR <<< "$(grep -m1 '^LPGEO ' "$DK_DUMP")"; }
thumb() { read -r _ T_X T_SZ <<< "$(grep -m1 '^LPTHUMB ' "$DK_DUMP")"; }
menu() { read -r _ M_OPEN M_THUMB M_X M_Y M_W M_N <<< "$(grep -m1 '^LPMENU ' "$DK_DUMP")"; }
row_of() { awk -v v="$1" '$1=="LPMENUR" && $3==v {print $4" "$5" "$6; exit}' "$DK_DUMP"; }
saved() { grep -q "^$1=$2\b" "$QA_CFG" && pass "$1=$2 saved" || fail "$1: saved '$(grep "^$1=" "$QA_CFG")', want $2"; }
# pick VALUE in the open menu
pick() {
    local ry rh
    read -r ry rh _ <<< "$(row_of "$1")"
    if [[ -z "$ry" ]]; then fail "no menu row $1"; key Escape; return 1; fi
    click $(( M_X + M_W / 2 )) $(( ry + rh / 2 )); wait_for 0.6 "menu row $1"; dk_park; dk_settle
}
TOP_Y() { echo $(( P_Y + G_HDR + G_ROW / 2 )); }

dk_begin
park_mouse; key ctrl+shift+n; wait_for 0.6 "layer 2"; dk_settle
dk_p layers || fail "no layers panel in the dump"
geo; R0=$G_ROW; thumb
[[ "$T_SZ" == 0 ]] && pass "thumbnails off at the start" || fail "thumbnails on at the start ($T_SZ)"

# --- off: the layer menu has SHOW THUMBNAILS --------------------------------
right_click $(( P_X + P_W / 2 )) "$(TOP_Y)"; wait_for 0.6 "the layer menu"; dk_settle; menu
[[ "$M_OPEN" == -1 && "$M_THUMB" == 0 ]] && pass "off: right-click a row opens the layer menu" || fail "off: menu open '$M_OPEN' thumb '$M_THUMB'"
if [[ -n "$(row_of 202)" ]]; then pass "off: the layer menu has SHOW THUMBNAILS"; pick 202; else fail "off: no SHOW THUMBNAILS row"; key Escape; fi
saved LAYER_THUMBNAILS SMALL
geo; thumb
(( T_SZ == 32 && G_ROW == 36 )) && pass "small: 32 px thumbnails, 36 px rows" || fail "small: thumb $T_SZ, row $G_ROW (want 32 / 36)"
screenshot "layer-thumb-menu-small"

# --- on: a right-click on the thumbnail is the thumbnail menu ---------------
right_click $(( T_X + T_SZ / 2 )) "$(TOP_Y)"; wait_for 0.6 "the thumbnail menu"; dk_settle; menu
[[ "$M_OPEN" == -1 && "$M_THUMB" == -1 ]] && pass "right-click the thumbnail: the thumbnail menu" || fail "thumbnail: menu open '$M_OPEN' thumb '$M_THUMB'"
read -r _ _ CK <<< "$(row_of 202)"
[[ "$CK" == -1 ]] && pass "the thumbnail menu checks SMALL" || fail "SMALL row checked '$CK'"
[[ -z "$(row_of 707)" ]] && pass "no layer commands in it" || fail "the thumbnail menu has DUPLICATE (707)"
snap_region "$P_X" "$P_Y" "$P_W" $(( G_HDR + G_ROW * 2 )) "rows-small"; S_SMALL=$SNAP_RESULT
pick 203
saved LAYER_THUMBNAILS MEDIUM
geo; thumb
(( T_SZ == 48 && G_ROW == 52 )) && pass "medium: 48 px thumbnails, 52 px rows" || fail "medium: thumb $T_SZ, row $G_ROW (want 48 / 52)"
snap_region "$P_X" "$P_Y" "$P_W" $(( G_HDR + 36 * 2 )) "rows-medium"
assert_regions_differ "$S_SMALL" "$SNAP_RESULT" "the panel redraws with bigger thumbnails"

# what it shows
right_click $(( T_X + T_SZ / 2 )) "$(TOP_Y)"; wait_for 0.6 "the thumbnail menu"; dk_settle; menu
pick 211
saved LAYER_THUMBNAIL_FIT CANVAS
right_click $(( T_X + T_SZ / 2 )) "$(TOP_Y)"; wait_for 0.6 "the thumbnail menu"; dk_settle; menu
read -r _ _ CK <<< "$(row_of 211)"
[[ "$CK" == -1 ]] && pass "the thumbnail menu checks SHOW CANVAS" || fail "SHOW CANVAS checked '$CK'"
pick 210
saved LAYER_THUMBNAIL_FIT CONTENT

# the name beside the thumbnail is still the layer menu
right_click $(( P_X + P_W - 30 )) "$(TOP_Y)"; wait_for 0.6 "the layer menu"; dk_settle; menu
[[ "$M_OPEN" == -1 && "$M_THUMB" == 0 && -n "$(row_of 707)" && -z "$(row_of 202)" ]] && pass "right-click the name: the layer menu (no thumbnail rows while they are on)" || fail "name: menu open '$M_OPEN' thumb '$M_THUMB'"
key Escape; wait_for 0.4 "close"; dk_park; dk_settle; menu
[[ "$M_OPEN" == 0 ]] || { click $(( P_X + P_W / 2 )) $(( P_Y + P_H - G_BAR - 40 )); wait_for 0.4 "close"; dk_park; dk_settle; }

# hide them again
right_click $(( T_X + T_SZ / 2 )) "$(TOP_Y)"; wait_for 0.6 "the thumbnail menu"; dk_settle; menu
pick 200
saved LAYER_THUMBNAILS OFF
geo; thumb
(( T_SZ == 0 && G_ROW == R0 )) && pass "off again: no thumbnails, ${G_ROW}px rows" || fail "off: thumb $T_SZ, row $G_ROW (want 0 / $R0)"
assert_no_crash
info "=== Layers: right-click a thumbnail > size: done ==="
