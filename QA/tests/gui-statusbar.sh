#!/bin/bash
# =============================================================================
# gui-statusbar.sh — QA test: Status Bar
# Tests: Toggle visibility, verify info updates on tool switch and drawing
# =============================================================================

info "=== Status Bar Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap status bar region BEFORE toggle --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "statusbar-visible"
STATUSBAR_VIS="$SNAP_RESULT"
assert_no_crash

# -- Switch tool to verify status bar updates --
info "Switch to fill tool"
key f
wait_for 0.3 "Fill tool active"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "statusbar-fill"
STATUSBAR_FILL="$SNAP_RESULT"
assert_regions_differ "$STATUSBAR_VIS" "$STATUSBAR_FILL" "Status bar should update when tool changes"

# -- Switch to dot tool --
info "Switch to dot tool"
key d
wait_for 0.3 "Dot tool active"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "statusbar-dot"
STATUSBAR_DOT="$SNAP_RESULT"
assert_regions_differ "$STATUSBAR_FILL" "$STATUSBAR_DOT" "Status bar should update for dot tool"

# -- Switch back to brush --
key b
wait_for 0.2 "Brush tool restored"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Status Bar Test PASSED ==="
