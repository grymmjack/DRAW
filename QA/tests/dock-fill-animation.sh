#!/bin/bash
# =============================================================================
# dock-fill-animation.sh — QA test: the Animation panel docked fills its slot -
# the slot's width beside the layers, spare height alone in a column, and its
# natural size floating again. Steps: QA/dock-fill-lib.sh.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LAYER_PANEL_WIDTH=300 ANIM_PANEL_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-fill-lib.sh"
df_run animation 0
