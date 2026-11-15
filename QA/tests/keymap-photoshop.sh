#!/bin/bash
# =============================================================================
# keymap-photoshop.sh — QA test: the Photoshop keymap (ASSETS/PRESETS/photoshop.bindings)
# gives Photoshop's keys their Photoshop jobs (Rick, 2026-11-15: "make the other keyboard
# presets please" - the preset had no rows, so loading it changed nothing).
#
# Each key is pressed for real: it must fire its action (inputs.log FIRE line)
# and not the DRAW action that had the key. Toggles are pressed twice.
# Every row is also checked statically by QA/keymap-presets.sh.
# QA-BINDINGS: ASSETS/PRESETS/photoshop.bindings
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEVELOPER_MODE=TRUE TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/keymap-lib.sh"
info "=== Photoshop keymap ==="
dk_begin
km_begin || { assert_no_crash; return 0 2>/dev/null || exit 0; }

km_want g 103 "paint bucket = Fill"
km_want l 119 105 "lasso (not Line)"
km_want shift+l 120 "polygonal lasso"
km_want shift+m 121 "elliptical marquee"
km_want shift+b 102 "pencil = Dot"
km_want p 122 106 "pen = Bezier (not Polygon)"
km_want u 108 "rectangle"; km_want shift+u 110 "ellipse"
km_want d 518 102 "default colours (not Dot)"
km_want ctrl+j 321 "layer via copy"
km_want ctrl+shift+j 323 "layer via cut"
km_want ctrl+e 705 306 "merge down (not clear selection)"
km_want ctrl+bracketright 703 708 "bring forward (not to the top)"
km_want ctrl+bracketleft 704 709 "send backward"
km_want ctrl+shift+bracketright 708 703 "Ctrl+Shift+] still to the top"
km_want alt+BackSpace 313 "fill with foreground"
km_want ctrl+BackSpace 314 "fill with background"
km_want ctrl+1 405 "100%"
km_want ctrl+apostrophe 8101 8103 "show grid (not grid mode)"; km_want ctrl+apostrophe 8101 "grid off"
km_want F7 404 8007 "layers panel (not symmetry)"; km_want F7 404 "layers back"
km_want F6 2021 8006 "colour panel (not pixel perfect)"; km_want F6 2021 "colour panel off"
km_want Tab 403 401 "hide panels"; km_want Tab 403 "panels back"
km_want shift+Tab 437 2060 "hide panels but tools (not colour cycling)"; km_want shift+Tab 437 "back"
km_want ctrl+k 2100 "preferences = Settings"; wait_for 0.6 "dialog"; key Escape; wait_for 0.6 "closed"
km_want b 101 "B still the brush"
dk_park; dk_settle
assert_no_crash
info "=== Photoshop keymap: done ==="
