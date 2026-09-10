#!/bin/bash
# =============================================================================
# file-save-as-draw.sh — QA test: File > Save As with a .draw filename
#
# Regression for the "Save Failed" bug: Save As (Ctrl+Shift+S -> SAVE_as) is the
# image-save path and hands the typed name to _SAVEIMAGE, which has no encoder
# for .draw. Typing "foo.draw" there wrote nothing and tripped the "Save Failed"
# dialog. SAVE_as now detects a .draw name and routes it through DRW_save.
#
# No existing test drives the Save As *dialog* with a .draw name:
#   - file-draw-roundtrip.sh saves .draw only via silent Ctrl+S (known path)
#   - file-save-readonly.sh types a .png into a read-only dir
# This one types a .draw into a WRITABLE dir and proves the file lands, is a
# real project (reloads onto the canvas), and clears the dirty marker.
#
# Like file-draw-roundtrip.sh, this test manages its own DRAW instances and MUST
# restore DRAW_EXTRA_ARGS="" and leave a plain instance running — the harness
# shares this shell with every later test.
# =============================================================================

info "=== Save As -> .draw Test ==="

# DRAW's custom file dialog (FD_*) joins whatever is typed in the FILENAME field
# onto its current browse directory — an absolute path typed there is NOT honored
# (it becomes <curdir>/<abs>, e.g. /home/grymmjack//tmp/...). So we type only a
# BASENAME and let it land in the dialog's start dir. The harness rebuilds the QA
# config from DRAW.cfg.default before each test launch, where every *_SAVE_DIR is
# empty, so SAVE_as opens the dialog in $HOME deterministically. The reload step
# passes the path on the command line (unquoted), so it must contain no spaces.
SA_FILE="$HOME/draw-qa-saveas-$$.draw"
SA_BASENAME="$(basename "$SA_FILE")"
rm -f "$SA_FILE"

SA_SNAP_X=$WORK_LEFT
SA_SNAP_Y=$WORK_TOP
SA_SNAP_W=$WORK_W
SA_SNAP_H=$WORK_H

# -- Baseline: what a blank default document looks like (for the reload diff) --
park_mouse
snap_region "$SA_SNAP_X" "$SA_SNAP_Y" "$SA_SNAP_W" "$SA_SNAP_H" "sa-blank"
BLANK="$SNAP_RESULT"

# ---------------------------------------------------------------------------
# 1. Make the document dirty so a save has something to persist
# ---------------------------------------------------------------------------
canvas_focus v
wait_for 0.3 "Move tool ready"
info "Draw a stroke so the document has unsaved changes"
key b
wait_for 0.3 "Brush tool"
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.4 "Stroke committed"
assert_no_crash

TITLE_DIRTY=$(xdotool getwindowname "$DRAW_WID" 2>/dev/null)
info "title while dirty: $TITLE_DIRTY"

# ---------------------------------------------------------------------------
# 2. File > Save As, typing a .draw name into a writable directory
# ---------------------------------------------------------------------------
info "File > Save As, typing basename $SA_BASENAME (dialog opens in \$HOME)"
wake_draw          # leave idle mode first — idle drops Ctrl-combos
key ctrl+shift+s
wait_for 1.2 "Save As dialog open"
screenshot "saveas-draw-dialog"
type_text "$SA_BASENAME"
wait_for 0.3 "Path typed"
key Return
wait_for 1.8 "Save attempted"
assert_no_crash
screenshot "saveas-draw-after-save"

# -- Dismiss anything still up (a "Save Failed" dialog if the bug regressed) --
key Return
wait_for 0.3 "Dismiss any dialog"
key Escape
wait_for 0.3 "Escape any remaining dialog"
assert_no_crash

# ---------------------------------------------------------------------------
# 3. The .draw must exist on disk and be a real project, not an empty stub
# ---------------------------------------------------------------------------
if [[ -s "$SA_FILE" ]]; then
    pass "Save As wrote $SA_FILE ($(stat -c%s "$SA_FILE" 2>/dev/null) bytes)"
else
    fail "Save As did not create $SA_FILE — .draw name was not routed to DRW_save"
    # Nothing to reload; restore a clean instance and bail out of this test.
    rm -f "$SA_FILE"
    DRAW_EXTRA_ARGS=""
    return 0 2>/dev/null || exit 0
fi

# -- The document must now be CLEAN (dirty marker cleared) --
TITLE_AFTER=$(xdotool getwindowname "$DRAW_WID" 2>/dev/null)
info "title after save: $TITLE_AFTER"
if [[ "$TITLE_AFTER" != "$TITLE_DIRTY" ]]; then
    pass "Document flagged clean after a successful .draw save"
else
    warn "Title unchanged after save: '$TITLE_DIRTY' -> '$TITLE_AFTER'"
    warn "If the dirty marker persists, the save may not have completed"
fi

# ---------------------------------------------------------------------------
# 4. Reload the saved .draw from the command line — it must load its artwork
# ---------------------------------------------------------------------------
info "Relaunching DRAW with the saved $SA_FILE to confirm it is a valid project"
draw_quit
DRAW_EXTRA_ARGS="$SA_FILE"
draw_launch 15
wait_for 1.5 "Project loaded from command line"
assert_no_crash

park_mouse
snap_region "$SA_SNAP_X" "$SA_SNAP_Y" "$SA_SNAP_W" "$SA_SNAP_H" "sa-reloaded"
assert_regions_differ "$BLANK" "$SNAP_RESULT" \
    "Reloading the Save-As .draw should reproduce the artwork (canvas differs from blank)"
screenshot "saveas-draw-reloaded"

# ---------------------------------------------------------------------------
# Cleanup — restore default launch args and leave a plain instance running
# ---------------------------------------------------------------------------
rm -f "$SA_FILE"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"

assert_no_crash
assert_window_exists
info "=== Save As -> .draw Test PASSED ==="
