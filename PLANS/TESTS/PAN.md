# [ ] PAN TESTING

## [ ] PAN METHODS

### [ ] Pan Canvas
#### [ ] Space + drag
1. [ ] Hold `Space`
2. [ ] Click and drag on canvas
3. [ ] Verify canvas pans (scrolls) following mouse movement
4. [ ] Release `Space` and mouse
5. [ ] Verify previous tool restores

#### [ ] Middle-click drag
1. [ ] Middle-click and drag on canvas
2. [ ] Verify canvas pans

#### [ ] Scroll bars (if visible)
1. [ ] Check if horizontal/vertical scroll bars are visible
2. [ ] Drag scroll bar thumb — verify canvas scrolls

---

## [ ] PAN BOUNDARIES

### [ ] Edge Behavior
#### [ ] Pan to edges
1. [ ] Pan until canvas edge reaches work area boundary
2. [ ] Verify panning stops or allows over-scroll as expected
3. [ ] Pan back to center — verify canvas returns

---

## [ ] PAN + ZOOM INTERACTION

### [ ] Pan After Zoom
#### [ ] Zoom in then pan
1. [ ] Zoom to 400%+
2. [ ] Pan around the canvas
3. [ ] Verify smooth panning at high zoom
4. [ ] Zoom back out — verify canvas still centered correctly
