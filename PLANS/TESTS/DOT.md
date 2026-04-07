# [ ] DOT TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Dot Tool
#### [ ] Activate via D key
1. [ ] Press `D`
2. [ ] Verify toolbar highlights Dot tool
3. [ ] Verify status bar shows "Dot"

#### [ ] Activate via toolbar click
1. [ ] Click Dot tool icon in toolbar
2. [ ] Verify tool activates

---

## [ ] PIXEL PLACEMENT

### [ ] Single Pixel Drawing
#### [ ] Click to place pixel
1. [ ] Click on canvas at a specific position
2. [ ] Verify a single pixel appears at that position (1×1)
3. [ ] Verify pixel uses current foreground color

#### [ ] Drag to draw continuous dots
1. [ ] Click and drag across canvas
2. [ ] Verify continuous 1px line along drag path

#### [ ] Right-click for background color
1. [ ] Right-click on canvas
2. [ ] Verify dot placed using background color (or eraser behavior)

---

## [ ] UNDO / REDO

### [ ] Dot Undo
#### [ ] Undo single dot
1. [ ] Place a single dot
2. [ ] Press `Ctrl+Z`
3. [ ] Verify dot disappears

#### [ ] Multiple dots undo
1. [ ] Draw a series of connected dots (single drag)
2. [ ] Press `Ctrl+Z`
3. [ ] Verify entire drag stroke undone as one operation

---

## [ ] GRID SNAP

### [ ] Dot with Grid Snap
#### [ ] Enable grid snap and place dots
1. [ ] Enable grid snap (`;`)
2. [ ] Click on canvas
3. [ ] Verify dot snaps to nearest grid intersection
4. [ ] Disable grid snap (`;`)
