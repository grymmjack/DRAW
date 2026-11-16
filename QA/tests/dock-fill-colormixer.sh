#!/bin/bash
# =============================================================================
# dock-fill-colormixer.sh — QA test: the Color Mixer panel docked fills its slot -
# the slot's width beside the layers, spare height alone in a column, and its
# natural size floating again. Steps: QA/dock-fill-lib.sh.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LAYER_PANEL_WIDTH=300 COLOR_MIXER_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-fill-lib.sh"
df_run colormixer 1
