# BUGS

## TO DO

### TEXT TOOL

- [ ] Bold style is good for faux bold, but it makes letters too close together
  - the letters should be spaced at least 1 px apart, and never touch
    - at size 8 for tiny 5 regular, they touch on left/right sides
    - at size 16 for tiny 5 regular, they don't touch on left/right sides
      - need a consistent gap between characters for any faux bold style

- [ ] When the canvas is panned under the text tool i am able to still pick colors
  and interact with the canvas, even though the mouse pointer is over the 
  text properties bar.
    - This should not be the case
    - When the mouse is over the properties bar, no events should reach the canvas

---

## COMPLETED

### TEXT TOOL

- [x] Pressing enter does not move to new line
  - Fixed TEXT_LAYER_add_char line break shift: `>=` → `>` so chars after Enter belong to the new line
  - Fixed TEXT_LAYER_get_char_x to reset curX to startX when charIdx sits at a line break position

- [x] I should not be able to type off the canvas
  - Auto-wraps text at right canvas edge (word-wrap with char-wrap fallback)
  - Blocks typing/Enter when text would overflow bottom edge
  - Plays pitched-down alert sound + flashing black/white cursor on overflow

- [x] Key repeat rate is too fast
  - Arrowing back after typing some text ...
  - and pressing DELETE sometimes deletes more than 1 character

- [x] Hide/Show All is not hiding the text properties bar
  - F11 should hide/show all chrome / widgets in the UI

- [x] Cannot choose transparent as background color
  - Left-click FG/BG swatches opens palette picker; right-click toggles transparent
  - BG/FG color changes now sync to all existing characters in active text layer
  - Fixed _PRINTSTRING filling char cells with opaque black (_PRINTMODE _KEEPBACKGROUND)
  - Fixed _MEM clear for guaranteed transparent buffer before text render

