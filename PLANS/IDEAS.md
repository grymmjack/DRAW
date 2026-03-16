# IDEAS

## PREVIEW WINDOW MODE <-> FLOATING IMAGE WINDOW MODE

Allow toggling preview window to become a floating image window for a separate image.

### PREVIEW WINDOW SUB-MENU IN VIEW MENU 

Position new "Preview Window ->" Sub-menu Under VIEW -> [x] Edit Bar

- View -> Preview Window -> [x] Follow Mode (mutually exclusive to reference mode)
- View -> Preview Window -> [x] Floating Image Mode (mutually exclusive to follow mode)
- View -> Preview Window -> [x] Bin Quick Look
- View -> Preview Window -> [x] Allow Color Picking
- View -> Preview Window -> Load Image... ->
  - This loads the image into the preview window when in floating image window mode.
- View -> Preview Window -> Recent -> (last 10 stored here)
- View -> Preview Window -> Recent -> --- DIVIDER ---
- View -> Preview Window -> Recent -> Clear (clear recent preview images)
- The Preview Window Mode, Zoom level, Pan Position, should be remembered in #DRAW.cfg file
- The Recent -> for Preview Window images should be remembered in #DRAW.cfg up to 10 like File -> Recent
- The preferences for Follow Mode, Can Pick Colors, Use for Bin Quick Look should be remembered in #DRAW.cfg

Re-use what you can for Recent Images... as we do for File -> Recent
Identical patterns, cursors, etc.

### DETAILS FOR FLOATING IMAGE WINDOW MODE

In floating image mode, use identical controls as the existing preview window mode when follow pointer is off

- When Floating Image Mode: change the [x] FP (follow pointer) to [x] CP (pick colors)
  - [x] PC if checked should enable same menu option: Preview Window -> [x] Allow Color Picking
  - [x] PC if checked should allow the user to pick colors from Floating Image Window (Preview Window)
  - When sampling colors, you simply can alt click including the color loupe directly from the preview window canvas.  
- When loading into floating image window for canvas the image:
    - Honor the existing preview window configuration (size, zoom level, pan position)
      - But replace the previewed canvas dynamically with that loaded image.
- Remember where we loaded the last reference image from on disk in #DRAW.cfg
- Tooltip with custom delay for when mouse is just hovering over Floating Image Window canvas that shows:
  - Path to file on disk and filename
  - Dimensions width and height
  - Color depth
    - Example (3 lines) 
      Cool.jpg
      in /media/grymmjack/windows/b/Inspiration/DigitalArt/
      W x H @ ### bit
  - Use same #THEME.cfg as for regular tooltips. Make the Cool.jpg the 1st line color like those too

#### CONTROLS (SAME AS PREVIEW WINDOW WITHOUT FOLLOW POINTER)

The same controls as regular preview window for floating image mode...

- M-WHEEL: Zoom IN/OUT
- D-CLICK: 100% and Center
- D-MCLICK: Fit and Center
- L-CLICK and DRAG to pan
- Resizable window edges


### BIN QUICK LOOK

Regardless of Preview Window Mode or Floating Image Window Mode, if Bin Quick Look is enabled,
and mouse hovering over a bin, show quick look details of the bin:

- When [x] Use Preview for Bin Quick Look is enabled:
  - When hovering over a bin, display a loop to it's side showing the full size (100%)
    of the object stored in the bin temporarily. When mouse out, dispose the
    loupe. Like a dynamic thumbnail, but quick look into it. 
  
  - The quick look always shows like the following (showing itself into the preview window):

    - For Brush bin hover:
      - Display the full image of the custom brush
      - Honor the existing preview window configuration (size, zoom level, pan position)
        - But replace the canvas dynamically when hovered over the bins.

    - For Gradient bin hover:
      - Display a gradient mapped across full canvas on checkered transparency.
      - Should honor it's rotation, and stops and everything as if it was used
        to fill a real full canvas.
      - Display the full gradient on the canvas
      - Honor the existing preview window configuration (size, zoom level, pan position)
        - But replace the preview canvas dynamically when hovered over the bins.

    - For Pattern bin hover:
      - Display a 3x3 configuration for the pattern 
        - Just like we do for Pattern Tile Mode.
        - Including the canvas edges
        - But use the pattern that is being hovered over
      - Display the full image of the custom brush
      - Honor the existing preview window configuration (size, zoom level, pan position)
        - But replace the preview canvas dynamically when hovered over the bins.

  - When hovering off the bin, return the canvas to the previous display 
    according to it's mode for the Preview Window or Floating Image Window, as if 
    nothing has happened (like it was before the hover over the bin)

  - For empty bins do not use Bin Quick Look, just allow uninterrupted use of
    whatever mode we are in for preview window or floating image window.

