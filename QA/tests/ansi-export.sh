#!/bin/bash
# =============================================================================
# ansi-export.sh — QA test: File > Export ANSI opens the ANSI options dialog
# Action ANS_ACT_EXPORT (2300) -> ANSI_export_dialog% (DRAW-rendered modal with
# split source/render preview + mode radios). We verify the dialog opens over a
# drawn canvas and DRAW stays responsive after cancelling. The dialog is
# DRAW-drawn (not a native dialog) so it is reliable to snap.
# =============================================================================

info "=== ANSI Export Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw something so there is content to export --
drag $(( CANVAS_CX - 15 )) $CANVAS_CY $(( CANVAS_CX + 15 )) $CANVAS_CY
wait_for 0.3 "Stroke drawn"
assert_no_crash

park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "before-ansi-export"
BEFORE="$SNAP_RESULT"

# -- Open Export ANSI via the command palette (indexes menu items by label) --
info "Open Export ANSI (command palette)"
key question
wait_for 0.5 "Command palette"
type_text "export ansi"
wait_for 0.3 "Filter"
key Return
wait_for 1.2 "ANSI export options dialog opened"
assert_no_crash

park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "ansi-export-dialog"
DIALOG="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$DIALOG" "Export ANSI should open the options dialog"
screenshot "ansi-export-dialog"

# -- Cancel the options dialog (Escape) — avoids the native save dialog --
info "Cancel export (Escape)"
key Escape
wait_for 0.5 "Dialog closed"
assert_no_crash

# -- Verify DRAW still responsive after the dialog cycle --
key b
wait_for 0.3 "Switch to brush — dispatch still works post-dialog"
assert_no_crash

# -- Cleanup: undo the stroke --
key ctrl+z
wait_for 0.3 "Undo stroke"

assert_window_exists
info "=== ANSI Export Test PASSED ==="
