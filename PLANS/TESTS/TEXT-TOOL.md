# [ ] TEXT TOOL TESTING

## [ ] TOOL ACTIVATION AND DEACTIVATION

### [ ] Activating the text tool from INACTIVE state
The text tool can be activated via keyboard shortcut or toolbar click. Verify all activation paths work and the TEXT_BAR becomes visible.

#### [ ] Activate via T key
1. [ ] Ensure another tool is active (e.g. Dot tool)
2. [ ] Press `T`
3. [ ] Verify the toolbar highlights the Text tool icon
4. [ ] Verify the TEXT_BAR appears below the menu bar
5. [ ] Verify no text cursor appears yet (IDLE state — not yet editing)

#### [ ] Activate via Shift+T (Tiny5 font)
1. [ ] Press `Shift+T` from another tool
2. [ ] Verify text tool activates
3. [ ] Verify Tiny5 font is selected in the TEXT_BAR font dropdown

#### [ ] Activate via Ctrl+T (custom font)
1. [ ] Press `Ctrl+T` from another tool
2. [ ] Verify text tool activates with custom font selection

#### [ ] Activate via toolbar left-click
1. [ ] Left-click the Text tool icon in the toolbar
2. [ ] Verify text tool activates with VGA font

#### [ ] Activate via toolbar right-click (Tiny5)
1. [ ] Right-click the Text tool icon in the toolbar
2. [ ] Verify Tiny5 font is selected in the TEXT_BAR

#### [ ] Activate via toolbar middle-click (load custom font)
1. [ ] Middle-click the Text tool icon in the toolbar
2. [ ] Verify a file dialog opens asking to choose a TTF/OTF font

#### [ ] Deactivate by switching to another tool
1. [ ] Activate text tool and type some text
2. [ ] Switch to Dot tool (press `D`)
3. [ ] Verify text is committed (layer remains LAYER_TYPE_TEXT, editable)
4. [ ] Verify TEXT_BAR disappears
5. [ ] Verify the text layer is visible on canvas

---

## [ ] STARTING TEXT ENTRY

### [ ] Creating a new text layer by clicking the canvas
When in IDLE state (text tool active, no editing), clicking the canvas should create a new text layer.

#### [ ] Click on empty canvas
1. [ ] Activate text tool (press `T`)
2. [ ] Click on the canvas at an arbitrary position
3. [ ] Verify a blinking cursor appears at the click position
4. [ ] Verify a new layer is created in the layers panel (type: Text)
5. [ ] Verify TEXT_BAR shows editing state (DONE button visible)

#### [ ] Click on canvas at different positions
1. [ ] Click near the top-left corner
2. [ ] Verify text cursor appears at that position
3. [ ] Press `Escape` to commit
4. [ ] Click near the center of the canvas
5. [ ] Verify a new text layer cursor appears at the center

#### [ ] Click on canvas with grid snap enabled
1. [ ] Enable grid snap (`G` or organizer)
2. [ ] Click on canvas
3. [ ] Verify the text insertion point snaps to the nearest grid intersection

---

## [ ] BASIC TEXT ENTRY

### [ ] Typing characters
Verify characters appear at the cursor position with correct formatting from the TEXT_BAR.

#### [ ] Type simple ASCII characters
1. [ ] Start a new text entry (click canvas)
2. [ ] Type "Hello World"
3. [ ] Verify each character appears on the canvas as typed
4. [ ] Verify the cursor advances to the right after each character

#### [ ] Type special characters
1. [ ] Start a new text entry
2. [ ] Type characters: `!@#$%^&*()_+-=[]{}|;':'",./<>?`
3. [ ] Verify all characters render correctly

#### [ ] Type Tab key inserts 4 spaces
1. [ ] Start a new text entry
2. [ ] Type "A"
3. [ ] Press `Tab`
4. [ ] Type "B"
5. [ ] Verify there are 4 spaces between A and B

#### [ ] Enter key creates a new line
1. [ ] Start a new text entry
2. [ ] Type "Line 1"
3. [ ] Press `Enter`
4. [ ] Type "Line 2"
5. [ ] Verify text appears on two separate lines
6. [ ] Verify cursor is on the second line

#### [ ] Backspace deletes character before cursor
1. [ ] Type "Hello"
2. [ ] Press `Backspace`
3. [ ] Verify "Hell" remains
4. [ ] Verify cursor moved back one position

#### [ ] Delete key removes character after cursor
1. [ ] Type "Hello"
2. [ ] Press `Left Arrow` twice (cursor after "Hel")
3. [ ] Press `Delete`
4. [ ] Verify "Helo" remains (second 'l' deleted)

#### [ ] Backspace at beginning of line joins with previous line
1. [ ] Type "Line 1", press `Enter`, type "Line 2"
2. [ ] Press `Home` to go to start of Line 2
3. [ ] Press `Backspace`
4. [ ] Verify "Line 1Line 2" appears on a single line

---

## [ ] CURSOR NAVIGATION

### [ ] Arrow key navigation
Test cursor movement through text using arrow keys.

#### [ ] Left arrow moves cursor one character left
1. [ ] Type "ABCDE"
2. [ ] Press `Left Arrow`
3. [ ] Verify cursor is between D and E
4. [ ] Press `Left Arrow` again
5. [ ] Verify cursor is between C and D

#### [ ] Right arrow moves cursor one character right
1. [ ] Type "ABCDE"
2. [ ] Press `Left Arrow` three times (cursor after B)
3. [ ] Press `Right Arrow`
4. [ ] Verify cursor is between C and D

#### [ ] Up arrow moves cursor to line above
1. [ ] Type "Line 1", `Enter`, "Line 2"
2. [ ] Press `Up Arrow`
3. [ ] Verify cursor moves to Line 1 at the same column position (or end of line if shorter)

#### [ ] Down arrow moves cursor to line below
1. [ ] Type "Line 1", `Enter`, "Line 2"
2. [ ] Press `Up Arrow` to go to Line 1
3. [ ] Press `Down Arrow`
4. [ ] Verify cursor returns to Line 2

#### [ ] Home key moves cursor to start of line
1. [ ] Type "Hello World"
2. [ ] Press `Home`
3. [ ] Verify cursor is at the beginning of the line (before "H")

#### [ ] End key moves cursor to end of line
1. [ ] Press `Home` first
2. [ ] Press `End`
3. [ ] Verify cursor is at the end of the line (after "d")

#### [ ] Ctrl+Left moves cursor one word left
1. [ ] Type "Hello World Test"
2. [ ] Press `Ctrl+Left`
3. [ ] Verify cursor jumps to the beginning of "Test"
4. [ ] Press `Ctrl+Left` again
5. [ ] Verify cursor jumps to the beginning of "World"

#### [ ] Ctrl+Right moves cursor one word right
1. [ ] Press `Home` to go to start
2. [ ] Press `Ctrl+Right`
3. [ ] Verify cursor jumps to the end of "Hello" (or start of "World")

#### [ ] Left arrow at beginning of line goes to end of previous line
1. [ ] Type "Line 1", `Enter`, "Line 2"
2. [ ] Go to start of Line 2 (`Home`)
3. [ ] Press `Left Arrow`
4. [ ] Verify cursor is at the end of Line 1

#### [ ] Right arrow at end of line goes to beginning of next line
1. [ ] Go to end of Line 1 (`End`)
2. [ ] Press `Right Arrow`
3. [ ] Verify cursor is at the beginning of Line 2

---

## [ ] CURSOR BLINKING

### [ ] Blink timer behavior
The cursor should blink on/off every 0.5 seconds.

#### [ ] Cursor blinks while idle
1. [ ] Start text editing (click canvas)
2. [ ] Do not type anything
3. [ ] Verify cursor blinks on and off approximately every 0.5 seconds

#### [ ] Cursor resets to visible on keypress
1. [ ] Wait for cursor to blink off
2. [ ] Press any arrow key
3. [ ] Verify cursor immediately becomes visible and starts its blink cycle fresh

---

## [ ] TEXT SELECTION

### [ ] Keyboard selection
Test selecting text using Shift+arrow key combinations.

#### [ ] Shift+Right selects one character
1. [ ] Type "Hello"
2. [ ] Press `Home`
3. [ ] Press `Shift+Right` three times
4. [ ] Verify "Hel" is highlighted/selected

#### [ ] Shift+Left extends selection left
1. [ ] Type "Hello"
2. [ ] Press `Shift+Left` twice
3. [ ] Verify "lo" is selected (from end backwards)

#### [ ] Shift+Up selects to the line above
1. [ ] Type "Line 1", `Enter`, "Line 2"
2. [ ] Position cursor at end of Line 2
3. [ ] Press `Shift+Up`
4. [ ] Verify selection extends from Line 2 cursor into Line 1

#### [ ] Shift+Down selects to the line below
1. [ ] Position cursor at beginning of Line 1
2. [ ] Press `Shift+Down`
3. [ ] Verify selection extends from Line 1 into Line 2

#### [ ] Shift+Home selects to start of line
1. [ ] Type "Hello World"
2. [ ] Press `End` to be at end
3. [ ] Press `Shift+Home`
4. [ ] Verify entire line "Hello World" is selected

#### [ ] Shift+End selects to end of line
1. [ ] Press `Home` to be at start
2. [ ] Press `Shift+End`
3. [ ] Verify entire line is selected

#### [ ] Ctrl+Shift+Left selects one word left
1. [ ] Type "Hello World Test"
2. [ ] Press `Ctrl+Shift+Left`
3. [ ] Verify "Test" is selected

#### [ ] Ctrl+Shift+Right selects one word right
1. [ ] Press `Home`
2. [ ] Press `Ctrl+Shift+Right`
3. [ ] Verify "Hello" (or "Hello ") is selected

#### [ ] Ctrl+A selects all text
1. [ ] Type several lines of text
2. [ ] Press `Ctrl+A`
3. [ ] Verify all text in the text layer is selected (highlight covers everything)

#### [ ] Typing replaces selection
1. [ ] Select some text with `Shift+Right`
2. [ ] Type "X"
3. [ ] Verify the selected text is replaced by "X"

#### [ ] Backspace deletes selection
1. [ ] Select "World" in "Hello World"
2. [ ] Press `Backspace`
3. [ ] Verify "Hello " remains (selection deleted)

#### [ ] Delete key deletes selection
1. [ ] Select some text
2. [ ] Press `Delete`
3. [ ] Verify selected text is removed

#### [ ] Plain arrow key clears selection
1. [ ] Select some text
2. [ ] Press `Right Arrow` (without Shift)
3. [ ] Verify selection is cleared and cursor is at the right edge of the former selection

### [ ] Mouse selection
Test selecting text using mouse interactions.

#### [ ] Click to position cursor
1. [ ] Type "Hello World"
2. [ ] Click between "Hello" and "World"
3. [ ] Verify cursor moves to the clicked position

#### [ ] Shift+click extends selection
1. [ ] Click at the start of text
2. [ ] Shift+click at a later position
3. [ ] Verify text between the two click positions is selected

#### [ ] Double-click selects a word
1. [ ] Type "Hello World"
2. [ ] Double-click on "World"
3. [ ] Verify "World" is selected

#### [ ] Triple-click selects a line
1. [ ] Type "Hello World"
2. [ ] Triple-click on the line
3. [ ] Verify the entire line is selected

#### [ ] Mouse drag to select range
1. [ ] Click and drag across "Hello"
2. [ ] Verify "Hello" is selected during and after the drag

---

## [ ] RICH CLIPBOARD (COPY/CUT/PASTE)

### [ ] Copy and paste preserving formatting
The internal rich clipboard preserves per-character attributes (font, size, bold, italic, colors, etc.)

#### [ ] Ctrl+C copies selected text
1. [ ] Type "Hello" in bold (Ctrl+B before typing)
2. [ ] Select all with `Ctrl+A`
3. [ ] Press `Ctrl+C`
4. [ ] Verify OS clipboard contains "Hello" (plain text)

#### [ ] Ctrl+V pastes text with rich formatting
1. [ ] After copying bold "Hello", commit text
2. [ ] Start a new text entry
3. [ ] Press `Ctrl+V`
4. [ ] Verify "Hello" is pasted with bold formatting preserved

#### [ ] Ctrl+X cuts selected text
1. [ ] Type "Hello World"
2. [ ] Select "World"
3. [ ] Press `Ctrl+X`
4. [ ] Verify "Hello " remains
5. [ ] Move cursor and press `Ctrl+V`
6. [ ] Verify "World" is pasted

#### [ ] External clipboard paste uses TEXT_BAR defaults
1. [ ] Copy text from another application to OS clipboard
2. [ ] Start text editing in DRAW
3. [ ] Set Bold in TEXT_BAR
4. [ ] Press `Ctrl+V`
5. [ ] Verify pasted text uses the current TEXT_BAR formatting (bold, current font, current size)

#### [ ] Rich paste detects external clipboard change
1. [ ] Copy "Hello" from within DRAW (Ctrl+C), getting rich clipboard
2. [ ] Copy different text from another application to OS clipboard
3. [ ] Paste in DRAW (Ctrl+V)
4. [ ] Verify the newly pasted text is from the external clipboard (not the old rich "Hello"), using TEXT_BAR defaults

---

## [ ] TEXT FORMATTING (STYLE TOGGLES)

### [ ] Bold, Italic, Underline, Strikethrough
Test per-character style toggling and the TEXT_BAR buttons.

#### [ ] Ctrl+B toggles bold
1. [ ] Start text editing
2. [ ] Press `Ctrl+B`
3. [ ] Type "Bold"
4. [ ] Press `Ctrl+B` again (toggle off)
5. [ ] Type " Normal"
6. [ ] Verify "Bold" renders in bold and " Normal" renders normal

#### [ ] Ctrl+I toggles italic
1. [ ] Press `Ctrl+I`
2. [ ] Type "Italic"
3. [ ] Press `Ctrl+I` again
4. [ ] Verify "Italic" appears in italic style

#### [ ] Ctrl+U toggles underline
1. [ ] Press `Ctrl+U`
2. [ ] Type "Underlined"
3. [ ] Verify text has an underline decoration

#### [ ] Ctrl+Shift+X toggles strikethrough
1. [ ] Press `Ctrl+Shift+X`
2. [ ] Type "Struck"
3. [ ] Verify text has a strikethrough line

#### [ ] Apply bold to existing selection
1. [ ] Type "Hello World"
2. [ ] Select "World" (Shift+click or Shift+arrows)
3. [ ] Press `Ctrl+B`
4. [ ] Verify only "World" becomes bold, "Hello " stays normal

#### [ ] Apply italic to existing selection
1. [ ] Select text
2. [ ] Press `Ctrl+I`
3. [ ] Verify selected text becomes italic

#### [ ] Apply underline to existing selection
1. [ ] Select text
2. [ ] Press `Ctrl+U`
3. [ ] Verify selected text gets underline

#### [ ] Apply strikethrough to existing selection
1. [ ] Select text
2. [ ] Press `Ctrl+Shift+X`
3. [ ] Verify selected text gets strikethrough

#### [ ] TEXT_BAR [B] button toggles bold
1. [ ] Click the [B] button in the TEXT_BAR
2. [ ] Type some text
3. [ ] Verify it appears bold
4. [ ] Click [B] again and type more
5. [ ] Verify new text is not bold

---

## [ ] FONT SELECTION

### [ ] Font dropdown in TEXT_BAR
Test changing fonts via the TEXT_BAR dropdown.

#### [ ] Open font dropdown
1. [ ] Start text editing
2. [ ] Click the font name area in the TEXT_BAR
3. [ ] Verify a dropdown list opens showing available fonts
4. [ ] Verify the dropdown can be scrolled with the mouse wheel

#### [ ] Select a different font
1. [ ] Open the font dropdown
2. [ ] Click on a different font name
3. [ ] Verify the dropdown closes
4. [ ] Type some text
5. [ ] Verify the new text renders in the selected font

#### [ ] Font dropdown shows favorites at top
1. [ ] Open the font dropdown
2. [ ] Verify favorited fonts (from DRAW_FONT_FAVORITES.txt) appear at the top

#### [ ] Font dropdown shows subfolder hierarchy
1. [ ] Open the font dropdown
2. [ ] Verify bundled fonts organized in subfolders (AMIGA, RETRO, etc.) appear as expandable sections

#### [ ] Close dropdown by clicking outside
1. [ ] Open the font dropdown
2. [ ] Click anywhere outside the dropdown
3. [ ] Verify the dropdown closes

### [ ] Font size controls
Test changing font size via the TEXT_BAR.

#### [ ] Open size dropdown
1. [ ] Click the size field in TEXT_BAR
2. [ ] Verify a dropdown of preset sizes (3–128) appears

#### [ ] Select a size from dropdown
1. [ ] Click on size "24"
2. [ ] Type some text
3. [ ] Verify text renders at 24px size

#### [ ] Ctrl+Shift+. increases font size
1. [ ] Note the current size
2. [ ] Press `Ctrl+Shift+.` (Ctrl+Shift+>)
3. [ ] Verify the size increments to the next preset value

#### [ ] Ctrl+Shift+, decreases font size
1. [ ] Press `Ctrl+Shift+,` (Ctrl+Shift+<)
2. [ ] Verify the size decrements to the previous preset value

#### [ ] Apply size change to selection
1. [ ] Type "Hello World"
2. [ ] Select "World"
3. [ ] Change font size to 32
4. [ ] Verify only "World" changes to 32px, "Hello " stays at original size

---

## [ ] KERNING AND BASELINE

### [ ] Kerning (letter spacing) adjustment
Test per-character kerning controls.

#### [ ] Ctrl+Alt+. increases kerning
1. [ ] Type "Hello"
2. [ ] Select all text
3. [ ] Press `Ctrl+Alt+.`
4. [ ] Verify letters spread apart slightly

#### [ ] Ctrl+Alt+, decreases kerning
1. [ ] Press `Ctrl+Alt+,`
2. [ ] Verify letters move closer together

### [ ] Baseline shift adjustment
Test per-character vertical baseline offset.

#### [ ] Ctrl+Alt+Up raises baseline
1. [ ] Type "Hello"
2. [ ] Select "llo"
3. [ ] Press `Ctrl+Alt+Up`
4. [ ] Verify "llo" moves visually upward relative to "He"

#### [ ] Ctrl+Alt+Down lowers baseline
1. [ ] Press `Ctrl+Alt+Down`
2. [ ] Verify selected text moves downward

---

## [ ] COLOR CONTROLS

### [ ] Foreground and background color
Test color application to text characters.

#### [ ] New characters use current PAINT_COLOR
1. [ ] Set FG color to red using the palette
2. [ ] Start text editing and type "Red"
3. [ ] Verify text renders in red

#### [ ] Change FG color mid-typing
1. [ ] Type "Red" in red
2. [ ] Change FG color to blue
3. [ ] Type "Blue"
4. [ ] Verify "Red" is red and "Blue" is blue (per-character colors)

#### [ ] BG color swatch in TEXT_BAR
1. [ ] Click the BG swatch in TEXT_BAR to toggle BG transparency
2. [ ] Type some text
3. [ ] Verify text has no background if transparent, or solid BG if opaque

#### [ ] Apply color to selection
1. [ ] Type "Hello World"
2. [ ] Select "World"
3. [ ] Change FG color to green
4. [ ] Verify "World" changes to green while "Hello " stays original color

---

## [ ] OUTLINE CONTROLS

### [ ] Text outline feature
Test per-character outline rendering controlled from TEXT_BAR row 2.

#### [ ] Toggle outline on
1. [ ] Start text editing
2. [ ] Click the outline toggle button in TEXT_BAR row 2
3. [ ] Type some text
4. [ ] Verify text renders with an outline around each character

#### [ ] Change outline color
1. [ ] Click the outline color swatch in TEXT_BAR
2. [ ] Pick a different color
3. [ ] Verify outline color changes on subsequently typed text

#### [ ] Adjust outline size
1. [ ] Use the outline size +/- buttons in TEXT_BAR
2. [ ] Verify outline thickness changes (1-10 range)

#### [ ] Apply outline to selection
1. [ ] Type text without outline
2. [ ] Select some characters
3. [ ] Enable outline
4. [ ] Verify only selected characters get outline

---

## [ ] SHADOW CONTROLS

### [ ] Text shadow feature
Test per-character shadow rendering controlled from TEXT_BAR row 2.

#### [ ] Toggle shadow on
1. [ ] Start text editing
2. [ ] Click the shadow toggle button in TEXT_BAR row 2
3. [ ] Type some text
4. [ ] Verify text renders with a shadow behind each character

#### [ ] Change shadow color
1. [ ] Click the shadow color swatch
2. [ ] Pick a color
3. [ ] Verify shadow color updates

#### [ ] Adjust shadow X offset
1. [ ] Use shadow X +/- buttons
2. [ ] Verify shadow moves horizontally (range 1-10)

#### [ ] Adjust shadow Y offset
1. [ ] Use shadow Y +/- buttons
2. [ ] Verify shadow moves vertically (range 1-10)

---

## [ ] TEXT ALIGNMENT

### [ ] Alignment modes
Test per-layer text alignment (Left, Center, Right).

#### [ ] Align Left (default)
1. [ ] Start text editing
2. [ ] Verify alignment is LEFT by default (or click [L] in TEXT_BAR)
3. [ ] Type multiple lines
4. [ ] Verify all lines are left-aligned at the insertion point

#### [ ] Align Center
1. [ ] Click [C] alignment button in TEXT_BAR
2. [ ] Type multiple lines of different lengths
3. [ ] Verify lines are centered around the insertion point

#### [ ] Align Right
1. [ ] Click [R] alignment button in TEXT_BAR
2. [ ] Type multiple lines
3. [ ] Verify lines are right-aligned to the insertion point

#### [ ] Cycle alignment L→C→R→L
1. [ ] Click alignment buttons sequentially
2. [ ] Verify the active indicator cycles through L, C, R

---

## [ ] ANTIALIAS TOGGLE

### [ ] Font antialiasing
Test the per-layer antialias toggle.

#### [ ] Toggle antialias off (crisp pixels)
1. [ ] Start text editing
2. [ ] Click [AA] button in TEXT_BAR to toggle OFF
3. [ ] Type some text with a TTF font
4. [ ] Verify text renders with crisp, non-smoothed edges

#### [ ] Toggle antialias on (smooth)
1. [ ] Click [AA] button to toggle ON
2. [ ] Verify text renders with smooth anti-aliased edges

---

## [ ] MONOSPACE MODE

### [ ] Monospace toggle [M]
Test forcing all fonts to render in monospace mode.

#### [ ] Enable monospace
1. [ ] Start text editing with a proportional font
2. [ ] Click the [M] button in TEXT_BAR
3. [ ] Type "iiiii" and "MMMMM"
4. [ ] Verify both strings occupy the same width (equal character spacing)

#### [ ] Disable monospace
1. [ ] Click [M] again to disable
2. [ ] Type "iiiii" and "MMMMM"
3. [ ] Verify proportional spacing (i's narrower than M's)

---

## [ ] LINE HEIGHT

### [ ] Line height / leading
Test line spacing controls.

#### [ ] Auto line-height (default)
1. [ ] Start text editing
2. [ ] Verify auto LH is checked
3. [ ] Type two lines with a large font
4. [ ] Verify line spacing matches font cell height

#### [ ] Manual line height
1. [ ] Disable auto line-height
2. [ ] Set line height to a specific value
3. [ ] Type multiple lines
4. [ ] Verify lines are spaced at the specified pixel distance

---

## [ ] STYLE PRESETS

### [ ] Style preset dropdown
Test saving and applying text style presets.

#### [ ] Open style preset dropdown
1. [ ] Click the [STYLE ▾] button in TEXT_BAR
2. [ ] Verify a dropdown of preset slots appears

#### [ ] Apply a style preset
1. [ ] Select a defined preset from the dropdown
2. [ ] Verify TEXT_BAR updates to the preset's font, size, bold/italic/underline/strike, colors

#### [ ] Update (capture) current style to preset
1. [ ] Set some formatting in TEXT_BAR
2. [ ] Click the [U] update button for a preset slot
3. [ ] Verify the preset captures current TEXT_BAR settings

---

## [ ] COMMITTING AND CANCELING TEXT

### [ ] Escape key behavior
Test how Escape commits or cancels text editing.

#### [ ] Escape with text commits the layer
1. [ ] Type "Hello World"
2. [ ] Press `Escape`
3. [ ] Verify text editing ends
4. [ ] Verify the text layer remains in the layers panel as LAYER_TYPE_TEXT (still editable)
5. [ ] Verify text is visible on canvas

#### [ ] Escape with empty text deletes the layer
1. [ ] Click canvas to start a new text entry (cursor appears)
2. [ ] Press `Escape` without typing anything
3. [ ] Verify the empty text layer is deleted from the layers panel
4. [ ] Verify no blank layer remains

#### [ ] DONE button in TEXT_BAR commits text
1. [ ] Type some text
2. [ ] Click the [DONE] button in TEXT_BAR
3. [ ] Verify text editing ends and layer is committed (editable)

#### [ ] Tool switch commits active text
1. [ ] Type some text
2. [ ] Press `D` to switch to Dot tool
3. [ ] Verify text is committed (layer preserved as LAYER_TYPE_TEXT)
4. [ ] Switch back to text tool and verify the text layer still exists

---

## [ ] RE-EDITING TEXT LAYERS

### [ ] Re-entering edit mode on committed text layers
Committed text layers (LAYER_TYPE_TEXT) can be re-edited by clicking or double-clicking them.

#### [ ] Click on text layer in text tool mode
1. [ ] Commit a text layer with "Hello"
2. [ ] Ensure text tool is still active (IDLE state)
3. [ ] Click on the text layer content on canvas
4. [ ] Verify editing resumes — cursor appears, TEXT_BAR shows layer formatting
5. [ ] Verify cursor position matches the click location

#### [ ] Double-click on text layer from another tool
1. [ ] Commit a text layer
2. [ ] Switch to Dot tool
3. [ ] Double-click on the text layer content
4. [ ] Verify DRAW switches to text tool and enters editing mode
5. [ ] Verify all formatting is preserved (font, size, bold, colors)

#### [ ] Re-edit preserves per-character formatting
1. [ ] Create a text layer with mixed formatting (some bold, some italic, different colors)
2. [ ] Commit with Escape
3. [ ] Re-edit by clicking the text
4. [ ] Navigate cursor through characters
5. [ ] Verify TEXT_BAR toggles update to reflect each character's formatting (TEXT_sync_bar_to_cursor)

#### [ ] Re-edit places cursor at end by default
1. [ ] Commit "Hello World"
2. [ ] Re-edit the layer
3. [ ] Verify cursor is at the end of the text
4. [ ] Verify you can immediately type more text

---

## [ ] RASTERIZING TEXT LAYERS

### [ ] Converting text to pixels — irreversible
Rasterization converts a LAYER_TYPE_TEXT layer to LAYER_TYPE_IMAGE. Text data is freed.

#### [ ] Rasterize via menu (action 713)
1. [ ] Create and commit a text layer
2. [ ] Open Layer menu → Rasterize Text Layer
3. [ ] Confirm the dialog
4. [ ] Verify the layer becomes an image layer (no longer editable as text)
5. [ ] Verify pixels look identical to the text rendering

#### [ ] Rasterize All Text Layers (action 714)
1. [ ] Create multiple text layers
2. [ ] Layer menu → Rasterize All Text Layers
3. [ ] Verify all text layers are converted to image layers

#### [ ] Rasterize records history
1. [ ] Rasterize a text layer
2. [ ] Press `Ctrl+Z`
3. [ ] Verify the rasterization is undone (layer reverts to editable text)

#### [ ] Cannot re-edit after rasterize
1. [ ] Rasterize a text layer
2. [ ] Try to double-click the layer content with text tool
3. [ ] Verify it does NOT enter text editing (it's now an image layer)

---

## [ ] TEXT-LOCAL UNDO/REDO

### [ ] Undo/redo within text editing session
While actively editing text, Ctrl+Z/Y use the text-local undo stack (not global history).

#### [ ] Ctrl+Z undoes last character
1. [ ] Type "Hello"
2. [ ] Press `Ctrl+Z`
3. [ ] Verify "Hell" remains (last character undone)

#### [ ] Multiple Ctrl+Z undoes multiple steps
1. [ ] Type "ABCDE"
2. [ ] Press `Ctrl+Z` three times
3. [ ] Verify "AB" remains

#### [ ] Ctrl+Y redoes undone changes
1. [ ] After undoing to "AB"
2. [ ] Press `Ctrl+Y`
3. [ ] Verify "ABC" is restored

#### [ ] Undo after selection delete
1. [ ] Type "Hello World"
2. [ ] Select "World" and press `Delete`
3. [ ] Press `Ctrl+Z`
4. [ ] Verify "Hello World" is restored with "World" back

#### [ ] Undo after paste
1. [ ] Type "A", copy, place cursor at end, paste "A" again
2. [ ] Press `Ctrl+Z`
3. [ ] Verify the pasted character is removed

#### [ ] Undo after style change on selection
1. [ ] Type "Hello", select all, apply bold
2. [ ] Press `Ctrl+Z`
3. [ ] Verify bold formatting is removed (text reverts to non-bold)

#### [ ] Text-local undo stack resets on commit
1. [ ] Type text, do multiple actions, verify Ctrl+Z works
2. [ ] Press Escape to commit
3. [ ] Re-edit the layer
4. [ ] Press `Ctrl+Z`
5. [ ] Verify it does NOT undo edits from the previous session (stack was reset)

---

## [ ] GLOBAL UNDO/REDO WITH TEXT

### [ ] History integration when not actively editing
When not in text editing mode, Ctrl+Z/Y use the global history system.

#### [ ] Undo rasterize restores text layer
1. [ ] Rasterize a text layer
2. [ ] Press `Ctrl+Z` (global undo)
3. [ ] Verify the layer is restored as LAYER_TYPE_TEXT, editable

#### [ ] Undo does not affect committed (non-rasterized) text layers
1. [ ] Create and commit a text layer
2. [ ] TEXT_commit does NOT create a history entry
3. [ ] Press `Ctrl+Z`
4. [ ] Verify the action before the text commit is undone, not the commit itself

---

## [ ] AUTO-WRAP AND OVERFLOW

### [ ] Text wrapping at canvas boundary
When text reaches the right edge of the canvas, it should auto-wrap.

#### [ ] Word-wrap at canvas right edge
1. [ ] Start text near the left edge with a small canvas
2. [ ] Type a long sentence
3. [ ] Verify text wraps to the next line at a word boundary when it hits the right edge

#### [ ] Character-wrap when no space found
1. [ ] Type a very long string without spaces (e.g. "AAAAAAAAA...")
2. [ ] Verify it wraps at the canvas edge even without word boundaries

#### [ ] Overflow at bottom edge
1. [ ] Type many lines until the bottom of the canvas
2. [ ] Try to type more / press Enter
3. [ ] Verify an overflow feedback occurs (flashing cursor, sound)
4. [ ] Verify no text is placed beyond the canvas bottom

---

## [ ] CHARACTER MODE (CHARMAP)

### [ ] Character Mode activation and grid cursor
Character Mode enables a text art / ANSI art workflow with a fixed-cell grid.

#### [ ] Toggle Character Mode via CHAR button
1. [ ] With text tool active and editing
2. [ ] Click [CHAR] in TEXT_BAR
3. [ ] Verify Character Mode activates
4. [ ] Verify the character map panel opens (if not already visible)

#### [ ] Toggle via Ctrl+M (charmap panel)
1. [ ] Press `Ctrl+M`
2. [ ] Verify the character map panel toggles visibility

#### [ ] Arrow keys move virtual cursor freely
1. [ ] In Character Mode, use arrow keys
2. [ ] Verify the cursor moves in a grid pattern (cell-by-cell)
3. [ ] Verify the cursor can move to cells that don't have text yet

#### [ ] Type character replaces cell content
1. [ ] Move virtual cursor to an empty cell
2. [ ] Press a character key
3. [ ] Verify the character appears at the cell position
4. [ ] Verify the cursor advances one cell to the right

#### [ ] Backspace erases current cell (replaces with space)
1. [ ] Place a character at a cell
2. [ ] Press `Backspace`
3. [ ] Verify the cell is erased (replaced with transparent space)
4. [ ] Verify the cursor moves one cell to the left

#### [ ] Delete erases character at cursor position
1. [ ] Place a character at a cell
2. [ ] Press `Delete`
3. [ ] Verify the cell is erased but cursor does NOT move

#### [ ] F-key ANSI block characters
1. [ ] In Character Mode with text tool active
2. [ ] Press `F1` — verify ░ (light shade, code 176) is placed
3. [ ] Press `F2` — verify ▒ (medium shade, code 177) is placed
4. [ ] Press `F3` — verify ▓ (dark shade, code 178) is placed
5. [ ] Press `F4` — verify █ (full block, code 219) is placed
6. [ ] Press `F5` — verify ▀ (upper half, code 223) is placed
7. [ ] Press `F6` — verify ▄ (lower half, code 220) is placed
8. [ ] Press `F7` — verify ▌ (left half, code 221) is placed
9. [ ] Press `F8` — verify ▐ (right half, code 222) is placed
10. [ ] Press `F9` — verify ■ (small square, code 254) is placed
11. [ ] Press `F10` — verify · (middle dot, code 250) is placed

#### [ ] Enter in Character Mode moves to next row
1. [ ] Press `Enter` in Character Mode
2. [ ] Verify cursor moves to column 0 of the next row

#### [ ] Charmap cell click inserts glyph
1. [ ] In Character Mode with text tool active
2. [ ] Click a glyph cell in the character map panel
3. [ ] Verify that glyph is inserted at the text cursor position on canvas

#### [ ] Character Mode selection works
1. [ ] In Character Mode, use Shift+arrow keys
2. [ ] Verify rectangular or linear selection highlights cells

#### [ ] DOT/RECT tools work on text layers in Char Mode
1. [ ] Switch to DOT tool while in Character Mode on a text layer
2. [ ] Click on the canvas
3. [ ] Verify the selected charmap glyph is placed at the clicked cell
4. [ ] Switch to RECT tool and draw a rectangle
5. [ ] Verify cells within the rectangle are filled with the selected glyph

#### [ ] Character grid overlay
1. [ ] In Character Mode
2. [ ] Verify a grid overlay appears on the canvas showing cell boundaries
3. [ ] Toggle **Grid Snap** — verify character placement snaps to grid cells

#### [ ] Color pick from character under cursor (Alt+U)
1. [ ] Place a character with a specific FG and BG color
2. [ ] Move cursor over that character
3. [ ] Press `Alt+U`
4. [ ] Verify FG and BG colors are picked up from the character

---

## [ ] TEXT_BAR UI INTERACTIONS

### [ ] Text bar visibility
Test the TEXT_BAR showing/hiding behavior.

#### [ ] TEXT_BAR appears when text tool selected
1. [ ] Switch to text tool
2. [ ] Verify TEXT_BAR row 1 and row 2 appear below the menu bar

#### [ ] TEXT_BAR disappears when switching away
1. [ ] Switch to dot tool
2. [ ] Verify TEXT_BAR is no longer visible

### [ ] Dropdown mutual exclusion
Only one dropdown should be open at a time.

#### [ ] Switching from font to size dropdown
1. [ ] Open font dropdown (click font area)
2. [ ] Click size area
3. [ ] Verify font dropdown closes and size dropdown opens

#### [ ] Switching from size to font dropdown
1. [ ] Open size dropdown
2. [ ] Click font area
3. [ ] Verify size dropdown closes and font dropdown opens

#### [ ] Scrolling in font dropdown
1. [ ] Open font dropdown
2. [ ] Scroll mouse wheel
3. [ ] Verify the font list scrolls (±3 items per wheel tick)

---

## [ ] RENDERING AND ZOOM

### [ ] Text rendering at various zoom levels
Verify text looks correct at different zoom levels.

#### [ ] 1x zoom
1. [ ] Set zoom to 1x
2. [ ] Type text
3. [ ] Verify text renders at native resolution

#### [ ] 2x zoom
1. [ ] Zoom to 2x
2. [ ] Verify text preview scales correctly
3. [ ] Verify cursor position scales with text

#### [ ] 8x zoom
1. [ ] Zoom to 8x
2. [ ] Verify individual pixels of text glyphs are visible
3. [ ] Verify cursor is still positioned correctly

#### [ ] 16x zoom
1. [ ] Zoom to 16x
2. [ ] Verify text is still rendered and cursor works
3. [ ] Verify click-to-position-cursor works at high zoom

### [ ] Different canvas sizes

#### [ ] Small canvas (16×16)
1. [ ] Set canvas to 16×16
2. [ ] Start text entry
3. [ ] Verify text clips/wraps at the tiny canvas boundaries
4. [ ] Verify overflow detection triggers early

#### [ ] Medium canvas (128×128)
1. [ ] Set canvas to 128×128
2. [ ] Type several lines
3. [ ] Verify text wraps and overflow works at this size

#### [ ] Large canvas (320×200)
1. [ ] Set canvas to 320×200
2. [ ] Type a paragraph of text
3. [ ] Verify smooth rendering with no artifacts

---

## [ ] TEXT LAYER POOL

### [ ] Pool allocation and freeing
The text layer pool supports up to 64 slots.

#### [ ] Allocate a text layer slot
1. [ ] Create a new text layer by clicking canvas
2. [ ] Verify a pool slot is allocated (TEXT_LAYER_alloc)
3. [ ] Verify the layers panel shows a new text layer

#### [ ] Free slot on empty text cancel
1. [ ] Click canvas (allocates slot)
2. [ ] Press Escape without typing
3. [ ] Verify the slot is freed and layer is deleted

#### [ ] Multiple text layers
1. [ ] Create several text layers with different content
2. [ ] Verify each has its own pool slot
3. [ ] Verify switching between layers shows correct content

#### [ ] Maximum pool slots (64)
1. [ ] Create many text layers
2. [ ] Verify a warning or limit when approaching 64 text layers

---

## [ ] LAYER INTERACTIONS

### [ ] Text layer with other layers
Test text layers interacting with the layer system.

#### [ ] Text layer visibility toggle
1. [ ] Create a text layer
2. [ ] Toggle its visibility in the layers panel
3. [ ] Verify text disappears from canvas when hidden

#### [ ] Text layer opacity
1. [ ] Create a text layer
2. [ ] Adjust opacity in the layers panel
3. [ ] Verify text renders semi-transparently

#### [ ] Text layer reorder
1. [ ] Create a text layer and an image layer
2. [ ] Reorder them in the layers panel
3. [ ] Verify z-order changes on canvas

#### [ ] Delete text layer from panel
1. [ ] While NOT editing the text layer, delete it from the layers panel
2. [ ] Verify the text layer and its pool slot are cleaned up
3. [ ] Verify no crash or stale state

#### [ ] Delete currently-editing text layer
1. [ ] While actively editing a text layer (cursor blinking)
2. [ ] Delete the layer from the layers panel
3. [ ] Verify text editing is force-cancelled
4. [ ] Verify TEXT.ACTIVE resets to FALSE
5. [ ] Verify TEXT_BAR.editingLayerIdx resets

---

## [ ] DRW FILE SAVE/LOAD

### [ ] Text layers survive save and load
Text layer data should be preserved in the DRW binary format.

#### [ ] Save DRW with text layers
1. [ ] Create a text layer with mixed formatting
2. [ ] Save the project as DRW
3. [ ] Verify no errors during save

#### [ ] Load DRW preserves text layers
1. [ ] Close and reload the saved DRW file
2. [ ] Verify text layers appear correctly
3. [ ] Verify re-editing works (double-click to edit)
4. [ ] Verify all per-character formatting is preserved (font, size, bold, italic, colors, outline, shadow)

#### [ ] Load DRW resets text tool state
1. [ ] Start editing a text layer
2. [ ] Load a different DRW file
3. [ ] Verify all text tool state is reset (TEXT.ACTIVE = FALSE, editingTextLayer = 0)
4. [ ] Verify TEXT_BAR resets properly

---

## [ ] EDGE CASES AND ERROR HANDLING

### [ ] State machine edge cases from the diagram

#### [ ] Rapid clicks on canvas in text tool mode
1. [ ] Click rapidly on different parts of the canvas
2. [ ] Verify each click commits the previous text layer (if any) and starts a new one
3. [ ] Verify no duplicate or orphaned layers

#### [ ] Click on canvas, click on same text layer immediately
1. [ ] Click canvas to start text, type "A"
2. [ ] Click on the same text at a different cursor position
3. [ ] Verify the cursor moves (does NOT create a new layer — stays in editing state 3→3)

#### [ ] Switch tool during text editing and switch back
1. [ ] Start text editing
2. [ ] Switch to another tool (text committed)
3. [ ] Switch back to text tool
4. [ ] Verify in IDLE state (TEXT_BAR visible, no cursor)
5. [ ] Click canvas to start new text entry

#### [ ] Max character limit (TEXT_LAYER_MAX_CHARS = 4096)
1. [ ] Type or paste a very long string (close to 4096 characters)
2. [ ] Verify text stops accepting input gracefully at the limit
3. [ ] Verify no crash or data corruption

#### [ ] Max line limit (TEXT_LAYER_MAX_LINES = 256)
1. [ ] Create very many lines (near 256)
2. [ ] Verify the system handles the limit gracefully

---

## [ ] SYMMETRY AND GRID INTERACTION

### [ ] Text tool with symmetry active
Verify text tool behavior when symmetry modes are enabled.

#### [ ] Horizontal symmetry
1. [ ] Enable horizontal symmetry
2. [ ] Type text
3. [ ] Verify text behavior (text may not reflect — this tests that symmetry doesn't break text tool)

#### [ ] Grid snap with text tool
1. [ ] Enable grid snap
2. [ ] Click canvas to start text
3. [ ] Verify insertion point snaps to grid
4. [ ] Type text — verify characters still appear correctly

---

## [ ] STATUS BAR UPDATES

### [ ] Status bar reflects text tool state

#### [ ] Status bar shows text tool info
1. [ ] Activate text tool
2. [ ] Verify status bar shows text-tool-specific information
3. [ ] Start editing
4. [ ] Verify status bar updates to show cursor position / editing state

---

## [ ] UNICODE AND BITMAP FONTS

### [ ] Bitmap font rendering in text tool

#### [ ] Select a bitmap font (F?? / PSF / BDF)
1. [ ] Open font dropdown
2. [ ] Select a bitmap font
3. [ ] Type some text
4. [ ] Verify bitmap glyphs render at their native size

#### [ ] Unicode mode in charmap
1. [ ] With a Unicode-capable TTF font selected
2. [ ] Toggle Unicode mode in the charmap panel
3. [ ] Verify Unicode codepoints appear in the grid
4. [ ] Click to insert a Unicode glyph
5. [ ] Verify the glyph appears correctly in the text layer
