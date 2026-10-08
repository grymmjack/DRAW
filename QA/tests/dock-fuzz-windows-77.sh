#!/bin/bash
# =============================================================================
# dock-fuzz-windows-77.sh — QA test: a seeded chain of 14 random moves among
# the floating windows and docked panels together (Color Mixer, Advanced Color
# Picker, 3D Color Space, Preview, layers, edit bar, toolbox) - every move checks
# its outcome and the invariants (QA/dock-lib.sh dk_fuzz / dk_check).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_MIXER_VISIBLE=1 ADV_COLOR_PICKER_VISIBLE=1 COLOR_SPACE_3D_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: fuzz windows 77 Test ==="
dk_begin
dk_check "start"
dk_fuzz 77 14 colormixer advcolorpicker colorspace3d preview layers editbar toolbox
screenshot "dock-fuzz-windows-77"
assert_window_exists
info "=== Dock: fuzz windows 77 Test PASSED ==="
