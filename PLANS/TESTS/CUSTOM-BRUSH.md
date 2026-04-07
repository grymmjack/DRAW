# [ ] CUSTOM BRUSH TESTING

## [ ] CAPTURE

### [ ] Capture from Marquee
#### [ ] Ctrl+B with active marquee
1. [ ] Select Marquee tool (`M`)
2. [ ] Draw a selection around some content
3. [ ] Press `Ctrl+B`
4. [ ] Verify custom brush captured from selection
5. [ ] Verify brush preview follows cursor

### [ ] Ctrl+B Without Marquee
#### [ ] No marquee active
1. [ ] Ensure no marquee selection active
2. [ ] Press `Ctrl+B`
3. [ ] Verify no-op or error message (no crash)

---

## [ ] PAINTING

### [ ] Stamp Mode
#### [ ] Single click stamps brush
1. [ ] With custom brush active, click on canvas
2. [ ] Verify brush image stamped at click position

### [ ] Drag Painting
#### [ ] Click and drag paints with brush
1. [ ] With custom brush active, click and drag
2. [ ] Verify brush stamped along path
3. [ ] Verify interpolation between samples

---

## [ ] OPERATIONS

### [ ] Flip Horizontal
#### [ ] Toggle horizontal flip
1. [ ] FLIP_H — verify brush mirrors left-right
2. [ ] Toggle again — verify back to original

### [ ] Flip Vertical
#### [ ] Toggle vertical flip
1. [ ] FLIP_V — verify brush mirrors top-bottom
2. [ ] Toggle again — verify back to original

### [ ] Rotate CW
#### [ ] Rotate clockwise
1. [ ] Rotate CW — verify brush rotated 90° clockwise
2. [ ] Verify W/H swapped

### [ ] Rotate CCW
#### [ ] Rotate counter-clockwise
1. [ ] Rotate CCW — verify brush rotated 90° counter-clockwise

### [ ] Scale Up/Down
#### [ ] Adjust brush scale
1. [ ] Scale up (scroll wheel +) — verify brush grows
2. [ ] Scale down (scroll wheel -) — verify brush shrinks
3. [ ] Reset scale — verify SCALE = 1.0

### [ ] Recolor Mode
#### [ ] Toggle recolor
1. [ ] Enable recolor mode
2. [ ] Verify all non-transparent pixels painted as FG color
3. [ ] Disable — verify original brush colors restored

### [ ] Outline Mode
#### [ ] Toggle outline
1. [ ] Enable outline mode
2. [ ] Verify outline silhouette shown in cursor preview
3. [ ] Disable — verify outline hidden

---

## [ ] STASH / UNSTASH

### [ ] Tool Switch Stash
#### [ ] Switching away stashes brush
1. [ ] Capture a custom brush
2. [ ] Switch to a non-brush tool (e.g., Line)
3. [ ] Verify custom brush stashed
4. [ ] Switch back to Brush tool
5. [ ] Verify custom brush restored from stash

---

## [ ] CLEAR

### [ ] Clear Custom Brush
#### [ ] Ctrl+B clears active brush
1. [ ] With custom brush active (no marquee)
2. [ ] Press `Ctrl+B`
3. [ ] Verify custom brush cleared
4. [ ] Verify standard circular brush restored

---

## [ ] ERASER MODE

### [ ] Custom Brush Eraser
#### [ ] Transparent FG with custom brush
1. [ ] Set FG to transparent
2. [ ] Activate custom brush
3. [ ] Paint on canvas
4. [ ] Verify eraser behavior (pixels become transparent)
5. [ ] Verify uses _DONTBLEND + per-pixel PSET of _RGBA32(0,0,0,0)

---

## [ ] FILL OPERATIONS

### [ ] Custom Brush Fill Rectangle
#### [ ] Fill rect with custom brush tiles
1. [ ] Activate custom brush
2. [ ] Use Rectangle fill tool
3. [ ] Verify rectangle filled with tiled custom brush

### [ ] Custom Brush Fill Ellipse
#### [ ] Fill ellipse with custom brush tiles
1. [ ] Activate custom brush
2. [ ] Use Ellipse fill tool
3. [ ] Verify ellipse filled with tiled custom brush

---

## [ ] EXPORT

### [ ] Export Brush as PNG
#### [ ] Save brush image
1. [ ] With custom brush active
2. [ ] Export as PNG
3. [ ] Verify file saved with correct dimensions and alpha

---

## [ ] UNDO / REDO

### [ ] Custom Brush Undo
#### [ ] Undo custom brush strokes
1. [ ] Paint with custom brush
2. [ ] Ctrl+Z — verify stroke undone
3. [ ] Ctrl+Y — verify stroke restored
