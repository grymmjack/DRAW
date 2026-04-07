# [ ] TOOLTIPS TESTING

## [ ] TOOLTIP LIFECYCLE

### [ ] Delay Phase
#### [ ] Hover triggers delay timer
1. [ ] Move mouse over a toolbar button
2. [ ] Verify no tooltip appears immediately
3. [ ] Wait ~0.5-1.0 seconds without moving
4. [ ] Verify tooltip appears after delay threshold

### [ ] Visible Phase
#### [ ] Tooltip shows correct text
1. [ ] Hover over toolbar brush button
2. [ ] Wait for tooltip
3. [ ] Verify text shows tool name + hotkey (e.g., "Brush (B)")

#### [ ] Tooltip positioning
1. [ ] Hover near right edge of screen
2. [ ] Verify tooltip repositions to avoid overflow
3. [ ] Hover near bottom edge
4. [ ] Verify tooltip repositions upward

### [ ] Dismiss Phase
#### [ ] Move away hides tooltip
1. [ ] Show tooltip via hover
2. [ ] Move mouse away from target
3. [ ] Verify tooltip fades/disappears

#### [ ] Click dismisses tooltip
1. [ ] Show tooltip via hover
2. [ ] Click the button
3. [ ] Verify tooltip immediately disappears

---

## [ ] TOOLTIP SOURCES

### [ ] Toolbar Buttons
#### [ ] Each toolbar button has tooltip
1. [ ] Hover over each toolbar tool button
2. [ ] Verify each shows tool name + hotkey

### [ ] Organizer Widgets
#### [ ] Each organizer icon has tooltip
1. [ ] Hover over organizer widget icons
2. [ ] Verify tooltip shows widget name + state (e.g., "Grid Snap: Corner")

### [ ] Palette Colors
#### [ ] Palette cells show color info
1. [ ] Hover over palette strip colors
2. [ ] Verify tooltip shows color index + RGB hex value

### [ ] Edit Bar Buttons
#### [ ] Edit bar action tooltips
1. [ ] Show Edit Bar (F5)
2. [ ] Hover over edit bar buttons
3. [ ] Verify tooltip shows action name + hotkey (e.g., "Undo (Ctrl+Z)")

### [ ] Advanced Bar Buttons
#### [ ] Advanced bar toggle tooltips
1. [ ] Show Advanced Bar (Shift+F5)
2. [ ] Hover over advanced bar buttons
3. [ ] Verify tooltip shows toggle name + state

### [ ] Layer Panel Icons
#### [ ] Layer button tooltips
1. [ ] Hover over layer panel icons (eye, lock, etc.)
2. [ ] Verify tooltip shows button function

---

## [ ] EDGE CASES

### [ ] Rapid Mouse Movement
#### [ ] No stale tooltips
1. [ ] Quickly move mouse across multiple buttons
2. [ ] Verify no stale/orphan tooltips remain
3. [ ] Verify only the current hover target triggers tooltip

### [ ] Panel Hidden During Tooltip
#### [ ] Panel hide clears tooltip
1. [ ] Show tooltip on a panel element
2. [ ] Hide the panel (toggle visibility)
3. [ ] Verify tooltip disappears
