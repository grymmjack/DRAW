# [ ] DIALOGS TESTING

## [ ] NATIVE DIALOGS

### [ ] File Open Dialog
#### [ ] Open file dialog
1. [ ] Press `Ctrl+O` (or File → Open)
2. [ ] Verify native OS file dialog appears
3. [ ] Verify supported file filters shown (DRW, PNG, BMP, etc.)
4. [ ] Select a file — verify file loaded
5. [ ] Verify post-dialog cleanup (mouse buffer drained, buttons up, suppress frames)

#### [ ] Cancel file open
1. [ ] Open file dialog
2. [ ] Click Cancel
3. [ ] Verify no file loaded, application state unchanged

### [ ] File Save Dialog
#### [ ] Save file dialog
1. [ ] Press `Ctrl+Shift+S` (or File → Save As)
2. [ ] Verify native OS save dialog appears
3. [ ] Enter filename — verify file saved
4. [ ] Verify post-dialog cleanup

#### [ ] Cancel file save
1. [ ] Open save dialog
2. [ ] Click Cancel
3. [ ] Verify no file saved

### [ ] Message Box
#### [ ] Confirmation dialogs
1. [ ] Modify canvas, then try to open a new file (Ctrl+N)
2. [ ] Verify "Unsaved changes" message box appears
3. [ ] Click "Save" — verify file saved then new file created
4. [ ] Click "Don't Save" — verify new file without saving
5. [ ] Click "Cancel" — verify stays on current file

---

## [ ] POST-DIALOG CLEANUP

### [ ] Mouse Cleanup
#### [ ] Input state restored after dialog
1. [ ] Open and close a native dialog
2. [ ] Verify mouse buttons report as released
3. [ ] Verify SUPPRESS_FRAMES counter active (2 frames)
4. [ ] Verify keyboard buffer cleared
5. [ ] Verify no phantom clicks

---

## [ ] OVERLAY DIALOGS (Image Adjustments)

### [ ] Open Overlay
#### [ ] Open image adjustment overlay
1. [ ] Go to Image → Adjustments → Brightness/Contrast
2. [ ] Verify overlay panel appears (not a native dialog)
3. [ ] Verify IMGADJ.ACTIVE% = TRUE flag set
4. [ ] Verify live preview active on canvas

### [ ] Modal Behavior
#### [ ] Overlay blocks other input
1. [ ] With overlay open, try to click on canvas
2. [ ] Verify clicks handled by overlay (not canvas tools)
3. [ ] Try keyboard shortcuts — verify overlay captures input

### [ ] Slider Interaction
#### [ ] Drag sliders
1. [ ] Drag adjustment sliders
2. [ ] Verify live preview updates
3. [ ] Verify debounced (not excessive recompute)

### [ ] Apply Overlay
#### [ ] OK / Enter
1. [ ] Adjust values
2. [ ] Press Enter (or click OK)
3. [ ] Verify adjustment applied to pixels
4. [ ] Verify HISTORY_record saved
5. [ ] Verify IMGADJ.ACTIVE% = FALSE

### [ ] Cancel Overlay
#### [ ] Cancel / Escape
1. [ ] Adjust values
2. [ ] Press Escape (or click Cancel)
3. [ ] Verify original snapshot restored
4. [ ] Verify no history state added

---

## [ ] DEFERRED ACTION PIPELINE

### [ ] Deferred Dialogs
#### [ ] Dialog deferred to input_handler_loop
1. [ ] Trigger a file dialog (via menu or keyboard)
2. [ ] Verify MOUSE.DEFERRED_ACTION% set
3. [ ] Verify dialog opens in MOUSE_input_handler_loop (post-render)
4. [ ] Verify no rendering corruption during dialog
