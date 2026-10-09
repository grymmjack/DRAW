#!/bin/bash
# =============================================================================
# dock-native-preview.sh — QA test: the Preview window docked with every docked
# panel (layers, toolbox column, edit bar, advanced bar, character map): stacked
# above it, below it, as a tab, and floated again; when stacked, the divider is
# dragged all the way up and down. dk_check after every step, including: no
# window covers another panel, a docked window stays inside its slot (Rick,
# 2026-10-08: the layer text went under a docked Preview).
# Generated with the other dock-native-*.sh (same steps, one window each).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1 CHARMAP_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: Preview with every docked panel ==="
dk_begin
dk_check "start"
dk_move_expect preview above layers;   dk_check "preview above the layers"
dk_divider_extremes preview layers "preview above the layers"
dk_move_expect preview below layers;   dk_check "preview below the layers"
dk_divider_extremes layers preview "preview below the layers"
dk_move_expect preview tab layers;     dk_check "preview a tab of the layers"
dk_move_expect preview float;       dk_check "preview floating again"
dk_move_expect preview above toolbox;   dk_check "preview above the toolbox"
dk_divider_extremes preview toolbox "preview above the toolbox"
dk_move_expect preview below toolbox;   dk_check "preview below the toolbox"
dk_divider_extremes toolbox preview "preview below the toolbox"
dk_move_expect preview tab toolbox;     dk_check "preview a tab of the toolbox"
dk_move_expect preview float;       dk_check "preview floating again"
dk_move_expect preview above editbar;   dk_check "preview above the editbar"
dk_divider_extremes preview editbar "preview above the editbar"
dk_move_expect preview below editbar;   dk_check "preview below the editbar"
dk_divider_extremes editbar preview "preview below the editbar"
dk_move_expect preview tab editbar;     dk_check "preview a tab of the editbar"
dk_move_expect preview float;       dk_check "preview floating again"
dk_move_expect preview above advbar;   dk_check "preview above the advbar"
dk_divider_extremes preview advbar "preview above the advbar"
dk_move_expect preview below advbar;   dk_check "preview below the advbar"
dk_divider_extremes advbar preview "preview below the advbar"
dk_move_expect preview tab advbar;     dk_check "preview a tab of the advbar"
dk_move_expect preview float;       dk_check "preview floating again"
dk_move_expect preview above charmap;   dk_check "preview above the charmap"
dk_divider_extremes preview charmap "preview above the charmap"
dk_move_expect preview below charmap;   dk_check "preview below the charmap"
dk_divider_extremes charmap preview "preview below the charmap"
dk_move_expect preview tab charmap;     dk_check "preview a tab of the charmap"
dk_move_expect preview float;       dk_check "preview floating again"
screenshot "dock-native-preview-end"
assert_window_exists
info "=== Dock: Preview with every docked panel PASSED ==="
