#!/bin/bash
# =============================================================================
# workspace-simple.sh — QA test: the Simple built-in. Its [MENUS] ROOTS keeps
# FILE/EDIT/VIEW/HELP only and its [TOOLBOX] is 10 buttons in 2 columns, so
# the menu bar and the toolbox both change when switching to Default (and the
# menu bar's SELECT/TOOLS/... come back).
# QA-OPTIONS: WORKSPACE=simple
# =============================================================================

info "=== Workspace: Simple (menus + toolbox) Test ==="
wait_for 0.8 "workspace settles"
key Escape
park_mouse
wait_for 0.3 "settle"

MBX=$(( VIEWPORT_W / 2 - 150 )); MBY=0
snap_region $MBX $MBY 300 $(( MENU_BAR_H > 0 ? MENU_BAR_H : 12 )) "menubar-simple"; M0="$SNAP_RESULT"
TBX=$(( VIEWPORT_W - 120 )); TBY=0
snap_region $TBX $TBY 110 90 "toolbox-simple"; T0="$SNAP_RESULT"
screenshot "workspace-simple"

key ctrl+shift+w
wait_for 0.5 "switcher"
type_text "def"
wait_for 0.3 "filtered"
key Return
wait_for 1.0 "default"
park_mouse
wait_for 0.3 "settle"
snap_region $MBX $MBY 300 $(( MENU_BAR_H > 0 ? MENU_BAR_H : 12 )) "menubar-default"; M1="$SNAP_RESULT"
snap_region $TBX $TBY 110 90 "toolbox-default"; T1="$SNAP_RESULT"
assert_regions_differ "$M0" "$M1" "Default brings the full menu bar back (Simple kept FILE EDIT VIEW HELP)"
assert_regions_differ "$T0" "$T1" "Default brings the full 4-column toolbox back"

assert_no_crash
assert_window_exists
info "=== Workspace: Simple Test PASSED ==="
