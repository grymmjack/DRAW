#!/bin/bash
# =============================================================================
# text-kerning-alt-arrows.sh — QA test / regression guard
#
# In the text tool, Alt+Right increases and Alt+Left decreases letter spacing
# (kerning) at the cursor or across a selection. (Was Ctrl+Alt+. / Ctrl+Alt+,;
# rebound to Alt+arrows 2026-08-14.) Also guards that the Alt eyedropper loupe
# does NOT hijack Alt while editing text.
#
# Verifies by selecting all typed text and nudging kerning: the rendered text
# visibly spreads (Alt+Right) and contracts (Alt+Left).
# =============================================================================

info "=== Text Kerning (Alt+Arrows) Test ==="

canvas_focus b
wait_for 0.3 "Brush tool ready (baseline)"
key grave
wait_for 0.1 "Pointer arrow hidden"
assert_no_crash

# -- Activate text tool, start editing left-of-centre so text grows rightward --
key t
wait_for 0.4 "Text tool active"
click $(( CANVAS_CX - 60 )) $CANVAS_CY
wait_for 0.6 "Text editing started"
type_text "MMMMMM"
wait_for 0.4 "Text typed"
assert_no_crash

# -- Select all so kerning applies across every glyph (big, clean change) --
key ctrl+a
wait_for 0.3 "All text selected"

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "kern-before"
BEFORE="$SNAP_RESULT"

# -- Increase letter spacing: Alt+Right several times --
info "Increase kerning (Alt+Right x8)"
for i in 1 2 3 4 5 6 7 8; do key alt+Right; done
wait_for 0.4 "Kerning increased"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "kern-after-increase"
AFTER_INC="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER_INC" "Alt+Right should widen letter spacing"
screenshot "text-kerning-increased"

# -- Decrease letter spacing back: Alt+Left several times --
info "Decrease kerning (Alt+Left x8)"
for i in 1 2 3 4 5 6 7 8; do key alt+Left; done
wait_for 0.4 "Kerning decreased"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "kern-after-decrease"
AFTER_DEC="$SNAP_RESULT"
assert_regions_differ "$AFTER_INC" "$AFTER_DEC" "Alt+Left should change (narrow) letter spacing"
screenshot "text-kerning-decreased"

assert_no_crash
assert_window_exists
info "=== Text Kerning (Alt+Arrows) Test PASSED ==="
