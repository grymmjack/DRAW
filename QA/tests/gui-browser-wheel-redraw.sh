#!/bin/bash
# =============================================================================
# gui-browser-wheel-redraw.sh — QA test: a wheel scroll over the Browser's file
# list shows at once, with the pointer held still. The Browser consumes the
# wheel (MOUSE.SW -> 0) and only marks the scene dirty, and idle frames skip
# SCREEN_render, so the scroll appeared only on the next mouse move.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=60 BROWSER_WIDTH=320 BROWSER_HEIGHT=220 BROWSER_DEFAULT_FOLDER=ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX BROWSER_DEFAULT_PREVIEW_OPEN=0 BROWSER_DEFAULT_VIEW_MODE=2
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Browser: wheel scroll redraws without a mouse move Test ==="
dk_begin
read -r _ _ WX WY WW WH _ <<< "$(grep '^WIN browser ' "$DK_DUMP")"
[[ -n "$WH" ]] || fail "the Browser is not showing"
LX=$(( WX + WW * 2 / 3 )); LY=$(( WY + WH / 2 ))
info "browser at $WX,$WY ${WW}x$WH, file list point $LX,$LY"
hover "$LX" "$LY"; wait_for 1.0 "pointer still over the file list"
snap_region $(( WX + WW / 2 )) $(( WY + 30 )) $(( WW / 2 - 4 )) $(( WH - 50 )) "list-before"
BEFORE=$SNAP_RESULT
for i in 1 2 3; do driver_input_scroll down 1; sleep 0.05; done
wait_for 0.6 "the scroll, pointer not moved"
snap_region $(( WX + WW / 2 )) $(( WY + 30 )) $(( WW / 2 - 4 )) $(( WH - 50 )) "list-after"
assert_regions_differ "$BEFORE" "$SNAP_RESULT" \
    "the file list shows the wheel scroll with the pointer held still"
screenshot "browser-wheel-redraw"
assert_window_exists
info "=== Browser: wheel scroll redraws without a mouse move Test PASSED ==="
