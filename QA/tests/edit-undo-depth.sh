#!/bin/bash
# =============================================================================
# edit-undo-depth.sh — QA test: undo/redo walks the history STEP BY STEP
#
# edit-undo-redo.sh only checks the endpoints: draw 3, undo 3, "did anything
# change?". That passes even if undo overshoots, undershoots, or collapses
# several records into one.
#
# This test pins each rung of the ladder. It snapshots the canvas after every
# stroke, then asserts that undo N lands exactly on snapshot N-1 and redo N
# lands exactly back on snapshot N.
#
# Why it matters: HISTORY_init was silently dropped from DRAW.BAS (glued onto
# the end of a comment line by an unrelated merge), leaving
# HISTORY.maxRecords% at 0 so "IF HISTORY.count% >= HISTORY.maxRecords%"
# rejected the very first record — undo was completely dead in v1.7.0. Record
# eviction and redo-tail discard were also refactored, and both are depth
# behaviours that endpoint-only assertions cannot see.
# =============================================================================

STROKES=5

info "=== Undo/Redo Depth Test ($STROKES strokes) ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# Region covering every stroke position, snapped after each step.
SNAP_X=$(( CANVAS_CX - 60 ))
SNAP_Y=$(( CANVAS_CY - 60 ))
SNAP_W=120
SNAP_H=120

# STATE[0] = blank canvas, STATE[n] = after stroke n
declare -a STATE

park_mouse
snap_region "$SNAP_X" "$SNAP_Y" "$SNAP_W" "$SNAP_H" "depth-state-0"
STATE[0]="$SNAP_RESULT"

# -- Draw N well-separated horizontal strokes --
for (( n = 1; n <= STROKES; n++ )); do
    Y=$(( CANVAS_CY - 45 + (n - 1) * 18 ))
    drag $(( CANVAS_CX - 40 )) "$Y" $(( CANVAS_CX + 40 )) "$Y"
    wait_for 0.35 "Stroke $n drawn"
    park_mouse
    snap_region "$SNAP_X" "$SNAP_Y" "$SNAP_W" "$SNAP_H" "depth-state-$n"
    STATE[$n]="$SNAP_RESULT"
    assert_regions_differ "${STATE[$((n-1))]}" "${STATE[$n]}" \
        "Stroke $n should change the canvas"
done
assert_no_crash

# -- Undo down the ladder: after undo #k the canvas must equal STATE[N-k] --
for (( n = STROKES; n >= 1; n-- )); do
    key ctrl+z
    wait_for 0.45 "Undo back to state $((n-1))"
    park_mouse
    snap_region "$SNAP_X" "$SNAP_Y" "$SNAP_W" "$SNAP_H" "depth-undo-to-$((n-1))"
    assert_regions_same "${STATE[$((n-1))]}" "$SNAP_RESULT" \
        "Undo #$(( STROKES - n + 1 )) should land exactly on state $((n-1))"
done
assert_no_crash

# -- Redo back up the ladder --
for (( n = 1; n <= STROKES; n++ )); do
    key ctrl+y
    wait_for 0.45 "Redo forward to state $n"
    park_mouse
    snap_region "$SNAP_X" "$SNAP_Y" "$SNAP_W" "$SNAP_H" "depth-redo-to-$n"
    assert_regions_same "${STATE[$n]}" "$SNAP_RESULT" \
        "Redo #$n should land exactly on state $n"
done
assert_no_crash

# -- A new edit after undoing must discard the redo tail --
# Undo twice, draw something new, then Ctrl+Y must NOT resurrect old stroke 5.
key ctrl+z
wait_for 0.4 "Undo once"
key ctrl+z
wait_for 0.4 "Undo twice"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 45 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 45 ))
wait_for 0.4 "New branch stroke drawn"
park_mouse
snap_region "$SNAP_X" "$SNAP_Y" "$SNAP_W" "$SNAP_H" "depth-branch"
BRANCH="$SNAP_RESULT"

key ctrl+y
wait_for 0.45 "Redo attempt after branching"
park_mouse
snap_region "$SNAP_X" "$SNAP_Y" "$SNAP_W" "$SNAP_H" "depth-branch-redo"
assert_regions_same "$BRANCH" "$SNAP_RESULT" \
    "Redo after a new edit must be a no-op (redo tail discarded, not replayed)"

assert_no_crash
assert_window_exists
info "=== Undo/Redo Depth Test PASSED ==="
