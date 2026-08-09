#!/bin/bash
# =============================================================================
# regression-trapped-errors.sh — QA test: no trapped runtime errors
#
# DRAW survives a runtime error: FatalError stashes it and RESUME NEXTs, so the
# process stays alive and assert_no_crash still passes. The only visible trace
# is a crash report on the Desktop. Every test in this suite was therefore blind
# to trapped errors.
#
# This exercises the paths that used to raise ERR 9 "Subscript out of range"
# because AND does not short-circuit in QB64 — the guard was evaluated but the
# array access next to it ran anyway on a 1-based array with index 0.
#
# The worst offender was Ctrl+A with no active text layer:
# TEXT_get_active_text_data_idx% returns 0, so TEXT_LAYER_DATA(0) was read on
# every press. Fixed by _ANDALSO; this test keeps it fixed.
# =============================================================================

info "=== Trapped Runtime Errors Regression ==="

CRASH_DIR="$HOME/Desktop/DRAW-log/DRAW-crash-logs"
mkdir -p "$CRASH_DIR"
BEFORE_N=$(ls -1 "$CRASH_DIR" 2>/dev/null | wc -l)
BEFORE_BYTES=$(cat "$CRASH_DIR"/*.log 2>/dev/null | wc -c)
info "crash logs before: $BEFORE_N files, $BEFORE_BYTES bytes"

canvas_focus v
wait_for 0.3 "Move tool ready"

# -- Ctrl+A with NO text layer: the original ERR 9 path --
info "Ctrl+A with no active text layer (was TEXT_LAYER_DATA(0))"
key ctrl+a
wait_for 0.4 "Select all"
assert_no_crash

# -- Repeat a few times; a trap fires per press --
key ctrl+a
wait_for 0.2 "Select all again"
key ctrl+a
wait_for 0.2 "Select all again"
assert_no_crash

# -- Layer ops with no/edge layer state (LAYERS(0) guards) --
info "Layer navigation and picker with edge layer state"
key ctrl+shift+n
wait_for 0.5 "New layer"
key ctrl+z
wait_for 0.4 "Undo new layer"
assert_no_crash

# -- Word-jump and Home/End in the canvas text tool --
info "Text tool caret navigation"
key t
wait_for 0.4 "Text tool"
key Escape
wait_for 0.3 "Leave text tool"
key v
wait_for 0.2 "Back to move"
assert_no_crash

screenshot "trapped-errors-final"

# -- The actual assertion: no NEW crash report --
AFTER_N=$(ls -1 "$CRASH_DIR" 2>/dev/null | wc -l)
AFTER_BYTES=$(cat "$CRASH_DIR"/*.log 2>/dev/null | wc -c)
info "crash logs after: $AFTER_N files, $AFTER_BYTES bytes"

if [[ "$AFTER_N" -gt "$BEFORE_N" ]]; then
    fail "A new crash report was written ($BEFORE_N -> $AFTER_N). Newest:
$(ls -1t "$CRASH_DIR" | head -1)"
elif [[ "$AFTER_BYTES" -gt "$BEFORE_BYTES" ]]; then
    # Same file, more content: DRAW appends "--- ERROR #n ---" per session
    fail "An existing crash report grew ($BEFORE_BYTES -> $AFTER_BYTES bytes) — a runtime error was trapped"
else
    pass "No runtime errors trapped during this test"
fi
