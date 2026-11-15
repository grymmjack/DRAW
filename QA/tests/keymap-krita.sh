#!/bin/bash
# =============================================================================
# keymap-krita.sh — QA test: the Krita keymap (ASSETS/PRESETS/krita.bindings)
# gives Krita's keys their Krita jobs (Rick, 2026-11-15: "make the other keyboard
# presets please" - the preset had no rows, so loading it changed nothing).
#
# Each key is pressed for real: it must fire its action (inputs.log FIRE line)
# and not the DRAW action that had the key. Toggles are pressed twice.
# Every row is also checked statically by QA/keymap-presets.sh.
# QA-BINDINGS: ASSETS/PRESETS/krita.bindings
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEVELOPER_MODE=TRUE TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/keymap-lib.sh"
info "=== Krita keymap ==="
dk_begin
km_begin || { assert_no_crash; return 0 2>/dev/null || exit 0; }

km_want p 104 106 "colour sampler = Picker (not Polygon)"
km_want t 113 114 "move (not Text)"
km_want v 113 "V still moves"
km_want q 8007 122 "multibrush = symmetry (not Bezier)"; for i in 1 2 3; do key q; wait_for 0.2 "cycle"; done
km_want shift+r 108 109 "rectangle tool (not filled)"
km_want shift+j 110 "ellipse tool"
km_want ctrl+r 112 1501 "rectangular selection = Marquee (not reference image)"
km_want j 121 "elliptical selection"
km_want d 518 102 "default colours"
km_want shift+i 2023 "colour selector = Advanced Color Picker"; km_want shift+i 2023 "off"
km_want ctrl+shift+a 307 "deselect"
km_want shift+BackSpace 313 314 "fill with foreground"
km_want BackSpace 314 313 "fill with background"
km_want Insert 701 "add paint layer"
km_want ctrl+j 707 "duplicate layer"
km_want ctrl+alt+j 321 "copy selection to new layer"
km_want ctrl+e 705 306 "merge down (not clear selection)"
km_want shift+Delete 702 519 "remove layer (not BG transparent)"
km_want Tab 403 401 "canvas only"; km_want Tab 403 "back"
km_want ctrl+shift+apostrophe 8101 "show grid"; km_want ctrl+shift+apostrophe 8101 "grid off"
km_want ctrl+shift+semicolon 8104 "snap to grid"; km_want ctrl+shift+semicolon 8104 "snap off"
km_want ctrl+Return 1703 "search actions = Command Palette"; key Escape; wait_for 0.4 "close"
km_want b 101 "B still the brush"
dk_park; dk_settle
assert_no_crash
info "=== Krita keymap: done ==="
