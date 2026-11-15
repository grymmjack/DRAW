#!/bin/bash
# =============================================================================
# keymap-gimp.sh — QA test: the GIMP keymap (ASSETS/PRESETS/gimp.bindings)
# gives GIMP's keys their GIMP jobs (Rick, 2026-11-15: "make the other keyboard
# presets please" - the preset had no rows, so loading it changed nothing).
#
# Each key is pressed for real: it must fire its action (inputs.log FIRE line)
# and not the DRAW action that had the key. Toggles are pressed twice.
# Every row is also checked statically by QA/keymap-presets.sh.
# QA-BINDINGS: ASSETS/PRESETS/gimp.bindings
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEVELOPER_MODE=TRUE TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/keymap-lib.sh"
info "=== GIMP keymap ==="
dk_begin
km_begin || { assert_no_crash; return 0 2>/dev/null || exit 0; }

km_want r 112 108 "rectangle select = Marquee (not Rectangle)"
km_want e 121 118 "ellipse select (not the eraser)"
km_want f 119 103 "free select (not Fill)"
km_want u 117 "fuzzy select = Magic Wand"
km_want b 122 101 "paths = Bezier (not Brush)"
km_want o 104 1707 "colour picker"
km_want m 113 112 "move (not Marquee)"
km_want v 113 "V still moves"
km_want shift+b 103 "bucket fill"
km_want p 101 106 "paintbrush = Brush (not Polygon)"
km_want n 101 "pencil = Brush"
km_want a 1702 "airbrush = Spray"
km_want shift+e 118 "eraser"
km_want d 518 102 "default colours (not Dot)"
km_want 1 405 501 "zoom 1:1 (not opacity 10%)"
km_want plus 406 "zoom in"; km_want equal 406 "zoom in (=)"; km_want minus 407 "zoom out"
km_want ctrl+comma 313 2100 "fill with FG (not Settings)"
km_want p 101 "a key right after it still fires (no Settings dialog in the way)"
km_want ctrl+period 314 "fill with BG"
km_want ctrl+shift+a 307 "select none"
km_want ctrl+i 311 "invert selection"
km_want ctrl+m 706 2050 "merge visible (not the character map)"
km_want Tab 403 401 "hide docks = Toggle All UI"; km_want Tab 403 "docks back"
km_want ctrl+b 401 1101 "toolbox (not custom brush)"; km_want ctrl+b 401 "toolbox back"
km_want ctrl+z 301 "Ctrl+Z still undoes"
dk_park; dk_settle
assert_no_crash
info "=== GIMP keymap: done ==="
