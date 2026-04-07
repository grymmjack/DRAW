# [ ] DRAWER TESTING

## [ ] PANEL VISIBILITY

### [ ] Toggle Drawer
#### [ ] Toggle via F6
1. [ ] Press `F6`
2. [ ] Verify drawer panel appears (30 slots visible)
3. [ ] Press `F6` again
4. [ ] Verify drawer hides

---

## [ ] DRAWING MODES

### [ ] Mode Switching
#### [ ] F1 — Brush/Color mode
1. [ ] Press `F1`
2. [ ] Verify drawer shows brush slots

#### [ ] F2 — Gradient mode
1. [ ] Press `F2`
2. [ ] Verify drawer shows gradient slots

#### [ ] F3 — Pattern mode
1. [ ] Press `F3`
2. [ ] Verify drawer shows pattern slots

---

## [ ] SLOT OPERATIONS

### [ ] Slot Selection and Management
#### [ ] Left-click slot to select
1. [ ] Click a populated slot
2. [ ] Verify that slot becomes active (highlighted)
3. [ ] Verify drawing uses that slot's brush/pattern/gradient

#### [ ] Shift+Left-click to store
1. [ ] Hold `Shift` and click an empty slot
2. [ ] Verify current brush/pattern is stored in that slot

#### [ ] Right-click for context menu
1. [ ] Right-click a slot
2. [ ] Verify context menu appears (Edit, Copy, Paste, Clear, Import, Export)

#### [ ] Middle-click to cycle mode
1. [ ] Middle-click a slot
2. [ ] Verify drawer mode cycles

#### [ ] Shift+Middle-click to clear
1. [ ] Shift+Middle-click a populated slot
2. [ ] Verify slot is cleared

---

## [ ] DRAG REORDER

### [ ] Reorder Slots
#### [ ] Drag slot to new position
1. [ ] Click and drag a slot to a different position
2. [ ] Verify insertion marker appears during drag
3. [ ] Release — verify slot order changes

---

## [ ] MINI PALETTE

### [ ] Mini Palette Interaction
#### [ ] Left-click for FG
1. [ ] Click a color in the mini palette
2. [ ] Verify FG color changes

#### [ ] Right-click for BG
1. [ ] Right-click a color in mini palette
2. [ ] Verify BG color changes

---

## [ ] IMPORT / EXPORT

### [ ] Drawer Set Files (.dset)
#### [ ] Import dset
1. [ ] Right-click slot → Import
2. [ ] Verify file dialog opens for .dset files

#### [ ] Export dset
1. [ ] Right-click slot → Export
2. [ ] Verify file dialog opens for save
