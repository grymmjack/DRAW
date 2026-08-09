#!/bin/bash
# =============================================================================
# ui-textbar-visibility.sh — QA test: TEXT_BAR follows the active tool
#
# SCREEN.BM decides this every frame:
#   TEXT_BAR.visible% = (CURRENT_TOOL% = TOOL_TEXT) OR (TEXT_BAR.editingLayerIdx% > 0)
# and TOOLS_reset_all -> TEXT_reset clears editingLayerIdx% on every tool
# switch. This pins the simple half of that: with no text entry ever started,
# T shows the bar and any other tool hides it again.
#
# The status-bar check in the middle is the important one — it proves the tool
# actually changed, so a failure here means the BAR is wrong rather than the
# keypress having been swallowed.
#
# Split from tool-text.sh, where the equivalent checks run only after a text
# layer has been committed; see the notes there.
# =============================================================================

info "=== TEXT_BAR Visibility Test ==="
canvas_focus b
wait_for 0.4 "Brush ready"
key grave
wait_for 0.2 "Pointer hidden"

BAR_X=$WORK_LEFT; BAR_Y=$MENU_BAR_H; BAR_W=$WORK_W; BAR_H=30
SB_Y=$(( VIEWPORT_H - STATUS_H ))

park_mouse
snap_region "$BAR_X" "$BAR_Y" "$BAR_W" "$BAR_H" "tb-brush"
BAR_BRUSH="$SNAP_RESULT"

key t
wait_for 0.8 "Text tool active"
park_mouse
snap_region "$BAR_X" "$BAR_Y" "$BAR_W" "$BAR_H" "tb-text"
BAR_TEXT="$SNAP_RESULT"
snap_region 0 "$SB_Y" "$VIEWPORT_W" "$STATUS_H" "tb-sb-text"
SB_TEXT="$SNAP_RESULT"
assert_regions_differ "$BAR_BRUSH" "$BAR_TEXT" "T should show the text formatting bar"
screenshot "textbar-visible"

# Back to brush WITHOUT starting a text entry, so editingLayerIdx% stays 0.
wake_draw
key b
wait_for 0.8 "Brush tool again"
park_mouse
snap_region "$BAR_X" "$BAR_Y" "$BAR_W" "$BAR_H" "tb-back"
BAR_BACK="$SNAP_RESULT"
snap_region 0 "$SB_Y" "$VIEWPORT_W" "$STATUS_H" "tb-sb-back"
SB_BACK="$SNAP_RESULT"

assert_regions_differ "$SB_TEXT" "$SB_BACK" \
    "Status bar should go TEXT -> BRUSH (proves the tool really switched)"
assert_regions_same "$BAR_BRUSH" "$BAR_BACK" \
    "Switching away from the text tool should hide the text formatting bar"

assert_no_crash
assert_window_exists
info "=== TEXT_BAR Visibility Test PASSED ==="
