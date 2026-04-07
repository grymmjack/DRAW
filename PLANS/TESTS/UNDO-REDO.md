# [ ] UNDO / REDO TESTING

## [ ] BASIC UNDO

### [ ] Ctrl+Z Undo
#### [ ] Undo single action
1. [ ] Perform any drawing action (brush stroke, fill, etc.)
2. [ ] Press `Ctrl+Z`
3. [ ] Verify action is fully reversed

#### [ ] Undo multiple actions
1. [ ] Perform 5 distinct actions (draw, fill, draw, move, draw)
2. [ ] Press `Ctrl+Z` 5 times
3. [ ] Verify each action undone in reverse order

#### [ ] Undo to empty canvas
1. [ ] Continue pressing `Ctrl+Z` until canvas is blank
2. [ ] Verify no crash when undo stack is empty
3. [ ] Additional `Ctrl+Z` should be a no-op

---

## [ ] BASIC REDO

### [ ] Ctrl+Y Redo
#### [ ] Redo single undone action
1. [ ] Undo an action
2. [ ] Press `Ctrl+Y`
3. [ ] Verify action re-applied

#### [ ] Redo chain
1. [ ] Undo 3 actions
2. [ ] Press `Ctrl+Y` 3 times
3. [ ] Verify all 3 actions restored in original order

#### [ ] Redo invalidated by new action
1. [ ] Draw 3 strokes
2. [ ] Undo 2 strokes
3. [ ] Draw a new stroke
4. [ ] Press `Ctrl+Y`
5. [ ] Verify redo does nothing (new action cleared redo stack)

---

## [ ] TOOL-SPECIFIC UNDO

### [ ] Each Tool Records History
#### [ ] Brush undo
1. [ ] Draw brush stroke → Ctrl+Z → verify removed

#### [ ] Fill undo
1. [ ] Flood fill → Ctrl+Z → verify unfilled

#### [ ] Line undo
1. [ ] Commit line → Ctrl+Z → verify removed

#### [ ] Rectangle undo
1. [ ] Draw rect → Ctrl+Z → verify removed

#### [ ] Ellipse undo
1. [ ] Draw ellipse → Ctrl+Z → verify removed

#### [ ] Move undo
1. [ ] Move layer → Ctrl+Z → verify position restored

#### [ ] Eraser undo
1. [ ] Erase pixels → Ctrl+Z → verify pixels restored

---

## [ ] LAYER OPERATION UNDO

### [ ] Layer Changes Are Undoable
#### [ ] Undo new layer
1. [ ] Create new layer → Ctrl+Z → verify layer removed

#### [ ] Undo delete layer
1. [ ] Delete layer → Ctrl+Z → verify layer restored with content

#### [ ] Undo merge
1. [ ] Merge 2 layers → Ctrl+Z → verify layers separated

---

## [ ] IMAGE ADJUSTMENT UNDO

### [ ] Adjustments Are Undoable
#### [ ] Undo invert
1. [ ] Apply Image → Invert → Ctrl+Z → verify original colors

#### [ ] Undo desaturate
1. [ ] Apply Desaturate → Ctrl+Z → verify color restored

#### [ ] Undo brightness
1. [ ] Apply Brightness → Ctrl+Z → verify original brightness

---

## [ ] GUI CHROME INTERACTIONS

### [ ] No Ghost History from UI Clicks
#### [ ] Toolbar click does not create undo state
1. [ ] Draw a stroke (state 1)
2. [ ] Click a tool in the toolbar
3. [ ] Press `Ctrl+Z`
4. [ ] Verify brush stroke undoes (not a phantom UI state)

#### [ ] Menu click does not create undo state
1. [ ] Open and close a menu without executing
2. [ ] Press `Ctrl+Z`
3. [ ] Verify no ghost undo state
