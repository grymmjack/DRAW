#!/bin/bash
# =============================================================================
# dock-native-colormixer.sh — QA test: the Color Mixer window docked with every docked
# panel (layers, toolbox column, edit bar, advanced bar, character map): stacked
# above it, below it, as a tab, and floated again; when stacked, the divider is
# dragged all the way up and down. dk_check after every step, including: no
# window covers another panel, a docked window stays inside its slot (Rick,
# 2026-10-08: the layer text went under a docked Preview).
# Generated with the other dock-native-*.sh (same steps, one window each).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_MIXER_VISIBLE=1 CHARMAP_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: Color Mixer with every docked panel ==="
dk_begin
dk_check "start"
dk_move_expect colormixer above layers;   dk_check "colormixer above the layers"
dk_divider_extremes colormixer layers "colormixer above the layers"
dk_move_expect colormixer below layers;   dk_check "colormixer below the layers"
dk_divider_extremes layers colormixer "colormixer below the layers"
dk_move_expect colormixer tab layers;     dk_check "colormixer a tab of the layers"
dk_move_expect colormixer float;       dk_check "colormixer floating again"
dk_move_expect colormixer above toolbox;   dk_check "colormixer above the toolbox"
dk_divider_extremes colormixer toolbox "colormixer above the toolbox"
dk_move_expect colormixer below toolbox;   dk_check "colormixer below the toolbox"
dk_divider_extremes toolbox colormixer "colormixer below the toolbox"
dk_move_expect colormixer tab toolbox;     dk_check "colormixer a tab of the toolbox"
dk_move_expect colormixer float;       dk_check "colormixer floating again"
dk_move_expect colormixer above editbar;   dk_check "colormixer above the editbar"
dk_divider_extremes colormixer editbar "colormixer above the editbar"
dk_move_expect colormixer below editbar;   dk_check "colormixer below the editbar"
dk_divider_extremes editbar colormixer "colormixer below the editbar"
dk_move_expect colormixer tab editbar;     dk_check "colormixer a tab of the editbar"
dk_move_expect colormixer float;       dk_check "colormixer floating again"
dk_move_expect colormixer above advbar;   dk_check "colormixer above the advbar"
dk_divider_extremes colormixer advbar "colormixer above the advbar"
dk_move_expect colormixer below advbar;   dk_check "colormixer below the advbar"
dk_divider_extremes advbar colormixer "colormixer below the advbar"
dk_move_expect colormixer tab advbar;     dk_check "colormixer a tab of the advbar"
dk_move_expect colormixer float;       dk_check "colormixer floating again"
dk_move_expect colormixer above charmap;   dk_check "colormixer above the charmap"
dk_divider_extremes colormixer charmap "colormixer above the charmap"
dk_move_expect colormixer below charmap;   dk_check "colormixer below the charmap"
dk_divider_extremes charmap colormixer "colormixer below the charmap"
dk_move_expect colormixer tab charmap;     dk_check "colormixer a tab of the charmap"
dk_move_expect colormixer float;       dk_check "colormixer floating again"
screenshot "dock-native-colormixer-end"
assert_window_exists
info "=== Dock: Color Mixer with every docked panel PASSED ==="
