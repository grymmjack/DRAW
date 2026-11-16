#!/bin/bash
# =============================================================================
# dock-display-scale-live-float.sh — QA test: a live display scale change
# against fresh starts, with the docking flipped from
# dock-display-scale-live.sh: the Animation, Color Mixer and Pen panels
# FLOATING; the Advanced Color Picker and 3D Color Space docked beside the
# toolbox column on the right; the layers and the character map on the left;
# the Preview floating and the Browser open. (The Browser's size is pinned to
# one that fits at every scale: a floating Browser clamped to a small work
# area keeps - and autosaves - the clamped size, so a fresh start from the
# unclamped BROWSER_WIDTH would differ for no layout reason.)
#
# Rick 2026-11-10: "all the docks and panels should work as intended during a
# resize event for settings display scale".
# Steps and checks: QA/display-scale-lib.sh (ds_run).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ANIM_PANEL_VISIBLE=-1 COLOR_MIXER_VISIBLE=1 PEN_PANEL_VISIBLE=1 ADV_COLOR_PICKER_VISIBLE=1 COLOR_SPACE_3D_VISIBLE=1 PREVIEW_VISIBLE=1 CHARMAP_VISIBLE=1 BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=60 BROWSER_WIDTH=400 BROWSER_HEIGHT=300 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;layers|charmap DOCK_LEFT_2=AUTO;advbar|editbar DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_2=AUTO;advcolorpicker|colorspace3d
# =============================================================================
info "=== Dock: a live display scale change, floating panels ==="
source "$DRAW_ROOT/QA/display-scale-lib.sh"
ds_run animation colormixer pen advcolorpicker colorspace3d layers charmap
