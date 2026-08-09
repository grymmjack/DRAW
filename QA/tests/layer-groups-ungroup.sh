#!/bin/bash
# =============================================================================
# layer-groups-ungroup.sh — QA test: Ctrl+Shift+U dissolves a group
#
# Split out of layer-groups.sh, whose "ungroup with children" step ran after a
# dozen other sub-tests and clicked a hardcoded row to select the group. By
# then the group was not on that row, so CASE 722 found a plain layer current
# and did nothing — the panel legitimately did not change, and the failure read
# like an ungroup bug.
#
# The dependency worth pinning is this: Ungroup (722), Merge Group (723) and
# Toggle Collapse (724) all require CURRENT_LAYER% to BE the group —
#     IF LAYERS(CURRENT_LAYER%).layerType% = LAYER_TYPE_GROUP THEN ...
# with no else branch, so a wrong selection is a SILENT no-op. (Select All in
# Group, 725, is the odd one out: it also accepts a group CHILD via
# parentGroupIdx%.)
#
# Both group-creating functions end with "LAYERS_select <newIndex>", so a group
# is current the moment it is made. Creating the group here instead of hunting
# for its row is what makes this deterministic.
# =============================================================================

info "=== Ungroup Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

LP_HEADER_H=16
LAYER_ENTRY_H=20
LAYER_MID_X=$(( LP_X + LP_W / 2 ))
row_y() { echo $(( LP_Y + LP_HEADER_H + $1 * LAYER_ENTRY_H + LAYER_ENTRY_H / 2 )); }

# ---------------------------------------------------------------------------
# Case 1: empty group — Ctrl+G then Ctrl+Shift+U
# ---------------------------------------------------------------------------
info "Case 1: ungroup an empty group"
park_mouse
snap_region "$LP_X" "$LP_Y" "$LP_W" 120 "ug-empty-before"
EMPTY_BEFORE="$SNAP_RESULT"

wake_draw
key ctrl+g
wait_for 0.6 "Group created (and selected by LAYERS_new_group%)"
assert_no_crash

park_mouse
snap_region "$LP_X" "$LP_Y" "$LP_W" 120 "ug-empty-created"
EMPTY_CREATED="$SNAP_RESULT"
assert_regions_differ "$EMPTY_BEFORE" "$EMPTY_CREATED" "Ctrl+G should add a group row"

wake_draw
key ctrl+shift+u
wait_for 0.6 "Group dissolved"
assert_no_crash

park_mouse
snap_region "$LP_X" "$LP_Y" "$LP_W" 120 "ug-empty-after"
assert_regions_differ "$EMPTY_CREATED" "$SNAP_RESULT" \
    "Ctrl+Shift+U should remove the group row from the panel"
assert_regions_same "$EMPTY_BEFORE" "$SNAP_RESULT" \
    "Ungrouping should return the panel to its pre-group state"

# ---------------------------------------------------------------------------
# Case 2 (ungroup a group WITH children) is deliberately not automated here.
#
# It could not be driven from the harness: with --developer, inputs.log records
# action=721 (Group from Sel.) and then NO action=722 at all for the following
# Ctrl+Shift+U — the binding is never matched, so Ungroup is not declining the
# work, the key event simply never arrives. The same chord works moments
# earlier in Case 1, and Ctrl+Shift+N / Ctrl+Shift+G both dispatch fine in the
# same run, so it is specific to this state rather than to Ctrl+Shift chords in
# general (gotcha #6: _KEYHIT is unreliable for Ctrl+ combos on Linux/SDL2).
#
# Selecting the group row first and inserting a plain keypress to settle the
# modifier state were both tried; neither made the event appear.
#
# Case 1 above still covers the Ungroup command end to end (create → dissolve →
# panel returns to its pre-group state), which is the part that regressed
# before. The children-promotion path is left to the manual plans in
# PLANS/TESTS/.
# ---------------------------------------------------------------------------

assert_no_crash
assert_window_exists
info "=== Ungroup Test PASSED ==="
