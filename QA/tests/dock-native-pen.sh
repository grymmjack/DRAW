#!/bin/bash
# =============================================================================
# dock-native-pen.sh — QA test: the Pen Pressure window docked with every docked
# panel (layers, toolbox column, edit bar, advanced bar, character map): stacked
# above it, below it, as a tab, and floated again; when stacked, the divider is
# dragged all the way up and down. dk_check after every step, including: no
# window covers another panel, a docked window stays inside its slot (Rick,
# 2026-10-08: the layer text went under a docked Preview).
# Generated with the other dock-native-*.sh (same steps, one window each).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PEN_PANEL_VISIBLE=1 CHARMAP_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: Pen Pressure with every docked panel ==="
dk_begin
dk_check "start"
dk_move_expect pen above layers;   dk_check "pen above the layers"
dk_divider_extremes pen layers "pen above the layers"
dk_move_expect pen below layers;   dk_check "pen below the layers"
dk_divider_extremes layers pen "pen below the layers"
dk_move_expect pen tab layers;     dk_check "pen a tab of the layers"
dk_move_expect pen float;       dk_check "pen floating again"
dk_move_expect pen above toolbox;   dk_check "pen above the toolbox"
dk_divider_extremes pen toolbox "pen above the toolbox"
dk_move_expect pen below toolbox;   dk_check "pen below the toolbox"
dk_divider_extremes toolbox pen "pen below the toolbox"
dk_move_expect pen tab toolbox;     dk_check "pen a tab of the toolbox"
dk_move_expect pen float;       dk_check "pen floating again"
dk_move_expect pen above editbar;   dk_check "pen above the editbar"
dk_divider_extremes pen editbar "pen above the editbar"
dk_move_expect pen below editbar;   dk_check "pen below the editbar"
dk_divider_extremes editbar pen "pen below the editbar"
dk_move_expect pen tab editbar;     dk_check "pen a tab of the editbar"
dk_move_expect pen float;       dk_check "pen floating again"
dk_move_expect pen above advbar;   dk_check "pen above the advbar"
dk_divider_extremes pen advbar "pen above the advbar"
dk_move_expect pen below advbar;   dk_check "pen below the advbar"
dk_divider_extremes advbar pen "pen below the advbar"
dk_move_expect pen tab advbar;     dk_check "pen a tab of the advbar"
dk_move_expect pen float;       dk_check "pen floating again"
dk_move_expect pen above charmap;   dk_check "pen above the charmap"
dk_divider_extremes pen charmap "pen above the charmap"
dk_move_expect pen below charmap;   dk_check "pen below the charmap"
dk_divider_extremes charmap pen "pen below the charmap"
dk_move_expect pen tab charmap;     dk_check "pen a tab of the charmap"
dk_move_expect pen float;       dk_check "pen floating again"
screenshot "dock-native-pen-end"
assert_window_exists
info "=== Dock: Pen Pressure with every docked panel PASSED ==="
