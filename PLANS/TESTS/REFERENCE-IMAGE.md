# [ ] REFERENCE IMAGE TESTING

## [ ] LOADING

### [ ] Load Reference Image
#### [ ] Load via menu
1. [ ] Go to View → Ref Image → Load
2. [ ] Verify native file dialog opens
3. [ ] Select a valid image file
4. [ ] Verify image loaded (but hidden by default)

### [ ] Load with No File Selected
#### [ ] Cancel dialog
1. [ ] Open load dialog
2. [ ] Click Cancel
3. [ ] Verify no reference image loaded

---

## [ ] VISIBILITY TOGGLE (Ctrl+R)

### [ ] Toggle Visible
#### [ ] Show/hide with Ctrl+R
1. [ ] Load a reference image
2. [ ] Press `Ctrl+R` — verify reference image appears on canvas
3. [ ] Verify it renders BEFORE grid and layers (behind artwork)
4. [ ] Press `Ctrl+R` again — verify reference image hidden
5. [ ] Verify image still in memory (not unloaded)

### [ ] Toggle Without Image
#### [ ] Ctrl+R with no image loaded
1. [ ] Ensure no reference image loaded
2. [ ] Press `Ctrl+R` — verify no-op / no crash

---

## [ ] OPACITY CONTROL

### [ ] Adjust Opacity
#### [ ] Ctrl+Shift+Wheel
1. [ ] Show reference image
2. [ ] `Ctrl+Shift+Wheel Up` — verify opacity increases (step 5%)
3. [ ] `Ctrl+Shift+Wheel Down` — verify opacity decreases (step 5%)
4. [ ] Increase to 100% — verify fully opaque
5. [ ] Decrease to minimum (~5%) — verify barely visible

---

## [ ] REPOSITION MODE

### [ ] Enter Reposition Mode
#### [ ] Activate via menu
1. [ ] Go to View → Ref Image → Reposition
2. [ ] Verify modal drag mode activated
3. [ ] Verify cursor changes

### [ ] Drag to Reposition
#### [ ] Move reference image
1. [ ] In reposition mode, click and drag
2. [ ] Verify reference image position follows mouse
3. [ ] Release — verify position updated

### [ ] Exit Reposition
#### [ ] Cancel with Escape
1. [ ] In reposition mode, press Escape
2. [ ] Verify reposition mode deactivated
3. [ ] Verify previous tool restored

---

## [ ] CLEAR REFERENCE IMAGE

### [ ] Unload Image
#### [ ] Clear via menu
1. [ ] With reference image loaded
2. [ ] Go to View → Ref Image → Clear
3. [ ] Verify reference image freed
4. [ ] Verify no reference overlay rendered

---

## [ ] COLOR SAMPLING

### [ ] Sample from Ref Image
#### [ ] Use picker on reference image area
1. [ ] Show reference image
2. [ ] Activate Picker tool (I)
3. [ ] Click on a reference image pixel
4. [ ] Verify color sampled from reference image

---

## [ ] PERSISTENCE

### [ ] DRW Save/Load (v4+)
#### [ ] Reference image persists in DRW file
1. [ ] Load a reference image with specific position and opacity
2. [ ] Save DRW file
3. [ ] Reload DRW file
4. [ ] Verify reference image filename, position, scale, opacity restored
