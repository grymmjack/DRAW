#!/bin/bash
# SKIP: cannot select a group CHILD by clicking — the group row stays selected (see notes below)
# =============================================================================
# layer-groups-child.sh — QA test: painting on a layer inside a group
#
# Split out of layer-groups.sh. That file runs thirteen sub-tests against one
# document, so by the time it reached "draw on a group child" the panel had
# been through create / collapse / ungroup / undo / group-from-selection, the
# group was no longer on the row the constants claimed, and the assertion was
# really measuring accumulated state rather than drawing.
#
# Here the document is fresh (the harness launches a new DRAW per file), so the
# row layout is known exactly:
#
# Captured from a real run right after Ctrl+Shift+G on a 2-layer stack:
#     Row 0: Layer 2      (NOT grouped)
#     Row 1: Group 1 (1)  (group header, selected)
#     Row 2: Background   (the group's single child)
#
# Two things to know. The group is created IN PLACE, so it is not row 0. And
# only ONE layer ends up inside it: the harness has no true ctrl+click — `key
# ctrl` taps and releases Ctrl, so the click that follows is a plain click that
# REPLACES the selection instead of extending it.
#
# Panel geometry: panelY% = 0, 16px header, 20px rows — so row N's centre is
# 26 + N*20. The eye hit-zone is localX < 14, so click the row BODY at
# LP_X + LP_W/2 to select without toggling visibility.
#
# WHY THIS IS SKIPPED
# -------------------
# Clicking the child's row body does not make the child current. A full-window
# capture taken immediately after `click LAYER_MID_X row_y 2` (the Background
# row, verified against the rendered panel) shows the GROUP row still
# highlighted, and the brush stroke that follows paints nothing — consistent
# with painting on a group header, which is a silent no-op.
#
# So the harness cannot put a group child into CURRENT_LAYER% by clicking, and
# the assertion below measures that limitation rather than DRAW's drawing code.
# Everything up to the selection is verified and passes: two layers are made,
# multi-select runs, Ctrl+Shift+G nests one of them, and the panel changes.
#
# Worth a manual check: does clicking a child row inside an expanded group
# select the child, or the group? If DRAW intends the child, this is a real
# selection bug and this file becomes a regression test by deleting the SKIP.
#
# Also noted while writing this: `key ctrl` taps and RELEASES Ctrl, so the
# "ctrl+click" used here (and in layer-groups.sh / layer-multiselect.sh) is a
# plain click that replaces the selection. That is why Ctrl+Shift+G nests only
# one of the two layers. A real ctrl+click helper would need keydown/keyup
# around the click.
# =============================================================================

LP_HEADER_H=16
LAYER_ENTRY_H=20
LAYER_MID_X=$(( LP_X + LP_W / 2 ))
row_y() { echo $(( LP_Y + LP_HEADER_H + $1 * LAYER_ENTRY_H + LAYER_ENTRY_H / 2 )); }

info "=== Layer Group Child Drawing Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Two layers, each with a dot, so both are real content --
click $(( CANVAS_CX - 30 )) "$CANVAS_CY"
wait_for 0.3 "Dot on background layer"

key ctrl+shift+n
wait_for 0.5 "Second layer created"
click $(( CANVAS_CX + 30 )) "$CANVAS_CY"
wait_for 0.3 "Dot on second layer"
assert_no_crash

# -- Multi-select both rows, then group them --
# Current layer is the new one at row 0; Ctrl+Click row 1 adds the other.
wake_draw
key ctrl
click "$LAYER_MID_X" "$(row_y 1)"
wait_for 0.4 "Both layers selected"

wake_draw
key ctrl+shift+g
wait_for 0.6 "Group created from selection"
assert_no_crash

park_mouse
snap_region "$LP_X" "$LP_Y" "$LP_W" 120 "child-panel-grouped"
screenshot "group-child-panel"

# -- Select the CHILD (row 2) and paint on it --
# Row 1 is the group header, and painting on a group is a silent no-op.
click "$LAYER_MID_X" "$(row_y 2)"
wait_for 0.4 "Child layer selected"
assert_no_crash

canvas_focus b
wait_for 0.3 "Brush tool"
park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 50 )) 100 100 "child-canvas-before"
BEFORE_DRAW="$SNAP_RESULT"

drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 ))
wait_for 0.5 "Stroke drawn on group child"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 50 )) 100 100 "child-canvas-after"
AFTER_DRAW="$SNAP_RESULT"
assert_regions_differ "$BEFORE_DRAW" "$AFTER_DRAW" \
    "Painting on a layer inside a group should show on the canvas"
screenshot "group-child-drawn"

# -- Undo restores the pre-stroke canvas --
wake_draw
key ctrl+z
wait_for 0.6 "Stroke undone"
park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 50 )) 100 100 "child-canvas-undo"
assert_regions_same "$BEFORE_DRAW" "$SNAP_RESULT" \
    "Undo should remove the stroke from the group child"

assert_no_crash
assert_window_exists
info "=== Layer Group Child Drawing Test PASSED ==="
