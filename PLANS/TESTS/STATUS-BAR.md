# [ ] STATUS BAR TESTING

## [ ] VISIBILITY

### [ ] Toggle Status Bar
#### [ ] Toggle via keyboard
1. [ ] Use shortcut to toggle status bar (Ctrl+Shift+Down or via View menu)
2. [ ] Verify status bar hides
3. [ ] Toggle again — verify it returns

---

## [ ] INFORMATION DISPLAY

### [ ] Coordinate Display
#### [ ] Coordinates update on mouse move
1. [ ] Move mouse over canvas
2. [ ] Verify X,Y coordinates update in real-time
3. [ ] Verify coordinates reflect canvas pixels (not screen pixels)

### [ ] Color Swatches
#### [ ] FG swatch shows current foreground
1. [ ] Change FG color by clicking palette
2. [ ] Verify status bar FG swatch updates to new color

#### [ ] BG swatch shows current background
1. [ ] Change BG color
2. [ ] Verify status bar BG swatch updates

#### [ ] Click FG swatch opens picker
1. [ ] Click the FG color swatch in status bar
2. [ ] Verify color picker dialog opens

#### [ ] Click BG swatch opens picker
1. [ ] Click the BG color swatch
2. [ ] Verify color picker dialog opens

### [ ] Tool Information
#### [ ] Tool name updates on switch
1. [ ] Switch between tools (B, D, F, L, etc.)
2. [ ] Verify status bar shows current tool name

#### [ ] Brush size shown
1. [ ] Change brush size with `[` and `]`
2. [ ] Verify size value updates in status bar

#### [ ] Zoom percentage shown
1. [ ] Zoom in/out
2. [ ] Verify zoom percentage updates

---

## [ ] COLOR SHORTCUTS

### [ ] Swap and Reset Colors
#### [ ] X swaps FG/BG
1. [ ] Press `X`
2. [ ] Verify FG and BG swatches swap

#### [ ] Ctrl+D resets to defaults
1. [ ] Press `Ctrl+D`
2. [ ] Verify FG=white, BG=black (or default palette entry)
