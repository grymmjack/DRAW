#!/bin/bash
# controls-preset-picker.sh — BEHAVIOURAL: the Customize Controls button bar shows
# the "Load preset" dropdown (in-app keymap picker). Opens the dialog and snapshots
# the button-bar row so the picker's presence + layout is screenshot-verified.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "=== Customize Controls: preset picker present ==="
key b
wait_for 0.3 "Brush ready"
key grave
wait_for 0.1 "Pointer hidden"
key question
wait_for 0.5 "Command palette"
type_text "customize controls"
wait_for 0.3 "Filter"
key Return
wait_for 0.8 "Dialog open"
assert_no_crash
park_mouse
screenshot "controls-preset-picker"
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "preset-picker-open"
info "=== preset picker screenshot captured ==="
