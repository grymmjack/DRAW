#!/bin/bash
# =============================================================================
# file-export-again.sh — QA test: Ctrl+Shift+E "Export Again"
# Action EXPORT_ACT_REPEAT (2217) — re-runs the last File > Export As with the
# same format and file name, with no dialog.
#
#   1. Ctrl+Shift+E before any export: nothing is written, no crash.
#   2. Export As BMP through the dialog (command palette "export as bmp"),
#      typing a basename — the file lands in the dialog's start dir ($HOME,
#      see file-save-as-draw.sh for why only a basename works).
#   3. Draw more, Ctrl+Shift+E: the same file is rewritten (content changes).
#   4. Draw more, Ctrl+Shift+E again: rewritten again. If step 3 had opened a
#      dialog, this stroke and export would not have happened.
# =============================================================================

info "=== Ctrl+Shift+E Export Again Test ==="

EA_FILE="$HOME/draw-qa-export-again-$$.bmp"
EA_BASENAME="$(basename "$EA_FILE")"
rm -f "$EA_FILE"

ea_sum() { md5sum "$EA_FILE" 2>/dev/null | cut -d' ' -f1; }

canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- 1. Nothing exported yet: Ctrl+Shift+E only flashes a status message --
info "Ctrl+Shift+E before any export"
wake_draw
key ctrl+shift+e
wait_for 0.6 "Status message"
assert_no_crash
if [[ -e "$EA_FILE" ]]; then
    fail "Ctrl+Shift+E wrote $EA_FILE before anything was exported"
else
    pass "Ctrl+Shift+E with no earlier export wrote nothing"
fi

# -- 2. Export As BMP through the dialog --
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.4 "Stroke 1 drawn"

info "Export As BMP via command palette, typing $EA_BASENAME"
key question
wait_for 0.5 "Command palette"
type_text "export as bmp"
wait_for 0.3 "Filter"
key Return
wait_for 1.2 "Export dialog open"
screenshot "export-again-dialog"
type_text "$EA_BASENAME"
wait_for 0.3 "Name typed"
key Return
wait_for 1.5 "Export written"
assert_no_crash

if [[ -s "$EA_FILE" ]]; then
    pass "Export As BMP wrote $EA_FILE"
else
    fail "Export As BMP did not write $EA_FILE"
    key Escape
    rm -f "$EA_FILE"
    return 0 2>/dev/null || exit 0
fi
SUM1=$(ea_sum)

# -- 3. Draw more, Ctrl+Shift+E rewrites the same file with no dialog --
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 12 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 12 ))
wait_for 0.4 "Stroke 2 drawn"
info "Ctrl+Shift+E (export again)"
wake_draw
key ctrl+shift+e
wait_for 1.0 "Re-exported"
assert_no_crash
screenshot "export-again-after-1"
SUM2=$(ea_sum)
if [[ -n "$SUM2" && "$SUM2" != "$SUM1" ]]; then
    pass "Ctrl+Shift+E rewrote $EA_BASENAME with the new artwork"
else
    fail "Ctrl+Shift+E did not rewrite $EA_BASENAME (checksum unchanged)"
fi

# -- 4. Again: proves step 3 left no dialog open --
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 24 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 24 ))
wait_for 0.4 "Stroke 3 drawn"
wake_draw
key ctrl+shift+e
wait_for 1.0 "Re-exported again"
assert_no_crash
SUM3=$(ea_sum)
if [[ -n "$SUM3" && "$SUM3" != "$SUM2" ]]; then
    pass "Second Ctrl+Shift+E rewrote the file again (no dialog in the way)"
else
    fail "Second Ctrl+Shift+E did not rewrite the file (a dialog may be open)"
    key Escape
fi

# -- Cleanup --
rm -f "$EA_FILE"
key ctrl+z
key ctrl+z
key ctrl+z
wait_for 0.3 "Undo strokes"

assert_window_exists
info "=== Export Again Test PASSED ==="
