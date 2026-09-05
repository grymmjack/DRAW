#!/bin/bash
# =============================================================================
# controls-tilt-row.sh — BEHAVIOURAL: the Customize Controls dialog surfaces the
# horizontal wheel-TILT bindings as rebindable rows (2B.2 C-tilt). Filtering to
# "tilt" — a word only the tilt binds carry ("Canvas: Wheel tilt right/left —
# brush size…") — must reveal a row, proving the dispatched wheel binds pass the
# visibility filter and render. Offscreen-safe: pure list rendering, no wheel
# gesture (synthetic wheel/tilt can't reach the GLFW device API under Xvfb).
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "=== Customize Controls: wheel-tilt bindings surfaced ==="

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

# Clear, then filter to "tilt" — only the wheel-tilt binds' labels contain it.
key ctrl+a
key BackSpace
type_text "tilt"
wait_for 0.5 "Tilt-bind filter"
assert_no_crash
park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "controls-tilt"
TILT="$SNAP_RESULT"
screenshot "controls-tilt-row"

assert_regions_differ "$NOMATCH" "$TILT" "Filtering 'tilt' should reveal the wheel-tilt binding rows"

info "=== Customize Controls wheel-tilt-row test PASSED ==="
