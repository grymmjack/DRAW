#!/bin/bash
# =============================================================================
# dock-seams-right.sh — QA test: one border line between every dock column and
# its neighbour, with the toolbox docked on the RIGHT next to the canvas.
# Rick, 2026-11-07: docked to the right side, the toolbox is "missing a pixel
# or 2" - no line between it and the canvas, while its column's empty part
# below it had one.
# Right: Advanced Bar outermost, toolbox|organizer|drawer next to the canvas;
# left: Edit Bar, Advanced Color Picker (a docked window), Preview (docked,
# stretches to its slot).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ADV_COLOR_PICKER_VISIBLE=1 PREVIEW_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;editbar DOCK_LEFT_2=AUTO;advcolorpicker|preview DOCK_RIGHT_1=AUTO;advbar DOCK_RIGHT_2=AUTO;toolbox|organizer|drawer DOCK_RIGHT_3=AUTO;layers
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock seams (right) ==="
dk_begin
info "tree [$(dk_tree)]"
dk_seams "editbar, acp|preview | layers, toolbox|organizer|drawer, advbar"
assert_window_exists
info "=== Dock seams (right) done ==="
