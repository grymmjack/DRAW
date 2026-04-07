# [ ] IMAGE IMPORT TESTING

## [ ] LOAD IMAGE

### [ ] Open File Dialog
#### [ ] Open via menu
1. [ ] Go to File → Import Image
2. [ ] Verify native file dialog opens
3. [ ] Verify supported formats listed (PNG, BMP, JPG, etc.)

#### [ ] Cancel dialog
1. [ ] Open import dialog
2. [ ] Click Cancel
3. [ ] Verify no change to canvas, tool restored

#### [ ] Load valid image
1. [ ] Select a valid image file
2. [ ] Verify image loaded (IMAGE handle valid)
3. [ ] Verify tool switches to import placement mode

---

## [ ] PLACEMENT

### [ ] Draw Marquee
#### [ ] Draw placement rectangle
1. [ ] Click and drag on canvas to define placement area
2. [ ] Verify imported image appears in marquee
3. [ ] Verify resize handles visible at corners/edges

### [ ] Resize via Handles
#### [ ] Drag corner handles
1. [ ] Drag a corner handle to resize
2. [ ] Hold Shift while dragging — verify aspect ratio locked
3. [ ] Verify imported image preview updates

#### [ ] Drag edge handles
1. [ ] Drag an edge handle
2. [ ] Verify stretching in one dimension

### [ ] Pan Within Image (Middle-Click)
#### [ ] Pan crop region
1. [ ] Middle-click and drag on imported image
2. [ ] Verify crop window shifts (panning within source image)
3. [ ] Release — verify pan offset committed

### [ ] Zoom Within Image (Scroll Wheel)
#### [ ] Zoom crop region
1. [ ] Scroll wheel up — verify zoom into source image
2. [ ] Scroll wheel down — verify zoom out
3. [ ] Verify crop window adjusts

---

## [ ] COMMIT / CANCEL

### [ ] Apply Import
#### [ ] Commit with Enter
1. [ ] Adjust placement and size
2. [ ] Press Enter
3. [ ] Verify image pasted to current layer
4. [ ] Verify history state recorded
5. [ ] Verify previous tool restored

### [ ] Cancel Import
#### [ ] Cancel with Escape
1. [ ] Start import placement
2. [ ] Press Escape
3. [ ] Verify import canceled
4. [ ] Verify no changes to canvas
5. [ ] Verify previous tool restored

---

## [ ] DRAG AND DROP

### [ ] Windows Drag & Drop
#### [ ] Drag image file onto DRAW window
1. [ ] Drag an image from file manager onto DRAW
2. [ ] Verify auto-import: same flow as File → Import

---

## [ ] UNDO / REDO

### [ ] Import Undo
#### [ ] Undo committed import
1. [ ] Import and commit an image
2. [ ] Ctrl+Z — verify imported pixels removed
3. [ ] Ctrl+Y — verify imported pixels restored
