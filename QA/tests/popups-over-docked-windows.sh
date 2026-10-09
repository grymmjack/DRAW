#!/bin/bash
# =============================================================================
# popups-over-docked-windows.sh — QA test: every kind of popup opened while
# native windows are up (docked AND floating) is complete on top of them, the
# windows stay drawn, and nothing around the popup changes.
#   windows: Color Mixer + Pen docked beside the layers, Advanced Color
#            Picker + 3D Color Space docked beside the toolbox column, the
#            Preview floating, Customize Toolbars open in the middle
#   popups:  layer context menu, drawer context menu, dock handle menu,
#            command palette, palette menu, a menu bar dropdown + its flyout
# For each popup (its frame from the dump's POPUP lines):
#   - the 2px strips around it are identical open and closed (no band of
#     canvas pixels, POPUP_reblit_to_screen0 draws exactly its frame)
#   - its 1px frame rows / columns are a single color (no window over it)
#   - every window it does not touch is identical open and closed
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws COLOR_MIXER_VISIBLE=1 PEN_PANEL_VISIBLE=1 ADV_COLOR_PICKER_VISIBLE=1 COLOR_SPACE_3D_VISIBLE=1 PREVIEW_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;layers DOCK_LEFT_2=AUTO;colormixer|pen DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_2=AUTO;advcolorpicker|colorspace3d DOCK_RIGHT_3=AUTO;advbar|editbar
# =============================================================================

source "$DRAW_ROOT/QA/popup-lib.sh"
tb_reset_ws

info "=== Popups over docked and floating windows ==="
wait_for 1.2 "settle"
key Escape
dk_park
dk_settle
for i in 1 2 3; do key ctrl+shift+n; sleep 0.2; done
dk_park; dk_settle
dk_check "the arrangement"
tb_open
dk_park; dk_settle
load_wins
info "windows: $(printf '%s | ' "${WINS[@]}")"

run_popups

dk_park; dk_settle
dk_check "after the popups"
assert_no_crash
tb_reset_ws
