# [ ] SAVE AND LOAD TESTING

## [ ] SAVE

### [ ] Save DRW File
#### [ ] Ctrl+S saves current file
1. [ ] Draw content on canvas
2. [ ] Press `Ctrl+S`
3. [ ] Verify save dialog appears (or saves to existing path)
4. [ ] Save as .drw file
5. [ ] Verify file created with correct PNG+drAw chunk data

#### [ ] Ctrl+Shift+S saves as new file
1. [ ] Press `Ctrl+Shift+S`
2. [ ] Verify Save As dialog appears
3. [ ] Choose new filename
4. [ ] Verify file saved

---

## [ ] LOAD

### [ ] Load DRW File
#### [ ] Ctrl+O opens file
1. [ ] Press `Ctrl+O`
2. [ ] Select a .drw file
3. [ ] Verify file loads completely
4. [ ] Verify all layers restored
5. [ ] Verify palette restored
6. [ ] Verify tool states reset

#### [ ] Load PNG file
1. [ ] Open a .png file
2. [ ] Verify single-layer import with RGBA preserved

#### [ ] Load BMP file
1. [ ] Open a .bmp file
2. [ ] Verify single-layer import (RGB)

---

## [ ] UNSAVED CHANGES

### [ ] Dirty Canvas Protection
#### [ ] Prompt on load with unsaved changes
1. [ ] Draw content (make canvas dirty)
2. [ ] Press `Ctrl+O` to load a different file
3. [ ] Verify unsaved-changes dialog appears
4. [ ] Click "Cancel" — verify no file loaded
5. [ ] Click "Don't Save" — verify new file loads (old changes lost)

---

## [ ] EXPORT

### [ ] QB64 Code Export
#### [ ] Ctrl+E exports .bas
1. [ ] Draw content
2. [ ] Press `Ctrl+E`
3. [ ] Verify Save dialog with .bas filter
4. [ ] Save — verify .bas file with DATA statements generated

### [ ] Export Selection
#### [ ] Ctrl+Shift+E exports PNG
1. [ ] Create a marquee selection
2. [ ] Press `Ctrl+Shift+E`
3. [ ] Verify export selection dialog
4. [ ] Save as PNG — verify file has correct dimensions and alpha

---

## [ ] RECENT FILES

### [ ] File → Open Recent
#### [ ] Recent files listed
1. [ ] Save a file, then open a different file
2. [ ] Open File → Open Recent submenu
3. [ ] Verify previously opened file listed
4. [ ] Click recent file — verify it loads

---

## [ ] ROUND-TRIP INTEGRITY

### [ ] Save → Load Preserves State
#### [ ] All state survives round-trip
1. [ ] Create multi-layer artwork with various settings
2. [ ] Set specific zoom, pan, grid, symmetry settings
3. [ ] Save as .drw
4. [ ] Close and reopen DRAW
5. [ ] Load the saved .drw file
6. [ ] Verify all layers, palette, zoom, grid, symmetry, drawer states match
