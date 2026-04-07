# [ ] FILL TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Fill Tool
#### [ ] Activate via F key
1. [ ] Press `F`
2. [ ] Verify toolbar highlights Fill tool
3. [ ] Verify status bar shows "Fill"

---

## [ ] FLOOD FILL

### [ ] Basic Flood Fill
#### [ ] Fill an empty region
1. [ ] Draw a closed shape (e.g. rectangle with Brush)
2. [ ] Switch to Fill (`F`)
3. [ ] Click inside the shape
4. [ ] Verify region fills with foreground color
5. [ ] Verify fill stops at shape boundaries

#### [ ] Fill with background color (right-click)
1. [ ] Right-click inside a region
2. [ ] Verify fill uses background color

#### [ ] Fill on already-filled region
1. [ ] Fill a region with one color
2. [ ] Change foreground color
3. [ ] Fill the same region again
4. [ ] Verify entire region changes to new color

---

## [ ] FILL MODES

### [ ] Pattern and Gradient Fill
#### [ ] Fill with pattern
1. [ ] Open drawer (`F6`), switch to Pattern mode (`F3`)
2. [ ] Select a pattern slot
3. [ ] Use Fill tool on canvas
4. [ ] Verify region fills with tiled pattern

#### [ ] Fill with gradient
1. [ ] Switch to Gradient mode (`F2`)
2. [ ] Select a gradient slot
3. [ ] Fill a region
4. [ ] Verify gradient fill between FG and BG colors

---

## [ ] UNDO / REDO

### [ ] Fill Undo
#### [ ] Undo fill
1. [ ] Flood fill a region
2. [ ] Press `Ctrl+Z`
3. [ ] Verify fill removed, original pixels restored

---

## [ ] EDIT MENU FILL

### [ ] Fill FG / Fill BG shortcuts
#### [ ] Ctrl+Backspace fills with FG
1. [ ] Draw some content
2. [ ] Press `Ctrl+Backspace`
3. [ ] Verify entire layer fills with foreground color

#### [ ] Ctrl+Delete fills with BG
1. [ ] Press `Ctrl+Delete`
2. [ ] Verify entire layer fills with background color
