#!/bin/bash
# =============================================================================
# file-export-qb64.sh — QA test: Ctrl+Shift+Q export QB64 project
# Action EXPORT_QB64_ACTION (220) — exports current canvas as a standalone
# QB64 source program. Phase 6d batch 5 migrated this to dispatched=TRUE.
# =============================================================================

info "=== Ctrl+Shift+Q Export QB64 Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw something so there's content to export --
drag $(( CANVAS_CX - 15 )) $CANVAS_CY $(( CANVAS_CX + 15 )) $CANVAS_CY
wait_for 0.3 "Stroke drawn"
assert_no_crash

park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "before-export"
BEFORE="$SNAP_RESULT"

# -- Ctrl+Shift+Q opens the QB64 export dialog --
info "Ctrl+Shift+Q (export QB64 project)"
key ctrl+shift+q
wait_for 1.2 "Export dialog opened"
assert_no_crash

park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "export-dialog"
DIALOG="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$DIALOG" "Ctrl+Shift+Q should open the QB64 export dialog"
screenshot "export-qb64-dialog"

# -- Cancel the dialog (Escape) --
info "Cancel export (Escape)"
key Escape
wait_for 0.5 "Dialog closed"
assert_no_crash

# -- Cleanup --
key ctrl+z
wait_for 0.3 "Undo stroke"

assert_window_exists
info "=== Export QB64 Test PASSED ==="
