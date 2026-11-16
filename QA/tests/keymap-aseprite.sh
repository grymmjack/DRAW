#!/bin/bash
# =============================================================================
# keymap-aseprite.sh — QA test: the Aseprite keymap (ASSETS/PRESETS/aseprite.bindings)
# gives Aseprite's keys their Aseprite jobs (Rick, 2026-11-15: "make the other keyboard
# presets please" - the preset had no rows, so loading it changed nothing).
#
# Each key is pressed for real: it must fire its action (inputs.log FIRE line)
# and not the DRAW action that had the key. Toggles are pressed twice.
# Every row is also checked statically by QA/keymap-presets.sh.
# QA-BINDINGS: ASSETS/PRESETS/aseprite.bindings
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEVELOPER_MODE=TRUE TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/keymap-lib.sh"
info "=== Aseprite keymap ==="
dk_begin
km_begin || { assert_no_crash; return 0 2>/dev/null || exit 0; }

km_want g 103 "paint bucket = Fill"
km_want shift+b 1702 "spray"; km_want k 1702 "K still sprays"
km_want u 108 "rectangle"; km_want shift+u 110 "ellipse"
km_want q 119 122 "lasso (not Bezier)"; km_want shift+q 120 "polygonal lasso"
km_want shift+l 122 "curve = Bezier"
km_want shift+d 106 "polygon"
km_want f 313 103 "Edit > Fill (not the Fill tool)"
km_want BackSpace 306 313 "clear (not fill)"
km_want s 324 1706 "stroke (not smart shapes)"
km_want shift+h 315 "flip horizontal"; km_want shift+v 316 "flip vertical"
km_want shift+n 701 "new layer"
km_want alt+n 2514 "new frame = Duplicate Frame"
km_want alt+b 2511 "new empty frame"
km_want alt+i 2518 "reverse frames"
km_want comma 2502 905 "previous frame (not grid size)"
km_want period 2503 904 "next frame"
km_want Home 2501 315 "first frame (not flip)"
km_want End 2504 316 "last frame"
km_want Tab 2505 401 "timeline = Animation Panel (not toolbar)"; km_want Tab 2505 "off"
km_want F3 2527 8003 "onion skin (not pattern mode)"; km_want F3 2527 "off"
km_want F7 434 8007 "preview (not symmetry)"; km_want F7 434 "off"
km_want a 2021 "palette editor = Color Mixer"; km_want a 2021 "off"
km_want bracketright 521 602 "next colour (not brush size)"
km_want bracketleft 520 601 "previous colour"
km_want 0 521 510 "next colour (not opacity)"
km_want 9 520 509 "previous colour"
km_want equal 602 "brush size +"; km_want minus 601 "brush size -"
km_want shift+s 8104 "snap to grid"; km_want shift+s 8104 "snap off"
km_want ctrl+apostrophe 8101 "show grid"; km_want ctrl+apostrophe 8101 "grid off"
km_want ctrl+shift+apostrophe 8102 "pixel grid"; km_want ctrl+shift+apostrophe 8102 "pixel grid off"
km_want b 101 "B the pencil"
dk_park; dk_settle
assert_no_crash
info "=== Aseprite keymap: done ==="
