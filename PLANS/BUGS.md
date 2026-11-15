# ISSUES / BUGS


## HELP MENU - LAST DIVIDER WITH NO ITEMS UNDER

- [x] Remove the divider in the help menu under SAMPLES, there is no point to divider anything if nothing is under


## GUI

- [x] Zoom Loupe is showing up even when not holding ALT when hovering over tool box buttons
  - It is also showing wrong z-index underneath bars, underneath all other chrome in GUI except layer panel and color strip.
  - REPRODUCE: hover over a toolbox button, notice the zoom loupe preview image near by.

- [x] Symmetry tool - add tooltip text: CTRL+LCLICK to set symmetry center point.
  - These controls should be dynamic mention per bindings / customize controls)

- [x] UNDO when holding undo/redo, it should go back in history step by step with a delay between steps

- [x] For all SHAPE smart shape operations on rect, circle, ellipse, smart shapes, etc. 
    - HOLD the key to modify should repeat the same modification after a delay 
    - For example, creating a rect while still drawing and pressing up or right arrow should add the divisions
    - For polygon number of sides, etc.

- [x] Now that we have floating/docking/etc. we don't need View -> Layout or any of those hotkeys
  - LOCK LAYOUT should also read LOCK WORKSPACE as a result of removing them.
  

## ORGANIZER GRID BUTTON

- [x] RCLICK on button to adjust grid with drag (like deluxe paint - super impose a grid, then let user drag to adjust width/height)
- [x] Add to status: RCLICK to visually adjust


## MOVE TOOL

- [x] When holding ALT to make clones of something, a canvas sized rectangular selection is made.
  - This should not happen. No selection should be made.
  - Also hitting ESCAPE moves the rectangle back to the original art area, with some of the apron selected. Why?
  - REPRODUCE: New file. Pick a custom brush from bin, draw something. Then press move tool button in toolbox, then hold ALT and drag on top of it. Notice it creates the selection

- [x] Holding SHIFT while using arrows no longer nudges by 10px it scrolls the canvas.
  - I don't understand why this happened, but I don't want it to work this way by default. 
  - REPRODUCE: With move tool selected, hold SHIFT and press any arrow. It moves the canvas, not the art.

- [x] Using ALT while using the arrows creates a floating copy of what was cloned, after if using move tool on same layer.
  - This should not happen. ALT arrow clones should just stamp as they are, and not make a floating copy.
  - REPRODUCE: Use custom brush, stamp it. Use move tool, hold ALT, press down arrow left arrow 3 times to make a diagonally thick version of it. Now on move tool, drag on the layer - it has a separate strangely floated copy.

- [x] Status bar says H/V flip - this is false, this is for custom brush
  - Remove status that says H/V: Flip from Move tool status text
  - REPRODUCE: Use move tool, observe the status text.

- [x] Status bar says ENTER: apply
  - This should not be the case for move tool? Why is it like this? ENTER is not needed? 
  - REPRODUCE: Use move tool, observe the status text.


## HAND TOOL

- [x] Double clicking hand-tool to fit canvas is not centering properly. The right side is centered properly the left shows no padding like the right. 
  - It should be centered. Both above, below, left and right should have equal padding/distance of the apron
  - REPRODUCE: Using DEFAULT 2 workspace, Double click the hand tool. Observe GUI elements above left side of canvas and no padding to reveal apron.


## ZOOM TOOL

- [x] Drag rectangular zoom is not positioning the canvas in the center of what was zoomed
  - It should position the zoomed content in the center of the window, scroll the canvas to show that in the center
  - It is currently offset to the right side a bit. It is still in view, but not centered, more right justified.
  - REPRODUCE: Use Zoom tool and drag a rectangle around art. Observe not centered.

- [x] Add to tooltip: DCLICK to zoom to 100% 


## CROP TOOL

- [x] I dislike how it selects the entire canvas automatically. It should instead let the user drag a rect to crop.
  - This is a strange behavior and one that I would like to fix to not work like this.
  - REPRODUCE: Click Crop tool, observe it selects the entire artwork.

- [x] IMAGE -> Crop can act like it is now, selecting the whole image, but it needs to zoom out automatically to make sure the image boundaries/edges are visible (otherwise the selection won't be obvious)

- [x] Add feature: Double click on crop tool to trim image to boundaries of visible layers
  - This is a feature that would be a nice fast workflow and would make sense to make instant.
  - Add to tooltip: DCLICK to trim image to artwork boundaries

- [x] Clicking away from selection during crop creates a 1x1 crop rect. I dislike this and would prefer it to clear the rectangle. 

- [x] When I have a crop rectangle present and use the keyboard to nudge it, the highlighted part and shadowed parts do not update until I move the mouse.
  - REPRODUCE: Create a crop selection. Use arrows to move it. Observe that the highlighted and shadowed parts do not redraw.


## RECTANGULAR MARQUEE TOOL 

- [x] Clicking away from selection while selection is present creates a 1x1 selection. I dislike this and would prefer it to clear the selection. 
  - REPRODUCE: Click rect marquee tool, select something. Click in the apron without dragging. Observe 1x1 selection created.


## ALL MARQUEE TOOLS

- [x] When creating a selection I would like to be able to Hold SPACE like I am able to do for the shape tools to reposition the selection like photoshop.


## MAGIC WAND

- [x] Remove tooltip : SHIFT + LCLICK to select on all image. THat's false.
  - Replace Click to select on layer with: Click to select color contiguous.
  - Add to tooltip HOLD w and LCLICK to select color discontiguous.
  - Add to tooltip HOLD SHIFT + w and LCLICK to select color on image. 
  - Add to tooltip HOLD f and LCLICK to replace color with FG color.
  - Add to tooltip HOLD e and LCLICK to erase color.
  - as a result of having this tooltip be so tall, let's make each line separate, so it's tall and easy to parse visually.


## COLOR PIPETTE PICKER

- [x] HOLD R selects the rectangle tool, it doesn't select from reference at all.
  - REPRODUCE: Select color pipette, hold r, automatically selects rectangle tool


## EDIT BAR

- [x] Operations for H | V | Scale | Rotate, when the art crosses into the apron, destroy the art. 
  - REPRODUCE: Perform the operation on a piece of art near the apron. It destroys the part that overlaps the apron. We fixed this before, Why is it back?

- [x] Hovering over a button used to show it as an option to select with a sound, it doesn't any more.
  - If the option is not DISABLED out right (in which case it should be dimmed out) it should be obvious to the user that it's state isn't enabled but CAN be.


## ADVANCED BAR

- [x] REF ON button is always lit, it should only light if it's on, and dim when off.
  - REPRODUCE: Load a reference, turn it off by clicking REF ON in bar, observe still bright

- [x] REF ADJUST button - should allow CTRL+ALT+SHIFT+WHEEL to adjust reference opacity
  - Same for IMAGE -> REPOSITION REFERENCE

- [x] Hovering over a button used to show it as an option to select with a sound, it doesn't any more.
  - If the option is not DISABLED out right (in which case it should be dimmed out) it should be obvious to the user that it's state isn't enabled but CAN be.

- [x] Angle snap button cannot be turned off - it's always on


## ERASER

- [x] HOLD SHIFT is not erasing on all layers


## DOT TOOL

- [x] HOLD E to erase is allowing more than 1 dot at a time


## SPRAY TOOL

- [x] HOLD E to erase is not erasing with spray pattern, just brush size single brush


## FLOOD FILL TOOL

- [x] HOLDING SHIFT and LCLICK to fill canvas area is filling a previous mask vs. what was placed with custom brush or clone initially.
- [x] HOLDING SHIFT is not merging on all visible colors across layers
- [x] HOLD G or W should fill on all layers like magic wand when holding F (complement to that feature)


## BEZIER CURVE TOOL

- [x] Can't see handle or rubber band, and ` doesn't toggle it. 
  - I can see it if I press ` but as soon as I move the mouse it vanishes
  - REPRODUCE: Draw a curve, note the lack of rubber band visibilty and the handles toggling with ` not working


## EXPORT SELECTION TO DISK TOOL

- [x] If I click the tool and there is no selection, it should allow me to create one, then export.


## BROWSER BUTTON ON TOOL BOX

- [x] Add feature: MCLICK to open SAMPLES
- [x] Add to tooltip: RCLICK to OPEN a new file


## FILL ADJUST 

- [x] ADD press D to cycle through dither modes (same ones as in gradient editor but operate on the fill only)
- [x] ADD hold D + MWHEEL to increase/decrease dither amount
- [x] ADD hold D + drag to reposition dither pattern
- [x] ADD hold D and SHIFT and press 1-9 to save a fill preset
- [x] ADD hold D and press 1-9 to recall fill preset
- [x] This should remember it's settings, even if not saved to preset


## COLOR MIXER PANEL

- [x] The MORE disclosure is showing some of the stuff under it
  - It shouldn't show anything under it. Add some vertical padding above/below it.


## ADVANCED COLOR MIXER PANEL

- [x] The variations ... text is too close to the bottom when collpased.
  - It shouldn't be so tight to the bottom edge of the panel. Add some vertical padding above/below it.


## TOOLS -> ANNOTATE MENU

- [x] ANNOTATE should read ANNOTATE (WIP)
  - As should it's sub-menu items:
    - Arrow, Highlighter, Redact, Numbered Callout, Restart Callout Numbers
    - Under these options should be a divider then:
    - QUICK SAVE PNG
    - DONE (SAVE, COPY, GO BACK)


## TOOLS -> CODE MENU

- [x] This should be completely removed along with the divider above it.
  - Keep the divider under it.


## PALETTE -> COLOR CYCLING MENU

- [x] This should also show up just like it is in this PALETTE menu in the COlor strip right click popup menu but flattened so the options show under the existing max rows, max cols, chip height, chip width, etc. so:
  - After MAX ROWS = .. CHIP WIDTH = .. 
  - DIVIDER
  - COLOR CYCLING: (dimmed)
  - DIVIDER
  - Flattened options from COLOR CYCLING MENU in PALETTE -> COLOR CYCLING
  - All options should be uppercase even the Max Rows, Chip Width, etc.


## ANIMATION

- [ ] Color cycling should work across every frame and include the animation frames too.
  - It does not right now.
  - REPRODUCE: Open christmas.draw, press SHIFT+TAB to enable cycling, press NUMPAD + to add a frame, on second frame draw something. Make hold for both frame 1 and frame 2 long, press enter to play. Observe drawing not present while cycling enabled in animation.