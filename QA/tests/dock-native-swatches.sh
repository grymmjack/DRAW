#!/bin/bash
# =============================================================================
# dock-native-swatches.sh — QA test: the Swatches panel docked with every docked
# panel (layers, toolbox column, edit bar, advanced bar, character map): stacked
# above it, below it, as a tab, and floated again; when stacked, the divider is
# dragged all the way up and down. dk_check after every step, including: no
# window covers another panel, a docked window stays inside its slot (Rick,
# 2026-10-08: the layer text went under a docked Preview).
# Generated with the other dock-native-*.sh (same steps, one window each).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 CHARMAP_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: Swatches with every docked panel ==="
dk_begin
dk_check "start"
dk_move_expect swatches above layers;   dk_check "swatches above the layers"
dk_divider_extremes swatches layers "swatches above the layers"
dk_move_expect swatches below layers;   dk_check "swatches below the layers"
dk_divider_extremes layers swatches "swatches below the layers"
dk_move_expect swatches tab layers;     dk_check "swatches a tab of the layers"
dk_move_expect swatches float;       dk_check "swatches floating again"
dk_move_expect swatches above toolbox;   dk_check "swatches above the toolbox"
dk_divider_extremes swatches toolbox "swatches above the toolbox"
dk_move_expect swatches below toolbox;   dk_check "swatches below the toolbox"
dk_divider_extremes toolbox swatches "swatches below the toolbox"
dk_move_expect swatches tab toolbox;     dk_check "swatches a tab of the toolbox"
dk_move_expect swatches float;       dk_check "swatches floating again"
dk_move_expect swatches above editbar;   dk_check "swatches above the editbar"
dk_divider_extremes swatches editbar "swatches above the editbar"
dk_move_expect swatches below editbar;   dk_check "swatches below the editbar"
dk_divider_extremes editbar swatches "swatches below the editbar"
dk_move_expect swatches tab editbar;     dk_check "swatches a tab of the editbar"
dk_move_expect swatches float;       dk_check "swatches floating again"
dk_move_expect swatches above advbar;   dk_check "swatches above the advbar"
dk_divider_extremes swatches advbar "swatches above the advbar"
dk_move_expect swatches below advbar;   dk_check "swatches below the advbar"
dk_divider_extremes advbar swatches "swatches below the advbar"
dk_move_expect swatches tab advbar;     dk_check "swatches a tab of the advbar"
dk_move_expect swatches float;       dk_check "swatches floating again"
dk_move_expect swatches above charmap;   dk_check "swatches above the charmap"
dk_divider_extremes swatches charmap "swatches above the charmap"
dk_move_expect swatches below charmap;   dk_check "swatches below the charmap"
dk_divider_extremes charmap swatches "swatches below the charmap"
dk_move_expect swatches tab charmap;     dk_check "swatches a tab of the charmap"
dk_move_expect swatches float;       dk_check "swatches floating again"
screenshot "dock-native-swatches-end"
assert_window_exists
info "=== Dock: Swatches with every docked panel PASSED ==="
