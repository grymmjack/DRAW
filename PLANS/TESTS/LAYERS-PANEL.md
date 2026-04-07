# [ ] LAYERS PANEL TESTING

## [ ] PANEL VISIBILITY

### [ ] Toggle Layers Panel
#### [ ] Toggle via View menu
1. [ ] Open View → click "Layers Panel"
2. [ ] Verify panel hides
3. [ ] Repeat to show

---

## [ ] LAYER CREATION

### [ ] Add New Layer
#### [ ] Ctrl+Shift+N creates new layer
1. [ ] Press `Ctrl+Shift+N`
2. [ ] Verify new layer appears in panel above current
3. [ ] Verify new layer is now active (highlighted)

#### [ ] Duplicate layer
1. [ ] Select a layer with content
2. [ ] Press `Ctrl+J` (or via menu)
3. [ ] Verify duplicated layer appears above original
4. [ ] Verify duplicate has identical content

---

## [ ] LAYER DELETION

### [ ] Delete Layer
#### [ ] Delete via shortcut
1. [ ] Select a non-background layer
2. [ ] Press `Ctrl+Shift+Delete`
3. [ ] Verify layer removed from panel
4. [ ] Verify adjacent layer becomes active

---

## [ ] LAYER VISIBILITY

### [ ] Toggle Layer Visibility
#### [ ] Click eye icon
1. [ ] Click the eye icon on a layer
2. [ ] Verify layer hides (eye icon changes)
3. [ ] Click eye icon again
4. [ ] Verify layer shows

#### [ ] Solo mode (Alt+Click eye)
1. [ ] Alt+Click eye icon on one layer
2. [ ] Verify all other layers hide, only clicked layer visible
3. [ ] Alt+Click same eye again
4. [ ] Verify all layers restore previous visibility

---

## [ ] LAYER REORDERING

### [ ] Drag to Reorder
#### [ ] Drag layer up
1. [ ] Create 3+ layers
2. [ ] Drag bottom layer to top position
3. [ ] Verify rendering order changes (top layer drawn last)

#### [ ] Keyboard reorder
1. [ ] Select a layer
2. [ ] Use reorder shortcut (via menu Layer → Arrange)
3. [ ] Verify layer moves up/down in stack

---

## [ ] LAYER OPACITY

### [ ] Adjust Layer Opacity
#### [ ] Set layer opacity
1. [ ] Select a layer with content
2. [ ] Adjust layer opacity slider/value
3. [ ] Verify layer content becomes semi-transparent

---

## [ ] LAYER MERGE

### [ ] Merge Layers
#### [ ] Merge down
1. [ ] Create 2 layers with content
2. [ ] Select top layer
3. [ ] Use Layer → Merge Down
4. [ ] Verify both layers merge into one

#### [ ] Flatten all
1. [ ] Create multiple layers
2. [ ] Use Layer → Flatten
3. [ ] Verify all layers collapse to one

---

## [ ] MULTI-SELECT

### [ ] Select Multiple Layers
#### [ ] Ctrl+Click to multi-select
1. [ ] Click layer 1
2. [ ] Ctrl+Click layer 3
3. [ ] Verify both layers highlighted

#### [ ] Shift+Click for range
1. [ ] Click layer 1
2. [ ] Shift+Click layer 4
3. [ ] Verify layers 1–4 all selected

#### [ ] Click to deselect
1. [ ] With multiple selected, click single layer without modifier
2. [ ] Verify only clicked layer remains selected

---

## [ ] LAYER ALIGNMENT

### [ ] Align and Distribute
#### [ ] Align center
1. [ ] Select layer(s) to align
2. [ ] Use Layer → Align → Center
3. [ ] Verify layer content centers on canvas

#### [ ] Distribute horizontal
1. [ ] Select 3+ layers
2. [ ] Use Layer → Distribute → Horizontal
3. [ ] Verify even horizontal spacing between layers
