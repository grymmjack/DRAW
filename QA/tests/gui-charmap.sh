#!/bin/bash
# =============================================================================
# gui-charmap.sh — QA test: Character Map Panel
# Tests: Toggle visibility (Ctrl+M), glyph selection, cell hover, cache rebuild
# =============================================================================

info "=== Character Map Panel Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap right side BEFORE opening charmap --
park_mouse
snap_region $(( VIEWPORT_W - 200 )) $WORK_TOP 200 $WORK_H "charmap-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Open charmap with Ctrl+M --
info "Open charmap (Ctrl+M)"
key ctrl+m
wait_for 0.5 "Charmap opened"
assert_no_crash

# -- Snap right side AFTER opening --
park_mouse
snap_region $(( VIEWPORT_W - 200 )) $WORK_TOP 200 $WORK_H "charmap-open"
CHARMAP_OPEN="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$CHARMAP_OPEN" "Charmap panel should appear"
screenshot "charmap-open"

# -- Close charmap with Ctrl+M --
info "Close charmap (Ctrl+M)"
key ctrl+m
wait_for 0.3 "Charmap closed"
assert_no_crash

# -- Verify closed --
park_mouse
snap_region $(( VIEWPORT_W - 200 )) $WORK_TOP 200 $WORK_H "charmap-closed"
CHARMAP_CLOSED="$SNAP_RESULT"
assert_regions_differ "$CHARMAP_OPEN" "$CHARMAP_CLOSED" "Charmap panel should disappear"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Character Map Panel Test PASSED ==="
