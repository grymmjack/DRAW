# [ ] PATTERN / TILE MODE TESTING

## [ ] DRAWING MODES

### [ ] Solid Color Mode (Default)
#### [ ] Normal painting
1. [ ] Verify drawer panel shows Color bin active
2. [ ] Paint with brush — verify solid FG color

### [ ] Pattern Mode
#### [ ] Switch to pattern mode
1. [ ] Open Drawer panel (`F6`)
2. [ ] Switch to Pattern bin (`F2`)
3. [ ] Select a pattern slot
4. [ ] Verify drawing mode changes to Pattern
5. [ ] Paint with brush — verify pattern tiles into stroke

### [ ] Gradient Mode
#### [ ] Switch to gradient mode
1. [ ] Open Drawer panel (`F6`)
2. [ ] Switch to Gradient bin (`F3`)
3. [ ] Select a gradient slot
4. [ ] Verify drawing mode changes to Gradient
5. [ ] Paint with brush — verify gradient applied along stroke

### [ ] Return to Solid Color
#### [ ] Switch back to color mode
1. [ ] Switch to Brush bin (`F1`) in Drawer
2. [ ] Verify drawing mode returns to solid color
3. [ ] Paint — verify solid color again

---

## [ ] MODE SWITCHING

### [ ] Pattern ↔ Gradient
#### [ ] Switch between pattern and gradient
1. [ ] Activate Pattern mode (F2 bin)
2. [ ] Switch to Gradient mode (F3 bin)
3. [ ] Verify mode reflects gradient
4. [ ] Switch back to Pattern (F2 bin)
5. [ ] Verify mode reflects pattern

---

## [ ] FILL ADJUSTMENT (F8)

### [ ] Toggle Fill Adjustment
#### [ ] Enable/Disable F8
1. [ ] Press `F8` — verify Fill-Adj ON
2. [ ] Press `F8` again — verify Fill-Adj OFF

### [ ] Interactive Adjustment
#### [ ] Adjust after fill
1. [ ] Enable Fill-Adj (F8)
2. [ ] Perform a fill or brush stroke
3. [ ] Verify adjustment overlay appears on release
4. [ ] Drag origin point — verify tile origin shifts
5. [ ] Drag L-handle — verify independent X/Y scaling

### [ ] Commit/Cancel Adjustment
#### [ ] Apply adjustment
1. [ ] In fill adjustment mode, press Enter
2. [ ] Verify adjustment committed

#### [ ] Cancel adjustment
1. [ ] In fill adjustment mode, press Escape
2. [ ] Verify original fill state restored

---

## [ ] TILE RENDERING

### [ ] Tile Origin
#### [ ] Verify tile alignment
1. [ ] With pattern mode active, fill a region
2. [ ] Verify pattern tiles from FILL_ADJ.ORIGIN_X/Y
3. [ ] Adjust origin — verify tiles shift

### [ ] Tile Scale
#### [ ] Verify independent X/Y scale
1. [ ] Use L-handle to scale X independently
2. [ ] Verify tiles stretch horizontally
3. [ ] Scale Y independently — verify vertical stretch
