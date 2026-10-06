#!/bin/bash
# =============================================================================
# workspace-configurator.sh — QA test: View > Workspace > Configure Workspaces
# (action 2401, opened from the command palette) shows the configurator over a
# clean frame (the palette closes first), switches tabs, and Esc closes it
# without saving or changing the layout. Never saves (QA must not write the
# user's workspaces folder).
# QA-OPTIONS: WORKSPACE=annotate
# =============================================================================

info "=== Workspace configurator Test ==="
wait_for 0.8 "workspace [START] settles"
key Escape
park_mouse
wait_for 0.3 "settle"
snap_region $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 60 )) 240 120 "before"; S0="$SNAP_RESULT"

canvas_focus
key ctrl+p
wait_for 0.5 "palette"
type_text "configure work"
wait_for 0.4 "filtered"
key Return
wait_for 1.0 "configurator open"
park_mouse
snap_region $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 60 )) 240 120 "dialog"; S1="$SNAP_RESULT"
screenshot "workspace-configurator"
assert_regions_differ "$S0" "$S1" "the configurator opened"

# Toolbox tab (second tab button in the header row)
click $(( VIEWPORT_W / 2 - 60 )) $(( VIEWPORT_H / 2 - 153 ))
wait_for 0.5 "tab"
key Escape
wait_for 0.8 "closed"
park_mouse
wait_for 0.3 "settle"
snap_region $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 60 )) 240 120 "after"; S2="$SNAP_RESULT"
assert_regions_same "$S0" "$S2" "Esc closes it and nothing changed"

assert_no_crash
assert_window_exists
info "=== Workspace configurator Test PASSED ==="
