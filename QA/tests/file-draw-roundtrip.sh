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

# ---------------------------------------------------------------------------
# 2. Edit the canvas
# ---------------------------------------------------------------------------
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"
drag $(( CANVAS_CX - 35 )) $(( CANVAS_CY - 25 )) $(( CANVAS_CX + 35 )) $(( CANVAS_CY + 25 ))
wait_for 0.4 "Edit stroke drawn"
assert_no_crash

park_mouse
snap_region "$RT_SNAP_X" "$RT_SNAP_Y" "$RT_SNAP_W" "$RT_SNAP_H" "rt-edited"
EDITED="$SNAP_RESULT"
assert_regions_differ "$LOADED" "$EDITED" "Brush stroke should change the loaded artwork"

# ---------------------------------------------------------------------------
# 3. Ctrl+S — a known .draw path saves silently, no dialog
# ---------------------------------------------------------------------------
BEFORE_SUM=$(md5sum "$RT_FILE" | cut -d' ' -f1)
info "Saving with Ctrl+S (should be silent — path is known)"
key ctrl+s
wait_for 2.0 "Project saved"
assert_no_crash
AFTER_SUM=$(md5sum "$RT_FILE" | cut -d' ' -f1)

if [[ "$BEFORE_SUM" != "$AFTER_SUM" ]]; then
    pass "Ctrl+S rewrote $RT_FILE on disk (checksum changed)"
else
    fail "Ctrl+S did not rewrite $RT_FILE — file is byte-identical after editing and saving"
fi

# A save dialog would have covered the canvas; confirm we are still on it.
park_mouse
snap_region "$RT_SNAP_X" "$RT_SNAP_Y" "$RT_SNAP_W" "$RT_SNAP_H" "rt-after-save"
assert_regions_same "$EDITED" "$SNAP_RESULT" \
    "Ctrl+S on a known .draw path should save silently (no dialog over the canvas)"

# ---------------------------------------------------------------------------
# 4. Reload and compare
# ---------------------------------------------------------------------------
info "Relaunching to verify the edit persisted"
draw_quit
draw_launch 15
wait_for 1.5 "Project reloaded"
assert_no_crash

park_mouse
snap_region "$RT_SNAP_X" "$RT_SNAP_Y" "$RT_SNAP_W" "$RT_SNAP_H" "rt-reloaded"
assert_regions_same "$EDITED" "$SNAP_RESULT" \
    "Reloading the saved .draw should reproduce the edited canvas"
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
