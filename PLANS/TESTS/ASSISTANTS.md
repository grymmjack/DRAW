# [ ] ASSISTANTS TESTING

## [ ] COLOR PICKER ASSISTANT (Alt)

### [ ] Temporary Picker Activation
#### [ ] Hold Alt to pick color
1. [ ] Hold `Alt` key
2. [ ] Verify cursor changes to eyedropper
3. [ ] Left-click on canvas — verify FG color sampled
4. [ ] Right-click on canvas — verify BG color sampled
5. [ ] Release `Alt` — verify previous tool restored

---

## [ ] PAN ASSISTANT (Space / Middle-Click)

### [ ] Space+Drag Pan
#### [ ] Hold Space to pan
1. [ ] Hold `Space` key
2. [ ] Verify cursor changes to pan/hand
3. [ ] Left-click and drag — verify canvas pans
4. [ ] Release `Space` — verify previous tool restored

### [ ] Middle-Click Pan
#### [ ] Middle-click drag to pan
1. [ ] Middle-click and drag on canvas
2. [ ] Verify canvas pans
3. [ ] Release — verify pan stops, tool unchanged

---

## [ ] ZOOM ASSISTANT (Ctrl+Alt)

### [ ] Temporary Zoom Mode
#### [ ] Hold Ctrl+Alt to zoom
1. [ ] Hold `Ctrl+Alt`
2. [ ] Verify cursor changes to zoom
3. [ ] Left-click on canvas — verify zoom in
4. [ ] Right-click on canvas — verify zoom out
5. [ ] Release `Ctrl+Alt` — verify previous tool restored

---

## [ ] CROSSHAIR ASSISTANT (Shift / Caps-Lock)

### [ ] Temporary Crosshair
#### [ ] Hold Shift for crosshair
1. [ ] Hold `Shift` key
2. [ ] Verify full-canvas crosshair lines rendered at cursor position
3. [ ] Release `Shift` — verify crosshair disappears

#### [ ] Caps-Lock for persistent crosshair
1. [ ] Engage `Caps Lock`
2. [ ] Verify crosshair remains active while Caps Lock is on
3. [ ] Disengage `Caps Lock` — verify crosshair deactivates

---

## [ ] SYMMETRY ASSISTANT (Scroll-Lock)

### [ ] Toggle Symmetry
#### [ ] Scroll-Lock toggles symmetry
1. [ ] Press `Scroll Lock`
2. [ ] Verify symmetry mode toggles on/off
3. [ ] Press again — verify toggled back

---

## [ ] ASSISTANT INTERACTIONS

### [ ] Assistants Don't Conflict with Tools
#### [ ] Multi-assistant overlap
1. [ ] While drawing with brush, hold Alt briefly — verify picker activates, then brush resumes
2. [ ] While using any tool, hold Space — verify pan activates, then tool resumes
3. [ ] Verify assistants don't leave tools in broken state
