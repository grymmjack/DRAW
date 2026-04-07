# [ ] ERASER TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Eraser
#### [ ] Activate via E key
1. [ ] Press `E`
2. [ ] Verify toolbar highlights Eraser
3. [ ] Verify status bar shows "Eraser"

#### [ ] Temporary eraser (Hold E)
1. [ ] While using another tool (e.g. Brush), hold `E`
2. [ ] Verify eraser activates temporarily
3. [ ] Release `E`
4. [ ] Verify previous tool restores

---

## [ ] ERASING

### [ ] Basic Erasing
#### [ ] Erase pixels to transparent
1. [ ] Draw some content on canvas
2. [ ] Activate Eraser (`E`)
3. [ ] Click and drag over drawn content
4. [ ] Verify pixels become transparent (checkerboard pattern visible if on transparent bg)

#### [ ] Smart Erase (Shift+drag)
1. [ ] Draw content on multiple visible layers
2. [ ] Hold `Shift` and drag with Eraser
3. [ ] Verify erasing affects all visible, non-locked layers

---

## [ ] BRUSH SIZE

### [ ] Eraser Size
#### [ ] Change eraser size
1. [ ] Press `]` to increase eraser size
2. [ ] Verify larger erasing area
3. [ ] Press `[` to decrease
4. [ ] Verify smaller erasing area

---

## [ ] UNDO / REDO

### [ ] Eraser Undo
#### [ ] Undo erase
1. [ ] Erase some pixels
2. [ ] Press `Ctrl+Z`
3. [ ] Verify erased pixels restored
