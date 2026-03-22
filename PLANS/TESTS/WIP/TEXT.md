# [ ] TEXT TOOL TESTING

## [ ] TOOL ACTIVATION AND SWITCHING

### [ ] Activating the Text Tool
Verify the text tool can be activated from keyboard and toolbar, and that the TEXT BAR appears.

#### [x] Activate via T key
1. [x] Press `T` to activate text tool
2. [x] Verify toolbar shows text tool as active (highlighted)
3. [x] Verify TEXT BAR appears below the menu bar
4. [x] Verify status bar shows text tool indicator

#### [x] Activate via Shift+T (Tiny5 font)
1. [x] Press `Shift+T` to activate text tool with Tiny5 font
2. [x] Verify TEXT BAR shows "Tiny5" or small font selected
3. [x] Click canvas and type — verify text appears in Tiny5 (5px wide glyphs)

#### [x] Activate via Ctrl+T (custom font)
1. [x] First load a custom font: middle-click the Text toolbar icon, select a .ttf file
2. [x] Switch to another tool (e.g. Brush)
3. [x] Press `Ctrl+T` to activate text tool with custom font
4. [x] Click canvas and type — verify text appears in the loaded custom font

#### [x] Activate via toolbar click
1. [x] Click the Text tool icon in the toolbar
2. [x] Verify TEXT BAR appears
3. [x] Verify tool is active (toolbar highlight)

#### [x] Switch away from text tool
1. [x] Activate text tool with `T`
2. [x] Press `B` to switch to Brush
3. [x] Verify TEXT BAR disappears
4. [x] Verify toolbar shows Brush as active

> **FIXED** 2026-03-21: Root cause — GUI-only render path restored stale `SCENE_CACHE&` (which had TEXT BAR baked in) then composited transparent `SCRN.GUI&` on top, leaving bar visible. Fix: set `SCENE_DIRTY% = TRUE` alongside `GUI_NEEDS_REDRAW% = TRUE` in `KEYBOARD_tools` and `TOOLBAR_handle_click%` whenever the tool changes, ensuring the full render path runs and `SCENE_CACHE&` is rebuilt correctly.

#### [x] Switch away while editing text (commit)
1. [x] Activate text tool, click canvas, type "Hello"
2. [x] Press `Escape` to commit text (stays as editable text layer)
3. [x] Press `B` to switch to Brush
4. [x] Verify the text "Hello" is preserved as a text layer (not rasterized)
5. [x] Verify TEXT BAR disappears immediately
6. [x] Re-activate text tool (`T`), click the text — verify it's re-editable

> Note: pressing `B` **while actively editing** (cursor blinking) types the letter 'b' — Escape must be pressed first to commit, then B switches tools.
> **FIXED** 2026-03-21: same root cause as above; test step 2 updated to include Escape.

---

## [ ] TEXT ENTRY — BASIC

### [ ] Starting Text Entry
Verify clicking on the canvas creates a new text layer and begins editing.

#### [x] Click canvas to start text entry
1. [x] Activate text tool (`T`)
2. [x] Click on empty area of canvas
3. [x] Verify a blinking cursor appears at the click point
4. [x] Verify a new layer is created in the layer panel with type TEXT
5. [x] Type "DRAW" — verify each character appears at the cursor position

#### [x] Type printable ASCII characters
1. [x] Start text entry on canvas
2. [x] Type lowercase: `abcdefghijklmnopqrstuvwxyz`
3. [x] Verify all 26 lowercase characters render correctly
4. [x] Start new text entry, type uppercase: `ABCDEFGHIJKLMNOPQRSTUVWXYZ`
5. [x] Verify all 26 uppercase characters render correctly
6. [x] Start new text entry, type digits: `0123456789`
7. [x] Verify all 10 digits render correctly
8. [x] Start new text entry, type symbols: `!@#$%^&*()-=_+[]{}|;:',.<>/?`
9. [x] Verify all symbols render correctly

#### [x] Enter key inserts newline
1. [x] Start text entry, type "Line 1"
2. [x] Press `Enter`
3. [x] Type "Line 2"
4. [x] Verify two lines of text appear, with "Line 2" below "Line 1"

#### [x] Tab inserts 4 spaces
1. [x] Start text entry
2. [x] Press `Tab`
3. [x] Type "indented"
4. [x] Verify 4 spaces appear before "indented"

#### [x] Backspace deletes character
1. [x] Type "Hello World"
2. [x] Press `Backspace` once
3. [x] Verify "d" is deleted, text shows "Hello Worl"
4. [x] Press `Backspace` 5 more times
5. [x] Verify text shows "Hello"

#### [x] Backspace at start of line does nothing
1. [x] Start text entry, type "Test"
2. [x] Press `Home` to move cursor to start of line
3. [x] Press `Backspace`
4. [x] Verify "Test" remains unchanged and cursor stays at position 0

#### [x] Delete key removes character after cursor
1. [x] Type "Hello"
2. [x] Press `Home` to move cursor to start
3. [x] Press `Delete`
4. [x] Verify "H" is removed, text shows "ello"
5. [x] Press `Delete` again
6. [x] Verify text shows "llo"

#### [x] Delete key at end of text does nothing
1. [x] Type "Test"
2. [x] Cursor should be at the end
3. [x] Press `Delete`
4. [x] Verify "Test" remains unchanged

---

## [ ] TEXT ENTRY — ADVANCED

### [ ] Auto-Wrap Behavior
Verify text wraps when reaching canvas edge.

#### [x] Word-wrap at right edge
1. [x] Start text entry near the right edge of canvas (within ~30px of right edge)
2. [x] Type a long sentence: "This is a test of word wrapping behavior"
3. [x] Verify text wraps to next line at a word boundary (space character)
4. [x] Verify wrapped text continues on the next line below

#### [x] Character-wrap when no space found
1. [x] Start text entry near the right edge of canvas
2. [x] Type a single long word with no spaces: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
3. [x] Verify text wraps character-by-character when no space is available

#### [x] Bottom overflow flash
1. [x] Use a small canvas (e.g. 16x16)
2. [x] Start text entry at top-left
3. [x] Type many lines until text would exceed canvas bottom boundary
4. [x] Verify cursor flashes (visual feedback) and an error sound plays
5. [x] Verify no new line is added past the canvas bottom

### [ ] Multi-line Text
Verify multi-line text behavior with line navigation.

#### [x] Multiple newlines
1. [x] Type "A", press `Enter`
2. [x] Type "B", press `Enter`
3. [x] Type "C", press `Enter`
4. [x] Type "D"
5. [x] Verify 4 lines appear correctly stacked

#### [x] Lines with different lengths
1. [x] Type "Short" + Enter
2. [x] Type "A much longer line of text" + Enter
3. [x] Type "Mid"
4. [x] Verify all three lines render at their respective lengths
5. [x] Navigate with arrows — verify cursor moves correctly across different-length lines

---

## [ ] CURSOR NAVIGATION

### [x] Arrow Key Movement
Verify cursor movement with arrow keys, including key repeat.

#### [x] Left arrow moves cursor left
1. [x] Type "Hello"
2. [x] Press Left arrow once
3. [x] Verify cursor is between 'l' and 'o'
4. [x] Type "X"
5. [x] Verify text reads "HellXo"

#### [x] Right arrow moves cursor right
1. [x] Type "Hello"
2. [x] Press `Home` to go to start
3. [x] Press Right arrow once
4. [x] Verify cursor is between 'H' and 'e'
5. [x] Type "X"
6. [x] Verify text reads "HXello"

#### [x] Left arrow at position 0 does nothing
1. [x] Type "Test"
2. [x] Press `Home`
3. [x] Press Left arrow
4. [x] Verify cursor stays at position 0

#### [x] Right arrow at end of text does nothing
1. [x] Type "Test"
2. [x] Press Right arrow
3. [x] Verify cursor stays at end

#### [x] Up arrow moves to line above
1. [x] Type "Line 1" + Enter + "Line 2"
2. [x] Cursor should be at end of "Line 2"
3. [x] Press Up arrow
4. [x] Verify cursor moves to "Line 1" (approximately same X position)

#### [x] Down arrow moves to line below
1. [x] Type "Line 1" + Enter + "Line 2"
2. [x] Press `Home`, then Up arrow to position cursor on Line 1
3. [x] Press Down arrow
4. [x] Verify cursor moves to Line 2

#### [x] Up arrow on first line moves to position 0
1. [x] Type "Hello"
2. [x] Press `End` to ensure at end of line
3. [x] Press Up arrow
4. [x] Verify cursor moves to position 0 (start of text)

#### [x] Down arrow on last line moves to end
1. [x] Type "Hello" + Enter + "World"
2. [x] Press `Home` (cursor at start of "World")
3. [x] Press Down arrow
4. [x] Verify cursor moves to end of "World"

#### [x] Home key moves to start of line
1. [x] Type "Hello World"
2. [x] Press `Home`
3. [x] Verify cursor is at position 0 (start of the line)

#### [x] End key moves to end of line
1. [x] Type "Line 1" + Enter + "Line 2"
2. [x] Press Up arrow, then `Home` (cursor at start of "Line 1")
3. [x] Press `End`
4. [x] Verify cursor is at end of "Line 1" (before the newline)

> **FIXED**: End key was using `TL_LINE_BREAK(line+1)` (start of next line) instead of `TL_LINE_BREAK(line+1) - 1` (end of current line). Fixed in `INPUT/KEYBOARD.BM`.

#### [x] Key repeat on held arrow key
1. [x] Type "A long line of text for testing"
2. [x] Press `Home`
3. [x] Hold Right arrow for ~1 second
4. [x] Verify cursor advances multiple positions (initial 0.3s delay, then 0.08s repeat)
5. [x] Release and verify cursor stops

### [x] Word Navigation
Verify Ctrl+Left/Right jumps by word boundaries.

#### [x] Ctrl+Left jumps to previous word
1. [x] Type "Hello World Test"
2. [x] Cursor at end
3. [x] Press `Ctrl+Left`
4. [x] Verify cursor jumps to start of "Test"
5. [x] Press `Ctrl+Left` again
6. [x] Verify cursor jumps to start of "World"
7. [x] Press `Ctrl+Left` again
8. [x] Verify cursor jumps to start of "Hello"

#### [x] Ctrl+Right jumps to next word
1. [x] Type "Hello World Test"
2. [x] Press `Home`
3. [x] Press `Ctrl+Right`
4. [x] Verify cursor jumps to end of "Hello" / start of space
5. [x] Press `Ctrl+Right` again
6. [x] Verify cursor jumps to end of "World" / start of space
7. [x] Press `Ctrl+Right` again
8. [x] Verify cursor jumps to end of "Test"

---

## [x] TEXT SELECTION

### [x] Keyboard Selection
Verify text selection via Shift+arrow keys and other keyboard shortcuts.

#### [x] Shift+Right extends selection right
1. [x] Type "Hello"
2. [x] Press `Home`
3. [x] Press `Shift+Right` three times
4. [x] Verify "Hel" is highlighted/selected
5. [x] Selected text should show a visible highlight overlay

#### [x] Shift+Left extends selection left
1. [x] Type "Hello"
2. [x] Cursor at end
3. [x] Press `Shift+Left` twice
4. [x] Verify "lo" is highlighted/selected

#### [x] Shift+Up extends selection up
1. [x] Type "Line 1" + Enter + "Line 2"
2. [x] Cursor at end of "Line 2"
3. [x] Press `Shift+Up`
4. [x] Verify selection extends from cursor up to Line 1

#### [x] Shift+Down extends selection down
1. [x] Type "Line 1" + Enter + "Line 2"
2. [x] Move cursor to start of "Line 1"
3. [x] Press `Shift+Down`
4. [x] Verify selection extends from cursor down to Line 2

#### [x] Shift+Home selects to start of line
1. [x] Type "Hello World"
2. [x] Cursor at end
3. [x] Press `Shift+Home`
4. [x] Verify entire "Hello World" is selected

#### [x] Shift+End selects to end of line
1. [x] Type "Hello World"
2. [x] Press `Home`
3. [x] Press `Shift+End`
4. [x] Verify entire "Hello World" is selected

#### [x] Ctrl+Shift+Left selects to previous word
1. [x] Type "Hello World Test"
2. [x] Cursor at end
3. [x] Press `Ctrl+Shift+Left`
4. [x] Verify "Test" is selected

#### [x] Ctrl+Shift+Right selects to next word
1. [x] Type "Hello World Test"
2. [x] Press `Home`
3. [x] Press `Ctrl+Shift+Right`
4. [x] Verify "Hello" (and trailing space) is selected

#### [x] Ctrl+A selects all text
1. [x] Type "Hello World" + Enter + "Line Two"
2. [x] Press `Ctrl+A`
3. [x] Verify all text across all lines is selected

#### [x] Plain arrow key collapses selection
1. [x] Type "Hello"
2. [x] Press `Ctrl+A` to select all
3. [x] Press Right arrow (no Shift)
4. [x] Verify selection is cleared and cursor moves to right edge of former selection
5. [x] Repeat: select all, press Left arrow
6. [x] Verify selection is cleared and cursor moves to left edge of former selection

#### [x] Typing replaces selection
1. [x] Type "Hello World"
2. [x] Select "World" using Shift+Left (5 times from end)
3. [x] Type "DRAW"
4. [x] Verify text reads "Hello DRAW" (selection deleted, new text inserted)

#### [x] Backspace deletes selection
1. [x] Type "Hello World"
2. [x] Select "World" (Shift+Left 5 times)
3. [x] Press Backspace
4. [x] Verify text reads "Hello "

#### [x] Delete key deletes selection
1. [x] Type "Hello World"
2. [x] Select "Hello" (Home, then Shift+Right 5 times)
3. [x] Press Delete
4. [x] Verify text reads " World"

### [x] Mouse Selection
Verify text can be selected by clicking and dragging.

#### [x] Click to position cursor
1. [x] Type "Hello World"
2. [x] Click between 'o' and ' ' (space) in "Hello World"
3. [x] Verify cursor moves to the clicked position
4. [x] Type "X"
5. [x] Verify text reads "HelloX World"

#### [x] Shift+Click extends selection
1. [x] Type "Hello World"
2. [x] Click at start of "Hello" (no shift)
3. [x] Shift+Click at end of "World"
4. [x] Verify entire "Hello World" is selected

#### [x] Click and drag to select text
1. [x] Type "Hello World Test"
2. [x] Click on "W" in "World", hold mouse button and drag to "t" in "Test"
3. [x] Release mouse button
4. [x] Verify "World Test" (or approximate range) is selected/highlighted

---

## [x] CLIPBOARD OPERATIONS

### [x] Copy, Cut, Paste with Rich Formatting
Verify clipboard operations preserve per-character formatting.

#### [x] Ctrl+C copies selected text
1. [x] Type "Hello", select all with Ctrl+A
2. [x] Press Ctrl+C
3. [x] Open another app (e.g. text editor), paste — verify "Hello" is in system clipboard

#### [x] Ctrl+V pastes text from clipboard
1. [x] Copy "Test paste" from an external text editor (Ctrl+C there)
2. [x] In DRAW, start text entry on canvas
3. [x] Press Ctrl+V
4. [x] Verify "Test paste" appears at cursor position

#### [x] Ctrl+X cuts selected text
1. [x] Type "Hello World"
2. [x] Select "World" (Shift+Left 5 times from end)
3. [x] Press Ctrl+X
4. [x] Verify text reads "Hello " ("World" removed)
5. [x] Verify clipboard contains "World" (paste in external editor to confirm)

#### [x] Rich clipboard preserves formatting (internal copy-paste)
1. [x] Type "Hello"
2. [x] Select "Hello"
3. [x] Toggle Bold (Ctrl+B), change font size, change FG color
4. [x] Select "Hello" again (Ctrl+A)
5. [x] Press Ctrl+C (copy with rich formatting)
6. [x] Click elsewhere on canvas to start new text
7. [x] Press Ctrl+V
8. [x] Verify pasted text retains bold, font size, and color of the original

#### [x] External clipboard paste uses TEXT BAR defaults
1. [x] In an external editor, copy some plain text
2. [x] In DRAW, set TEXT BAR to Bold, 24px, red FG
3. [x] Start text entry, press Ctrl+V
4. [x] Verify pasted text uses the current TEXT BAR settings (bold, 24px, red)

#### [x] Paste multi-line text
1. [x] Copy multi-line text from external editor (e.g. "Line 1\nLine 2\nLine 3")
2. [x] In DRAW, start text entry, press Ctrl+V
3. [x] Verify 3 lines appear correctly, with newlines at correct positions

---

## [ ] TEXT BAR — FONT CONTROLS

### [ ] Font Dropdown
Verify the font dropdown lists available fonts and applies selection.

#### [x] Open font dropdown
1. [x] Activate text tool, start editing text
2. [x] Click the font name area in the TEXT BAR
3. [x] Verify a dropdown list appears listing available fonts
4. [x] Verify favorites appear at top (if DRAW_FONT_FAVORITES.txt exists)
5. [x] Verify separator lines show between favorites/bundled/system sections

#### [x] Select a font from dropdown
1. [x] Open font dropdown
2. [x] Click on a different font name
3. [x] Verify dropdown closes
4. [x] Type new text — verify it appears in the newly selected font

#### [x] Scroll font dropdown with mouse wheel
1. [x] Open font dropdown
2. [x] Scroll mouse wheel down
3. [x] Verify the list scrolls to show more fonts
4. [x] Scroll mouse wheel up
5. [x] Verify the list scrolls back up

#### [ ] Close font dropdown by clicking outside
1. [ ] Open font dropdown
2. [ ] Click somewhere outside the dropdown (on canvas or other bar area)
3. [ ] Verify dropdown closes

#### [ ] Font change applies to selection
1. [ ] Type "Hello World"
2. [ ] Select "World" (Shift+Left 5 times)
3. [ ] Change font in the TEXT BAR dropdown
4. [ ] Verify "World" renders in the new font while "Hello " stays in the original font

### [ ] Size Dropdown
Verify font size controls work correctly.

#### [ ] Open size dropdown
1. [ ] Click the size number in the TEXT BAR
2. [ ] Verify a dropdown with 25 preset sizes appears (4–128)
3. [ ] Verify the current size is highlighted

#### [ ] Select a size from dropdown
1. [ ] Open size dropdown
2. [ ] Click on size "24"
3. [ ] Verify dropdown closes
4. [ ] Type new text — verify it appears at 24px size

#### [ ] Size change applies to selection
1. [ ] Type "Hello World"
2. [ ] Select "World"
3. [ ] Change size from dropdown to a different value (e.g. 32)
4. [ ] Verify "World" renders larger while "Hello " stays at the original size

#### [ ] Ctrl+Shift+. increases font size
1. [ ] Type "Test" — note the current size
2. [ ] Select all (Ctrl+A)
3. [ ] Press Ctrl+Shift+. (period / >)
4. [ ] Verify text size increases to next preset size
5. [ ] Press again — verify it steps to next preset

#### [ ] Ctrl+Shift+, decreases font size
1. [ ] Type "Test" with size 24
2. [ ] Select all (Ctrl+A)
3. [ ] Press Ctrl+Shift+, (comma / <)
4. [ ] Verify text size decreases to next smaller preset size

---

## [ ] TEXT BAR — STYLE TOGGLES

### [ ] Bold
Verify bold toggle works via button click and keyboard shortcut.

#### [ ] Toggle bold via Ctrl+B
1. [ ] Start text entry
2. [ ] Press Ctrl+B
3. [ ] Verify [B] button in TEXT BAR shows active (darker background)
4. [ ] Type "Bold" — verify text appears bold (or faux-bold with +1px offset)
5. [ ] Press Ctrl+B again
6. [ ] Verify [B] button shows inactive
7. [ ] Type "Normal" — verify text appears normal weight

#### [ ] Toggle bold via button click
1. [ ] Click the [B] button in the TEXT BAR
2. [ ] Verify it toggles active/inactive
3. [ ] Type text — verify bold/normal respectively

#### [ ] Apply bold to selection
1. [ ] Type "Hello World"
2. [ ] Select "World"
3. [ ] Press Ctrl+B
4. [ ] Verify "World" appears bold while "Hello " is normal

### [ ] Italic
Verify italic toggle.

#### [ ] Toggle italic via Ctrl+I
1. [ ] Start text entry, press Ctrl+I
2. [ ] Verify [I] button shows active
3. [ ] Type "Italic" — verify text appears italic (if font supports it) or faux-italic
4. [ ] Press Ctrl+I to toggle off

#### [ ] Apply italic to selection
1. [ ] Type "Hello World", select "World"
2. [ ] Press Ctrl+I
3. [ ] Verify "World" appears italic

### [ ] Underline
Verify underline toggle.

#### [ ] Toggle underline via Ctrl+U
1. [ ] Start text entry, press Ctrl+U
2. [ ] Verify [U] button shows active
3. [ ] Type "Underline" — verify underline appears 1px below text
4. [ ] Press Ctrl+U to toggle off

#### [ ] Apply underline to selection
1. [ ] Type "Hello World", select "World"
2. [ ] Press Ctrl+U
3. [ ] Verify underline appears only under "World"

### [ ] Strikethrough
Verify strikethrough toggle.

#### [ ] Toggle strikethrough via Ctrl+Shift+X
1. [ ] Start text entry, press Ctrl+Shift+X
2. [ ] Verify [S] button shows active
3. [ ] Type "Strike" — verify strikethrough line at vertical midpoint
4. [ ] Press Ctrl+Shift+X to toggle off

#### [ ] Apply strikethrough to selection
1. [ ] Type "Hello World", select "World"
2. [ ] Press Ctrl+Shift+X
3. [ ] Verify strikethrough appears only through "World"

### [ ] Monospace Toggle
Verify monospace mode.

#### [ ] Toggle monospace via TEXT BAR [M] button
1. [ ] Start text entry
2. [ ] Click the [M] button in TEXT BAR
3. [ ] Verify it toggles active
4. [ ] Type "monospace test" — verify all characters are equal width
5. [ ] Click [M] again to toggle off
6. [ ] Verify monospace applies to entire text layer (not per-character)

---

## [ ] TEXT BAR — COLOR CONTROLS

### [ ] FG Color Swatch
Verify foreground color from TEXT BAR affects text.

#### [ ] FG color syncs from palette
1. [ ] Start text entry
2. [ ] Change FG color by clicking a swatch in the palette strip
3. [ ] Verify TEXT BAR FG swatch updates to match
4. [ ] Type text — verify it appears in the new FG color

#### [ ] Click FG swatch opens color picker
1. [ ] Start text entry
2. [ ] Click the FG color swatch in the TEXT BAR
3. [ ] Verify color picker dialog opens
4. [ ] Select a color and confirm
5. [ ] Type text — verify it appears in chosen color

#### [ ] FG color applies to selection
1. [ ] Type "Hello World" in red
2. [ ] Select "World"
3. [ ] Change FG color to blue (via palette strip click)
4. [ ] Verify "World" changes to blue while "Hello " stays red

### [ ] BG Color Swatch
Verify background color highlighting for text characters.

#### [ ] Click BG swatch toggles transparent background
1. [ ] Start text entry
2. [ ] Click the BG color swatch in the TEXT BAR
3. [ ] Verify it toggles between transparent (checkerboard) and the BG color
4. [ ] Type text — verify background appears behind characters when BG is not transparent

---

## [ ] TEXT BAR — LINE HEIGHT

### [ ] Line Height Controls
Verify line height (leading) adjustment.

#### [ ] Auto line height updates from largest font
1. [ ] Start text entry with AUTO line-height enabled (default)
2. [ ] Type text at size 12, then select some chars, change to size 24
3. [ ] Verify line height auto-adjusts based on the largest font size in the layer
4. [ ] Verify the line height value in TEXT BAR updates

#### [ ] Manual line height via input dialog
1. [ ] Click the line height value in TEXT BAR
2. [ ] Verify an input dialog appears
3. [ ] Enter a value (e.g. "30") and confirm
4. [ ] Verify AUTO checkbox is unchecked
5. [ ] Verify line spacing changes to 30px

#### [ ] Toggle AUTO line height
1. [ ] Click the AUTO checkbox in TEXT BAR
2. [ ] Verify toggling AUTO on restores automatic line height calculation
3. [ ] Verify toggling AUTO off preserves the current height value

---

## [ ] TYPOGRAPHY CONTROLS

### [ ] Kerning Adjustment
Verify per-character kerning via Ctrl+Alt shortcuts.

#### [ ] Ctrl+Alt+. increases kerning
1. [ ] Type "AV" (two characters commonly used for kerning test)
2. [ ] Position cursor on 'V' (or select it)
3. [ ] Press Ctrl+Alt+. (period)
4. [ ] Verify spacing between A and V increases by 1px
5. [ ] Press again — verify it increases further

#### [ ] Ctrl+Alt+, decreases kerning
1. [ ] Type "AV"
2. [ ] Position cursor on 'V'
3. [ ] Press Ctrl+Alt+, (comma)
4. [ ] Verify spacing between A and V decreases by 1px
5. [ ] Verify negative kerning (overlap) is possible

#### [ ] Kerning applies to selection
1. [ ] Type "HELLO"
2. [ ] Select "ELL"
3. [ ] Press Ctrl+Alt+. several times
4. [ ] Verify kerning applies to all 3 selected characters
5. [ ] Verify "H" and "O" are unaffected

### [ ] Baseline Adjustment
Verify per-character baseline shift via Ctrl+Alt+Arrow.

#### [ ] Ctrl+Alt+Up raises baseline
1. [ ] Type "Hello"
2. [ ] Position cursor on 'e' (or select it)
3. [ ] Press Ctrl+Alt+Up arrow
4. [ ] Verify 'e' moves up by 1px relative to other characters

#### [ ] Ctrl+Alt+Down lowers baseline
1. [ ] Type "Hello"
2. [ ] Position cursor on 'e'
3. [ ] Press Ctrl+Alt+Down arrow
4. [ ] Verify 'e' moves down by 1px relative to other characters

#### [ ] Baseline applies to selection
1. [ ] Type "HELLO"
2. [ ] Select "ELL"
3. [ ] Press Ctrl+Alt+Up several times
4. [ ] Verify all 3 selected characters shift up while "H" and "O" stay

---

## [ ] CURSOR BEHAVIOR

### [ ] Cursor Blinking
Verify cursor blink state and visual feedback.

#### [ ] Cursor blinks at 0.5s interval
1. [ ] Start text entry on canvas
2. [ ] Observe the cursor — verify it alternates visible/hidden every ~0.5 seconds

#### [ ] Cursor resets blink on key press
1. [ ] Start text entry, wait for cursor to blink off
2. [ ] Press any arrow key
3. [ ] Verify cursor immediately becomes visible (blink reset)

#### [ ] Cursor position tracks with text insertion
1. [ ] Type "Hello" — cursor should be after 'o'
2. [ ] Press `Home` — cursor should be before 'H'
3. [ ] Type "X" — cursor should be after 'X', before 'H'
4. [ ] Verify "XHello" renders correctly

---

## [ ] RE-EDITING TEXT LAYERS

### [ ] Single-click Re-edit
Verify clicking on a committed text layer opens it for editing.

#### [ ] Single-click opens committed text for editing
1. [ ] Create text: type "Test Layer", press Escape to commit
2. [ ] Activate text tool again (`T`)
3. [ ] Single-click on the "Test Layer" text on canvas
4. [ ] Verify the text layer enters edit mode (cursor appears at click position)
5. [ ] Type " More" — verify it inserts at the cursor position

#### [ ] Click positions cursor at click point
1. [ ] Create text "Hello World", commit (Esc)
2. [ ] Re-edit by clicking between "Hello" and "World"
3. [ ] Verify cursor appears at the clicked position (not at end of text)

### [ ] Double-click Re-edit
Verify double-clicking also re-edits text layers.

#### [ ] Double-click on text layer re-edits it
1. [ ] Create text "Test", commit (Esc)
2. [ ] Switch to another tool and back to text tool
3. [ ] Double-click on the committed text
4. [ ] Verify it enters edit mode with cursor at the double-click position

### [ ] Re-edit Across Layers
Verify re-editing works when clicking text on different layers.

#### [ ] Click on overlapping text layers picks topmost visible
1. [ ] Create text "Layer 1" on layer 1, commit
2. [ ] Create new layer, create text "Layer 2" overlapping Layer 1's position
3. [ ] Commit Layer 2
4. [ ] Click on the overlapping region
5. [ ] Verify the topmost visible text layer (Layer 2) is re-edited

#### [ ] Re-edit hidden text layer is not possible
1. [ ] Create text on a layer, commit
2. [ ] Hide the layer (toggle visibility in layer panel)
3. [ ] Click where the text was
4. [ ] Verify a new text layer is created instead of re-editing the hidden one

---

## [ ] FONT LOADING

### [ ] Custom Font from Disk
Verify loading TTF/OTF fonts via the TEXT BAR LOAD button.

#### [ ] Load font via TEXT BAR LOAD button
1. [ ] Activate text tool
2. [ ] Click the LOAD button in TEXT BAR
3. [ ] Verify file dialog opens filtered for .ttf and .otf files
4. [ ] Select a .ttf font file and confirm
5. [ ] Verify the font dropdown updates to show the loaded font
6. [ ] Type text — verify it renders in the loaded font

#### [ ] Load font via middle-click toolbar icon
1. [ ] Middle-click the Text tool icon in the toolbar
2. [ ] Verify file dialog opens for font selection
3. [ ] Select a font and confirm
4. [ ] Verify the custom font is loaded and active

#### [ ] Custom font persists across tool switches
1. [ ] Load a custom font
2. [ ] Switch to Brush tool, then back to text tool (Ctrl+T)
3. [ ] Verify the custom font is still selected and usable

### [ ] Font List Features
Verify the font list scan and filtering features.

#### [ ] Bundled fonts appear above system fonts
1. [ ] Open the font dropdown
2. [ ] Verify ASSETS/FONTS/ fonts appear near the top
3. [ ] Verify system fonts appear after bundled fonts

#### [ ] Built-in QB64-PE bitmap fonts available
1. [ ] Open font dropdown
2. [ ] Verify QB64-PE bitmap fonts (8x8, 8x16) appear in the list
3. [ ] Select "QB64-PE 8x16" — verify text renders in classic bitmap style

---

## [ ] COMMIT AND CANCEL

### [ ] Escape Key Behavior
Verify Escape commits text with content, or cancels (deletes) empty text layers.

#### [ ] Escape with text commits the layer
1. [ ] Start text entry, type "Hello"
2. [ ] Press Escape
3. [ ] Verify text tool returns to idle (editing stops)
4. [ ] Verify the text layer is preserved (visible in layer panel as LAYER_TYPE_TEXT)
5. [ ] Verify the text is still visible on canvas

#### [ ] Escape with empty text deletes the layer
1. [ ] Start text entry by clicking canvas (creates new layer)
2. [ ] Don't type anything
3. [ ] Press Escape
4. [ ] Verify the empty text layer is deleted from the layer panel
5. [ ] Verify no blank layer remains

#### [ ] Tool switch commits active text
1. [ ] Start text entry, type "Auto Commit"
2. [ ] Press `B` to switch to Brush tool
3. [ ] Verify text is committed (layer preserved)
4. [ ] Switch back to text tool — verify text is still there and re-editable

### [ ] Done Button
Verify the DONE button in the TEXT BAR.

#### [ ] Click DONE commits text and exits editing
1. [ ] Start text entry, type "Done Test"
2. [ ] Click the DONE button in the TEXT BAR
3. [ ] Verify text editing exits and text is committed
4. [ ] Verify cursor disappears
5. [ ] Verify text layer preserved

---

## [ ] RASTERIZE

### [ ] Rasterize Text Layer
Verify converting text layers to image layers.

#### [ ] Rasterize current text layer (Action 713)
1. [ ] Create text "Rasterize Me", commit (Esc)
2. [ ] Ensure the text layer is selected in layer panel
3. [ ] Open Layer menu → Rasterize Text Layer
4. [ ] Verify confirmation dialog appears
5. [ ] Click Yes
6. [ ] Verify layer type changes from TEXT to IMAGE in layer panel
7. [ ] Verify text is no longer editable (clicking it doesn't open text editor)
8. [ ] Verify the text pixels look the same as before rasterization

#### [ ] Rasterize all text layers (Action 714)
1. [ ] Create multiple text layers: "Text A", "Text B", "Text C"
2. [ ] Commit all (Esc after each)
3. [ ] Open Layer menu → Rasterize All Text Layers
4. [ ] Verify confirmation dialog appears
5. [ ] Click Yes
6. [ ] Verify all 3 text layers convert to IMAGE type
7. [ ] Verify no text layers remain in the layer panel

#### [ ] Cancel rasterize dialog
1. [ ] Create text, commit, select the text layer
2. [ ] Layer menu → Rasterize Text Layer
3. [ ] Click No/Cancel on the dialog
4. [ ] Verify text layer remains as LAYER_TYPE_TEXT (unchanged)

#### [ ] Rasterize while actively editing
1. [ ] Start text entry, type "Active Edit"
2. [ ] Open Layer menu → Rasterize Text Layer (or use Command Palette)
3. [ ] Confirm rasterization
4. [ ] Verify text is committed first, then rasterized to pixels
5. [ ] Verify text editing mode exits cleanly

---

## [ ] UNDO / REDO

### [ ] History Integration
Verify undo/redo interactions with text actions.

#### [ ] Undo after rasterize restores text layer
1. [ ] Create text "Undo Test", commit
2. [ ] Rasterize the text layer
3. [ ] Press Ctrl+Z (undo)
4. [ ] Verify the layer returns to TEXT type and is re-editable

#### [ ] Redo after undo restores rasterized state
1. [ ] After undoing a rasterize (previous test)
2. [ ] Press Ctrl+Y (redo)
3. [ ] Verify the layer is rasterized again (IMAGE type)

#### [ ] Text editing does not create history entries until rasterize
1. [ ] Create text, type various characters, edit
2. [ ] Commit text (Escape)
3. [ ] Press Ctrl+Z
4. [ ] Verify undo does NOT undo individual character additions
5. [ ] Text layers are non-destructive — history only applies to rasterize

---

## [ ] MOUSE INTERACTIONS — EDGE CASES

### [ ] Click Outside Text Bounds
Verify behavior when clicking outside existing text.

#### [ ] Click on empty canvas while editing starts new text
1. [ ] Start text entry at position (50,50), type "First"
2. [ ] Click on a distant empty area of canvas (e.g. 200, 150)
3. [ ] Verify the first text is committed
4. [ ] Verify a new text entry starts at the clicked position

#### [ ] Click on canvas near text boundary
1. [ ] Create text "Edge" at the very edge of the canvas
2. [ ] Click 1 pixel outside the text bounding box
3. [ ] Verify a new text entry starts (not a re-edit of "Edge")

### [ ] Drag Selection Edge Cases
Verify mouse drag selection handles various scenarios.

#### [ ] Drag past end of text
1. [ ] Type "Short"
2. [ ] Click at start, drag mouse far past the end of "Short"
3. [ ] Verify selection extends to end of text (doesn't crash or overflow)

#### [ ] Drag across multiple lines
1. [ ] Type "Line 1" + Enter + "Line 2" + Enter + "Line 3"
2. [ ] Click at "L" in "Line 1", drag down to "3" in "Line 3"
3. [ ] Verify selection spans all three lines
4. [ ] Verify the highlight covers the correct character ranges

### [ ] Space Bar Panning During Text Tool
Verify spacebar panning behavior conflicts are handled.

#### [ ] Space bar types space while editing (not pan)
1. [ ] Activate text tool, start editing text
2. [ ] Press Space bar
3. [ ] Verify a space character is inserted (NOT canvas pan)
4. [ ] Verify no inadvertent panning occurs

#### [ ] Space bar pans when text tool idle
1. [ ] Activate text tool (`T`) but don't click canvas (idle state)
2. [ ] Hold Space + drag
3. [ ] Verify canvas pans normally (text tool idle does not block panning)

---

## [ ] TEXT BAR — DROPDOWN INTERACTIONS

### [ ] Dropdown State Transitions
Verify font/size dropdowns don't conflict.

#### [ ] Opening font dropdown closes size dropdown
1. [ ] Open size dropdown (click size button)
2. [ ] Click font button
3. [ ] Verify size dropdown closes and font dropdown opens

#### [ ] Opening size dropdown closes font dropdown
1. [ ] Open font dropdown (click font button)
2. [ ] Click size button
3. [ ] Verify font dropdown closes and size dropdown opens

#### [ ] Click outside any dropdown closes it
1. [ ] Open font dropdown
2. [ ] Click on the canvas
3. [ ] Verify font dropdown closes

---

## [ ] DESIGN CONSIDERATIONS

### [ ] Multiple Zoom Levels
Verify text tool works correctly at various zoom levels.

#### [ ] Text entry at 1x zoom
1. [ ] Set zoom to 100% (Ctrl+0)
2. [ ] Activate text tool, click canvas, type "Zoom 1x"
3. [ ] Verify text renders clearly and cursor positions correctly

#### [ ] Text entry at 4x zoom
1. [ ] Zoom to 400%
2. [ ] Click canvas, type "Zoom 4x"
3. [ ] Verify text renders correctly (enlarged)
4. [ ] Verify cursor position tracks correctly at 4x magnification
5. [ ] Verify click-to-position and selection work at this zoom

#### [ ] Text entry at 8x zoom
1. [ ] Zoom to 800%
2. [ ] Click canvas, type "Zoom 8x"
3. [ ] Verify individual pixels of text glyphs are visible
4. [ ] Verify cursor and selection work correctly

#### [ ] Text entry at 25% zoom (zoomed out)
1. [ ] Zoom to 25%
2. [ ] Click canvas, type "Zoom 25"
3. [ ] Verify text placement is correct despite small rendering
4. [ ] Verify cursor appears at the correct position

### [ ] Different Canvas Sizes
Verify text tool on different canvas sizes.

#### [ ] Small canvas (16x16)
1. [ ] Create a 16x16 canvas
2. [ ] Activate text tool, click canvas
3. [ ] Type a few characters — verify overflow handling
4. [ ] Verify bottom overflow flash fires quickly

#### [ ] Medium canvas (128x128)
1. [ ] Create 128x128 canvas
2. [ ] Type text — verify word-wrap and multi-line work

#### [ ] Large canvas (320x200)
1. [ ] Create 320x200 canvas
2. [ ] Type a long paragraph — verify wrapping, lines, and scrolling

### [ ] Text on Different Layers
Verify text tool interaction with the layer system.

#### [ ] Text on layer 1 (bottom)
1. [ ] Ensure on layer 1
2. [ ] Type text — verify it appears on layer 1

#### [ ] Text on middle layer with content above/below
1. [ ] Create 3 layers, draw content on layers 1 and 3
2. [ ] Select layer 2, type text
3. [ ] Verify text appears between layer 1 and 3 content (correct stacking)

#### [ ] Text on locked layer (opacity lock)
1. [ ] Create text on a layer
2. [ ] Lock layer opacity in layer panel
3. [ ] Attempt to re-edit or create new text
4. [ ] Verify appropriate behavior (text may or may not be restricted)

### [ ] Grid Snap Interaction
Verify text placement respects grid snap settings.

#### [ ] Text start position snaps to grid when snap enabled
1. [ ] Enable grid snap (`;`)
2. [ ] Activate text tool, click on canvas
3. [ ] Verify text start position aligns to nearest grid intersection

#### [ ] Text start position is precise when snap disabled
1. [ ] Disable grid snap
2. [ ] Click at an arbitrary position
3. [ ] Verify text starts at the exact clicked pixel

---

## [ ] MIXED FORMATTING

### [ ] Per-Character Rich Formatting
Verify mixed formatting within a single text layer.

#### [ ] Multiple fonts in one layer
1. [ ] Start text entry
2. [ ] Type "A" in font A
3. [ ] Change font in TEXT BAR dropdown
4. [ ] Type "B" in font B
5. [ ] Verify both characters render in their respective fonts

#### [ ] Multiple sizes in one layer
1. [ ] Type "Big" at size 24
2. [ ] Change size to 8
3. [ ] Type "small"
4. [ ] Verify "Big" is 24px and "small" is 8px

#### [ ] Multiple colors in one layer
1. [ ] Type "Red" in red FG color
2. [ ] Change FG to blue
3. [ ] Type "Blue"
4. [ ] Verify "Red" is red and "Blue" is blue

#### [ ] Bold + Italic + Underline combination
1. [ ] Enable Bold, Italic, and Underline
2. [ ] Type "All Styles"
3. [ ] Verify text is bold, italic, and underlined simultaneously

#### [ ] Mixed line: font, size, color, style all different per-word
1. [ ] Type "Hello" in Arial 12px Bold Red
2. [ ] Type " " (space)
3. [ ] Change to Tiny5, 8px, Normal, Blue
4. [ ] Type "World"
5. [ ] Verify each segment renders with its own attributes

---

## [ ] TEXT LAYER POOL

### [ ] Pool Allocation and Limits
Verify the text layer pool manages slots correctly.

#### [ ] Create maximum text layers (up to 64)
1. [ ] Create multiple text layers one at a time (type text, commit, create new layer)
2. [ ] Continue until pool is full or layer limit is reached
3. [ ] Verify each text layer is independently re-editable

#### [ ] Delete text layer frees pool slot
1. [ ] Create a text layer, commit
2. [ ] Delete the layer (Ctrl+Shift+Delete)
3. [ ] Create a new text layer
4. [ ] Verify pool slot was freed and re-allocated

---

## [ ] FILE SAVE/LOAD

### [ ] DRW Format Preservation
Verify text layers survive save/load cycle in .draw format.

#### [ ] Save and load preserves text layers
1. [ ] Create multiple text layers with different content and formatting
2. [ ] Save as .draw file (Alt+S or File → Save)
3. [ ] Close and reopen the .draw file (Alt+O)
4. [ ] Verify all text layers load correctly
5. [ ] Verify text is re-editable (click to re-edit)
6. [ ] Verify per-character formatting (font, size, color, bold, etc.) is preserved

#### [ ] Export as image rasterizes all text
1. [ ] Create text layers
2. [ ] Export as PNG (Ctrl+S)
3. [ ] Verify the exported image contains the text as pixels
4. [ ] Verify no text layer data remains in the PNG (it's a flat image)

---

## [ ] RENDERING

### [ ] Text Preview on Canvas
Verify live text preview renders correctly while editing.

#### [ ] Live preview updates as you type
1. [ ] Start text entry
2. [ ] Type characters one at a time
3. [ ] Verify each character appears immediately on the canvas

#### [ ] Selection highlight renders correctly
1. [ ] Type "Hello World"
2. [ ] Select "World"
3. [ ] Verify highlight overlay covers exactly the selected characters
4. [ ] Verify highlight color is visible but doesn't fully obscure text

#### [ ] Cursor renders at correct position
1. [ ] Type "Test"
2. [ ] Press Home — verify cursor is at left edge of 'T'
3. [ ] Press End — verify cursor is at right edge of 't'
4. [ ] Press Left twice — verify cursor is between 'e' and 's'

#### [ ] Underline and strikethrough render at correct positions
1. [ ] Type "Underline" with underline enabled
2. [ ] Verify underline appears 1px below the text baseline
3. [ ] Type "Strike" with strikethrough enabled
4. [ ] Verify strikethrough line appears at vertical midpoint of text

---

## [ ] STATE MACHINE EDGE CASES

### [ ] State Transition Guard Conditions
Verify edge cases from the state machine diagram.

#### [ ] DRW load during active editing resets text state
1. [ ] Start editing text on canvas (type something)
2. [ ] While still editing, load a .draw file (Alt+O, select file)
3. [ ] Verify text editing is cleanly cancelled
4. [ ] Verify TEXT.ACTIVE = FALSE and TEXT BAR is reset

#### [ ] Layer delete during active editing resets text state
1. [ ] Start editing text on canvas
2. [ ] Delete the current layer (Ctrl+Shift+Delete) while editing
3. [ ] Verify text editing exits cleanly (no crash)
4. [ ] Verify tool returns to idle state

#### [ ] Rapid tool switching doesn't leave stale state
1. [ ] Activate text tool, click canvas, type "A"
2. [ ] Rapidly press: B (Brush), T (Text), B, T, B, T
3. [ ] Verify no ghost text layers or stale cursor states remain
4. [ ] Verify text typed in step 2 was committed on first switch

#### [ ] Re-enter text tool after cancel
1. [ ] Activate text tool, click canvas, type "First"
2. [ ] Press Escape to commit
3. [ ] Switch to Brush, then back to Text (T)
4. [ ] Click canvas to start new text
5. [ ] Verify clean state: no leftover cursor from "First", fresh editing

#### [ ] Empty text layer re-edit attempt
1. [ ] Start text entry (creates text layer)
2. [ ] Press Escape immediately (empty layer deleted)
3. [ ] Verify clicking where the layer was doesn't cause errors

---

## [ ] SOUND FEEDBACK

### [ ] Text Tool Sound Effects
Verify sound effects play at appropriate moments.

#### [ ] Character typing plays sound
1. [ ] Enable sound FX (Audio menu → Sound FX checked)
2. [ ] Type characters — verify a typing sound plays per character

#### [ ] Enter (newline) plays sound
1. [ ] Press Enter during text editing
2. [ ] Verify newline sound plays (different from character sound)

#### [ ] Backspace plays sound
1. [ ] Press Backspace during text editing
2. [ ] Verify a deletion sound plays

#### [ ] Overflow plays error sound
1. [ ] Type text until reaching bottom canvas boundary
2. [ ] Verify error/alert sound plays on overflow attempt
