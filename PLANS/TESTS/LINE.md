# [ ] LINE TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Line Tool
#### [ ] Activate via L key
1. [ ] Press `L`
2. [ ] Verify toolbar highlights Line tool
3. [ ] Verify status bar shows "Line"

---

## [ ] DRAWING LINES

### [ ] Two-Point Line Drawing
#### [ ] Draw a basic line
1. [ ] Click on canvas (start point)
2. [ ] Move mouse — verify rubber-band preview
3. [ ] Click again (end point) — verify line committed
4. [ ] Verify line drawn between start and end points

#### [ ] Draw constrained line (Shift)
1. [ ] Click start point
2. [ ] Hold `Shift` and move mouse
3. [ ] Verify line snaps to nearest 45° angle
4. [ ] Click to commit

#### [ ] Cancel line (Escape)
1. [ ] Click start point
2. [ ] Press `Escape` before clicking end
3. [ ] Verify line preview disappears, nothing committed

#### [ ] Cancel line (Right-click)
1. [ ] Click start point
2. [ ] Right-click before clicking end
3. [ ] Verify line cancelled

---

## [ ] UNDO / REDO

### [ ] Line Undo
#### [ ] Undo a committed line
1. [ ] Draw and commit a line
2. [ ] Press `Ctrl+Z`
3. [ ] Verify line disappears

---

## [ ] SYMMETRY

### [ ] Line with Symmetry
#### [ ] Vertical symmetry
1. [ ] Enable vertical symmetry (`F7`)
2. [ ] Draw a line
3. [ ] Verify mirrored line appears
4. [ ] Disable symmetry
