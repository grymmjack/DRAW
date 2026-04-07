# [ ] KEYBOARD SHORTCUTS TESTING

## [ ] TOOL SELECTION KEYS

### [ ] Tool Activation
#### [ ] Single-key tool selection
1. [ ] Press `B` — verify Brush tool activates
2. [ ] Press `D` — verify Dot tool activates
3. [ ] Press `F` — verify Fill tool activates
4. [ ] Press `I` — verify Picker tool activates
5. [ ] Press `K` — verify Spray tool activates
6. [ ] Press `L` — verify Line tool activates
7. [ ] Press `P` — verify Polygon tool activates
8. [ ] Press `R` — verify Rectangle tool activates
9. [ ] Press `C` — verify Ellipse tool activates
10. [ ] Press `E` — verify Eraser tool activates
11. [ ] Press `M` — verify Marquee tool activates
12. [ ] Press `W` — verify Magic Wand tool activates
13. [ ] Press `V` — verify Move tool activates
14. [ ] Press `Z` — verify Zoom tool activates
15. [ ] Press `T` — verify Text tool activates

#### [ ] Shift+key tool variants
1. [ ] Press `Shift+P` — verify Filled Polygon activates
2. [ ] Press `Shift+R` — verify Filled Rectangle activates
3. [ ] Press `Shift+C` — verify Filled Ellipse activates

#### [ ] Hold E for temporary eraser
1. [ ] Hold `E` — verify eraser active
2. [ ] Release `E` — verify previous tool restored

---

## [ ] PAINT OPACITY KEYS

### [ ] Number Keys
#### [ ] Opacity levels 1-9 and 0
1. [ ] Press `1` — verify ~10% opacity
2. [ ] Press `5` — verify ~50% opacity
3. [ ] Press `9` — verify ~90% opacity
4. [ ] Press `0` — verify 100% opacity

---

## [ ] COLOR KEYS

### [ ] Color Control
#### [ ] Swap and reset
1. [ ] Press `X` — verify FG/BG colors swapped
2. [ ] Press `Ctrl+D` — verify FG → white, BG → black, selection deselected
3. [ ] Press `Shift+Delete` — verify BG set to transparent

---

## [ ] BRUSH KEYS

### [ ] Brush Size
#### [ ] Increase/decrease
1. [ ] Press `]` or `}` — verify brush size increased
2. [ ] Press `[` or `{` — verify brush size decreased

### [ ] Brush Toggle
#### [ ] Preview and shape
1. [ ] Press `` ` `` or `~` — verify brush preview toggled
2. [ ] Press `\` or `|` — verify brush shape toggled (circle/square)
3. [ ] Press `F6` — verify pixel perfect mode toggled

---

## [ ] CUSTOM BRUSH KEYS

### [ ] Custom Brush Controls
#### [ ] All custom brush hotkeys
1. [ ] `Ctrl+B` — capture/clear custom brush
2. [ ] `F9` — toggle recolor mode
3. [ ] `Shift+O` — apply outline
4. [ ] `Home` — flip horizontal
5. [ ] `End` — flip vertical
6. [ ] `PgUp` — scale up
7. [ ] `PgDn` — scale down
8. [ ] `/` — reset scale

---

## [ ] GRID KEYS

### [ ] Grid Controls
#### [ ] Grid hotkeys
1. [ ] `'` (apostrophe) — toggle grid visibility
2. [ ] `Shift+'` — toggle pixel grid
3. [ ] `;` — toggle snap-to-grid
4. [ ] `.` — increase grid size
5. [ ] `,` — decrease grid size
6. [ ] `Ctrl+'` — cycle grid geometry mode

---

## [ ] SYMMETRY KEYS

### [ ] Symmetry Controls
#### [ ] Symmetry hotkeys
1. [ ] `F7` — cycle symmetry mode (Off → Vertical → Cross → Asterisk → Off)
2. [ ] `F8` — fill adjustment mode (or turn off symmetry)

---

## [ ] VIEW KEYS

### [ ] Panel Visibility
#### [ ] Toggle hotkeys
1. [ ] `Tab` — toggle toolbar
2. [ ] `Ctrl+L` — toggle layer panel
3. [ ] `F4` — toggle preview window
4. [ ] `F5` — toggle edit bar
5. [ ] `Shift+F5` — toggle advanced bar
6. [ ] `Ctrl+M` — toggle character map
7. [ ] `F10` — toggle status bar
8. [ ] `F11` — toggle all UI
9. [ ] `Ctrl+F11` — toggle menu bar
10. [ ] `Ctrl+Shift+Left` — toggle left-side panels
11. [ ] `Ctrl+Shift+Right` — toggle right-side panels
12. [ ] `Ctrl+Shift+Down` — toggle status bar + palette strip

### [ ] Zoom Keys
#### [ ] Canvas zoom controls
1. [ ] `Ctrl+0` — reset zoom to 100% and center
2. [ ] `Ctrl+=` — zoom in
3. [ ] `Ctrl+-` — zoom out

### [ ] Display Scale
#### [ ] Window scale
1. [ ] `Ctrl+PgUp` — increase display scale
2. [ ] `Ctrl+PgDn` — decrease display scale
3. [ ] `Ctrl+Alt+PgDn` — reset display scale

---

## [ ] CANVAS KEYS

### [ ] Canvas Operations
#### [ ] Clear and fill
1. [ ] `Delete` — clear selection (or whole layer)
2. [ ] `Backspace` — fill with FG color
3. [ ] `Shift+Backspace` — fill with BG color
4. [ ] `#` — toggle canvas border

---

## [ ] CLIPBOARD KEYS

### [ ] Copy/Cut/Paste
#### [ ] Clipboard operations
1. [ ] `Ctrl+C` — copy selection
2. [ ] `Ctrl+Shift+C` — copy merged
3. [ ] `Ctrl+X` — cut selection
4. [ ] `Ctrl+V` — paste at cursor
5. [ ] `Ctrl+E` — clear selection (BG color)
6. [ ] `Ctrl+Alt+C` — copy to new layer
7. [ ] `Ctrl+Alt+X` — cut to new layer

---

## [ ] SELECTION KEYS

### [ ] Selection Operations
#### [ ] Select hotkeys
1. [ ] `Ctrl+A` — select all
2. [ ] `Ctrl+D` — deselect
3. [ ] `Escape` — deselect (from any tool)
4. [ ] `Ctrl+Shift+I` — invert selection
5. [ ] Arrow keys — move selection 1px
6. [ ] Shift+Arrows — move selection 10px
7. [ ] Ctrl+Arrows — resize selection 1px
8. [ ] Ctrl+Shift+Arrows — resize selection 10px

---

## [ ] FILE KEYS

### [ ] File Operations
#### [ ] File hotkeys
1. [ ] `Ctrl+S` — save (DRW format)
2. [ ] `Ctrl+Shift+S` — save as
3. [ ] `Ctrl+O` — open file
4. [ ] `Ctrl+N` — new file

---

## [ ] UNDO / REDO KEYS

### [ ] History
#### [ ] Global undo/redo
1. [ ] `Ctrl+Z` — undo
2. [ ] `Ctrl+Y` — redo

---

## [ ] DRAWER KEYS

### [ ] Drawer Mode Switching
#### [ ] F1/F2/F3 modes
1. [ ] `F1` — drawer brush mode
2. [ ] `F2` — drawer gradient mode
3. [ ] `F3` — drawer pattern mode
4. [ ] `F6` — toggle drawer panel (when not used for pixel perfect)

---

## [ ] DRAWING MODIFIER KEYS

### [ ] Constraint Modifiers
#### [ ] Shift/Ctrl modifiers during draw
1. [ ] Shift+drag with Line/Rect/Ellipse — verify constrained to H/V
2. [ ] Ctrl+drag with Rectangle — verify perfect square
3. [ ] Ctrl+drag with Ellipse — verify perfect circle
4. [ ] Ctrl+Shift+drag with Line/Polygon — verify angle snapping

---

## [ ] COMMAND PALETTE KEY

### [ ] Open Command Palette
#### [ ] Quick access
1. [ ] Press `?` — verify command palette opens
2. [ ] Press `Ctrl+P` — verify command palette opens
3. [ ] Type to filter — verify results update
4. [ ] Press Escape — verify closes
