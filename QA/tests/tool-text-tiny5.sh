#!/bin/bash
# =============================================================================
# tool-text-tiny5.sh — QA test: Shift+T = Text tool with Tiny5 font
# Action 115 (Text Tiny5). Phase 6a-ii added the explicit Shift+T binding.
# Verifies the Phase 6 fix where the plain-T binding was migrated but the
# Shift+T variant would have silently dropped without an explicit binding.
#
# Note: the status bar shows "TEXT" for both VGA and Tiny5 variants — we
# can't distinguish font choice from the status bar alone. We verify that
# Shift+T causes a tool switch FROM brush TO text (the binding fires).
# Tiny5-specific behavior (5-pixel char width) is tested elsewhere.
# =============================================================================

info "=== Text Tool Tiny5 Font Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap status bar (tool name) in BRUSH state --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "ss-brush"
BRUSH_STATE="$SNAP_RESULT"
assert_no_crash

# -- Shift+T = Text tool with Tiny5 font (action 115) --
info "Shift+T (switch to text tool with Tiny5 font)"
key shift+t
wait_for 0.5 "Text Tiny5 active"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "ss-text-tiny5"
TEXT_TINY5="$SNAP_RESULT"
assert_regions_differ "$BRUSH_STATE" "$TEXT_TINY5" "Shift+T should switch from brush to text tool (binding fires)"
assert_no_crash

# -- Cleanup: Escape commits any text, switch back to brush --
key Escape
wait_for 0.2 "Text deactivated"
key b
wait_for 0.2 "Brush"

assert_window_exists
info "=== Text Tiny5 Test PASSED ==="
