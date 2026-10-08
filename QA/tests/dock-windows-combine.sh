#!/bin/bash
# =============================================================================
# dock-windows-combine.sh — QA test: the floating windows (Color Mixer, Advanced
# Color Picker, 3D Color Space, Pen Pressure, Preview) docked together and with
# docked panels: one on an edge, another stacked under it, a third as a tab, a
# fourth at the column's bottom, the Preview above the layers, a window as a tab
# of the layers, a docked panel as a tab of a window; then tabs pulled out to
# float, a docked window hidden and shown again (it comes back in its slot),
# and every window floated again. dk_check after every step.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_MIXER_VISIBLE=1 ADV_COLOR_PICKER_VISIBLE=1 COLOR_SPACE_3D_VISIBLE=1 PEN_PANEL_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: floating windows combined Test ==="
dk_begin
dk_check "start"
screenshot "dock-windows-combine-start"

dk_move_expect colormixer edge-right;            dk_check "mixer on the right edge"
dk_move_expect advcolorpicker below colormixer;  dk_check "picker under the mixer"
dk_move_expect colorspace3d tab colormixer;      dk_check "3D tab of the mixer"
dk_move_expect pen bottom colormixer;            dk_check "pen at the column's bottom"
screenshot "dock-windows-combine-column"
dk_move_expect preview above layers;             dk_check "preview above the layers"
dk_move_expect pen tab layers;                   dk_check "pen tab of the layers"
dk_move_expect editbar tab advcolorpicker;       dk_check "edit bar tab of the picker"

# tabs out to float
dk_move_expect colorspace3d float;               dk_check "3D out by its tab, floating"
dk_move_expect pen float;                        dk_check "pen out of the layers, floating"
dk_move_expect editbar edge-left;                dk_check "edit bar out of the picker's slot"

# hide a docked window and show it again: it returns to its slot
dk_p advcolorpicker; SLOT0=$P_SLOT
canvas_focus; key ctrl+shift+m; dk_park; dk_settle
dk_p advcolorpicker
if (( P_SHOWN == 0 && P_SLOT == SLOT0 )); then pass "hidden picker keeps its slot"; else fail "hidden picker: shown=$P_SHOWN slot=$P_SLOT (was $SLOT0)"; fi
dk_check "picker hidden"
key ctrl+shift+m; dk_park; dk_settle
dk_p advcolorpicker
dk_slot "$P_SLOT"
# (live, or auto-collapsed to its title when the column is too short for it)
if (( P_SHOWN != 0 && (P_LIVE != 0 || S_AUTOC != 0) && P_SLOT == SLOT0 )); then pass "picker shown again in its slot"; else fail "picker back: shown=$P_SHOWN live=$P_LIVE autoc=$S_AUTOC slot=$P_SLOT"; fi
dk_check "picker shown again"

# every window floats again
for w in colormixer advcolorpicker preview; do
    dk_scr; dk_move_expect $w float $(( CAN_LX + 60 + RANDOM % 120 )) $(( DOCK_TOP + 60 )); dk_check "$w floating again"
done
screenshot "dock-windows-combine-end"
assert_window_exists
info "=== Dock: floating windows combined Test PASSED ==="
