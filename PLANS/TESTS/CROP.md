# [ ] CROP TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Crop Tool
#### [ ] Activate via toolbar or command palette
1. [ ] Open command palette (`?`), type "crop", select
2. [ ] Verify crop tool activates

---

## [ ] CROPPING

### [ ] Draw Crop Area
#### [ ] Draw crop marquee
1. [ ] Click and drag on canvas to define crop area
2. [ ] Verify crop rectangle with handles appears

#### [ ] Resize crop via handles
1. [ ] Drag corner handles to resize crop area
2. [ ] Verify crop rectangle updates in real-time

#### [ ] Nudge crop with arrows
1. [ ] Press arrow keys while crop is active
2. [ ] Verify crop rectangle moves 1px per key press

#### [ ] Apply crop (Enter)
1. [ ] Draw crop area
2. [ ] Press `Enter`
3. [ ] Verify canvas resizes to crop dimensions
4. [ ] Verify layer content trimmed to crop area

#### [ ] Cancel crop (Escape)
1. [ ] Draw crop area
2. [ ] Press `Escape`
3. [ ] Verify crop cancelled, canvas unchanged

---

## [ ] UNDO / REDO

### [ ] Crop Undo
#### [ ] Undo applied crop
1. [ ] Apply a crop
2. [ ] Press `Ctrl+Z`
3. [ ] Verify canvas restores to original size
4. [ ] Verify layer content restored
