# BUGS

## Mousewheel over color strip does not scroll it
- [ ] The color strip used to scroll when mousewheel was over it
- [ ] It used to also allow SHIFT or CTRL to scroll by the size of a page (whatever the max color chips were -1 (i think))

## Apron wheel zoom
- [x] Should not be able to zoom in to negative apron space
  - [x] When zooming and the mouse pointer is over the apron:
    - [x] Consider the mousepointer over the center of the canvas when calculating
          the zoom position for the pointer.

## In palette picker, selecting downloaded LOSPEC palettes or USER palettes does not update color strip
- [x] When I click to load a downloaded LOSPECT or USER palette the color strip does not update

## ZOOM with hotkeys
- [x] When zoom with `z` + number, if the zoom would result only in showing apron, the entire canvas should zoom and center to the new desired zoom level
  - [x] Currently it is possible to just hold `z` and press `1` and see only apron, no canvas.

## Crosshair rendering over DRAW GUI CHROME
- [x] When holding SHIFT, and the mouse is over the GUI chrome, it is still rendering the crosshair on the canvas.
  - [x] It should only render the crosshair when the cursor is on the canvas OR apron
  - [x] If cursor is over the GUI CHROME - NONE of the assistants should render
    - [x] No crosshair assistant
    - [x] No color picker loupe

## Attempt to create layer group when max layers reached silently fails
- [x] When attempting to create a layer group in any way but the layer count is already max...
  - [x] The program silently fails and does nothing
- [x] I would like the program to show a dialog saying "Can't perform layer operation because all layers used"
- [x] This should happen for attempt to create a new layer in ANY WAY
  - [x] From the layer panel +
  - [x] From Edit -> Copy to New Layer
  - [x] From Edit -> Cut to New Layer
  - [x] From Edit -> Paste from OS Clipboard (note: paste goes to current layer, no new layer allocated — no guard needed)
  - [x] etc.
- [x] anything that would attempt to allocate a new layer, would need this check and that is why the message should be a generic one with OK button only
