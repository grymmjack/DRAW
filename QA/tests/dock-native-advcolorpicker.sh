#!/bin/bash
# =============================================================================
# dock-native-advcolorpicker.sh — QA test: the Advanced Color Picker window docked with every docked
# panel (layers, toolbox column, edit bar, advanced bar, character map): stacked
# above it, below it, as a tab, and floated again; when stacked, the divider is
# dragged all the way up and down. dk_check after every step, including: no
# window covers another panel, a docked window stays inside its slot (Rick,
# 2026-10-08: the layer text went under a docked Preview).
# Generated with the other dock-native-*.sh (same steps, one window each).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ADV_COLOR_PICKER_VISIBLE=1 CHARMAP_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: Advanced Color Picker with every docked panel ==="
dk_begin
dk_check "start"
dk_move_expect advcolorpicker above layers;   dk_check "advcolorpicker above the layers"
dk_divider_extremes advcolorpicker layers "advcolorpicker above the layers"
dk_move_expect advcolorpicker below layers;   dk_check "advcolorpicker below the layers"
dk_divider_extremes layers advcolorpicker "advcolorpicker below the layers"
dk_move_expect advcolorpicker tab layers;     dk_check "advcolorpicker a tab of the layers"
dk_move_expect advcolorpicker float;       dk_check "advcolorpicker floating again"
dk_move_expect advcolorpicker above toolbox;   dk_check "advcolorpicker above the toolbox"
dk_divider_extremes advcolorpicker toolbox "advcolorpicker above the toolbox"
dk_move_expect advcolorpicker below toolbox;   dk_check "advcolorpicker below the toolbox"
dk_divider_extremes toolbox advcolorpicker "advcolorpicker below the toolbox"
dk_move_expect advcolorpicker tab toolbox;     dk_check "advcolorpicker a tab of the toolbox"
dk_move_expect advcolorpicker float;       dk_check "advcolorpicker floating again"
dk_move_expect advcolorpicker above editbar;   dk_check "advcolorpicker above the editbar"
dk_divider_extremes advcolorpicker editbar "advcolorpicker above the editbar"
dk_move_expect advcolorpicker below editbar;   dk_check "advcolorpicker below the editbar"
dk_divider_extremes editbar advcolorpicker "advcolorpicker below the editbar"
dk_move_expect advcolorpicker tab editbar;     dk_check "advcolorpicker a tab of the editbar"
dk_move_expect advcolorpicker float;       dk_check "advcolorpicker floating again"
dk_move_expect advcolorpicker above advbar;   dk_check "advcolorpicker above the advbar"
dk_divider_extremes advcolorpicker advbar "advcolorpicker above the advbar"
dk_move_expect advcolorpicker below advbar;   dk_check "advcolorpicker below the advbar"
dk_divider_extremes advbar advcolorpicker "advcolorpicker below the advbar"
dk_move_expect advcolorpicker tab advbar;     dk_check "advcolorpicker a tab of the advbar"
dk_move_expect advcolorpicker float;       dk_check "advcolorpicker floating again"
dk_move_expect advcolorpicker above charmap;   dk_check "advcolorpicker above the charmap"
dk_divider_extremes advcolorpicker charmap "advcolorpicker above the charmap"
dk_move_expect advcolorpicker below charmap;   dk_check "advcolorpicker below the charmap"
dk_divider_extremes charmap advcolorpicker "advcolorpicker below the charmap"
dk_move_expect advcolorpicker tab charmap;     dk_check "advcolorpicker a tab of the charmap"
dk_move_expect advcolorpicker float;       dk_check "advcolorpicker floating again"
screenshot "dock-native-advcolorpicker-end"
assert_window_exists
info "=== Dock: Advanced Color Picker with every docked panel PASSED ==="
