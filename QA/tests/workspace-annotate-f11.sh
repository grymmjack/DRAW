#!/bin/bash
# =============================================================================
# workspace-annotate-f11.sh — QA test: starting in the Annotate workspace
# (CFG WORKSPACE=annotate) hides the layer panel, advanced bar and preview;
# F11 reveals what the workspace hid and a second F11 hides it again.
# The pinned QA config docks the advanced bar RIGHT and shows the preview, so
# the right edge of the window is the tell.
# QA-OPTIONS: WORKSPACE=annotate
# =============================================================================

info "=== Workspace: Annotate + F11 reveal Test ==="
wait_for 0.8 "workspace [START] settles"
key Escape
park_mouse
wait_for 0.3 "settle"

RX=$(( VIEWPORT_W - 70 )); RY=$(( MENU_BAR_H + 20 ))
snap_region $RX $RY 60 220 "annotate"; S_ANN="$SNAP_RESULT"
screenshot "workspace-annotate"

key F11
wait_for 0.6 "reveal"
park_mouse
snap_region $RX $RY 60 220 "revealed"; S_REV="$SNAP_RESULT"
screenshot "workspace-annotate-f11-revealed"
assert_regions_differ "$S_ANN" "$S_REV" "F11 in Annotate reveals the hidden panels"

key F11
wait_for 0.6 "re-hide"
park_mouse
snap_region $RX $RY 60 220 "rehidden"; S_HID="$SNAP_RESULT"
assert_regions_same "$S_ANN" "$S_HID" "second F11 hides them again"

assert_no_crash
assert_window_exists
info "=== Workspace: Annotate + F11 reveal Test PASSED ==="
