#!/bin/bash
# =============================================================================
# settings-open-close.sh — QA test: Settings dialog open/close
# Tests: Ctrl+, (open settings), Escape (close settings)
# =============================================================================

info "=== Settings Dialog Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap viewport before settings --
park_mouse
snap_region 0 0 $VP_W $VP_H "settings-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Open settings: Ctrl+, --
info "Opening settings (Ctrl+comma)"
key ctrl+comma
wait_for 1.0 "Settings dialog opened"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "settings-open"
OPEN="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$OPEN" "Settings dialog should be visible"
screenshot "settings-dialog-open"

# -- Close settings: Escape --
info "Closing settings (Escape)"
key Escape
wait_for 0.5 "Settings dialog closed"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "settings-closed"
CLOSED="$SNAP_RESULT"
assert_regions_differ "$OPEN" "$CLOSED" "Closing settings should restore normal view"

assert_window_exists
info "=== Settings Dialog Test PASSED ==="
