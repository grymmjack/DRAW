#!/bin/bash
# =============================================================================
# gui-charmap-scroll-range.sh — QA test: scrolled to the end, the character
# map's last row is wholly above its page indicator bar, and hovering the bar
# highlights no cell. The scroll range once used the whole panel height (not
# the grid's viewport above the 14px bar), so the last row stayed under it.
# Reads CMAP <scrollY> <max> <rows> <cellH> <rowStep> <gridY> <panelY2> <barH> <hover>.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt CHARMAP_VISIBLE=1 CHARMAP_ZOOM_LEVEL=3
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Charmap: scroll range ends above the page bar Test ==="
dk_begin
# short enough to scroll: under the drawer in the toolbox column
dk_move charmap below drawer && dk_expect_stacked drawer charmap
cmap() { read -r _ CM_SY CM_MAX CM_ROWS CM_CH CM_STEP CM_GY CM_Y2 CM_BAR CM_HOV <<< "$(grep '^CMAP ' "$DK_DUMP")"; }
dk_p charmap
GX=$(( P_X + 20 )); GY=$(( P_Y + P_H / 3 ))
cmap
info "charmap at $P_X,$P_Y ${P_W}x$P_H: rows $CM_ROWS, step $CM_STEP, max scroll $CM_MAX"
(( CM_MAX > 0 )) || fail "the charmap does not scroll here (max $CM_MAX) - nothing to test"
for i in $(seq 1 60); do scroll_down "$GX" "$GY"; done
wait_for 0.3 "scrolled to the end"; dk_park; dk_settle
cmap
LAST_BOT=$(( CM_GY - CM_SY + (CM_ROWS - 1) * CM_STEP + CM_CH - 1 ))
VIEW_BOT=$(( CM_Y2 - 1 - CM_BAR ))
info "scrolled $CM_SY/$CM_MAX: last row ends y=$LAST_BOT, viewport ends y=$VIEW_BOT"
(( CM_SY == CM_MAX )) || fail "did not reach the end of the scroll ($CM_SY of $CM_MAX)"
if (( LAST_BOT <= VIEW_BOT )); then
    pass "scrolled to the end, the last row is wholly above the page bar"
else
    fail "scrolled to the end, the last row runs $(( LAST_BOT - VIEW_BOT ))px under the page bar"
fi
# the bar itself: no (hidden) cell under it
hover "$GX" $(( CM_Y2 - CM_BAR / 2 )); wait_for 0.4 "hover the page bar"
hover $(( GX + 1 )) $(( CM_Y2 - CM_BAR / 2 )); sleep 0.3; dk_settle
cmap
if (( CM_HOV < 0 )); then pass "hovering the page bar highlights no cell"; else fail "hovering the page bar highlights cell $CM_HOV (hidden under it)"; fi
assert_window_exists
info "=== Charmap: scroll range ends above the page bar Test PASSED ==="
