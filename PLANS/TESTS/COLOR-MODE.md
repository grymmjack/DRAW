# [ ] COLOR MODE TESTING

## [ ] FOREGROUND / BACKGROUND COLORS

### [ ] FG Color from Palette
#### [ ] Left-click palette strip
1. [ ] Left-click a color in the palette strip
2. [ ] Verify FG color (PAINT_COLOR) updated
3. [ ] Verify FG swatch in status bar updates

### [ ] BG Color from Palette
#### [ ] Right-click palette strip
1. [ ] Right-click a color in the palette strip
2. [ ] Verify BG color (PAINT_BG_COLOR) updated
3. [ ] Verify BG swatch in status bar updates

### [ ] FG from Canvas Picker
#### [ ] Left-click with picker
1. [ ] Activate Picker tool (I)
2. [ ] Left-click on canvas
3. [ ] Verify FG color set to sampled pixel

### [ ] BG from Canvas Picker
#### [ ] Right-click with picker
1. [ ] Activate Picker tool (I)
2. [ ] Right-click on canvas
3. [ ] Verify BG color set to sampled pixel

### [ ] FG from Color Dialog
#### [ ] Click FG swatch to open picker dialog
1. [ ] Click FG swatch in status bar
2. [ ] Verify palette picker dialog opens
3. [ ] Select a color — verify FG updated

---

## [ ] SWAP COLORS (X)

### [ ] Swap FG/BG
#### [ ] Press X to swap
1. [ ] Note current FG and BG colors
2. [ ] Press `X`
3. [ ] Verify FG is now old BG, BG is now old FG
4. [ ] Press `X` again — verify swapped back to original

---

## [ ] RESET COLORS (D)

### [ ] Reset to Defaults
#### [ ] Press D to reset
1. [ ] Set FG and BG to non-default colors
2. [ ] Press `D`
3. [ ] Verify FG = Black `_RGB32(0,0,0)`
4. [ ] Verify BG = White `_RGB32(255,255,255)`

---

## [ ] TRANSPARENT FG

### [ ] Transparent Eraser Mode
#### [ ] FG set to transparent
1. [ ] Set FG color to the transparent slot (if available)
2. [ ] Verify PAL_FG_IS_TRANSPARENT% = TRUE
3. [ ] Paint on canvas — verify pixels become transparent (eraser behavior)

---

## [ ] COLOR INVERT

### [ ] Invert FG Color
#### [ ] Invert current FG
1. [ ] Activate COLOR_INVERT tool (if bound)
2. [ ] Verify FG color inverted (R=255-R, etc.)
3. [ ] Toggle again — verify back to original

---

## [ ] PAINT OPACITY (1-9, 0)

### [ ] Opacity Levels
#### [ ] Set opacity via number keys
1. [ ] Press `1` — verify opacity ~10%
2. [ ] Press `5` — verify opacity ~50%
3. [ ] Press `9` — verify opacity ~90%
4. [ ] Press `0` — verify opacity 100%

#### [ ] Paint with opacity
1. [ ] Set opacity to 50% (press `5`)
2. [ ] Paint a stroke
3. [ ] Verify pixels are semi-transparent
4. [ ] Set back to 100% (press `0`) — verify fully opaque painting
