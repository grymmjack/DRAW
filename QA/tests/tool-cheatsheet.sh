#!/bin/bash
# =============================================================================
# tool-cheatsheet.sh — QA test: Command Palette (the searchable cheat sheet)
# Tests: Open (?), scroll, close (Escape), reopen with `?`.
#
# Phase 6 fix (2026-05): the old test pressed `h` and `F1` expecting a "help
# overlay" — neither key has ever opened help in current DRAW. `h` = Flip
# Horizontal (action 315), `F1` = Drawer Brush Mode (action 8001). The
# canonical replacement for "what hotkey does X?" lookup is the Command
# Palette (`?` per CHEATSHEET line 27 and 1726, action 1703 via CMD_show_palette).
# =============================================================================

info "=== Command Palette (cheat sheet) Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap center BEFORE opening palette --
park_mouse
snap_region $(( CANVAS_CX - 150 )) $(( CANVAS_CY - 100 )) 300 200 "palette-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Open palette with ? --
info "Open command palette (Shift+/)"
key question
wait_for 0.5 "Palette opened"
assert_no_crash

# -- Snap center AFTER opening --
snap_region $(( CANVAS_CX - 150 )) $(( CANVAS_CY - 100 )) 300 200 "palette-open"
PALETTE_OPEN="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$PALETTE_OPEN" "Command palette should appear"
screenshot "palette-open"

# -- Scroll down through entries --
info "Scroll palette content"
key Down
wait_for 0.2 "Scroll down"
key Down
wait_for 0.2 "Scroll down"
key Down
wait_for 0.2 "Scroll down"
assert_no_crash

# -- Close with Escape --
info "Close palette (Escape)"
key Escape
wait_for 0.3 "Palette closed"
assert_no_crash

# -- Verify closed --
park_mouse
snap_region $(( CANVAS_CX - 150 )) $(( CANVAS_CY - 100 )) 300 200 "palette-closed"
PALETTE_CLOSED="$SNAP_RESULT"
assert_regions_differ "$PALETTE_OPEN" "$PALETTE_CLOSED" "Command palette should disappear"

# -- Reopen with ? --
info "Reopen palette (?)"
key question
wait_for 0.5 "Palette reopened"
assert_no_crash

snap_region $(( CANVAS_CX - 150 )) $(( CANVAS_CY - 100 )) 300 200 "palette-reopen"
PALETTE_REOPEN="$SNAP_RESULT"
assert_regions_differ "$PALETTE_CLOSED" "$PALETTE_REOPEN" "Palette should reopen with ?"

# -- Close again --
key Escape
wait_for 0.3 "Palette closed again"
assert_no_crash

assert_no_crash
assert_window_exists
info "=== Command Palette Test PASSED ==="
