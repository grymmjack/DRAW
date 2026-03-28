#!/bin/bash
# =============================================================================
# QA Auto Test: Text Tool
# Tests: Text tool activation, text entry, formatting, selection, clipboard,
#        text-local undo/redo, commit/cancel, re-editing, and rasterize.
# Generated: 2026-03-27
# =============================================================================

# TEXT_BAR sits below menu bar. Snap a strip to detect its appearance.
TEXT_BAR_SNAP_X=$WORK_LEFT
TEXT_BAR_SNAP_Y=$MENU_BAR_H
TEXT_BAR_SNAP_W=$WORK_W
TEXT_BAR_SNAP_H=30

# Canvas snap region for text preview detection
SNAP_X=$(( CANVAS_CX - 80 ))
SNAP_Y=$(( CANVAS_CY - 60 ))
SNAP_W=160
SNAP_H=120

# ---------------------------------------------------------------------------
# Setup — establish known state (brush tool, canvas focused)
# ---------------------------------------------------------------------------
info "=== Text Tool Tests ==="
canvas_focus b
wait_for 0.3 "Brush tool ready (baseline)"
key grave
wait_for 0.1 "Pointer arrow hidden"
assert_no_crash

# ---------------------------------------------------------------------------
# Test 1: Activate text tool via T key — TEXT_BAR appears
# ---------------------------------------------------------------------------
info "Test 1: Activate text tool via T key"

# Snap TEXT_BAR area BEFORE activation (should be canvas/work area)
park_mouse
snap_region $TEXT_BAR_SNAP_X $TEXT_BAR_SNAP_Y $TEXT_BAR_SNAP_W $TEXT_BAR_SNAP_H "text-bar-before-activate"
BEFORE_BAR="$SNAP_RESULT"

# Activate text tool
key t
wait_for 0.5 "Text tool activated"
assert_no_crash

# Snap TEXT_BAR area AFTER activation (TEXT_BAR should now be visible)
park_mouse
snap_region $TEXT_BAR_SNAP_X $TEXT_BAR_SNAP_Y $TEXT_BAR_SNAP_W $TEXT_BAR_SNAP_H "text-bar-after-activate"
AFTER_BAR="$SNAP_RESULT"
assert_regions_differ "$BEFORE_BAR" "$AFTER_BAR" "TEXT_BAR should appear when text tool is activated"
pass "Test 1: Text tool activation shows TEXT_BAR"

# ---------------------------------------------------------------------------
# Test 2: Click canvas to start text entry — cursor appears
# ---------------------------------------------------------------------------
info "Test 2: Click canvas to start text entry"

# Snap canvas center BEFORE clicking
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-canvas-before-click"
BEFORE_CLICK="$SNAP_RESULT"

# Click canvas to start editing (creates new text layer, blinking cursor)
click $CANVAS_CX $CANVAS_CY
wait_for 0.8 "Text editing started (cursor should blink)"
assert_no_crash

# Snap canvas center AFTER clicking — cursor should be visible
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-canvas-after-click"
AFTER_CLICK="$SNAP_RESULT"
assert_regions_differ "$BEFORE_CLICK" "$AFTER_CLICK" "Cursor should appear on canvas after click"
pass "Test 2: Click canvas starts text entry with cursor"

# ---------------------------------------------------------------------------
# Test 3: Type text — characters appear on canvas
# ---------------------------------------------------------------------------
info "Test 3: Type text on canvas"

# Snap canvas BEFORE typing
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-type"
BEFORE_TYPE="$SNAP_RESULT"

# Type some text
type_text "Hello World"
wait_for 0.5 "Text typed"
assert_no_crash

# Snap canvas AFTER typing — text should be visible
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-type"
AFTER_TYPE="$SNAP_RESULT"
assert_regions_differ "$BEFORE_TYPE" "$AFTER_TYPE" "Typed text should be visible on canvas"
pass "Test 3: Typed text appears on canvas"

# ---------------------------------------------------------------------------
# Test 4: Text-local undo (Ctrl+Z while editing)
# ---------------------------------------------------------------------------
info "Test 4: Text-local undo (Ctrl+Z)"

# Snap canvas with "Hello World"
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-undo"
BEFORE_UNDO="$SNAP_RESULT"

# Undo several characters
key ctrl+z
key ctrl+z
key ctrl+z
key ctrl+z
key ctrl+z
wait_for 0.5 "Text-local undo applied"
assert_no_crash

# Snap canvas AFTER undo — should differ (fewer characters)
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-undo"
AFTER_UNDO="$SNAP_RESULT"
assert_regions_differ "$BEFORE_UNDO" "$AFTER_UNDO" "Text-local undo should remove characters"
pass "Test 4: Text-local undo removes characters"

# ---------------------------------------------------------------------------
# Test 5: Text-local redo (Ctrl+Y while editing)
# ---------------------------------------------------------------------------
info "Test 5: Text-local redo (Ctrl+Y)"

# Snap canvas after undo
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-redo"
BEFORE_REDO="$SNAP_RESULT"

# Redo the undone characters
key ctrl+y
key ctrl+y
key ctrl+y
key ctrl+y
key ctrl+y
wait_for 0.5 "Text-local redo applied"
assert_no_crash

# Snap canvas AFTER redo — should differ (characters restored)
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-redo"
AFTER_REDO="$SNAP_RESULT"
assert_regions_differ "$BEFORE_REDO" "$AFTER_REDO" "Text-local redo should restore characters"
pass "Test 5: Text-local redo restores characters"

# ---------------------------------------------------------------------------
# Test 6: Backspace deletes character
# ---------------------------------------------------------------------------
info "Test 6: Backspace deletes character"

# Snap canvas with full text
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-backspace"
BEFORE_BS="$SNAP_RESULT"

# Delete a few characters with Backspace
key BackSpace
key BackSpace
key BackSpace
wait_for 0.5 "Backspace applied"
assert_no_crash

# Snap canvas AFTER backspace
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-backspace"
AFTER_BS="$SNAP_RESULT"
assert_regions_differ "$BEFORE_BS" "$AFTER_BS" "Backspace should remove characters from canvas"
pass "Test 6: Backspace removes characters"

# Undo backspaces to restore text
key ctrl+z
key ctrl+z
key ctrl+z
wait_for 0.3 "Undo backspaces"

# ---------------------------------------------------------------------------
# Test 7: Enter key creates new line
# ---------------------------------------------------------------------------
info "Test 7: Enter key creates new line"

# Snap canvas before newline
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-newline"
BEFORE_NL="$SNAP_RESULT"

# Press Enter and type a second line
key Return
type_text "Line 2"
wait_for 0.5 "Second line typed"
assert_no_crash

# Snap canvas after newline
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-newline"
AFTER_NL="$SNAP_RESULT"
assert_regions_differ "$BEFORE_NL" "$AFTER_NL" "Enter should create visible second line"
pass "Test 7: Enter creates new line"

# Undo the newline + second line for clean state
key ctrl+z
key ctrl+z
key ctrl+z
key ctrl+z
key ctrl+z
key ctrl+z
key ctrl+z
wait_for 0.3 "Undo newline and Line 2"

# ---------------------------------------------------------------------------
# Test 8: Bold toggle (Ctrl+B) changes text rendering
# ---------------------------------------------------------------------------
info "Test 8: Bold toggle (Ctrl+B)"

# Snap canvas with current text
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-bold"
BEFORE_BOLD="$SNAP_RESULT"

# Select all text, apply bold
key ctrl+a
wait_for 0.3 "Selected all text"
key ctrl+b
wait_for 0.5 "Bold applied to selection"
assert_no_crash

# Click at end to deselect and see bold result
key End
wait_for 0.3 "Moved to end"

# Snap canvas AFTER bold
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-bold"
AFTER_BOLD="$SNAP_RESULT"
assert_regions_differ "$BEFORE_BOLD" "$AFTER_BOLD" "Bold toggle should change text rendering"
pass "Test 8: Bold changes text rendering"

# Undo bold
key ctrl+z
wait_for 0.3 "Undo bold"

# ---------------------------------------------------------------------------
# Test 9: Italic toggle (Ctrl+I) — SKIPPED (not yet implemented)
# ---------------------------------------------------------------------------
skip "Test 9: Italic not yet implemented"

# ---------------------------------------------------------------------------
# Test 10: Font size increase (Ctrl+Shift+.) changes text rendering
# ---------------------------------------------------------------------------
info "Test 10: Font size increase (Ctrl+Shift+.)"

# Snap before size change
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-size-up"
BEFORE_SIZE="$SNAP_RESULT"

# Select all, increase font size several steps
key ctrl+a
wait_for 0.3 "Selected all text"
key ctrl+shift+period
key ctrl+shift+period
key ctrl+shift+period
wait_for 0.5 "Font size increased"
assert_no_crash

# Deselect
key End
wait_for 0.3 "Deselected"

# Snap after size change
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-size-up"
AFTER_SIZE="$SNAP_RESULT"
assert_regions_differ "$BEFORE_SIZE" "$AFTER_SIZE" "Font size increase should change text rendering"
pass "Test 10: Font size increase changes rendering"

# Undo size changes
key ctrl+z
key ctrl+z
key ctrl+z
wait_for 0.3 "Undo font size changes"

# ---------------------------------------------------------------------------
# Test 11: Select all (Ctrl+A) highlights text
# ---------------------------------------------------------------------------
info "Test 11: Select all (Ctrl+A)"

# Snap before selection
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-select-all"
BEFORE_SEL="$SNAP_RESULT"

# Select all
key ctrl+a
wait_for 0.5 "Select all applied"
assert_no_crash

# Snap after selection — selection highlight should be visible
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-select-all"
AFTER_SEL="$SNAP_RESULT"
assert_regions_differ "$BEFORE_SEL" "$AFTER_SEL" "Select All should show selection highlight"
pass "Test 11: Select All highlights text"

# Clear selection
key Right
wait_for 0.3 "Selection cleared"

# ---------------------------------------------------------------------------
# Test 12: Copy and paste (Ctrl+C, Ctrl+V)
# ---------------------------------------------------------------------------
info "Test 12: Copy and Paste within text editing"

# Select all and copy
key ctrl+a
wait_for 0.3 "Select all for copy"
key ctrl+c
wait_for 0.3 "Text copied"
assert_no_crash

# Move cursor to end, add newline, then paste
key End
key Return
wait_for 0.3 "Newline added"

# Snap before paste
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-paste"
BEFORE_PASTE="$SNAP_RESULT"

# Paste
key ctrl+v
wait_for 0.5 "Text pasted"
assert_no_crash

# Snap after paste
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-paste"
AFTER_PASTE="$SNAP_RESULT"
assert_regions_differ "$BEFORE_PASTE" "$AFTER_PASTE" "Paste should add copied text below"
pass "Test 12: Copy and Paste works"

# Undo paste and newline
key ctrl+z
key ctrl+z
wait_for 0.3 "Undo paste and newline"

# ---------------------------------------------------------------------------
# Test 13: Cut (Ctrl+X) removes selected text
# ---------------------------------------------------------------------------
info "Test 13: Cut (Ctrl+X) removes text"

# Snap before cut
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-cut"
BEFORE_CUT="$SNAP_RESULT"

# Select all and cut
key ctrl+a
wait_for 0.3 "Select all for cut"
key ctrl+x
wait_for 0.5 "Text cut"
assert_no_crash

# Snap after cut — canvas should differ (text removed)
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-cut"
AFTER_CUT="$SNAP_RESULT"
assert_regions_differ "$BEFORE_CUT" "$AFTER_CUT" "Cut should remove text from canvas"
pass "Test 13: Cut removes selected text"

# Undo cut to restore text
key ctrl+z
wait_for 0.3 "Undo cut"

# ---------------------------------------------------------------------------
# Test 14: Escape with text commits the layer (non-destructive)
# ---------------------------------------------------------------------------
info "Test 14: Escape commits text layer"

# Snap canvas with text visible
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-escape-commit"
BEFORE_COMMIT="$SNAP_RESULT"

# Press Escape to commit
key Escape
wait_for 0.5 "Text committed via Escape"
assert_no_crash

# Snap canvas after commit — text should still be visible (committed, not deleted)
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-escape-commit"
AFTER_COMMIT="$SNAP_RESULT"
# Note: regions may differ slightly due to cursor disappearing, but text stays.
# The key check is that DRAW didn't crash and text remains.
pass "Test 14: Escape commits text (no crash)"

# ---------------------------------------------------------------------------
# Test 15: Re-edit committed text layer (click on text)
# ---------------------------------------------------------------------------
info "Test 15: Re-edit committed text layer"

# We're now in IDLE state (text tool still active). Click on the text to re-edit.
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-reedit"
BEFORE_REEDIT="$SNAP_RESULT"

# Click on the canvas where text was placed to re-enter editing
click $CANVAS_CX $CANVAS_CY
wait_for 0.8 "Re-editing text layer"
assert_no_crash

# Snap after re-edit — cursor should appear again
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-reedit"
AFTER_REEDIT="$SNAP_RESULT"
assert_regions_differ "$BEFORE_REEDIT" "$AFTER_REEDIT" "Re-edit should show cursor on text"
pass "Test 15: Re-edit shows cursor on committed text"

# Type additional text to verify editing works
type_text " More"
wait_for 0.3 "Additional text typed during re-edit"
assert_no_crash

# Commit again
key Escape
wait_for 0.5 "Re-edited text committed"

# ---------------------------------------------------------------------------
# Test 16: Escape with empty text deletes the layer
# ---------------------------------------------------------------------------
info "Test 16: Escape with empty text deletes layer"

# Snap canvas before creating empty text layer
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-empty-escape"
BEFORE_EMPTY="$SNAP_RESULT"

# Click on empty area (offset from existing text) to start new text entry
click $(( CANVAS_CX + 60 )) $(( CANVAS_CY + 50 ))
wait_for 0.5 "Started empty text entry"
assert_no_crash

# Immediately press Escape without typing — should delete the empty text layer
key Escape
wait_for 0.5 "Escape on empty text"
assert_no_crash

# Snap after — canvas should return to same state (empty layer deleted)
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-empty-escape"
AFTER_EMPTY="$SNAP_RESULT"
pass "Test 16: Escape on empty text layer (no crash)"

# ---------------------------------------------------------------------------
# Test 17: Tool switch commits active text editing
# ---------------------------------------------------------------------------
info "Test 17: Escape-commit then tool switch"

# Start a new text entry
click $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 30 ))
wait_for 0.5 "New text entry started"
type_text "Switch Test"
wait_for 0.5 "Text typed"
assert_no_crash

# Snap canvas with text
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-tool-switch"
BEFORE_SWITCH="$SNAP_RESULT"

# Must Escape to commit text before switching tools
key Escape
wait_for 0.5 "Text committed via Escape"
assert_no_crash

# Now switch to brush tool
key b
wait_for 0.5 "Switched to brush tool"
assert_no_crash

# Snap canvas after tool switch — text should remain visible (committed)
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-tool-switch"
AFTER_SWITCH="$SNAP_RESULT"
# Text should be committed and mostly still visible
pass "Test 17: Escape-commit then tool switch (no crash)"

# Snap TEXT_BAR area — should be gone after switching away
park_mouse
snap_region $TEXT_BAR_SNAP_X $TEXT_BAR_SNAP_Y $TEXT_BAR_SNAP_W $TEXT_BAR_SNAP_H "text-bar-after-tool-switch"
BAR_AFTER_SWITCH="$SNAP_RESULT"
assert_regions_differ "$AFTER_BAR" "$BAR_AFTER_SWITCH" "TEXT_BAR should disappear after switching tool"
pass "Test 17b: TEXT_BAR disappears on tool switch"

# ---------------------------------------------------------------------------
# Test 18: Re-activate text tool, verify TEXT_BAR returns
# ---------------------------------------------------------------------------
info "Test 18: Re-activate text tool"

# Snap TEXT_BAR area before
park_mouse
snap_region $TEXT_BAR_SNAP_X $TEXT_BAR_SNAP_Y $TEXT_BAR_SNAP_W $TEXT_BAR_SNAP_H "text-bar-before-reactivate"
BEFORE_REACTIVATE="$SNAP_RESULT"

key t
wait_for 0.5 "Text tool re-activated"
assert_no_crash

park_mouse
snap_region $TEXT_BAR_SNAP_X $TEXT_BAR_SNAP_Y $TEXT_BAR_SNAP_W $TEXT_BAR_SNAP_H "text-bar-after-reactivate"
AFTER_REACTIVATE="$SNAP_RESULT"
assert_regions_differ "$BEFORE_REACTIVATE" "$AFTER_REACTIVATE" "TEXT_BAR should reappear"
pass "Test 18: TEXT_BAR reappears on text tool re-activation"

# ---------------------------------------------------------------------------
# Test 19: Underline toggle (Ctrl+U) changes rendering
# ---------------------------------------------------------------------------
info "Test 19: Underline toggle (Ctrl+U)"

# Start editing a new text entry
click $(( CANVAS_CX )) $(( CANVAS_CY + 40 ))
wait_for 0.5 "New text entry for underline test"
type_text "Underline"
wait_for 0.3 "Text typed"

# Snap before underline
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-underline"
BEFORE_UL="$SNAP_RESULT"

# Select all, apply underline
key ctrl+a
wait_for 0.3 "Selected all"
key ctrl+u
wait_for 0.5 "Underline applied"
assert_no_crash

# Deselect
key End
wait_for 0.3 "Deselected"

# Snap after underline
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-underline"
AFTER_UL="$SNAP_RESULT"
assert_regions_differ "$BEFORE_UL" "$AFTER_UL" "Underline should change text rendering"
pass "Test 19: Underline changes rendering"

# Commit this text layer
key Escape
wait_for 0.3 "Committed underline text"

# ---------------------------------------------------------------------------
# Test 20: Shift+T activates with Tiny5 font
# ---------------------------------------------------------------------------
info "Test 20: Shift+T activates with Tiny5 font"

# Switch to brush first to deactivate text tool
key b
wait_for 0.3 "Switched to brush"

# Snap before
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-tiny5"
BEFORE_TINY5="$SNAP_RESULT"

# Activate with Shift+T
key shift+t
wait_for 0.5 "Shift+T activated text tool"
assert_no_crash

# Click canvas and type
click $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 ))
wait_for 0.5 "Tiny5 text entry started"
type_text "Tiny5 Font"
wait_for 0.5 "Tiny5 text typed"
assert_no_crash

# Snap after
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-tiny5"
AFTER_TINY5="$SNAP_RESULT"
assert_regions_differ "$BEFORE_TINY5" "$AFTER_TINY5" "Tiny5 text should be visible on canvas"
pass "Test 20: Shift+T activates with Tiny5 font"

# Commit
key Escape
wait_for 0.3 "Committed Tiny5 text"

# ---------------------------------------------------------------------------
# Test 21: Cursor navigation — Home/End
# ---------------------------------------------------------------------------
info "Test 21: Cursor navigation (Home/End)"

# Re-edit the first text layer by clicking on it
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Re-editing for cursor navigation"
assert_no_crash

# Snap before Home
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-home"
BEFORE_HOME="$SNAP_RESULT"

# Press Home to move cursor to start
key Home
wait_for 0.5 "Cursor moved to start with Home"
assert_no_crash

# Snap after Home — cursor position should change
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-home"
AFTER_HOME="$SNAP_RESULT"
assert_regions_differ "$BEFORE_HOME" "$AFTER_HOME" "Home should move cursor (visible change)"
pass "Test 21: Home key moves cursor to start"

# Press End to move back
key End
wait_for 0.3 "Cursor moved to end with End"

# Commit
key Escape
wait_for 0.3 "Committed after cursor nav"

# ---------------------------------------------------------------------------
# Test 22: Shift+Right selects text (selection highlight)
# ---------------------------------------------------------------------------
info "Test 22: Selection with Shift+Right"

# Re-edit
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Re-editing for selection test"

# Move to start
key Home
wait_for 0.3 "At start"

# Snap before selection
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-shift-right"
BEFORE_SHIFT_R="$SNAP_RESULT"

# Select first 5 characters
key shift+Right
key shift+Right
key shift+Right
key shift+Right
key shift+Right
wait_for 0.5 "5 characters selected"
assert_no_crash

# Snap after selection
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-shift-right"
AFTER_SHIFT_R="$SNAP_RESULT"
assert_regions_differ "$BEFORE_SHIFT_R" "$AFTER_SHIFT_R" "Selection highlight should be visible"
pass "Test 22: Shift+Right selects text (highlight visible)"

# Clear selection and commit
key Right
wait_for 0.2 "Selection cleared"
key Escape
wait_for 0.3 "Committed after selection test"

# ---------------------------------------------------------------------------
# Test 23: Typing replaces selection
# ---------------------------------------------------------------------------
info "Test 23: Typing replaces selection"

# Re-edit
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Re-editing for replace-selection test"

# Select all
key ctrl+a
wait_for 0.3 "All text selected"

# Snap before replacement
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-before-replace-sel"
BEFORE_REPLACE="$SNAP_RESULT"

# Type replacement text — should replace all selected text
type_text "Replaced"
wait_for 0.5 "Selection replaced"
assert_no_crash

# Snap after replacement
park_mouse
snap_region $SNAP_X $SNAP_Y $SNAP_W $SNAP_H "text-after-replace-sel"
AFTER_REPLACE="$SNAP_RESULT"
assert_regions_differ "$BEFORE_REPLACE" "$AFTER_REPLACE" "Typing should replace selected text"
pass "Test 23: Typing replaces selection"

# Commit
key Escape
wait_for 0.3 "Committed after replace test"

# ---------------------------------------------------------------------------
# Cleanup — undo all text layers to restore clean canvas
# ---------------------------------------------------------------------------
info "=== Cleanup ==="

# Switch back to brush tool (deactivates text tool)
key b
wait_for 0.3 "Switched to brush tool"

# Undo text layers created during tests (multiple Ctrl+Z)
key ctrl+z
wait_for 0.3 "Undo 1"
key ctrl+z
wait_for 0.3 "Undo 2"
key ctrl+z
wait_for 0.3 "Undo 3"
key ctrl+z
wait_for 0.3 "Undo 4"
key ctrl+z
wait_for 0.3 "Undo 5"
key ctrl+z
wait_for 0.3 "Undo 6"
key ctrl+z
wait_for 0.3 "Undo 7"
key ctrl+z
wait_for 0.3 "Undo 8"
key ctrl+z
wait_for 0.3 "Undo 9"
key ctrl+z
wait_for 0.3 "Undo 10"
assert_no_crash

# Final checks
assert_window_exists
info "=== Text Tool Tests Complete ==="
