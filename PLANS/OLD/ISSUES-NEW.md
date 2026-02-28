# DRAW ISSUES LIST

## FILE OPERATIONS
[x] (CHANGE) When File -> Import Image and the image importing is smaller than canvas...
  - Do not stretch to fill the entire canvas
  - Center the image, and maintain it's original width and height initially
  - Allow all MOVE operations during import:
    - Scale +/- 50%
      - When scaling should not scale the rescaled image, but the original source image that's being imported
      - So we do not get generation loss of quality when for example scaling down then back up
    - Rotate CW/CCW
    - Flip Horizontal/Vertical


## MENU BAR
[x] (CHANGE) Edit -> Scale -50%/+50% 
  - Scaling up, then down, then down, then down, then back up, 
  - We incur generation loss
  - The scaling operation should use the original size when scaling each step, 
    not the previous step - to prevent generation loss. 

[x] (CHANGE) View -> Reference Image
  - Should render ON TOP of all layers, not beneath them
  - Should not be editable
  - Should still allow opacity changes
  - Should still allow repositioning

[x] (CHANGE) Layer -> Arrange to Top/Bottom - new hotkeys:
  - CTRL-Home = Arrange to Top
  - CTRL-End = Arrange to Bottom

[x] (CHANGE) Palette -> Random - new hotkey:
  - CTRL+ALT+R = Random Palette


## MOVE TOOL
[x] (CHANGE) When creating Cloned copied stamps do not outline the stamped clones with marching ants 
  - If I MOVE the selected stuff, then stamp, there are no outlines.
  - If I don't move the selected stuff first, and create stamps, there are marching ant outlines

[x] (CHANGE) When dragging to move with no selection on a layer, stop drawing boundaries of layers border


## SYMMETRY
[x] (BUG) When cycling through the symmetry modes, and getting to the end to turn off symmetry
  - The symmetry center point is lost if it was previously set
  - It should keep the existing center point for symmetry if it was previously set even when turning off

## ORGANIZER
[x] (NEW FEATURE) CANVAS OPS
  - Left click - Toggle Spare Page 
    - a separate blank file, that has no layer support, used just for manipulating/scratchboard.
    - **DEFERRED** — Spare page not yet implemented (stub remains)
  - Right click - Resize canvas 
    - Create dialog, centered, 
      - Title; Resize Canvas 
      - Current Width/Height, Values box for New Width New Height, a LOCK to make them stay correct aspect ratio 
      - Buttons at the bottom for cancel, and OK
  - Middle click - Crop canvas 
    - When clicked show status: "Drag to crop" 
    - and use the similar controls as Image Import
      - where the background is darkened while we crop
      -  and the user can resize using edges and corners. 
      - When hitting ENTER, canvas is resized accordingly. 
    - CROP assumes cutting away, CROP should not allow to make image bigger, only smaller.


---

## TEST PLAN

### 1. BUG: Symmetry center preserved across mode cycling
1. Open DRAW, create a canvas
2. Enable symmetry (F7 cycle to any mode)
3. Ctrl+Click on canvas to set a custom symmetry center point
4. Press F7 repeatedly to cycle OFF -> Mode 1 -> Mode 2 -> Mode 3 -> OFF -> Mode 1
5. **Verify**: When cycling back ON, the symmetry center stays at your custom location (not reset to canvas center)
6. Press F8 to explicitly clear symmetry
7. Press F7 to re-enable
8. **Verify**: NOW the center resets to canvas center (because explicit clear resets CENTER_SET)

### 2. CHANGE: Move clone stamps — no marching ants
1. Select marquee area on a layer with content
2. Switch to Move tool (V)
3. Alt+click to clone-stamp without moving first
4. **Verify**: No marching ants appear around the stamped clone
5. Move the selection, then stamp
6. **Verify**: Still no marching ants on the stamp

### 3. CHANGE: Move tool — no layer boundary outline
1. Switch to Move tool (V)
2. Click on a layer with content but NO marquee selection
3. Drag to move the entire layer
4. **Verify**: No white boundary rectangle appears during the move (only shows when `MARQUEE.USER_CREATED` is TRUE)

### 4. CHANGE: Reference image renders above layers
1. Load a reference image (Ctrl+R → load)
2. Create content on multiple layers
3. **Verify**: The reference image renders ON TOP of all layers, not behind them
4. Adjust reference image opacity
5. **Verify**: Opacity still works, and the ref image is still above layers

### 5. CHANGE: Layer Arrange to Top/Bottom hotkeys
1. Create 3+ layers with content
2. Select a middle layer
3. Press Ctrl+Home
4. **Verify**: Selected layer moves to the top (highest zIndex)
5. Press Ctrl+End
6. **Verify**: Selected layer moves to the bottom (lowest zIndex)
7. **Verify**: Menu bar shows "Ctrl+Home" / "Ctrl+End" for these items

### 6. CHANGE: Palette Random hotkey
1. Press Ctrl+Alt+R
2. **Verify**: Palette randomizes (same as Palette > Random menu item)
3. **Verify**: Menu bar shows "Ctrl+Alt+R" for the Random item

### 7. CHANGE: Scale without generation loss
**Move selection path:**
1. Select a region with marquee, switch to Move tool
2. Press Scale +50% multiple times, then Scale -50% back
3. **Verify**: Image quality is preserved (no progressive blurring/pixelation)

**Layer scaling path:**
1. With no selection, use Edit > Scale +50% on a layer
2. Scale up, then down, then up again
3. **Verify**: Scaling always works from the original, not the previously-scaled result

### 8. CHANGE: Import image — interactive placement for all sizes
1. Import a small image (e.g., 16x16 icon into a 128x128 canvas)
2. **Verify**: Image enters interactive placement mode (not auto-committed)
3. **Verify**: Image is centered at its original size (not stretched)
4. Use arrow keys to reposition, Ctrl+arrows to resize
5. Press R to rotate 90° CW, Shift+R for CCW
6. Press H to flip horizontal, V to flip vertical
7. Press +/- to scale up/down from original
8. Press Enter to commit
9. Import a large image (larger than canvas)
10. **Verify**: Image is proportionally fit to canvas and centered

### 9. NEW FEATURE: Canvas Resize
1. Right-click the Canvas Ops organizer widget (top-left of organizer grid)
2. **Verify**: An input dialog appears with title "Resize Canvas" showing current WxH
3. Enter "64x64" and confirm
4. **Verify**: Canvas resizes to 64x64, content is anchored at (0,0), undo is reset
5. Enter "256x256"
6. **Verify**: Canvas grows to 256x256, original content preserved at top-left
7. Test via Command Palette: Ctrl+Shift+P → "Resize Canvas"
8. **Verify**: Same dialog appears and works

### 10. NEW FEATURE: Canvas Crop
1. Middle-click the Canvas Ops organizer widget
2. **Verify**: Crop mode activates — darkened overlay appears outside crop region
3. **Verify**: Crop region starts at full canvas size with 8 handles (4 corners + 4 edges)
4. Drag corner handles to shrink the crop region
5. Drag edge handles to resize one dimension
6. Drag inside the crop region to move it
7. Use arrow keys to move, Ctrl+arrows to resize from bottom-right
8. Hold Shift with arrows for larger step sizes
9. **Verify**: Crop region cannot exceed canvas boundaries (crop = shrink only)
10. Press Enter to apply
11. **Verify**: Canvas is cropped to the selected region, layers are cropped, undo is reset
12. Press Escape instead of Enter
13. **Verify**: Crop is cancelled, canvas unchanged, previous tool restored
14. Test via Command Palette: Ctrl+Shift+P → "Crop Canvas"
