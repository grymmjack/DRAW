#!/bin/bash
# QA/tests/keyboard-shortcuts.sh — Verify common keyboard shortcuts don't crash
#
# Uses $CANVAS_CX / $CANVAS_CY from the harness (computed from DRAW.cfg).

# Focus canvas and hide pointer arrow
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# ── Undo / Redo ──────────────────────────────────────────────────────────────
info "Testing Ctrl+Z / Ctrl+Y"
key ctrl+z
assert_no_crash
key ctrl+y
assert_no_crash

# ── Tool shortcuts ────────────────────────────────────────────────────────────
# Note: z=Zoom, m=Marquee — test them but restore to brush (b) at the end
info "Testing tool hotkeys"
for k in b d f e l r p t m z; do
    key "$k"
    assert_no_crash
done

# Restore to brush so subsequent tests start in a known tool state
key b
assert_no_crash

# ── Grid toggle ───────────────────────────────────────────────────────────────
info "Testing grid toggle (g)"
key g
assert_no_crash
key g   # toggle back

# ── Select All / Deselect ─────────────────────────────────────────────────────
info "Testing Select All / Deselect"
key ctrl+a
assert_no_crash
key Escape
assert_no_crash

screenshot "keyboard-shortcuts-done"
