# BUGS

## TO DO

### TEXT TOOL

- [ ] When scrolling with the wheel of my mouse over the text dropdown when it is open i do not see a selected item color.
      - I want to be able to hover over a different font in the list to see a realtime preview of the font change

- [ ] I would also like to be able to use my arrow keys on the keyboard to go up and down, to choose the font.
    - In this way i can quickly preview fonts in realtime.
    - So if I open the picker, and go to a font with the wheel, then choose down arrow, or whatever, it loads that font but   
      keeps the picker open so i can quickly preview fonts for my text layer/selected text.
      - If the text has selection, just change the selected text, if not, the entire text
      - Keep the same other settings for bold, italic, strikethrough, underline, size, color, baseline, kerning, position, etc.

- [ ] I would like to have the option to arrow through fonts in the dropdown menu to show a popup preview
      of the font
      - DRAW.cfg settings:
        - FONT_PREVIEW_FONT_SIZE        - DEFAULT: 16
        - FONT_PREVIEW_PADDING          - DEFAULT: 4
        - FONT_PREVIEW_DELAY            - DEFAULT: 2 seconds
      - THEME.cfg settings:
        - FONT_PREVIEW_FONT_FG_COLOR    - DEFAULT: RGB(0,0,0)
        - FONT_PREVIEW_FONT_BG_COLOR    - DEFAULT: RGB(255,255,255)
        - FONT_PREVIEW_BORDER_COLOR     - DEFAULT: same as tooltip border color
        - FONT_PREVIEW_BORDER_WIDTH     - DEFAULT: same as tooltip border width
        - FONT_PREVIEW_OFFSET_X         - DEFAULT: 10
        - FONT_PREVIEW_OFFSET_Y         - DEFAULT: 4
      - The popup should use the DRAW.cfg and THEME.cfg settings

- [ ] I would like to be able to Outline text in a separate color, and have a outline width setting for that color
  - This should live in the font property bar
  - Outline text should work as a per character / selected text attribute and only apply to selected text if it's on.
  - So a checkbox [x] Outline (__) (color chip - click to pick), [ 1->10px ] outline size dropdown

- [ ] I would like to be able to have a Shadow text in a separate color, and a X/Y distance for that setting.
  - This should live in the font property bar
  - Shadow text should work as a per character / selected text attribute
  - So a checkbox [x] Shadow (__) (color chip - click to pick), Offset: x:[ 1->10px ] (dropdown) y:[ 1->10px ] dropdown

- [ ] I would like a text align in font property bar:
    - [ L | C | R ] (left, center, right)
    - The text should align to the entire body of the text.
    - So if I press L, all text new lines start Left justified same X position for all lines, flush left.
    - So if I press C, all text is centered across all lines in the whole text layer
    - So if I press R, all text is right justified to the edge of the longest line in the text layer,
      and the x position stays the same - spaces are used to position the text so it is flush right.

---

## COMPLETED

### TEXT TOOL

- [x] Extended editing in text mode with word-processor-style navigation
  - Ctrl+Left / Ctrl+Right: jump to previous/next word boundary (via `TEXT_LAYER_prev_word_pos%` / `TEXT_LAYER_next_word_pos%`)
  - Ctrl+Shift+Left / Ctrl+Shift+Right: select to previous/next word boundary
  - Shift+Home / Shift+End: select from cursor to start/end of line (already existed)
  - Tab: insert 4 spaces
  - Up / Down arrows: move cursor vertically to same X position on adjacent line (with key repeat)
  - Shift+Up / Shift+Down: extend selection vertically
  - Gated global hotkeys during text editing: Ctrl+Shift+Arrow (side toggles), Tab (toolbar toggle), Shift+Tab (pattern tile mode)

- [x] Bold style is good for faux bold, but it makes letters too close together
  - Faux bold synthesis now adds +1px advance for the synthesis pixel, guaranteeing 1px gap
  - Background fill, underline, and strikethrough extend to cover faux bold width
  - Cursor X recomputed after any style toggle (bold/italic/underline/strike) via `TEXT_BAR_apply_style_to_selection`
  - Hit-test and cursor-position functions all account for faux bold advance consistently

- [x] Home, End, Page up, Page down - are causing global transforms while the text tool is still editing and active
  - Added `TEXT.ACTIVE` guard in `KEYBOARD_handle_custom_brush` to skip Home/End/PgUp/PgDn transform handlers when text tool is editing
  - Keys now fall through to `KEYBOARD_handle_text_tool%` for proper cursor navigation

- [x] Pressing enter does not move to new line
  - Fixed TEXT_LAYER_add_char line break shift: `>=` → `>` so chars after Enter belong to the new line
  - Fixed TEXT_LAYER_get_char_x to reset curX to startX when charIdx sits at a line break position

- [x] I should not be able to type off the canvas
  - Auto-wraps text at right canvas edge (word-wrap with char-wrap fallback)
  - Blocks typing/Enter when text would overflow bottom edge
  - Plays pitched-down alert sound + flashing black/white cursor on overflow

- [x] Key repeat rate is too fast
  - Arrowing back after typing some text ...
  - and pressing DELETE sometimes deletes more than 1 character

- [x] Hide/Show All is not hiding the text properties bar
  - F11 should hide/show all chrome / widgets in the UI

- [x] I should be able to click while entering text if I click ON previously entered text (in the same text entry session)
  - To move the cursor there
  - Added `TEXT_LAYER_get_cursor_at_pos%()` — nearest-position hit-test for canvas clicks
  - Modified `MOUSE_tool_text()` to move cursor within active text layer on single-click
  - Clicking outside the text area still creates a new layer as before

- [x] Cannot choose transparent as background color
  - Left-click FG/BG swatches opens palette picker; right-click toggles transparent
  - BG/FG color changes now sync to all existing characters in active text layer
  - Fixed _PRINTSTRING filling char cells with opaque black (_PRINTMODE _KEEPBACKGROUND)
  - Fixed _MEM clear for guaranteed transparent buffer before text render

- [x] When the canvas is panned under the text tool properties bar i am able to still pick colors
  and interact with the canvas, even though the mouse pointer is over the
  text properties bar.
  - Added catch-all guard in `MOUSE_handle_gui_early%` that blocks all canvas interaction when mouse is within `TEXT_BAR_in_bounds%`, regardless of button state
  - Fresh button presses on the bar are flagged via `UI_CHROME_CLICKED%` to prevent spurious tool-release actions

- [x] I cannot select any characters to change their properties.
  - I cannot use SHIFT to select
  - I cannot span select with mouse, etc.
  - When I click anything in the text tool properties bar, like color, style, etc.
  - It changes all text.
  - I want to be able to change individual parts of the text like in photoshop,
  or word, etc. Where you can have rich editing experience.
  - **Fixed**: Added full selection system (Shift+Arrow, Shift+Home/End, mouse drag, Shift+click, Ctrl+A)
  - Style buttons (B/I/U/S), font, size, and color changes now apply only to selected range
  - Ctrl+C/X/V clipboard with rich formatting preservation (per-character attributes)
  - Ctrl+A → Delete/Backspace now visually clears (TEXT_LAYER_render clears imgHandle when charCount=0)
  - All Ctrl+letter hotkeys (A/B/C/I/U/V/X) work with CapsLock on or off

- [x] I cannot re-edit the existing text of the layer, the idea I am after is to have
      a non-destructive, always editable (until rasterized) text layer type.
  - **Fixed**: Single-click on a committed text layer enters re-edit mode (cursor at click position)
  - Double-click also positions cursor at click point instead of end-of-text
  - `TEXT_sync_bar_to_cursor` syncs TEXT_BAR style toggles (B/I/U/S, font, size) from character at cursor
  - Text layers remain `LAYER_TYPE_TEXT` until explicitly rasterized — fully non-destructive

- [x] Add settings in DRAW.cfg for:
  - FONT_DEFAULT_FONT - default font to choose when entering text if empty use as we have already
  - FONT_DEFAULT_SIZE - default size in legal range if empty use program default

- [x] The font dropdown menu should be longer down the screen, to about 75% of the size 
  - If there are enough fonts to warrant that, otherwise render as long down as the fonts need.
 
- [x] Add ./DRAW_FONT_BLACKLIST.txt support (if it exists)
  - This should contain lists of fonts by path/filename that are NOT shown in the font picker

- [x] Add ./DRAW_FONT_FAVORITES.txt support (if it exists)
  - This should contain a list of fonts that are shown at the very top of the font picker list.
  - Just the font name, not the whole filename obviously, should be in the dropdown.
  - Then a divider --- after them

