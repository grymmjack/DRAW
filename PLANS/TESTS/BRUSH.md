# [ ] BRUSH TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Brush Tool
Verify the brush tool can be activated from keyboard and toolbar.

#### [ ] Activate via B key
1. [ ] Ensure another tool is active (e.g. Dot)
2. [ ] Press `B`
3. [ ] Verify toolbar highlights Brush tool icon
4. [ ] Verify status bar shows "Brush"

#### [ ] Activate via toolbar click
1. [ ] Click the Brush tool icon in the toolbar
2. [ ] Verify Brush tool activates

---

## [ ] FREEHAND DRAWING

### [ ] Basic Brush Strokes
Verify brush produces continuous strokes on canvas.

#### [ ] Draw a horizontal stroke
1. [ ] Activate Brush (`B`)
2. [ ] Click and drag horizontally across canvas
3. [ ] Verify a continuous line of pixels appears
4. [ ] Release mouse button — verify stroke completes

#### [ ] Draw a diagonal stroke
1. [ ] Click and drag diagonally
2. [ ] Verify continuous pixel coverage (no gaps)

#### [ ] Single click paints a dot
1. [ ] Single click on canvas without dragging
2. [ ] Verify a single brush-sized stamp appears at click position

---

## [ ] BRUSH SIZE

### [ ] Changing Brush Size
Verify brush size controls work correctly.

#### [ ] Increase with ] key
1. [ ] Press `]` (right bracket) multiple times
2. [ ] Verify brush size increases (check status bar)
3. [ ] Draw a stroke — verify larger mark

#### [ ] Decrease with [ key
1. [ ] Press `[` (left bracket) multiple times
2. [ ] Verify brush size decreases
3. [ ] Verify minimum size of 1px

#### [ ] Brush presets F1–F4
1. [ ] Press `F1` — verify brush is preset shape 1
2. [ ] Press `F2` — verify brush is preset shape 2
3. [ ] Press `F3` — verify brush is preset shape 3
4. [ ] Press `F4` — verify brush is preset shape 4

---

## [ ] BRUSH SHAPES

### [ ] Square vs Round
Verify brush shape toggles work.

#### [ ] Toggle shape
1. [ ] Increase brush to 5+ px
2. [ ] Verify current shape (round or square)
3. [ ] Toggle brush shape (via organizer or command palette)
4. [ ] Draw a stroke — verify shape changed

---

## [ ] UNDO / REDO

### [ ] Brush Undo
Verify brush strokes are individually undoable.

#### [ ] Undo single stroke
1. [ ] Draw a brush stroke
2. [ ] Press `Ctrl+Z`
3. [ ] Verify stroke disappears completely

#### [ ] Redo undone stroke
1. [ ] After undo, press `Ctrl+Y`
2. [ ] Verify stroke reappears

#### [ ] Multiple strokes undo
1. [ ] Draw 3 separate strokes (release between each)
2. [ ] Press `Ctrl+Z` 3 times
3. [ ] Verify all 3 strokes removed in reverse order

---

## [ ] SYMMETRY MODE

### [ ] Brush with Symmetry
Verify brush paints mirrored in symmetry modes.

#### [ ] Vertical symmetry
1. [ ] Press `F7` to enable Vertical symmetry
2. [ ] Draw a stroke on one side of center
3. [ ] Verify mirrored stroke appears on opposite side

#### [ ] Cross symmetry
1. [ ] Press `F7` again (Cross mode)
2. [ ] Draw a stroke
3. [ ] Verify 4 mirrored strokes (H+V)

#### [ ] Asterisk symmetry
1. [ ] Press `F7` again (Asterisk mode)
2. [ ] Draw a stroke
3. [ ] Verify 8 mirrored strokes

#### [ ] Disable symmetry
1. [ ] Press `F7` until symmetry is Off
2. [ ] Verify single stroke output

---

## [ ] PAINT OPACITY

### [ ] Opacity Number Keys
Verify 1–9, 0 keys set paint opacity.

#### [ ] Set 50% opacity
1. [ ] Press `5`
2. [ ] Draw a stroke
3. [ ] Verify semi-transparent pixels

#### [ ] Set 100% opacity
1. [ ] Press `0`
2. [ ] Draw a stroke
3. [ ] Verify fully opaque pixels

---

## [ ] CUSTOM BRUSH

### [ ] Using Custom Brush
Verify custom brush stamps can be loaded and used.

#### [ ] Load from drawer slot
1. [ ] Open drawer (`F6`)
2. [ ] Click a populated brush slot
3. [ ] Draw a stroke
4. [ ] Verify custom brush stamp pattern appears along stroke path
