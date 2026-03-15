# BUGS

## CANVAS HITBOX NOT HONORING DIFFERENT LAYOUTS
- Set TOOLBOX and EDITBAR left, and LAYERS RIGHT to reproduce.


## PREVIEW WINDOW CANVAS JIGGLE
- The preview window canvas is jiggling in follow mode.
- It is sometimes showing one size of the canvas, and at sometimes showing a different size.
- It's only by 1px it seems, like old playstation 1 types of jiggling, but it's annoying and i'd like that to not happen.
- Is it because it's not using integers or a rounding error?


## PREVIEW CANVAS MISSING TRANSPARENCY CHECKERBOARD
- The preview window canvas used to have a checkerboard in both follow nad normal mode.


## MENU BARS
- I should not be able to hover to select a disabled option
- The disabled options should not play any sounds


## OVER-ZEALOUS CUSTOM BRUSH CURSOR
- Custom brush preview brush cursor should only be displayed when:
  - Drawing tool is selected:
    - DOT, BRUSH, SPRAY
  - Shape tool is selected:
    - LINE, POLY LINE, RECT, ELLIPSE
      - NOT filled POLY, filled RECT, or filled ELLIPSE
- Custom brush preview brush cursor should be hidden when:
  - Any other tool is in use.


### UNLESS i is possible to fill with custom brush?
- If dragging a shape or building a filled poly, making the brush
  - Repeat if nothing is held down (similar to the way the line tool works with custom brush)
    - It distributes the brush equally.
  - If SHIFT+CTRL is held down while drawing shapes it could fill the extents of the drawn shape 
    - e.g. if custom brush is 32x32 but I hold SHIFT+CTRL while drawing a RECT that is 128x128 
      - The shape is filled with a stretched (maintaining aspect ratio as much as possible) brush at 128x128.
      - Similar to how we would use a TRANSFORM -> SCALE operation or a distortion.
      - If the shape is a shape besides RECT
        - It could act as a mask in addition
        - So it would stretch the shape maintaining aspect ratio as the RECT but also
          - Cut out anything outside the edges of the shape - the RECT existed but then the shape
            served as a cut-out mask on top of it.
            

