#!/bin/bash
# =============================================================================
# capture-oneshot.sh — QA test: a cold `DRAW --capture` (desktop shortcut,
# DRAW not running) is one-shot: picker -> Space (whole screen) -> Annotate
# -> Ctrl+Enter saves the PNG, copies, and CLOSES DRAW. The capture's switch
# to Annotate is not remembered as the next launch's workspace.
# Needs DRAW started with --capture, so it only runs as:
#     DRAW_EXTRA_ARGS=--capture ./draw-qa.sh tests/capture-oneshot.sh
# (skipped otherwise). Esc in the picker of such a launch closes DRAW too.
# QA-OPTIONS: WORKSPACE=default CAPTURE_BACKEND=COMMAND CAPTURE_COMMAND=QA/fixtures/fake-capture.sh CAPTURE_DELAY=0 CAPTURE_HIDE_DRAW=FALSE CAPTURE_WORKSPACE=annotate CAPTURE_SAVE_DIR=QA/results/oneshot-shots
# =============================================================================

if [[ " $DRAW_EXTRA_ARGS " != *" --capture "* ]]; then
    skip "capture-oneshot needs DRAW_EXTRA_ARGS=--capture (a --capture launch)"
    return 0
fi

info "=== Capture one-shot (cold DRAW --capture) Test ==="
SHOTS="$DRAW_ROOT/QA/results/oneshot-shots"
rm -rf "$SHOTS"
wait_for 2.0 "cold --capture -> region picker"
key space
wait_for 2.0 "capture document in Annotate"
screenshot "capture-oneshot-annotate"
key ctrl+Return
wait_for 3.0 "Done -> DRAW closes"
if adapter_is_alive; then fail "DRAW still running after Ctrl+Enter"; else pass "Ctrl+Enter saved, copied and closed DRAW"; fi
if ls "$SHOTS"/DRAW-*.png >/dev/null 2>&1; then pass "the PNG was saved"; else fail "no PNG in $SHOTS"; fi
if grep -q '^WORKSPACE=default' "$DRAW_CFG"; then pass "Annotate was not remembered as the next launch's workspace"; else fail "WORKSPACE changed: $(grep '^WORKSPACE=' "$DRAW_CFG")"; fi
info "=== Capture one-shot Test PASSED ==="
