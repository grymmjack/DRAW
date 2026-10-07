#!/bin/bash
# =============================================================================
# capture-screen-fake.sh — QA test: Capture Screen (Ctrl+Shift+P) through the
# COMMAND backend with a fake capture tool (QA/fixtures/fake-capture.sh writes
# a fixed 640x400 PNG), so it never touches the real display. Expect: the
# region picker over the frozen capture; a dragged box + Enter opens just
# that region as a new document in the Annotate workspace; Esc cancels.
# QA-OPTIONS: WORKSPACE=default CAPTURE_BACKEND=COMMAND CAPTURE_COMMAND=QA/fixtures/fake-capture.sh CAPTURE_DELAY=0 CAPTURE_HIDE_DRAW=FALSE CAPTURE_WORKSPACE=annotate
# =============================================================================

info "=== Capture Screen (fake backend) Test ==="
key Escape
park_mouse
wait_for 0.4 "settle"

snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "canvas-before"; C0="$SNAP_RESULT"
snap_region 2 $(( MENU_BAR_H + 20 )) 60 220 "left-before"; L0="$SNAP_RESULT"

key ctrl+shift+p
wait_for 1.5 "capture + region picker"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "picker"; CP="$SNAP_RESULT"
assert_regions_differ "$C0" "$CP" "the region picker shows the frozen capture"

# The 640x400 fixture sits 1:1, centered in the window: drag a box inside it
drag $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 80 )) $(( CANVAS_CX - 20 )) $(( CANVAS_CY ))
wait_for 0.4 "box drawn"
screenshot "capture-picker-box"
key Return
wait_for 2.0 "new document + workspace"
park_mouse
wait_for 0.5 "settle"

snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "canvas-after"; C1="$SNAP_RESULT"
snap_region 2 $(( MENU_BAR_H + 20 )) 60 220 "left-after"; L1="$SNAP_RESULT"
screenshot "capture-fake-annotate"
assert_regions_differ "$C0" "$C1" "the picked region opened as a new document"
assert_regions_differ "$L0" "$L1" "switched to the Annotate workspace after the capture"

# Esc in the picker cancels: the document stays as it was
key ctrl+shift+p
wait_for 1.5 "picker again"
key Escape
wait_for 1.0 "cancelled"
park_mouse
wait_for 0.3 "settle"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "canvas-cancel"; C2="$SNAP_RESULT"
assert_regions_same "$C1" "$C2" "Esc in the region picker cancels"

assert_no_crash
assert_window_exists
info "=== Capture Screen (fake backend) Test PASSED ==="
