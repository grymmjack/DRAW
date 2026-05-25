#!/bin/bash
# =============================================================================
# tool-text-tiny5.sh — QA test: Shift+T = Text tool with Tiny5 font
# Action 115 (Text Tiny5). Phase 6a-ii added the explicit Shift+T binding.
# Verifies the Phase 6 fix where the plain-T binding was migrated but the
# Shift+T variant would have silently dropped without an explicit binding.
# =============================================================================

info "=== Text Tool Tiny5 Font Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap status bar (tool name will change) --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "text-before"
BEFORE="$SNAP_RESULT"

# -- Plain T = Text tool (VGA default font, action 114) --
info "Plain T (VGA default font)"
key t
wait_for 0.4 "Text tool active"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "text-vga"
TEXT_VGA="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$TEXT_VGA" "Plain T should switch to text tool (VGA)"
assert_no_crash

# -- Escape if text became active so Shift+T re-enters --
key Escape
wait_for 0.2 "Text deactivated"

# -- Switch back to brush so Shift+T is a clean re-entry --
key b
wait_for 0.2 "Brush"

# -- Shift+T = Text tool with Tiny5 (5-pixel-wide) font (action 115) --
info "Shift+T (Tiny5 font)"
key shift+t
wait_for 0.4 "Text Tiny5 active"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "text-tiny5"
TEXT_TINY5="$SNAP_RESULT"
assert_regions_differ "$TEXT_VGA" "$TEXT_TINY5" "Shift+T should switch to text tool with Tiny5 font"
assert_no_crash

# -- Cleanup --
key Escape
wait_for 0.2 "Text deactivated"
key b
wait_for 0.2 "Brush"

assert_window_exists
info "=== Text Tiny5 Test PASSED ==="
