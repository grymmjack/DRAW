# [ ] EXTRACT IMAGES TESTING

## [ ] CONFIGURATION DIALOG

### [ ] Open Dialog
#### [ ] Open via menu
1. [ ] Go to Tools → Extract Images
2. [ ] Verify settings dialog appears
3. [ ] Verify background mode selector
4. [ ] Verify output directory field
5. [ ] Verify naming method selector

### [ ] Background Mode
#### [ ] Select Transparent mode
1. [ ] Set background mode to "Transparent"
2. [ ] Verify only fully transparent pixels treated as background

#### [ ] Select FG Color mode
1. [ ] Set background mode to "FG Color"
2. [ ] Verify current FG color excluded from components

#### [ ] Select BG Color mode
1. [ ] Set background mode to "BG Color"
2. [ ] Verify current BG color excluded from components

### [ ] Naming Method
#### [ ] Sequential Numbers
1. [ ] Select "Sequential Numbers" naming
2. [ ] Verify start number configurable
3. [ ] Verify output: base_001.png, base_002.png, etc.

#### [ ] Layer Names
1. [ ] Select "Layer Names" naming
2. [ ] Verify output uses source layer name as filename

### [ ] Merge Layers Option
#### [ ] Per-Layer Mode
1. [ ] Uncheck "Merge Layers"
2. [ ] Verify extraction runs per-layer separately

#### [ ] Merged Mode
1. [ ] Check "Merge Layers"
2. [ ] Verify all layers flattened before extraction

### [ ] Cancel Dialog
#### [ ] Cancel without extracting
1. [ ] Open dialog
2. [ ] Click Cancel
3. [ ] Verify no files created, normal mode restored

---

## [ ] COMPONENT DETECTION

### [ ] Flood Fill Detection
#### [ ] Detect components
1. [ ] With content on canvas (multiple separate objects)
2. [ ] Run extraction
3. [ ] Verify each separate component found (8-connected)
4. [ ] Verify bounding boxes correct

### [ ] No Components
#### [ ] Empty or transparent canvas
1. [ ] Clear canvas (all transparent)
2. [ ] Run extraction
3. [ ] Verify graceful handling (message: nothing to extract)

---

## [ ] SAVING

### [ ] Save Components
#### [ ] Save all detected components
1. [ ] Run extraction with valid content
2. [ ] Verify each component saved as separate PNG
3. [ ] Verify alpha channel preserved
4. [ ] Verify files appear in output directory
5. [ ] Verify progress shown during save

### [ ] Append Dimensions Option
#### [ ] Include dimensions in filename
1. [ ] Enable "Append Dimensions" if available
2. [ ] Verify filenames include WxH size info

---

## [ ] PERSISTENCE (DRW v14+)

### [ ] Settings Saved in DRW
#### [ ] Persist extraction config
1. [ ] Configure extraction settings
2. [ ] Save DRW file
3. [ ] Reload DRW file
4. [ ] Open Extract Images dialog
5. [ ] Verify settings restored from file
