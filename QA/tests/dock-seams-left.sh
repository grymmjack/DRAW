#!/bin/bash
# =============================================================================
# dock-seams-left.sh — QA test: one border line between every dock column and
# its neighbour (the canvas or the next column), the whole column height.
# Rick, 2026-11-07: with the Drawer floated, a DOUBLE line on the right of the
# toolbox / organizer column (its empty part drew a border and the Edit Bar
# next to it drew its own); "make sure that all docks are consistent and have
# the correct borders between them and the canvas and them and other docks...
# in any configuration".
# Left: toolbox|organizer, Edit Bar, Color Mixer (a docked window); right:
# layers; the Drawer floating. Then the Edit Bar moves to the right edge.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE COLOR_MIXER_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer DOCK_LEFT_2=AUTO;editbar DOCK_LEFT_3=AUTO;colormixer DOCK_RIGHT_1=AUTO;layers DOCK_FLOAT_DRAWER=560,120,170,200
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock seams (left) ==="
dk_begin
info "tree [$(dk_tree)]"
dk_seams "toolbox|organizer, editbar, mixer | layers, drawer floating"
dk_move_expect editbar edge-right
dk_seams "the Edit Bar on the right edge"
assert_window_exists
info "=== Dock seams (left) done ==="
