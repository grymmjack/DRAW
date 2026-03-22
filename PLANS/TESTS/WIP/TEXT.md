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

## [x] TEXT BAR — FONT CONTROLS

### [x] Font Dropdown
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

#### [x] Close font dropdown by clicking outside
1. [x] Open font dropdown
2. [x] Click somewhere outside the dropdown (on canvas or other bar area)
3. [x] Verify dropdown closes

#### [x] Font change applies to selection
1. [x] Type "Hello World"
2. [x] Select "World" (Shift+Left 5 times)
3. [x] Change font in the TEXT BAR dropdown
4. [x] Verify "World" renders in the new font while "Hello " stays in the original font

### [x] Size Dropdown
Verify font size controls work correctly.

#### [x] Open size dropdown
1. [x] Click the size number in the TEXT BAR
2. [x] Verify a dropdown with 25 preset sizes appears (4–128)
3. [x] Verify the current size is highlighted

#### [x] Select a size from dropdown
1. [x] Open size dropdown
2. [x] Click on size "24"
3. [x] Verify dropdown closes
4. [x] Type new text — verify it appears at 24px size

#### [x] Size change applies to selection
1. [x] Type "Hello World"
2. [x] Select "World"
3. [x] Change size from dropdown to a different value (e.g. 32)
4. [x] Verify "World" renders larger while "Hello " stays at the original size

#### [x] Ctrl+Shift+. increases font size
1. [x] Type "Test" — note the current size
2. [x] Select all (Ctrl+A)
3. [x] Press Ctrl+Shift+. (period / >)
4. [x] Verify text size increases to next preset size
5. [x] Press again — verify it steps to next preset

#### [x] Ctrl+Shift+, decreases font size
1. [x] Type "Test" with size 24
2. [x] Select all (Ctrl+A)
3. [x] Press Ctrl+Shift+, (comma / <)
4. [x] Verify text size decreases to next smaller preset size

---

## [x] TEXT BAR — STYLE TOGGLES

### [x] Bold
Verify bold toggle works via button click and keyboard shortcut.

#### [x] Toggle bold via Ctrl+B
1. [x] Start text entry
2. [x] Press Ctrl+B
3. [x] Verify [B] button in TEXT BAR shows active (darker background)
4. [x] Type "Bold" — verify text appears bold (or faux-bold with +1px offset)
5. [x] Press Ctrl+B again
6. [x] Verify [B] button shows inactive
7. [x] Type "Normal" — verify text appears normal weight

#### [x] Toggle bold via button click
1. [x] Click the [B] button in the TEXT BAR
2. [x] Verify it toggles active/inactive
3. [x] Type text — verify bold/normal respectively

#### [x] Apply bold to selection
1. [x] Type "Hello World"
2. [x] Select "World"
3. [x] Press Ctrl+B
4. [x] Verify "World" appears bold while "Hello " is normal

### [x] Italic
Verify italic toggle.

#### [x] Toggle italic via Ctrl+I
1. [x] Start text entry, press Ctrl+I
2. [x] Verify [I] button shows active
3. [x] Type "Italic" — verify text appears italic (if font supports it) or faux-italic
4. [x] Press Ctrl+I to toggle off

#### [x] Apply italic to selection
1. [x] Type "Hello World", select "World"
2. [x] Press Ctrl+I
3. [x] Verify "World" appears italic

### [x] Underline
Verify underline toggle.

#### [x] Toggle underline via Ctrl+U
1. [x] Start text entry, press Ctrl+U
2. [x] Verify [U] button shows active
3. [x] Type "Underline" — verify underline appears 1px below text
4. [x] Press Ctrl+U to toggle off

#### [x] Apply underline to selection
1. [x] Type "Hello World", select "World"
2. [x] Press Ctrl+U
3. [x] Verify underline appears only under "World"

### [x] Strikethrough
Verify strikethrough toggle.

#### [x] Toggle strikethrough via Ctrl+Shift+X
1. [x] Start text entry, press Ctrl+Shift+X
2. [x] Verify [S] button shows active
3. [x] Type "Strike" — verify strikethrough line at vertical midpoint
4. [x] Press Ctrl+Shift+X to toggle off

#### [x] Apply strikethrough to selection
1. [x] Type "Hello World", select "World"
2. [x] Press Ctrl+Shift+X
3. [x] Verify strikethrough appears only through "World"

### [x] Monospace Toggle
Verify monospace mode.

#### [x] Toggle monospace via TEXT BAR [M] button
1. [x] Start text entry
2. [x] Click the [M] button in TEXT BAR
3. [x] Verify it toggles active
4. [x] Type "monospace test" — verify all characters are equal width
5. [x] Click [M] again to toggle off
6. [x] Verify monospace applies to entire text layer (not per-character)

---

## [x] TEXT BAR — COLOR CONTROLS

### [x] FG Color Swatch
Verify foreground color from TEXT BAR affects text.

#### [x] FG color syncs from palette
1. [x] Start text entry
2. [x] Change FG color by clicking a swatch in the palette strip
3. [x] Verify TEXT BAR FG swatch updates to match
4. [x] Type text — verify it appears in the new FG color

#### [x] Click FG swatch opens color picker
1. [x] Start text entry
2. [x] Click the FG color swatch in the TEXT BAR
3. [x] Verify color picker dialog opens
4. [x] Select a color and confirm
5. [x] Type text — verify it appears in chosen color

#### [x] FG color applies to selection
1. [x] Type "Hello World" in red
2. [x] Select "World"
3. [x] Change FG color to blue (via palette strip click)
4. [x] Verify "World" changes to blue while "Hello " stays red

### [x] BG Color Swatch
Verify background color highlighting for text characters.

#### [x] Click BG swatch toggles transparent background
1. [x] Start text entry
2. [x] Click the BG color swatch in the TEXT BAR
3. [x] Verify it toggles between transparent (checkerboard) and the BG color
4. [x] Type text — verify background appears behind characters when BG is not transparent

---

## [x] TEXT BAR — LINE HEIGHT

### [x] Line Height Controls
Verify line height (leading) adjustment.

#### [x] Auto line height updates from largest font
1. [x] Start text entry with AUTO line-height enabled (default)
2. [x] Type text at size 12, then select some chars, change to size 24
3. [x] Verify line height auto-adjusts based on the largest font size in the layer
4. [x] Verify the line height value in TEXT BAR updates

#### [x] Manual line height via input dialog
1. [x] Click the line height value in TEXT BAR
2. [x] Verify an input dialog appears
3. [x] Enter a value (e.g. "30") and confirm
4. [x] Verify AUTO checkbox is unchecked
5. [x] Verify line spacing changes to 30px

#### [x] Toggle AUTO line height
1. [x] Click the AUTO checkbox in TEXT BAR
2. [x] Verify toggling AUTO on restores automatic line height calculation
3. [x] Verify toggling AUTO off preserves the current height value

---

## [x] TYPOGRAPHY CONTROLS

### [x] Kerning Adjustment
Verify per-character kerning via Ctrl+Alt shortcuts.

#### [x] Ctrl+Alt+. increases kerning
1. [x] Type "AV" (two characters commonly used for kerning test)
2. [x] Position cursor on 'V' (or select it)
3. [x] Press Ctrl+Alt+. (period)
4. [x] Verify spacing between A and V increases by 1px
5. [x] Press again — verify it increases further

#### [x] Ctrl+Alt+, decreases kerning
1. [x] Type "AV"
2. [x] Position cursor on 'V'
3. [x] Press Ctrl+Alt+, (comma)
4. [x] Verify spacing between A and V decreases by 1px
5. [x] Verify negative kerning (overlap) is possible

#### [x] Kerning applies to selection
1. [x] Type "HELLO"
2. [x] Select "ELL"
3. [x] Press Ctrl+Alt+. several times
4. [x] Verify kerning applies to all 3 selected characters
5. [x] Verify "H" and "O" are unaffected

### [x] Baseline Adjustment
Verify per-character baseline shift via Ctrl+Alt+Arrow.

#### [x] Ctrl+Alt+Up raises baseline
1. [x] Type "Hello"
2. [x] Position cursor on 'e' (or select it)
3. [x] Press Ctrl+Alt+Up arrow
4. [x] Verify 'e' moves up by 1px relative to other characters

#### [x] Ctrl+Alt+Down lowers baseline
1. [x] Type "Hello"
2. [x] Position cursor on 'e'
3. [x] Press Ctrl+Alt+Down arrow
4. [x] Verify 'e' moves down by 1px relative to other characters

#### [x] Baseline applies to selection
1. [x] Type "HELLO"
2. [x] Select "ELL"
3. [x] Press Ctrl+Alt+Up several times
4. [x] Verify all 3 selected characters shift up while "H" and "O" stay

---

## [x] CURSOR BEHAVIOR

### [x] Cursor Blinking
Verify cursor blink state and visual feedback.

#### [x] Cursor blinks at 0.5s interval
1. [x] Start text entry on canvas
2. [x] Observe the cursor — verify it alternates visible/hidden every ~0.5 seconds

#### [x] Cursor resets blink on key press
1. [x] Start text entry, wait for cursor to blink off
2. [x] Press any arrow key
3. [x] Verify cursor immediately becomes visible (blink reset)

#### [x] Cursor position tracks with text insertion
1. [x] Type "Hello" — cursor should be after 'o'
2. [x] Press `Home` — cursor should be before 'H'
3. [x] Type "X" — cursor should be after 'X', before 'H'
4. [x] Verify "XHello" renders correctly

---

## [x] RE-EDITING TEXT LAYERS

### [x] Single-click Re-edit
Verify clicking on a committed text layer opens it for editing.

#### [x] Single-click opens committed text for editing
1. [x] Create text: type "Test Layer", press Escape to commit
2. [x] Activate text tool again (`T`)
3. [x] Single-click on the "Test Layer" text on canvas
4. [x] Verify the text layer enters edit mode (cursor appears at click position)
5. [x] Type " More" — verify it inserts at the cursor position

#### [x] Click positions cursor at click point
1. [x] Create text "Hello World", commit (Esc)
2. [x] Re-edit by clicking between "Hello" and "World"
3. [x] Verify cursor appears at the clicked position (not at end of text)

### [x] Double-click Re-edit
Verify double-clicking also re-edits text layers.

#### [x] Double-click on text layer re-edits it
1. [x] Create text "Test", commit (Esc)
2. [x] Switch to another tool and back to text tool
3. [x] Double-click on the committed text
4. [x] Verify it enters edit mode with cursor at the double-click position

### [x] Re-edit Across Layers
Verify re-editing works when clicking text on different layers.

#### [x] Click on overlapping text layers picks topmost visible
1. [x] Create text "Layer 1" on layer 1, commit
2. [x] Create new layer, create text "Layer 2" overlapping Layer 1's position
3. [x] Commit Layer 2
4. [x] Click on the overlapping region
5. [x] Verify the topmost visible text layer (Layer 2) is re-edited

#### [x] Re-edit hidden text layer is not possible
1. [x] Create text on a layer, commit
2. [x] Hide the layer (toggle visibility in layer panel)
3. [x] Click where the text was
4. [x] Verify a new text layer is created instead of re-editing the hidden one

---

## [x] FONT LOADING

### [x] Custom Font from Disk
Verify loading TTF/OTF fonts via the TEXT BAR LOAD button.

#### [x] Load font via TEXT BAR LOAD button — N/A (LOAD button removed from TEXT BAR)
1. [x] ~~Activate text tool~~
2. [x] ~~Click the LOAD button in TEXT BAR~~
3. [x] ~~Verify file dialog opens filtered for .ttf and .otf files~~
4. [x] ~~Select a .ttf font file and confirm~~
5. [x] ~~Verify the font dropdown updates to show the loaded font~~
6. [x] ~~Type text — verify it renders in the loaded font~~

#### [x] Load font via middle-click toolbar icon
1. [x] Middle-click the Text tool icon in the toolbar
2. [x] Verify file dialog opens for font selection
3. [x] Select a font and confirm
4. [x] Verify the custom font is loaded and active

#### [x] Custom font persists across tool switches
1. [x] Load a custom font
2. [x] Switch to Brush tool, then back to text tool (Ctrl+T)
3. [x] Verify the custom font is still selected and usable

### [x] Font List Features
Verify the font list scan and filtering features.

#### [x] Bundled fonts appear above system fonts
1. [x] Open the font dropdown
2. [x] Verify ASSETS/FONTS/ fonts appear near the top
3. [x] Verify system fonts appear after bundled fonts

#### [x] Built-in QB64-PE bitmap fonts available
1. [x] Open font dropdown
2. [x] Verify QB64-PE bitmap fonts (8x8, 8x16) appear in the list
3. [x] Select "QB64-PE 8x16" — verify text renders in classic bitmap style

---

## [x] COMMIT AND CANCEL

### [x] Escape Key Behavior
Verify Escape commits text with content, or cancels (deletes) empty text layers.

#### [x] Escape with text commits the layer
1. [x] Start text entry, type "Hello"
2. [x] Press Escape
3. [x] Verify text tool returns to idle (editing stops)
4. [x] Verify the text layer is preserved (visible in layer panel as LAYER_TYPE_TEXT)
5. [x] Verify the text is still visible on canvas

#### [x] Escape with empty text deletes the layer
1. [x] Start text entry by clicking canvas (creates new layer)
2. [x] Don't type anything
3. [x] Press Escape
4. [x] Verify the empty text layer is deleted from the layer panel
5. [x] Verify no blank layer remains

#### [x] Tool switch commits active text
1. [x] Start text entry, type "Auto Commit"
2. [x] Press `B` to switch to Brush tool
3. [x] Verify text is committed (layer preserved)
4. [x] Switch back to text tool — verify text is still there and re-editable

### [x] ~~Done Button~~ N/A — DONE button removed from TEXT BAR
~~Verify the DONE button in the TEXT BAR.~~

#### [x] ~~Click DONE commits text and exits editing~~ N/A
1. [x] ~~Start text entry, type "Done Test"~~ N/A
2. [x] ~~Click the DONE button in the TEXT BAR~~ N/A
3. [x] ~~Verify text editing exits and text is committed~~ N/A
4. [x] ~~Verify cursor disappears~~ N/A
5. [x] ~~Verify text layer preserved~~ N/A

---

## [x] RASTERIZE

### [x] Rasterize Text Layer
Verify converting text layers to image layers.

#### [x] Rasterize current text layer (Action 713)
1. [x] Create text "Rasterize Me", commit (Esc)
2. [x] Ensure the text layer is selected in layer panel
3. [x] Open Layer menu → Rasterize Text Layer
4. [x] Verify confirmation dialog appears
5. [x] Click Yes
6. [x] Verify layer type changes from TEXT to IMAGE in layer panel
7. [x] Verify text is no longer editable (clicking it doesn't open text editor)
8. [x] Verify the text pixels look the same as before rasterization

#### [x] Rasterize all text layers (Action 714)
1. [x] Create multiple text layers: "Text A", "Text B", "Text C"
2. [x] Commit all (Esc after each)
3. [x] Open Layer menu → Rasterize All Text Layers
4. [x] Verify confirmation dialog appears
5. [x] Click Yes
6. [x] Verify all 3 text layers convert to IMAGE type
7. [x] Verify no text layers remain in the layer panel

#### [x] Cancel rasterize dialog
1. [x] Create text, commit, select the text layer
2. [x] Layer menu → Rasterize Text Layer
3. [x] Click No/Cancel on the dialog
4. [x] Verify text layer remains as LAYER_TYPE_TEXT (unchanged)

#### [x] Rasterize while actively editing
1. [x] Start text entry, type "Active Edit"
2. [x] Open Layer menu → Rasterize Text Layer (or use Command Palette)
3. [x] Confirm rasterization
4. [x] Verify text is committed first, then rasterized to pixels
5. [x] Verify text editing mode exits cleanly

---

## [ ] UNDO / REDO

### [x] History Integration
Verify undo/redo interactions with text actions.

#### [x] Undo after rasterize restores text layer
1. [x] Create text "Undo Test", commit
2. [x] Rasterize the text layer
3. [x] Press Ctrl+Z (undo)
4. [x] Verify the layer returns to TEXT type and is re-editable

#### [x] Redo after undo restores rasterized state
1. [x] After undoing a rasterize (previous test)
2. [x] Press Ctrl+Y (redo)
3. [x] Verify the layer is rasterized again (IMAGE type)

#### [x] Text editing does not create history entries until rasterize
1. [x] Create text, type various characters, edit
2. [x] Commit text (Escape)
3. [x] Press Ctrl+Z
4. [x] Verify undo does NOT undo individual character additions
5. [x] Text layers are non-destructive — history only applies to rasterize

---

## [x] MOUSE INTERACTIONS — EDGE CASES

### [x] Click Outside Text Bounds
Verify behavior when clicking outside existing text.

#### [x] Click on empty canvas while editing starts new text
1. [x] Start text entry at position (50,50), type "First"
2. [x] Click on a distant empty area of canvas (e.g. 200, 150)
3. [x] Verify the first text is committed
4. [x] Verify a new text entry starts at the clicked position

#### [x] Click on canvas near text boundary
1. [x] Create text "Edge" at the very edge of the canvas
2. [x] Click 1 pixel outside the text bounding box
3. [x] Verify a new text entry starts (not a re-edit of "Edge")

### [x] Drag Selection Edge Cases
Verify mouse drag selection handles various scenarios.

#### [x] Drag past end of text
1. [x] Type "Short"
2. [x] Click at start, drag mouse far past the end of "Short"
3. [x] Verify selection extends to end of text (doesn't crash or overflow)

#### [x] Drag across multiple lines
1. [x] Type "Line 1" + Enter + "Line 2" + Enter + "Line 3"
2. [x] Click at "L" in "Line 1", drag down to "3" in "Line 3"
3. [x] Verify selection spans all three lines
4. [x] Verify the highlight covers the correct character ranges

### [x] Space Bar Panning During Text Tool
Verify spacebar panning behavior conflicts are handled.

#### [x] Space bar types space while editing (not pan)
1. [x] Activate text tool, start editing text
2. [x] Press Space bar
3. [x] Verify a space character is inserted (NOT canvas pan)
4. [x] Verify no inadvertent panning occurs

#### [x] Space bar pans when text tool idle
1. [x] Activate text tool (`T`) but don't click canvas (idle state)
2. [x] Hold Space + drag
3. [x] Verify canvas pans normally (text tool idle does not block panning)

---

## [x] TEXT BAR — DROPDOWN INTERACTIONS

### [x] Dropdown State Transitions
Verify font/size dropdowns don't conflict.

#### [x] Opening font dropdown closes size dropdown
1. [x] Open size dropdown (click size button)
2. [x] Click font button
3. [x] Verify size dropdown closes and font dropdown opens

#### [x] Opening size dropdown closes font dropdown
1. [x] Open font dropdown (click font button)
2. [x] Click size button
3. [x] Verify font dropdown closes and size dropdown opens

#### [x] Click outside any dropdown closes it
1. [x] Open font dropdown
2. [x] Click on the canvas
3. [x] Verify font dropdown closes

---

## [ ] DESIGN CONSIDERATIONS

### [x] Multiple Zoom Levels
Verify text tool works correctly at various zoom levels.

#### [x] Text entry at 1x zoom
1. [x] Set zoom to 100% (Ctrl+0)
2. [x] Activate text tool, click canvas, type "Zoom 1x"
3. [x] Verify text renders clearly and cursor positions correctly

#### [x] Text entry at 4x zoom
1. [x] Zoom to 400%
2. [x] Click canvas, type "Zoom 4x"
3. [x] Verify text renders correctly (enlarged)
4. [x] Verify cursor position tracks correctly at 4x magnification
5. [x] Verify click-to-position and selection work at this zoom

#### [x] Text entry at 8x zoom
1. [x] Zoom to 800%
2. [x] Click canvas, type "Zoom 8x"
3. [x] Verify individual pixels of text glyphs are visible
4. [x] Verify cursor and selection work correctly

#### [x] Text entry at 25% zoom (zoomed out)
1. [x] Zoom to 25%
2. [x] Click canvas, type "Zoom 25"
3. [x] Verify text placement is correct despite small rendering
4. [x] Verify cursor appears at the correct position

### [x] Different Canvas Sizes
Verify text tool on different canvas sizes.

#### [x] Small canvas (16x16)
1. [x] Create a 16x16 canvas
2. [x] Activate text tool, click canvas
3. [x] Type a few characters — verify overflow handling
4. [x] Verify bottom overflow flash fires quickly

#### [x] Medium canvas (128x128)
1. [x] Create 128x128 canvas
2. [x] Type text — verify word-wrap and multi-line work

#### [x] Large canvas (320x200)
1. [x] Create 320x200 canvas
2. [x] Type a long paragraph — verify wrapping, lines, and scrolling

### [x] Text on Different Layers
Verify text tool interaction with the layer system.

#### [x] Text on layer 1 (bottom)
1. [x] Ensure on layer 1
2. [x] Type text — verify it appears on layer 1

#### [x] Text on middle layer with content above/below
1. [x] Create 3 layers, draw content on layers 1 and 3
2. [x] Select layer 2, type text
3. [x] Verify text appears between layer 1 and 3 content (correct stacking)

#### [x] Text on locked layer (opacity lock)
1. [x] Create text on a layer
2. [x] Lock layer opacity in layer panel
3. [x] Attempt to re-edit or create new text
4. [x] Verify appropriate behavior (text may or may not be restricted)

### [x] Grid Snap Interaction
Verify text placement respects grid snap settings.

#### [x] Text start position snaps to grid when snap enabled
1. [x] Enable grid snap (`;`)
2. [x] Activate text tool, click on canvas
3. [x] Verify text start position aligns to nearest grid intersection

#### [x] Text start position is precise when snap disabled
1. [x] Disable grid snap
2. [x] Click at an arbitrary position
3. [x] Verify text starts at the exact clicked pixel

---

## [x] MIXED FORMATTING

### [x] Per-Character Rich Formatting
Verify mixed formatting within a single text layer.

#### [x] Multiple fonts in one layer
1. [x] Start text entry
2. [x] Type "A" in font A
3. [x] Change font in TEXT BAR dropdown
4. [x] Type "B" in font B
5. [x] Verify both characters render in their respective fonts

#### [x] Multiple sizes in one layer
1. [x] Type "Big" at size 24
2. [x] Change size to 8
3. [x] Type "small"
4. [x] Verify "Big" is 24px and "small" is 8px

#### [x] Multiple colors in one layer
1. [x] Type "Red" in red FG color
2. [x] Change FG to blue
3. [x] Type "Blue"
4. [x] Verify "Red" is red and "Blue" is blue

#### [x] Bold + Italic + Underline combination
1. [x] Enable Bold, Italic, and Underline
2. [x] Type "All Styles"
3. [x] Verify text is bold, italic, and underlined simultaneously

#### [x] Mixed line: font, size, color, style all different per-word
1. [x] Type "Hello" in Arial 12px Bold Red
2. [x] Type " " (space)
3. [x] Change to Tiny5, 8px, Normal, Blue
4. [x] Type "World"
5. [x] Verify each segment renders with its own attributes

---

## [x] TEXT LAYER POOL

### [x] Pool Allocation and Limits
Verify the text layer pool manages slots correctly.

#### [x] Create maximum text layers (up to 64)
1. [x] Create multiple text layers one at a time (type text, commit, create new layer)
2. [x] Continue until pool is full or layer limit is reached
3. [x] Verify each text layer is independently re-editable

#### [x] Delete text layer frees pool slot
1. [x] Create a text layer, commit
2. [x] Delete the layer (Ctrl+Shift+Delete)
3. [x] Create a new text layer
4. [x] Verify pool slot was freed and re-allocated

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
