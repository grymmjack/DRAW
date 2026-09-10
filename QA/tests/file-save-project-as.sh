#!/bin/bash
# =============================================================================
# file-save-project-as.sh — QA test: File > Save Project As... (.draw)
#
# "Save As..." (action 204) is the IMAGE save path. The native project format
# (.draw) had no File-menu entry — DRW_save_dialog was only reachable from the
# "save before opening/exiting?" prompts. A dedicated "SAVE PROJECT AS..." item
# (action 203 -> DRW_save_dialog, "Save DRAW Project", filter *.draw) was added.
#
# This drives it from the menu end-to-end: open File menu, click SAVE PROJECT
# AS..., type a basename into the project dialog, save, and assert a real .draw
# lands on disk and reloads. Coordinates are VIEWPORT pixels (958-wide @ 2x); the
# dialog opens in $HOME (harness rebuilds the cfg with empty *_SAVE_DIR), so a
# basename lands there. Reload passes the path on the command line (no spaces).
#
# Like file-draw-roundtrip.sh, this manages its own DRAW instances and MUST
# restore DRAW_EXTRA_ARGS="" and leave a plain instance running (shared shell).
# =============================================================================

info "=== Save Project As... (.draw) Test ==="

SP_FILE="$HOME/draw-qa-projectas-$$.draw"
SP_BASENAME="$(basename "$SP_FILE")"
rm -f "$SP_FILE"

SP_SNAP_X=$WORK_LEFT
SP_SNAP_Y=$WORK_TOP
SP_SNAP_W=$WORK_W
SP_SNAP_H=$WORK_H

park_mouse
snap_region "$SP_SNAP_X" "$SP_SNAP_Y" "$SP_SNAP_W" "$SP_SNAP_H" "sp-blank"
BLANK="$SNAP_RESULT"

# -- Make the document dirty so the save persists something --
canvas_focus b
wait_for 0.3 "Brush tool ready"
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.4 "Stroke committed"
assert_no_crash

# ---------------------------------------------------------------------------
# 1. File menu > SAVE PROJECT AS...  (FILE root at viewport x~111,y6; the item
#    sits just below SAVE AS... at viewport y~145)
# ---------------------------------------------------------------------------
key grave                     # hide the arrow pointer so it never dirties a snap
wait_for 0.1 "Pointer hidden"
info "File menu > SAVE PROJECT AS..."
click 111 6
wait_for 0.5 "File menu open"
screenshot "saveproj-menu-open"
click 150 145
wait_for 1.0 "Project save dialog dispatched"
assert_no_crash
screenshot "saveproj-dialog"

# ---------------------------------------------------------------------------
# 2. Type a basename into the project dialog and save
# ---------------------------------------------------------------------------
type_text "$SP_BASENAME"
wait_for 0.3 "Filename typed"
key Return
wait_for 1.5 "Save attempted"
assert_no_crash
# DRW_save_dialog shows a "Save Complete" alert on success — dismiss it.
key Return
wait_for 0.3 "Dismiss Save Complete"
key Escape
wait_for 0.3 "Escape any remaining dialog"
assert_no_crash

# ---------------------------------------------------------------------------
# 3. The .draw must exist and be a real project
# ---------------------------------------------------------------------------
if [[ -s "$SP_FILE" ]]; then
    pass "Save Project As wrote $SP_FILE ($(stat -c%s "$SP_FILE" 2>/dev/null) bytes)"
else
    fail "Save Project As did not create $SP_FILE — menu item 203 -> DRW_save_dialog failed"
    rm -f "$SP_FILE"
    DRAW_EXTRA_ARGS=""
    return 0 2>/dev/null || exit 0
fi

# ---------------------------------------------------------------------------
# 4. Reload from the command line — it must load its artwork
# ---------------------------------------------------------------------------
info "Relaunching with the saved project to confirm it is valid"
draw_quit
DRAW_EXTRA_ARGS="$SP_FILE"
draw_launch 15
wait_for 1.5 "Project loaded from command line"
assert_no_crash
park_mouse
snap_region "$SP_SNAP_X" "$SP_SNAP_Y" "$SP_SNAP_W" "$SP_SNAP_H" "sp-reloaded"
assert_regions_differ "$BLANK" "$SNAP_RESULT" \
    "Reloading the saved project should reproduce the artwork (canvas differs from blank)"
screenshot "saveproj-reloaded"

# ---------------------------------------------------------------------------
# Cleanup — restore default launch args, leave a plain instance running
# ---------------------------------------------------------------------------
rm -f "$SP_FILE"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"
assert_no_crash
assert_window_exists
info "=== Save Project As... (.draw) Test PASSED ==="
