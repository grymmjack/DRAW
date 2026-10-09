#!/bin/bash
# =============================================================================
# popups-over-floating-windows.sh — QA test: the same popups (QA/popup-lib.sh)
# with the other arrangement is complete on top of them, the
# windows stay drawn, and nothing around the popup changes.
#   windows: Color Mixer, Advanced Color Picker, 3D Color Space and Pen
#            floating, the Preview docked under the layers, the Browser
#            docked along the bottom, Customize Toolbars open
#   popups:  layer context menu, drawer context menu, dock handle menu,
#            command palette, palette menu, a menu bar dropdown + its flyout
# For each popup (its frame from the dump's POPUP lines):
#   - the 2px strips around it are identical open and closed (no band of
#     canvas pixels, POPUP_reblit_to_screen0 draws exactly its frame)
#   - its 1px frame rows / columns are a single color (no window over it)
#   - every window it does not touch is identical open and closed
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws COLOR_MIXER_VISIBLE=1 PEN_PANEL_VISIBLE=1 ADV_COLOR_PICKER_VISIBLE=1 COLOR_SPACE_3D_VISIBLE=1 PREVIEW_VISIBLE=1 BROWSER_VISIBLE=1 COLOR_MIXER_X=290 COLOR_MIXER_Y=30 ADV_COLOR_PICKER_X=480 ADV_COLOR_PICKER_Y=30 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;layers|preview DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_2=AUTO;advbar DOCK_BAND=BOTTOM,120
# =============================================================================

source "$DRAW_ROOT/QA/popup-lib.sh"
tb_reset_ws

info "=== Popups over floating windows (preview + browser docked) ==="
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

HANDLE_PANEL=preview run_popups

dk_park; dk_settle
dk_check "after the popups"
assert_no_crash
tb_reset_ws
