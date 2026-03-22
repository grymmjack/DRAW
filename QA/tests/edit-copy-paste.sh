#!/bin/bash
# =============================================================================
# edit-copy-paste.sh — QA test: Copy and Paste workflow
# Tests: Ctrl+A (select all), Ctrl+C (copy), Ctrl+Shift+N (new layer),
#        Ctrl+V (paste), then undo cleanup
# Verifies paste produces visible content on new layer
# =============================================================================

# -- Establish known state --
info "=== Edit Copy/Paste Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw a brush stroke to have content to copy --
info "Drawing brush stroke for copy source"
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.5 "Brush stroke drawn"
assert_no_crash

# -- Select All --
info "Select All (Ctrl+A)"
key ctrl+a
wait_for 0.3 "Selection made"
assert_no_crash

# -- Copy --
info "Copy (Ctrl+C)"
key ctrl+c
wait_for 0.3 "Content copied"
assert_no_crash

# -- Add new layer --
info "New layer (Ctrl+Shift+N)"
key ctrl+shift+n
wait_for 0.5 "New layer created"
assert_no_crash

# -- Snap canvas before paste --
park_mouse
BEFORE_PASTE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "copy-paste-before")

# -- Paste --
info "Paste (Ctrl+V)"
key ctrl+v
wait_for 0.5 "Content pasted"
assert_no_crash

# -- Snap canvas after paste --
park_mouse
AFTER_PASTE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "copy-paste-after")
assert_regions_differ "$BEFORE_PASTE" "$AFTER_PASTE" "Paste should place content on new layer"
screenshot "copy-paste-result"

# -- Clean up: undo paste, undo new layer, deselect, undo stroke --
info "Cleaning up"
key ctrl+z
wait_for 0.3 "Undo paste"
key ctrl+z
wait_for 0.3 "Undo new layer"
key Escape
wait_for 0.2 "Deselect"
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Edit Copy/Paste Test PASSED ==="
