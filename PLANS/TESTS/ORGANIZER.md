# [ ] ORGANIZER TESTING

## [ ] VISIBILITY

### [ ] Toggle Organizer
#### [ ] Toggle via hotkey/menu
1. [ ] Press `F4` or use View menu to toggle organizer
2. [ ] Verify organizer panel appears below toolbar
3. [ ] Verify 4×3 grid of icon buttons visible
4. [ ] Press `F4` again — verify organizer hidden
5. [ ] Verify ManuallyHidden% set when hidden via F4

---

## [ ] WIDGET INTERACTION

### [ ] Hover Highlight
#### [ ] Mouse over widget icon
1. [ ] Move mouse over an organizer widget icon
2. [ ] Verify highlight/hover state rendered
3. [ ] Verify tooltip queued after delay

### [ ] Click to Toggle
#### [ ] Click widget
1. [ ] Click an organizer widget icon
2. [ ] Verify widget state toggled
3. [ ] Verify icon updates to reflect new state

---

## [ ] GRID WIDGET

### [ ] Grid Toggle
#### [ ] Toggle grid visible/hidden
1. [ ] Click Grid widget
2. [ ] Verify grid visibility toggled on canvas
3. [ ] Verify icon shows grid-on.png or grid-off.png

---

## [ ] GRID SNAP WIDGET

### [ ] Snap Mode Cycle
#### [ ] Click cycles through modes
1. [ ] Click Grid Snap widget
2. [ ] Verify cycles: OFF → Corner → Center → OFF
3. [ ] Verify snap affects MOUSE.X/Y coordinate rounding

---

## [ ] PIXEL GRID WIDGET

### [ ] Pixel Grid Toggle
#### [ ] Toggle 1px grid
1. [ ] Click Pixel Grid widget
2. [ ] Zoom to ≥ 4x
3. [ ] Verify 1-pixel grid lines visible between pixels
4. [ ] Click again — verify pixel grid hidden

---

## [ ] CROSSHAIR WIDGET

### [ ] Crosshair Toggle
#### [ ] Toggle crosshair
1. [ ] Click Crosshair widget
2. [ ] Verify full-canvas axis lines drawn through cursor
3. [ ] Click again — verify crosshair hidden

---

## [ ] SYMMETRY WIDGET

### [ ] Symmetry Mode Cycle
#### [ ] Click cycles through symmetry modes
1. [ ] Click Symmetry widget
2. [ ] Verify cycles: OFF → Vertical → Cross → Asterisk → OFF
3. [ ] Draw with brush — verify symmetry in each mode

---

## [ ] PATTERN MODE WIDGET

### [ ] Pattern Toggle
#### [ ] Toggle pattern drawing
1. [ ] Click Pattern Mode widget
2. [ ] Verify drawing mode switches to pattern
3. [ ] Click again — verify back to solid color

---

## [ ] GRADIENT MODE WIDGET

### [ ] Gradient Toggle
#### [ ] Toggle gradient drawing
1. [ ] Click Gradient Mode widget
2. [ ] Verify drawing mode switches to gradient
3. [ ] Click again — verify back to solid color

---

## [ ] DITHER WIDGET

### [ ] Dither Toggle
#### [ ] Toggle dithered drawing
1. [ ] Click Dither widget
2. [ ] Verify dithered drawing mode active
3. [ ] Click again — verify clean drawing

---

## [ ] PREVIEW WIDGET

### [ ] Preview Toggle
#### [ ] Toggle preview window
1. [ ] Click Preview widget
2. [ ] Verify preview window appears/disappears

---

## [ ] TILE MODE WIDGET

### [ ] Tile Toggle
#### [ ] Toggle canvas tiling
1. [ ] Click Tile Mode widget
2. [ ] Verify canvas tiles for seamless pattern view
3. [ ] Click again — verify normal view

---

## [ ] REFERENCE IMAGE WIDGET

### [ ] RefImg Toggle
#### [ ] Toggle reference image overlay
1. [ ] Load a reference image
2. [ ] Click Reference Image widget
3. [ ] Verify reference image shown/hidden
