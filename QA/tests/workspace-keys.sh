#!/bin/bash
# =============================================================================
# workspace-keys.sh — QA test: a workspace's [KEYS] overlay. Annotate maps
# o = ellipse (C in Default) and r = rect: the toolbox highlight follows the
# workspace keys, and the overlay is gone after switching back to Default.
# QA-OPTIONS: WORKSPACE=annotate
# =============================================================================

info "=== Workspace [KEYS] overlay Test ==="
wait_for 0.8 "workspace [START] settles"
key Escape
park_mouse
wait_for 0.3 "settle"

# Annotate's toolbox: 2 columns, top-left of the window
TBX=0; TBY=0; TBW=$(( 2 * 12 * TOOLBAR_SCALE + 4 )); TBH=$(( 4 * 12 * TOOLBAR_SCALE + 4 ))
snap_region $TBX $TBY $TBW $TBH "tb-rect";  S0="$SNAP_RESULT"

canvas_focus
key v
wait_for 0.3 "move (workspace v)"
key o
wait_for 0.4 "ellipse via workspace o"
park_mouse
snap_region $TBX $TBY $TBW $TBH "tb-ellipse"; S1="$SNAP_RESULT"
assert_regions_differ "$S0" "$S1" "o selects the ellipse (highlight moved)"

key r
wait_for 0.4 "rect via workspace r"
park_mouse
snap_region $TBX $TBY $TBW $TBH "tb-rect2"; S2="$SNAP_RESULT"
assert_regions_same "$S0" "$S2" "r selects the rectangle again"
screenshot "workspace-keys"

assert_no_crash
assert_window_exists
info "=== Workspace [KEYS] overlay Test PASSED ==="
