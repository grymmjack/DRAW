#!/bin/bash
# =============================================================================
# controls-find-filter.sh — QA test: the Customize Controls FIND box filters
#
# Phase 4.2 guard. With the dialog open, typing in the FIND box narrows the
# binding list by label (CTRL_row_matches%). We verify: (a) an open dialog, (b)
# typing a query that matches few bindings visibly changes the list vs. the
# unfiltered dialog, (c) Escape clears the filter (list returns), (d) a second
# Escape closes the dialog, DRAW uncrashed.
#
# Note: this test only reads/filters — it never opens the rebind capture modal or
# commits an override, so it does not touch DRAW.bindings. The rebind-applies path
# is verified live (offscreen key capture is unreliable; see BUGS/paste-wand notes).
# =============================================================================

info "=== Customize Controls FIND filter Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Open the dialog via the command palette --
key question
wait_for 0.5 "Command palette"
type_text "customize controls"
wait_for 0.3 "Filter"
key Return
wait_for 0.8 "Customize Controls dialog opened"
assert_no_crash

park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "controls-unfiltered"
UNFILTERED="$SNAP_RESULT"

# -- Type a narrow query; the list should change (fewer/relabelled rows) --
info "Type FIND query 'flip'"
type_text "flip"
wait_for 0.4 "List filtered"
assert_no_crash

park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "controls-filtered"
FILTERED="$SNAP_RESULT"
assert_regions_differ "$UNFILTERED" "$FILTERED" "Typing in FIND should narrow the binding list"
screenshot "controls-filtered"

# -- Escape once clears the filter; the fuller list returns --
info "Escape clears the filter"
key Escape
wait_for 0.4 "Filter cleared"
assert_no_crash
park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "controls-refilled"
REFILLED="$SNAP_RESULT"
assert_regions_same "$UNFILTERED" "$REFILLED" "Escape should clear the filter back to the full list"

# -- Escape again closes the dialog --
info "Escape closes the dialog"
key Escape
wait_for 0.5 "Dialog closed"
assert_no_crash
assert_window_exists

info "=== Customize Controls FIND filter Test PASSED ==="
