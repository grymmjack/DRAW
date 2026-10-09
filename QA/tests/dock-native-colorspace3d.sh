#!/bin/bash
# =============================================================================
# dock-native-colorspace3d.sh — QA test: the 3D Color Space window docked with every docked
# panel (layers, toolbox column, edit bar, advanced bar, character map): stacked
# above it, below it, as a tab, and floated again; when stacked, the divider is
# dragged all the way up and down. dk_check after every step, including: no
# window covers another panel, a docked window stays inside its slot (Rick,
# 2026-10-08: the layer text went under a docked Preview).
# Generated with the other dock-native-*.sh (same steps, one window each).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_SPACE_3D_VISIBLE=1 CHARMAP_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: 3D Color Space with every docked panel ==="
dk_begin
dk_check "start"
dk_move_expect colorspace3d above layers;   dk_check "colorspace3d above the layers"
dk_divider_extremes colorspace3d layers "colorspace3d above the layers"
dk_move_expect colorspace3d below layers;   dk_check "colorspace3d below the layers"
dk_divider_extremes layers colorspace3d "colorspace3d below the layers"
dk_move_expect colorspace3d tab layers;     dk_check "colorspace3d a tab of the layers"
dk_move_expect colorspace3d float;       dk_check "colorspace3d floating again"
dk_move_expect colorspace3d above toolbox;   dk_check "colorspace3d above the toolbox"
dk_divider_extremes colorspace3d toolbox "colorspace3d above the toolbox"
dk_move_expect colorspace3d below toolbox;   dk_check "colorspace3d below the toolbox"
dk_divider_extremes toolbox colorspace3d "colorspace3d below the toolbox"
dk_move_expect colorspace3d tab toolbox;     dk_check "colorspace3d a tab of the toolbox"
dk_move_expect colorspace3d float;       dk_check "colorspace3d floating again"
dk_move_expect colorspace3d above editbar;   dk_check "colorspace3d above the editbar"
dk_divider_extremes colorspace3d editbar "colorspace3d above the editbar"
dk_move_expect colorspace3d below editbar;   dk_check "colorspace3d below the editbar"
dk_divider_extremes editbar colorspace3d "colorspace3d below the editbar"
dk_move_expect colorspace3d tab editbar;     dk_check "colorspace3d a tab of the editbar"
dk_move_expect colorspace3d float;       dk_check "colorspace3d floating again"
dk_move_expect colorspace3d above advbar;   dk_check "colorspace3d above the advbar"
dk_divider_extremes colorspace3d advbar "colorspace3d above the advbar"
dk_move_expect colorspace3d below advbar;   dk_check "colorspace3d below the advbar"
dk_divider_extremes advbar colorspace3d "colorspace3d below the advbar"
dk_move_expect colorspace3d tab advbar;     dk_check "colorspace3d a tab of the advbar"
dk_move_expect colorspace3d float;       dk_check "colorspace3d floating again"
dk_move_expect colorspace3d above charmap;   dk_check "colorspace3d above the charmap"
dk_divider_extremes colorspace3d charmap "colorspace3d above the charmap"
dk_move_expect colorspace3d below charmap;   dk_check "colorspace3d below the charmap"
dk_divider_extremes charmap colorspace3d "colorspace3d below the charmap"
dk_move_expect colorspace3d tab charmap;     dk_check "colorspace3d a tab of the charmap"
dk_move_expect colorspace3d float;       dk_check "colorspace3d floating again"
screenshot "dock-native-colorspace3d-end"
assert_window_exists
info "=== Dock: 3D Color Space with every docked panel PASSED ==="
