#!/bin/bash
# =============================================================================
# controls-mouse-row.sh — BEHAVIOURAL: the Customize Controls dialog now surfaces
# MOUSE bindings as rebindable rows (2B.2 A2). Filtering to a word that ONLY the
# mouse binds carry ("back", from "Undo (mouse back button)") must reveal a row —
# proving mouse binds pass the visibility filter and render. Offscreen-safe: this
# is pure list rendering, no button presses.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "=== Customize Controls: mouse bindings surfaced ==="

key b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# Open the dialog via the command palette.
key question
wait_for 0.5 "Command palette"
type_text "customize controls"
wait_for 0.3 "Filter"
key Return
wait_for 0.8 "Customize Controls dialog opened"
assert_no_crash

# Filter to a string no binding matches -> effectively empty list.
type_text "zzzzq"
wait_for 0.4 "No-match filter"
park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "controls-nomatch"
NOMATCH="$SNAP_RESULT"

# Clear, then filter to "back" — only the mouse Undo bind's label contains it.
key ctrl+a
key BackSpace
type_text "back"
wait_for 0.5 "Mouse-bind filter"
assert_no_crash
park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "controls-mouseback"
MOUSEBACK="$SNAP_RESULT"
screenshot "controls-mouse-back-row"

assert_regions_differ "$NOMATCH" "$MOUSEBACK" "Filtering 'back' should reveal the mouse Undo binding row"

info "=== Customize Controls mouse-row test PASSED ==="
