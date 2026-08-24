#!/bin/bash
# =============================================================================
# drag-drop-targets.sh — QA test: improved drag-and-drop dispatch.
#
# OS-level file drops CANNOT be synthesized headlessly: QB64-PE exposes no drop
# coordinates and the drop itself is an OS window-manager event, not something
# xdotool can inject into the app. So this test verifies the two things that ARE
# checkable without a real drop:
#   1) DRAW launches cleanly with the drag-and-drop dispatch module compiled in.
#   2) all four drop-target routes are present in the source (a regression guard
#      against a future edit silently dropping a target).
# Full behavior is verified manually on the fleet — see the checklist at the end.
# =============================================================================

info "=== Drag-and-drop targets test ==="

assert_window_exists
assert_no_crash

DROP="$DRAW_ROOT/INPUT/DROP.BM"

check_route() { # $1 = token to grep for, $2 = human label
    if grep -q "$1" "$DROP" 2>/dev/null; then
        pass "$2"
    else
        fail "missing drag-drop route: $2 ($1 not found in INPUT/DROP.BM)"
    fi
}

check_route "REGION_MENUBAR"              "menu-bar drop → new isolated window"
check_route "REGION_DRAWER"               "brush-bin drop → custom brush slot"
check_route "REGION_LAYER_PANEL"          "layer-panel drop → new layer"
check_route "REGION_CANVAS"               "canvas drop → current layer"
check_route "DROP_place_on_current_layer" "canvas destructive stamp helper"
check_route "DROP_place_on_new_layer"     "layer-panel new-layer helper"

# The full-bin new-page + first-free-slot helpers live in the drawer module.
if grep -q "FUNCTION DRAWER_first_free_slot%" "$DRAW_ROOT/GUI/DRAWER.BM" 2>/dev/null; then
    pass "DRAWER_first_free_slot% present"
else
    fail "DRAWER_first_free_slot% missing (brush-bin next-free-slot fill)"
fi
if grep -q "SUB DRAWER_new_page_with_brush" "$DRAW_ROOT/GUI/DRAWER.BM" 2>/dev/null; then
    pass "DRAWER_new_page_with_brush present"
else
    fail "DRAWER_new_page_with_brush missing (full-bin new blank page)"
fi

assert_no_crash

info "=== Manual GUI checks (run per-OS on the fleet) ==="
info "  canvas  : drop small image → current layer top-left; Shift → centered; Ctrl+Z undoes"
info "  layers  : drop small image on the layer panel → new layer; Ctrl+Z removes it"
info "  drawer  : drop image → custom brush in next free slot; fill 30 then drop → new page"
info "  menubar : drop image on the menu bar → second isolated window opens it (title [2])"
info "  large   : drop image larger than the canvas anywhere → interactive Import placement"
