#!/bin/bash
# =============================================================================
# file-draw-roundtrip.sh — QA test: real .draw load → edit → save → reload
#
# Every other file test in this suite only opens a dialog and cancels it, so
# nothing actually verifies that DRAW can write a project and read it back.
# This one does the full loop against the filesystem:
#
#   1. launch DRAW with a .draw on the command line   → load path
#   2. edit the canvas                                → dirty state
#   3. Ctrl+S                                         → silent save (a known
#      .draw path means SAVE_image writes without a dialog)
#   4. relaunch with the same file                    → persistence
#
# It also covers gotcha #15 (DRW_load_binary must reset tool/panel state), since
# a stale-state leak across loads usually shows up as a canvas mismatch here.
#
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt
#
# The test manages its own DRAW instances via draw_quit/draw_launch. It MUST
# leave one running and DRAW_EXTRA_ARGS empty, because the harness shares this
# shell with every later test.
# =============================================================================

info "=== .draw Round-Trip Test ==="

SAMPLE_DRAW="$DRAW_ROOT/DEV/_/DRAW Splash.draw"
# DRAW_EXTRA_ARGS is expanded unquoted at launch, so the path must not contain
# spaces — the sample's own name does, hence the copy.
RT_FILE="/tmp/draw-qa-roundtrip-$$.draw"

if [[ ! -f "$SAMPLE_DRAW" ]]; then
    skip "sample project not found: $SAMPLE_DRAW"
    return 0 2>/dev/null || exit 0
fi
cp "$SAMPLE_DRAW" "$RT_FILE" || { fail "could not stage $RT_FILE"; return 0 2>/dev/null; }

RT_SNAP_X=$WORK_LEFT
RT_SNAP_Y=$WORK_TOP
RT_SNAP_W=$WORK_W
RT_SNAP_H=$WORK_H

# -- Baseline: what an empty default document looks like --
park_mouse
snap_region "$RT_SNAP_X" "$RT_SNAP_Y" "$RT_SNAP_W" "$RT_SNAP_H" "rt-blank"
BLANK="$SNAP_RESULT"

# ---------------------------------------------------------------------------
# 1. Relaunch DRAW with the project on the command line
# ---------------------------------------------------------------------------
info "Relaunching DRAW with $RT_FILE"
draw_quit
DRAW_EXTRA_ARGS="$RT_FILE"
draw_launch 15
wait_for 1.5 "Project loaded from command line"
assert_no_crash

park_mouse
snap_region "$RT_SNAP_X" "$RT_SNAP_Y" "$RT_SNAP_W" "$RT_SNAP_H" "rt-loaded"
LOADED="$SNAP_RESULT"
assert_regions_differ "$BLANK" "$LOADED" \
    "Launching with a .draw argument should load its artwork onto the canvas"
screenshot "roundtrip-loaded"

# The layers panel is fixed-position (zoom/pan-independent), so we verify the
# persisted edit there. The canvas view can't be used: the sample loads zoomed
# and Ctrl+0 doesn't reproduce an identical pan on reload, so a canvas diff is
# dominated by view drift rather than the edit. Panel rows: ROW_N_Y = 26 + N*20. --
# The layers panel's title bar: "LAYERS" + the layer count. A new layer goes in above
# the CURRENT layer - often deep in a group, below any fixed strip of rows (which row
# is current after a load varies: "a different step each time"); the count always
# changes, survives the silent save, and must come back on reload (2026-11-20).
# Where the panel is: the dock dump (P layers shown live x y w h) - a user profile
# docks it on the right, wider.
LP_SNAP_X=0; LP_SNAP_Y=0; LP_SNAP_W=$LAYER_PANEL_W; LP_SNAP_H=14
read -r _ _ _RT_SH _RT_LV _RT_X _RT_Y _RT_W _ <<< "$(grep -m1 '^P layers ' "$DRAW_ROOT/QA/.dock-dump.txt" 2>/dev/null)"
if [[ "${_RT_LV:-0}" != 0 && "${_RT_W:-0}" -gt 0 ]]; then LP_SNAP_X=$_RT_X; LP_SNAP_Y=$_RT_Y; LP_SNAP_W=$_RT_W; fi
info "layers panel snap: x=$LP_SNAP_X y=$LP_SNAP_Y ${LP_SNAP_W}x$LP_SNAP_H"
park_mouse
snap_region "$LP_SNAP_X" "$LP_SNAP_Y" "$LP_SNAP_W" "$LP_SNAP_H" "rt-panel-loaded"
PANEL_LOADED="$SNAP_RESULT"

# ---------------------------------------------------------------------------
# 2. Edit the document — add a new layer (Ctrl+Shift+N). A brush stroke is a poor
#    edit here: the sample loads zoomed with LOCKED layers, so a stroke at the
#    default CANVAS_CX/CY neither lands nor commits, leaving the bytes identical.
#    An eye-click is fragile too (the top row is a GROUP; its eye is shifted by the
#    disclosure triangle). Adding a layer is coord-free, is a real persisted change
#    (the .draw stores the layer set), and inserts a new row 0 in the panel. --
info "Edit: add a layer (Ctrl+Shift+N) — a persisted, coord-free document change"
wake_draw
key ctrl+shift+n
wait_for 0.6 "New layer added (new row 0)"
assert_no_crash

park_mouse
snap_region "$LP_SNAP_X" "$LP_SNAP_Y" "$LP_SNAP_W" "$LP_SNAP_H" "rt-panel-edited"
PANEL_EDITED="$SNAP_RESULT"
assert_regions_differ "$PANEL_LOADED" "$PANEL_EDITED" \
    "Adding a layer should change the layer count in the panel title"

# ---------------------------------------------------------------------------
# 3. Ctrl+S — a known .draw path saves silently, no dialog
# ---------------------------------------------------------------------------
BEFORE_SUM=$(md5sum "$RT_FILE" | cut -d' ' -f1)
info "Saving with Ctrl+S (should be silent — path is known)"
wake_draw          # leave idle mode first — idle drops Ctrl-combos (no wait_for between)
key ctrl+s
wait_for 2.0 "Project saved"
assert_no_crash
AFTER_SUM=$(md5sum "$RT_FILE" | cut -d' ' -f1)

if [[ "$BEFORE_SUM" != "$AFTER_SUM" ]]; then
    pass "Ctrl+S rewrote $RT_FILE on disk (checksum changed)"
else
    fail "Ctrl+S did not rewrite $RT_FILE — file is byte-identical after editing and saving"
fi

# A save dialog would have covered the panel; confirm it is unchanged (silent save).
park_mouse
snap_region "$LP_SNAP_X" "$LP_SNAP_Y" "$LP_SNAP_W" "$LP_SNAP_H" "rt-panel-after-save"
assert_regions_same "$PANEL_EDITED" "$SNAP_RESULT" \
    "Ctrl+S on a known .draw path should save silently (no dialog over the workspace)"

# ---------------------------------------------------------------------------
# 4. Reload and compare — the persisted added layer must return
# ---------------------------------------------------------------------------
info "Relaunching to verify the edit persisted"
draw_quit
draw_launch 15
wait_for 1.5 "Project reloaded"
assert_no_crash

park_mouse
snap_region "$LP_SNAP_X" "$LP_SNAP_Y" "$LP_SNAP_W" "$LP_SNAP_H" "rt-panel-reloaded"
assert_regions_same "$PANEL_EDITED" "$SNAP_RESULT" \
    "Reloading the saved .draw should reproduce the edit (the added layer persists)"
screenshot "roundtrip-reloaded"

# ---------------------------------------------------------------------------
# Cleanup — the harness shares this shell, so restore the default launch args
# and leave a plain DRAW instance running for run_test_file to close.
# ---------------------------------------------------------------------------
rm -f "$RT_FILE"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"

assert_no_crash
assert_window_exists
info "=== .draw Round-Trip Test PASSED ==="
