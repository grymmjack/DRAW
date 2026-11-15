#!/bin/bash
# =============================================================================
# workspace-annotate-f11.sh — QA test: starting in the Annotate workspace
# (CFG WORKSPACE=annotate) hides the layer panel, advanced bar and preview;
# Shift+F11 reveals what the workspace hid and a second Shift+F11 hides it
# again (plain F11 hides / restores all UI: f11-toggle-all.sh).
# The pinned QA config docks the advanced bar RIGHT and shows the preview, so
# the right edge of the window is the tell.
# QA-OPTIONS: WORKSPACE=annotate
# =============================================================================

info "=== Workspace: Annotate + Shift+F11 reveal Test ==="
wait_for 0.8 "workspace [START] settles"
key Escape
park_mouse
wait_for 0.3 "settle"

RX=$(( VIEWPORT_W - 70 )); RY=$(( MENU_BAR_H + 20 ))
snap_region $RX $RY 60 220 "annotate"; S_ANN="$SNAP_RESULT"
screenshot "workspace-annotate"

key shift+F11
wait_for 0.6 "reveal"
park_mouse
snap_region $RX $RY 60 220 "revealed"; S_REV="$SNAP_RESULT"
screenshot "workspace-annotate-f11-revealed"
assert_regions_differ "$S_ANN" "$S_REV" "Shift+F11 in Annotate reveals the hidden panels"

key shift+F11
wait_for 0.6 "re-hide"
park_mouse
snap_region $RX $RY 60 220 "rehidden"; S_HID="$SNAP_RESULT"
assert_regions_same "$S_ANN" "$S_HID" "a second Shift+F11 hides them again"

# plain F11: everything off, then exactly the Annotate layout back (not the hidden panels)
key F11; wait_for 0.6 "all off"; park_mouse
snap_region $RX $RY 60 220 "f11-off"; S_OFF="$SNAP_RESULT"
key F11; wait_for 0.6 "all back"; park_mouse
snap_region $RX $RY 60 220 "f11-back"; S_BACK="$SNAP_RESULT"
assert_regions_same "$S_ANN" "$S_BACK" "F11 twice: the Annotate layout exactly (its hidden panels stay hidden)"

assert_no_crash
assert_window_exists
info "=== Workspace: Annotate + Shift+F11 reveal Test PASSED ==="
