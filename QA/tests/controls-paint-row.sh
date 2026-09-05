#!/bin/bash
# =============================================================================
# controls-paint-row.sh — BEHAVIOURAL: the Customize Controls dialog surfaces the
# rebindable PAINT behaviors (2B.2 B). Filtering "paint" must reveal the
# "Paint with foreground/background color" mouse rows (non-dispatched behavior
# binds), proving they pass the visibility filter and render. Offscreen-safe:
# pure list rendering. (The actual paint-colour swap is verified on real hardware.)
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "=== Customize Controls: paint behaviors surfaced ==="

key b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

key question
wait_for 0.5 "Command palette"
type_text "customize controls"
wait_for 0.3 "Filter"
key Return
wait_for 0.8 "Customize Controls dialog opened"
assert_no_crash

type_text "zzzzq"
wait_for 0.4 "No-match filter"
park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "paint-nomatch"
NOMATCH="$SNAP_RESULT"

key ctrl+a
key BackSpace
type_text "paint"
wait_for 0.5 "Paint-behavior filter"
assert_no_crash
park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "paint-match"
MATCH="$SNAP_RESULT"
screenshot "controls-paint-rows"

assert_regions_differ "$NOMATCH" "$MATCH" "Filtering 'paint' should reveal the Paint FG/BG mouse behavior rows"

info "=== Customize Controls paint-row test PASSED ==="
