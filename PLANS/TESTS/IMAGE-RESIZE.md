# [ ] IMAGE RESIZE TESTING

## [ ] CANVAS RESIZE DIALOG

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Image → Resize
2. [ ] Verify resize dialog appears
3. [ ] Verify current width/height shown

### [ ] Set New Dimensions
#### [ ] Enter new width and height
1. [ ] Enter new width value
2. [ ] Enter new height value
3. [ ] Toggle "Maintain aspect ratio" option
4. [ ] Verify aspect ratio locks when enabled

#### [ ] Validate dimensions
1. [ ] Enter 0 — verify rejected / no resize
2. [ ] Enter negative value — verify rejected
3. [ ] Enter very large value — verify limits enforced

### [ ] Apply Resize
#### [ ] Resize canvas
1. [ ] Set valid new dimensions
2. [ ] Click OK
3. [ ] Verify all layers resized to new dimensions
4. [ ] Verify canvas content scaled
5. [ ] Verify SCRN dimensions updated
6. [ ] Verify grid redrawn for new size
7. [ ] Verify zoom recalculated

### [ ] Cancel Resize
#### [ ] Cancel without changes
1. [ ] Open resize dialog
2. [ ] Change values
3. [ ] Press Cancel / Escape
4. [ ] Verify canvas unchanged

---

## [ ] POST-RESIZE STATE

### [ ] Verify Cache Invalidation
#### [ ] Scene dirty after resize
1. [ ] Resize canvas
2. [ ] Verify SCENE_DIRTY triggered (full recomposite)
3. [ ] Verify BLEND cache invalidated
4. [ ] Verify grid redrawn

---

## [ ] UNDO / REDO

### [ ] Resize Undo
#### [ ] Undo a resize
1. [ ] Resize canvas from 64×64 to 128×128
2. [ ] Ctrl+Z — verify canvas back to 64×64
3. [ ] Ctrl+Y — verify canvas back to 128×128
