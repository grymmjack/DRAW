# [ ] MOVE TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Move Tool
#### [ ] Activate via V key
1. [ ] Press `V`
2. [ ] Verify toolbar highlights Move tool
3. [ ] Verify cursor changes to move arrows

---

## [ ] LAYER MOVEMENT

### [ ] Drag to Move
#### [ ] Move layer content
1. [ ] Draw content on current layer
2. [ ] Activate Move (`V`)
3. [ ] Click and drag on canvas
4. [ ] Verify layer content follows mouse
5. [ ] Release — verify content placed at new position

#### [ ] Cancel move (Escape)
1. [ ] Start dragging layer content
2. [ ] Press `Escape` mid-drag
3. [ ] Verify content returns to original position

---

## [ ] NUDGE

### [ ] Arrow Key Nudge
#### [ ] Nudge right
1. [ ] Activate Move, draw content
2. [ ] Press `Right Arrow`
3. [ ] Verify content shifts 1px right

#### [ ] Nudge left
1. [ ] Press `Left Arrow`
2. [ ] Verify content shifts 1px left

#### [ ] Nudge up
1. [ ] Press `Up Arrow`
2. [ ] Verify content shifts 1px up

#### [ ] Nudge down
1. [ ] Press `Down Arrow`
2. [ ] Verify content shifts 1px down

#### [ ] Multiple nudges accumulate
1. [ ] Press `Right` 5 times
2. [ ] Verify content moved 5px right total

---

## [ ] MULTI-LAYER MOVE

### [ ] Linked Layer Move
#### [ ] Move multiple selected layers
1. [ ] Create 2+ layers with content
2. [ ] Select multiple layers (Ctrl+Click in layer panel)
3. [ ] Drag with Move tool
4. [ ] Verify all selected layers move together

---

## [ ] UNDO / REDO

### [ ] Move Undo
#### [ ] Undo drag move
1. [ ] Drag-move layer content
2. [ ] Press `Ctrl+Z`
3. [ ] Verify content returns to original position

#### [ ] Undo nudge
1. [ ] Nudge content with arrow keys
2. [ ] Press `Ctrl+Z`
3. [ ] Verify nudge reversed

#### [ ] Redo move
1. [ ] After undo, press `Ctrl+Y`
2. [ ] Verify move re-applied
