# BUGS

## Apron wheel zoom
- [x] Should not be able to zoom in to negative apron space
  - [x] When zooming and the mouse pointer is over the apron:
    - [x] Consider the mousepointer over the center of the canvas when calculating
          the zoom position for the pointer.

## Crosshair rendering over DRAW GUI CHROME
- [ ] When holding SHIFT, and the mouse is over the GUI chrome, it is still rendering the crosshair on the canvas.
  - [ ] It should only render the crosshair when the cursor is on the canvas OR apron
  - [ ] If cursor is over the GUI CHROME - NONE of the assistants should render
    - [ ] No crosshair assistant
    - [ ] No color picker loupe

