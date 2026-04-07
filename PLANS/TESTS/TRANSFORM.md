# [ ] TRANSFORM TESTING

## [ ] QUICK TRANSFORMS

### [ ] Flip Operations
#### [ ] Flip Horizontal
1. [ ] Draw asymmetric content
2. [ ] Use Edit → Transform → Flip Horizontal
3. [ ] Verify content is mirrored left↔right
4. [ ] Undo — verify restored

#### [ ] Flip Vertical
1. [ ] Use Edit → Transform → Flip Vertical
2. [ ] Verify content mirrored top↔bottom
3. [ ] Undo — verify restored

### [ ] Rotate Operations
#### [ ] Rotate 90° CW
1. [ ] Use Edit → Transform → Rotate 90° CW
2. [ ] Verify content rotated clockwise
3. [ ] Undo — verify restored

#### [ ] Rotate 90° CCW
1. [ ] Use Edit → Transform → Rotate 90° CCW
2. [ ] Verify counterclockwise rotation

#### [ ] Rotate 180°
1. [ ] Use Rotate 180°
2. [ ] Verify content inverted both axes

---

## [ ] TRANSFORM OVERLAY

### [ ] Interactive Transform (Edit → Transform...)
#### [ ] Activate overlay
1. [ ] Select content with Marquee (or operate on full layer)
2. [ ] Use Edit → Transform...
3. [ ] Verify transform handles appear around content

#### [ ] Scale via corner handles
1. [ ] Drag a corner handle
2. [ ] Verify content scales (with Shift for aspect lock)

#### [ ] Rotate via rotation handle
1. [ ] Drag rotation handle (outside corners)
2. [ ] Verify content rotates

#### [ ] Apply with Enter
1. [ ] Adjust transform
2. [ ] Press `Enter`
3. [ ] Verify transform committed
4. [ ] Verify history recorded

#### [ ] Cancel with Escape
1. [ ] Adjust transform
2. [ ] Press `Escape`
3. [ ] Verify transform reverted, original content restored

---

## [ ] UNDO / REDO

### [ ] Transform Undo
#### [ ] Undo applied transform
1. [ ] Apply a transform (scale, rotate, etc.)
2. [ ] Press `Ctrl+Z`
3. [ ] Verify content restored to pre-transform state
