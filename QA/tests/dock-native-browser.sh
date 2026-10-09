#!/bin/bash
# =============================================================================
# dock-native-browser.sh — QA test: the Browser window docked with every docked
# panel (layers, toolbox column, edit bar, advanced bar, character map): stacked
# above it, below it, as a tab, and floated again; when stacked, the divider is
# dragged all the way up and down. dk_check after every step, including: no
# window covers another panel, a docked window stays inside its slot (Rick,
# 2026-10-08: the layer text went under a docked Preview).
# Generated with the other dock-native-*.sh (same steps, one window each).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 CHARMAP_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: Browser with every docked panel ==="
dk_begin
dk_check "start"
dk_move_expect browser above layers;   dk_check "browser above the layers"
dk_divider_extremes browser layers "browser above the layers"
dk_move_expect browser below layers;   dk_check "browser below the layers"
dk_divider_extremes layers browser "browser below the layers"
dk_move_expect browser tab layers;     dk_check "browser a tab of the layers"
dk_move_expect browser float;       dk_check "browser floating again"
dk_move_expect browser above toolbox;   dk_check "browser above the toolbox"
dk_divider_extremes browser toolbox "browser above the toolbox"
dk_move_expect browser below toolbox;   dk_check "browser below the toolbox"
dk_divider_extremes toolbox browser "browser below the toolbox"
dk_move_expect browser tab toolbox;     dk_check "browser a tab of the toolbox"
dk_move_expect browser float;       dk_check "browser floating again"
dk_move_expect browser above editbar;   dk_check "browser above the editbar"
dk_divider_extremes browser editbar "browser above the editbar"
dk_move_expect browser below editbar;   dk_check "browser below the editbar"
dk_divider_extremes editbar browser "browser below the editbar"
dk_move_expect browser tab editbar;     dk_check "browser a tab of the editbar"
dk_move_expect browser float;       dk_check "browser floating again"
dk_move_expect browser above advbar;   dk_check "browser above the advbar"
dk_divider_extremes browser advbar "browser above the advbar"
dk_move_expect browser below advbar;   dk_check "browser below the advbar"
dk_divider_extremes advbar browser "browser below the advbar"
dk_move_expect browser tab advbar;     dk_check "browser a tab of the advbar"
dk_move_expect browser float;       dk_check "browser floating again"
dk_move_expect browser above charmap;   dk_check "browser above the charmap"
dk_divider_extremes browser charmap "browser above the charmap"
dk_move_expect browser below charmap;   dk_check "browser below the charmap"
dk_divider_extremes charmap browser "browser below the charmap"
dk_move_expect browser tab charmap;     dk_check "browser a tab of the charmap"
dk_move_expect browser float;       dk_check "browser floating again"
screenshot "dock-native-browser-end"
assert_window_exists
info "=== Dock: Browser with every docked panel PASSED ==="
