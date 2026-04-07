# [ ] PICKER TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Color Picker
#### [ ] Activate via I key
1. [ ] Press `I`
2. [ ] Verify toolbar highlights Picker tool
3. [ ] Verify picker loupe appears

#### [ ] Temporary picker (Alt+Click)
1. [ ] While using another tool, hold `Alt` and click
2. [ ] Verify FG color picks from clicked pixel
3. [ ] Release `Alt` — verify previous tool restores

---

## [ ] COLOR PICKING

### [ ] Pick Foreground Color
#### [ ] Left-click picks FG
1. [ ] Activate Picker (`I`)
2. [ ] Draw some colored content first (different colors)
3. [ ] Left-click on a colored pixel
4. [ ] Verify foreground color changes to that pixel's color
5. [ ] Check status bar FG swatch updates

#### [ ] Right-click picks BG
1. [ ] Right-click on a colored pixel
2. [ ] Verify background color changes
3. [ ] Check status bar BG swatch updates

### [ ] Pick from Different Layers
#### [ ] Pick samples from merged view
1. [ ] Create content on multiple layers
2. [ ] Pick a color — verify it samples the visible composite
3. [ ] Not just the active layer

---

## [ ] LOUPE

### [ ] Picker Loupe Magnifier
#### [ ] Loupe follows mouse
1. [ ] Move mouse over canvas with Picker active
2. [ ] Verify magnified view (loupe) follows cursor
3. [ ] Verify crosshair at loupe center

#### [ ] Loupe shows color info
1. [ ] Hover over different colors
2. [ ] Verify hex/RGB info updates in loupe overlay
