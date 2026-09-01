#!/bin/bash
# =============================================================================
# cheatsheet-menu-open.sh — QA test / regression guard
#
# Help > Cheat Sheet must OPEN the Hotkey Quick Reference overlay and leave it
# open. It must also own the keyboard while visible (ESC dismisses it), so that
# typing does not leak through to the canvas.
#
# REGRESSION GUARDED (fixed 2026-08-14):
#   The menu-item click that dispatched action 1602 -> CMD_show_quick_ref (which
#   sets CMD_PALETTE.visible = TRUE) had its OWN button-release reach
#   MOUSE_handle_command_palette_click% -> CMD_handle_click, which closed the
#   palette because the release landed outside the (just-created) palette bounds.
#   Net effect: the overlay opened and instantly closed on the same click, and
#   subsequent keystrokes (backspace, etc.) leaked to the canvas.
#   Fix: CMD_PALETTE.suppress_click swallows the opening button press until it is
#   released, so the palette survives the click that spawned it.
#
# The overlay is centered over the canvas, so snapping a central band cleanly
# separates "overlay up" (differs from closed) vs "overlay gone" (same as closed).
# =============================================================================

info "=== Cheat Sheet Menu-Open Test ==="

# -- Known state: brush tool, arrow pointer hidden so it never dirties a snap. --
canvas_focus b
wait_for 0.3 "Canvas focused, brush tool"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Central band that the Quick Reference overlay covers when open, but which
#    is bare canvas when closed. Viewport pixels. --
CS_X=180
CS_Y=45
CS_W=320
CS_H=120

# -- Baseline: overlay CLOSED --
park_mouse
snap_region $CS_X $CS_Y $CS_W $CS_H "cheatsheet-closed"
CLOSED="$SNAP_RESULT"
assert_no_crash

# -- Open via Help menu > CHEAT SHEET... The HELP root is RIGHT-ALIGNED to the
#    menu-bar edge (GUI/MENUBAR.BM: barX+barW-pw-PAD), so it sits at viewport
#    x~429, NOT the sequential ~387 (which now lands on EFFECTS). The dropdown
#    opens at x~420..570; CHEAT SHEET... is the 2nd item at y~37. --
info "Help menu > Cheat Sheet"
click 429 6
wait_for 0.5 "Help menu open"
click 455 37
wait_for 0.6 "Cheat Sheet dispatched"

# -- The overlay MUST still be up: central band differs from the closed baseline.
#    This is the core regression (self-close on the opening click). --
park_mouse
snap_region $CS_X $CS_Y $CS_W $CS_H "cheatsheet-open"
OPEN="$SNAP_RESULT"
screenshot "cheatsheet-open"
assert_regions_differ "$CLOSED" "$OPEN" \
    "Help > Cheat Sheet must leave the Quick Reference overlay OPEN (not self-close)"
assert_no_crash

# -- The palette owns the keyboard: ESC dismisses it. If ESC had leaked to the
#    canvas instead, the overlay would remain and this would fail. --
info "ESC dismisses the overlay"
key Escape
wait_for 0.5 "Overlay dismissed"
park_mouse
snap_region $CS_X $CS_Y $CS_W $CS_H "cheatsheet-dismissed"
DISMISSED="$SNAP_RESULT"
assert_regions_same "$CLOSED" "$DISMISSED" \
    "ESC must dismiss the Quick Reference overlay (palette owns keyboard input)"

assert_no_crash
assert_window_exists
info "=== Cheat Sheet Menu-Open Test PASSED ==="
