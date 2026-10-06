#!/bin/bash
# =============================================================================
# capture-screen-fake.sh — QA test: Capture Screen (Ctrl+Shift+P) through the
# COMMAND backend with a fake capture tool (QA/fixtures/fake-capture.sh writes
# a fixed 640x400 PNG), so it never touches the real display. Expect: a new
# document holding the fixture, and the switch to the Annotate workspace
# (toolbox docked left, layers hidden).
# QA-OPTIONS: CAPTURE_BACKEND=COMMAND CAPTURE_COMMAND=QA/fixtures/fake-capture.sh CAPTURE_DELAY=0 CAPTURE_HIDE_DRAW=FALSE CAPTURE_WORKSPACE=annotate
# =============================================================================

info "=== Capture Screen (fake backend) Test ==="
key Escape
park_mouse
wait_for 0.4 "settle"

snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "canvas-before"; C0="$SNAP_RESULT"
snap_region 2 $(( MENU_BAR_H + 20 )) 60 220 "left-before"; L0="$SNAP_RESULT"

key ctrl+shift+p
wait_for 2.0 "capture + new document + workspace"
park_mouse
wait_for 0.5 "settle"

snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "canvas-after"; C1="$SNAP_RESULT"
snap_region 2 $(( MENU_BAR_H + 20 )) 60 220 "left-after"; L1="$SNAP_RESULT"
screenshot "capture-fake-annotate"
assert_regions_differ "$C0" "$C1" "the capture opened as a new document"
assert_regions_differ "$L0" "$L1" "switched to the Annotate workspace after the capture"

assert_no_crash
assert_window_exists
info "=== Capture Screen (fake backend) Test PASSED ==="
