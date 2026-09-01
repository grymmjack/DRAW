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

# -- Blank baseline: the empty (transparent) canvas centre, before any content.
#    We prove the paste populated the NEW layer by later hiding the Background
#    and showing the region differs from this blank — an in-place whole-canvas
#    paste sits exactly over the identical original showing through, so the only
#    reliable proof is "content is on the new layer when Background is hidden". --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "copy-paste-blank"
BLANK="$SNAP_RESULT"

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

# -- Add new layer (goes on TOP: Layer 2 = row 0, Background = row 1) --
info "New layer (Ctrl+Shift+N)"
key ctrl+shift+n
wait_for 0.5 "New layer created"
assert_no_crash

# -- Paste onto the NEW layer while it is active (do this BEFORE touching the
#    layer panel — clicking the panel first makes an in-place paste land nothing
#    on the new layer). Commit the float by switching tools (key b →
#    apply-transform), the proven paste-commit path (seam-paste-then-switch). --
info "Paste (Ctrl+V) onto the new layer, commit via tool-switch"
key ctrl+v
wait_for 0.5 "Content pasted (floating)"
assert_no_crash
key b
wait_for 0.4 "Float committed onto the new layer"

# -- Now hide the Background (row 1 eye @ (7,46); harness-calibration:
#    ROW_N_Y = 26 + N*20, EYE_X = LP_X+7 = 7). The identical original that was
#    showing through disappears; if the paste really populated the new layer the
#    stroke REMAINS, so the region differs from the blank baseline. If paste had
#    placed nothing, the canvas would go blank == baseline and this fails. --
info "Hide Background (row 1 eye) — the pasted content must remain on the new layer"
click 7 46
wait_for 0.4 "Background hidden"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "copy-paste-layer2only"
LAYER2_ONLY="$SNAP_RESULT"
assert_regions_differ "$BLANK" "$LAYER2_ONLY" "Paste should place content on the new layer (visible with Background hidden)"
screenshot "copy-paste-result"

# -- Restore Background visibility, then clean up --
info "Cleaning up (restore Background, undo)"
click 7 46
wait_for 0.3 "Background shown"
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
