#!/bin/bash
# =============================================================================
# dock-fill-advcolorpicker.sh — QA test: the Advanced Color Picker panel docked fills its slot -
# the slot's width beside the layers, spare height alone in a column, and its
# natural size floating again. Steps: QA/dock-fill-lib.sh. The Basic shade set
# (4 rows): the Full set is nearly as tall as the QA window, no room to grow.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LAYER_PANEL_WIDTH=300 ADV_COLOR_PICKER_VISIBLE=1 ADV_COLOR_PICKER_SHADE_PRESET=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-fill-lib.sh"
df_run advcolorpicker 1
