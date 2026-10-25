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
#### [ ] Ctrl+Alt+S exports PNG
1. [ ] Create a marquee selection
2. [ ] Press `Ctrl+Alt+S`
3. [ ] Verify export selection dialog
4. [ ] Save as PNG — verify file has correct dimensions and alpha

### [ ] Saving a file you opened (automated: QA/tests/file-save-passed-in-format.sh)
#### [ ] Ctrl+S keeps the file's own name and format
1. [ ] `./DRAW.run art.png`, draw, `Ctrl+S` — `art.png` updated, reopens with layers, no `art.draw`
2. [ ] `./DRAW.run art.gif`, draw, `Ctrl+S` — `art.draw` written beside it, `art.gif` unchanged
3. [ ] Settings → General → Saving → untick *Save .draw Beside Images*; repeat 2 — `art.gif` updated (still a GIF), no `art.draw`
4. [ ] Same with File → Open, Recent Files (Alt+1), drag-and-drop and the image browser
5. [ ] `art.psd` with the setting off — `Ctrl+S` asks where to save, starting in the PSD's folder as `art.png`
#### [ ] Ctrl+Alt+Shift+S flattens into the same file
1. [ ] `./DRAW.run art.gif`, add a layer, `Ctrl+Alt+Shift+S` — `art.gif` updated, no dialog, no `art.draw`
2. [ ] `./DRAW.run art.png`, `Ctrl+Alt+Shift+S` — `art.png` updated and reopens as ONE flat layer
3. [ ] Untitled document — asks for a name; a second `Ctrl+Alt+Shift+S` writes there silently
4. [ ] Import Image into a document, then `Ctrl+S` — never overwrites the imported image

### [ ] Export Again
#### [ ] Ctrl+Shift+E repeats the last Export As
1. [ ] Fresh document, press `Ctrl+Shift+E` — status bar says nothing to export yet, no file written
2. [ ] File → Export As → GIF, save as `test.gif`
3. [ ] File menu shows `EXPORT AGAIN: TEST.GIF` (enabled)
4. [ ] Draw more, press `Ctrl+Shift+E` — no dialog, status bar says `Exported test.gif`, file updated
5. [ ] File → Revert, then `Ctrl+Shift+E` — still writes `test.gif`
6. [ ] File → New (or open another file), then `Ctrl+Shift+E` — nothing written, menu item disabled

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
