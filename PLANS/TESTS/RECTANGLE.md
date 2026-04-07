# [ ] RECTANGLE TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Rectangle Tool
#### [ ] Activate outlined via R key
1. [ ] Press `R`
2. [ ] Verify toolbar highlights Rectangle tool
3. [ ] Verify status bar shows "Rect"

#### [ ] Activate filled via Shift+R
1. [ ] Press `Shift+R`
2. [ ] Verify filled rectangle mode active

---

## [ ] DRAWING RECTANGLES

### [ ] Basic Rectangle Drawing
#### [ ] Draw outlined rectangle
1. [ ] Press `R` for outlined mode
2. [ ] Click and drag to define rectangle corners
3. [ ] Verify rubber-band preview during drag
4. [ ] Release — verify outlined rectangle committed

#### [ ] Draw filled rectangle
1. [ ] Press `Shift+R` for filled mode
2. [ ] Click and drag
3. [ ] Release — verify solid filled rectangle

#### [ ] Draw square (Shift constraint)
1. [ ] Press `R`, click and start dragging
2. [ ] Hold `Shift` while dragging
3. [ ] Verify rectangle constrains to square (1:1 aspect)

#### [ ] Cancel rectangle (Escape)
1. [ ] Start drawing rectangle
2. [ ] Press `Escape`
3. [ ] Verify preview disappears, nothing committed

---

## [ ] UNDO / REDO

### [ ] Rectangle Undo
#### [ ] Undo rectangle
1. [ ] Draw a rectangle
2. [ ] Press `Ctrl+Z`
3. [ ] Verify rectangle disappears

---

## [ ] SYMMETRY

### [ ] Rectangle with Symmetry
#### [ ] Draw with vertical symmetry
1. [ ] Enable symmetry (`F7`)
2. [ ] Draw a rectangle
3. [ ] Verify mirrored rectangle appears
4. [ ] Disable symmetry
