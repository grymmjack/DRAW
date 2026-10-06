#!/bin/bash
# =============================================================================
# capture-handoff.sh — QA test: `DRAW --capture` while DRAW is running (a
# desktop shortcut) hands the capture to the running window through its
# mailbox (CORE/INSTANCE capture.request) and exits at once without opening
# a second window; the running DRAW then shows the region picker.
# QA-OPTIONS: CAPTURE_BACKEND=COMMAND CAPTURE_COMMAND=QA/fixtures/fake-capture.sh CAPTURE_DELAY=0 CAPTURE_HIDE_DRAW=FALSE CAPTURE_WORKSPACE=annotate
# =============================================================================

info "=== Capture handoff (DRAW --capture to the running window) Test ==="
key Escape
park_mouse
wait_for 0.6 "settle"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "before"; S0="$SNAP_RESULT"

T0=$(date +%s%N)
OUT=$( cd "$DRAW_ROOT" && timeout 20 "$DRAW_BIN" --capture 2>&1 )
RC=$?
MS=$(( ( $(date +%s%N) - T0 ) / 1000000 ))
if [[ $RC -eq 0 ]] && grep -q "asked the running DRAW" <<<"$OUT"; then
    pass "second DRAW --capture handed off and exited (${MS} ms)"
else
    fail "second DRAW --capture did not hand off (rc=$RC): $OUT"
fi

wait_for 1.5 "running DRAW picks the request up"
park_mouse
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "picker"; S1="$SNAP_RESULT"
screenshot "capture-handoff-picker"
assert_regions_differ "$S0" "$S1" "the running DRAW opened the region picker"
key Escape
wait_for 0.8 "cancel"

assert_no_crash
assert_window_exists
info "=== Capture handoff Test PASSED ==="
