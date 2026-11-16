#!/bin/bash
# =============================================================================
# dock-fill-colorspace3d.sh — QA test: the 3D Color Space panel docked fills its slot -
# the slot's width beside the layers, spare height alone in a column, and its
# natural size floating again. Steps: QA/dock-fill-lib.sh.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LAYER_PANEL_WIDTH=300 COLOR_SPACE_3D_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-fill-lib.sh"
df_run colorspace3d 1
