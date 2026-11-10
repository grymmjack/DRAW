#!/bin/bash
# =============================================================================
# dock-display-scale-live.sh — QA test: every dock column, slot and panel is
# laid out the same after a display scale change at run time as after a fresh
# start at that scale.
#
# Rick 2026-11-10 (the Animation panel docked with the layers ran off the
# window's right edge): "it seems the bug only exists if you change the
# display scale in the settings and don't restart the progam" ... "all the
# docks and panels should work as intended during a resize event for settings
# display scale". The floating panels (Animation, Pen, 3D Color Space, Color
# Mixer, Advanced Color Picker) worked out their on-screen size once, when
# they opened, so after a change the dock kept their old width.
#
# Layout: toolbox | organizer | drawer | preview and the edit bar on the left;
# animation | layers, the advanced bar, and color mixer | pen docked on the
# right; the Advanced Color Picker and 3D Color Space floating.
# Steps and checks: QA/display-scale-lib.sh (ds_run) - start at scale 2,
# Display Scale Down to 1, Up to 2; each compared with a fresh start at its
# scale and viewport. Builds before had the Animation, Color Mixer and Pen
# panels at their scale 2 width after the change to 1 (187 px, fresh: 374).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ANIM_PANEL_VISIBLE=-1 COLOR_MIXER_VISIBLE=1 PEN_PANEL_VISIBLE=1 ADV_COLOR_PICKER_VISIBLE=1 COLOR_SPACE_3D_VISIBLE=1 PREVIEW_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer|preview DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;animation|layers DOCK_RIGHT_2=AUTO;advbar DOCK_RIGHT_3=AUTO;colormixer|pen
# =============================================================================
info "=== Dock: the layout after a live display scale change ==="
source "$DRAW_ROOT/QA/display-scale-lib.sh"
ds_run animation layers colormixer pen advcolorpicker colorspace3d preview
