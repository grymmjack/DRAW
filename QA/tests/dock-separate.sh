#!/bin/bash
# =============================================================================
# dock-separate.sh — QA test: take the default toolbox column apart and put it
# back. The toolbox, organizer and drawer start stacked in one column (QA cfg:
# right edge). Each is dragged out by its handle (the 3px grip on its top edge)
# to a column of its own, floated, docked back, and finally recombined.
# Geometry comes from the live dock dump (QA/dock-lib.sh); dk_check runs the
# invariants (each panel once, no overlap, on screen, saved = on screen) after
# every step.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: separate the toolbox column Test ==="
dk_begin
dk_check "start"
dk_expect_stacked toolbox organizer
dk_expect_stacked organizer drawer

# drawer out to the left edge
dk_move drawer edge-left
dk_expect_side drawer 1
dk_check "drawer to the left edge"

# organizer out to a new column beside the toolbox's (toward the canvas)
dk_move organizer newcol toolbox
dk_expect_side organizer 2
dk_check "organizer to a new column"
screenshot "dock-separate-apart"

# toolbox floats; then back by double-clicking its title
dk_move toolbox float
dk_expect_floating toolbox
dk_check "toolbox floating"
dk_grab_point toolbox && double_click "$GX" "$GY"
dk_park; dk_settle
dk_expect_docked toolbox
dk_check "toolbox docked back"

# recombine: organizer below the toolbox, drawer below the organizer
dk_move organizer below toolbox
dk_expect_stacked toolbox organizer
dk_check "organizer back under the toolbox"
dk_move drawer below organizer
dk_expect_stacked organizer drawer
dk_check "drawer back under the organizer"
screenshot "dock-separate-together"

assert_window_exists
info "=== Dock: separate the toolbox column Test PASSED ==="
