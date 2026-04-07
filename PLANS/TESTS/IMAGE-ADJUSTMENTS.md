# [ ] IMAGE ADJUSTMENTS TESTING

## [ ] BRIGHTNESS / CONTRAST

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Image → Adjustments → Brightness/Contrast
2. [ ] Verify overlay dialog appears with two sliders
3. [ ] Verify live preview active on canvas

#### [ ] Adjust Brightness
1. [ ] Drag brightness slider to +50
2. [ ] Verify canvas preview becomes brighter
3. [ ] Drag brightness slider to -50
4. [ ] Verify canvas preview becomes darker

#### [ ] Adjust Contrast
1. [ ] Drag contrast slider to +50
2. [ ] Verify increased color separation
3. [ ] Drag contrast slider to -50
4. [ ] Verify reduced color separation

#### [ ] Apply changes
1. [ ] Click OK (or press Enter)
2. [ ] Verify adjustment committed to pixels
3. [ ] Verify history state recorded (Ctrl+Z to undo)

#### [ ] Cancel changes
1. [ ] Open Brightness/Contrast dialog
2. [ ] Move sliders
3. [ ] Press Escape (or click Cancel)
4. [ ] Verify pixels restored to original state

---

## [ ] HUE / SATURATION

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Image → Adjustments → Hue/Saturation
2. [ ] Verify overlay with 3 sliders (Hue, Saturation, Lightness)

#### [ ] Adjust Hue
1. [ ] Drag hue slider (-180 to +180 degrees)
2. [ ] Verify color shift in preview

#### [ ] Adjust Saturation
1. [ ] Drag saturation slider to -100
2. [ ] Verify image becomes grayscale
3. [ ] Drag saturation slider to +100
4. [ ] Verify colors become vivid

#### [ ] Adjust Lightness
1. [ ] Drag lightness slider up/down
2. [ ] Verify brightness changes

#### [ ] Apply and Cancel
1. [ ] Apply changes — verify history recorded
2. [ ] Undo — reopen — cancel — verify original restored

---

## [ ] LEVELS

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Image → Adjustments → Levels
2. [ ] Verify histogram display appears
3. [ ] Verify input/output point sliders

#### [ ] Adjust Input Levels
1. [ ] Move black point slider inward
2. [ ] Verify shadows deepen
3. [ ] Move white point slider inward
4. [ ] Verify highlights brighten

#### [ ] Adjust Gamma/Midtone
1. [ ] Move gamma slider
2. [ ] Verify midtone brightness changes

#### [ ] Apply and Cancel
1. [ ] Apply — verify committed
2. [ ] Undo — reopen — cancel — verify restored

---

## [ ] BLUR

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Image → Adjustments → Blur
2. [ ] Verify radius slider appears

#### [ ] Adjust Blur Radius
1. [ ] Increase blur radius
2. [ ] Verify canvas preview shows blurring
3. [ ] Decrease to 0
4. [ ] Verify no blur effect

#### [ ] Apply and Cancel
1. [ ] Apply — verify committed and undoable
2. [ ] Reopen — cancel — verify restored

---

## [ ] SHARPEN

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Image → Adjustments → Sharpen
2. [ ] Verify amount slider

#### [ ] Adjust Amount
1. [ ] Increase sharpen amount
2. [ ] Verify edges become more defined
3. [ ] Apply — verify committed

---

## [ ] INVERT

### [ ] Instant Apply
#### [ ] Invert colors
1. [ ] Go to Image → Adjustments → Invert
2. [ ] Verify all pixel colors inverted (R=255-R, G=255-G, B=255-B)
3. [ ] Verify no dialog shown (instant)
4. [ ] Ctrl+Z — verify original restored
5. [ ] Invert twice — verify back to original

---

## [ ] DESATURATE

### [ ] Instant Apply
#### [ ] Desaturate to grayscale
1. [ ] Go to Image → Adjustments → Desaturate
2. [ ] Verify image converted to grayscale (luminosity method)
3. [ ] Verify no dialog shown (instant)
4. [ ] Ctrl+Z — verify original colors restored

---

## [ ] POSTERIZE

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Image → Adjustments → Posterize
2. [ ] Verify levels slider (2–256)

#### [ ] Adjust Levels
1. [ ] Drag slider to 2
2. [ ] Verify extreme color reduction
3. [ ] Drag slider to 128
4. [ ] Verify subtle posterization
5. [ ] Apply — verify committed and undoable

---

## [ ] PIXELATE

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Image → Adjustments → Pixelate
2. [ ] Verify block size slider

#### [ ] Adjust Block Size
1. [ ] Increase block size
2. [ ] Verify mosaic/blocky effect
3. [ ] Apply — verify committed and undoable

---

## [ ] REMOVE BACKGROUND

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Image → Adjustments → Remove Background
2. [ ] Verify threshold slider

#### [ ] Adjust Threshold
1. [ ] Increase threshold
2. [ ] Verify near-transparent or near-white pixels removed
3. [ ] Apply — verify committed and undoable

---

## [ ] UNDO / REDO

### [ ] Adjustment Undo
#### [ ] All adjustments are undoable
1. [ ] Apply any adjustment
2. [ ] Ctrl+Z — verify fully restored
3. [ ] Ctrl+Y — verify re-applied
