#!/bin/bash
# =============================================================================
# controls-scroll-header.sh — BEHAVIOURAL: scrolling the Customize Controls list
# must NOT let a partly-scrolled row bleed over the sticky "FUNCTION / CURRENT
# KEY / REBIND" column header (rows 16px vs header band 15px). Opens the dialog,
# scrolls, and screenshots for visual verification of the header mask + the
# app-style scrollbar. Offscreen-safe: list rendering only.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "=== Customize Controls: scroll header mask + scrollbar ==="
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

# Wheel-scroll the list down over its content (Page Down would go to the FIND box).
CX=$((VIEWPORT_W / 2)); CY=$((VIEWPORT_H / 2))
for i in 1 2 3 4 5 6 7 8; do scroll_down $CX $CY; done
wait_for 0.4 "Scrolled down"
assert_no_crash
park_mouse
screenshot "controls-scrolled"
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "controls-scrolled-full"

info "=== scroll-header screenshot captured ==="
