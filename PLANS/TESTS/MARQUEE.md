# [ ] MARQUEE TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Marquee Tool
#### [ ] Activate via M key
1. [ ] Press `M`
2. [ ] Verify toolbar highlights Marquee tool

---

## [ ] SELECTION

### [ ] Drawing a Selection
#### [ ] Draw selection rectangle
1. [ ] Click and drag on canvas
2. [ ] Verify marching ants rectangle appears during drag
3. [ ] Release — verify selection persists with marching ants

#### [ ] Constrain to square (Shift)
1. [ ] Hold `Shift` while dragging
2. [ ] Verify selection constrains to 1:1 square

#### [ ] Cancel selection (Escape)
1. [ ] Draw a selection
2. [ ] Press `Escape`
3. [ ] Verify selection removed (no marching ants)

---

## [ ] SELECTION OPERATIONS

### [ ] Move Selection Content
#### [ ] Drag to move
1. [ ] Draw content, create a selection over it
2. [ ] Click inside selection and drag
3. [ ] Verify selected content moves with mouse
4. [ ] Release — verify content placed at new position

#### [ ] Copy selection (Ctrl+C, Ctrl+V)
1. [ ] Create selection over content
2. [ ] Press `Ctrl+C` to copy
3. [ ] Press `Ctrl+V` to paste
4. [ ] Verify pasted content appears as floating layer/selection

#### [ ] Cut selection (Ctrl+X)
1. [ ] Create selection over content
2. [ ] Press `Ctrl+X`
3. [ ] Verify selected area becomes transparent
4. [ ] Press `Ctrl+V` to paste — verify content returns

### [ ] Delete Selection Content
#### [ ] Delete key clears selection
1. [ ] Create selection over content
2. [ ] Press `Delete`
3. [ ] Verify selected pixels become transparent

---

## [ ] UNDO / REDO

### [ ] Marquee Undo
#### [ ] Undo move
1. [ ] Move selection content
2. [ ] Press `Ctrl+Z`
3. [ ] Verify content returns to original position

#### [ ] Undo cut
1. [ ] Cut selection
2. [ ] Press `Ctrl+Z`
3. [ ] Verify cut pixels restored
