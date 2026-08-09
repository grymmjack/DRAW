#!/bin/bash
# SKIP: needs AI_ENABLED=1; enabling it adds an AI root menu that shifts menubar coordinates for other tests
# =============================================================================
# ai-prompt-textinput.sh — QA test: AI prompt multiline text area
#
# Covers the QB64_GJ_LIB TEXT_INPUT fixes (submodule f141562) as they appear in
# DRAW's File > New from AI dialog:
#
#   - proportional rendering (was forced MONOSPACE, text 50% too wide)
#   - caret/selection height from the font (were hardcoded 14px/16px)
#   - Home/End on the LOGICAL line, Ctrl+Home/Ctrl+End on the whole box
#   - Shift+Down on the last row extends to end of text
#   - Ctrl+Shift+Left stops at the line break
#   - Shift+ENTER inserts a newline; plain ENTER generates
#
# Run manually with AI enabled:
#   ./draw-qa.sh tests/ai-prompt-textinput.sh
# after setting AI_ENABLED=-1 in QA/DRAW.qa.cfg (revert afterwards — an AI root
# menu changes menubar hit coordinates for the rest of the suite).
# =============================================================================

info "=== AI Prompt Text Area ==="

canvas_focus v
wait_for 0.3 "Move tool ready"

# -- Open File > New from AI (4th item: New, New from Template, New from Clipboard, New from AI) --
info "Opening File > New from AI via keyboard menu navigation"
key alt
wait_for 0.6 "Menubar open on FILE"
key Down
wait_for 0.2 "New"
key Down
wait_for 0.2 "New from Template"
key Down
wait_for 0.2 "New from Clipboard"
key Down
wait_for 0.2 "New from AI"
key Return
wait_for 1.5 "AI dialog open"
assert_no_crash
screenshot "ai-dialog-open"

# The prompt field takes focus when the dialog opens (TI_set_focus).

# -- Typing: proportional layout --
info "Typing a prompt (proportional spacing, no gapping)"
type_text "a humanoid skull embelished with age and proportion to modern man"
wait_for 0.5 "Text entered"
screenshot "ai-prompt-typed"
assert_no_crash

# -- Shift+ENTER must insert a newline, NOT submit --
info "Shift+ENTER should add a line, not generate"
key shift+Return
wait_for 0.4 "Newline inserted"
type_text "second line here"
wait_for 0.4 "Second line typed"
screenshot "ai-prompt-shift-enter"
# If ENTER had submitted, the dialog would be gone and the canvas resized.
assert_no_crash

# -- Ctrl+Shift+Left selects the last word only, not across the line break --
info "Ctrl+Shift+Left from end selects one word on this line"
key ctrl+shift+Left
wait_for 0.4 "Word selected"
screenshot "ai-prompt-ctrl-shift-left"
assert_no_crash

# -- Home/End on the logical line --
info "End then Home on the logical line"
key End
wait_for 0.3 "End of logical line"
screenshot "ai-prompt-end"
key Home
wait_for 0.3 "Start of logical line"
screenshot "ai-prompt-home"
assert_no_crash

# -- Ctrl+Home / Ctrl+End span the whole box --
key ctrl+End
wait_for 0.3 "End of box"
screenshot "ai-prompt-ctrl-end"
key ctrl+Home
wait_for 0.3 "Start of box"
screenshot "ai-prompt-ctrl-home"
assert_no_crash

# -- Shift+Down repeatedly must reach the final line --
info "Shift+Down to the last line"
key shift+Down
wait_for 0.2 "Extend"
key shift+Down
wait_for 0.2 "Extend"
key shift+Down
wait_for 0.3 "Should now include the last line"
screenshot "ai-prompt-shift-down-last-line"
assert_no_crash

# -- Leave without generating --
info "ESC out (first leaves the text area, then cancels)"
key Escape
wait_for 0.4 "Leave text area"
key Escape
wait_for 0.8 "Cancel dialog"
assert_no_crash
screenshot "ai-prompt-cancelled"
