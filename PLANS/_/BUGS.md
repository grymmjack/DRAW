# BUGS

## Clicking outside a paste/move float re-stamps instead of deselecting (FIXED 2026-09-06)
- [x] TempodiBasic 2.0.3 report: after copy/paste (a float), clicking outside the
      selection then dragging re-stamped the content ("these lasts stamps on the
      pictures"), and there was no obvious way to null the selection.
  - [x] Root cause: the MOVE tool's click-outside branch committed the float then
        IMMEDIATELY re-captured + started transforming a NEW float, so it stayed
        "live" — a subsequent drag moved/stamped it (INPUT/MOUSE.BM, MOVE press).
  - [x] Fix: on a click outside the float, FINALIZE it once (MOVE_reset, honors
        IS_PASTE) and DESELECT (MARQUEE_clear + MAGIC_WAND_reset + INVALIDATE_scene),
        matching the marquee tools' click-to-deselect. No re-grab.
  - [x] Discoverability: added "SELECT ALL" (Ctrl+A) and "DESELECT" (Ctrl+D) to the
        Edit menu (GUI/MENUBAR.BM) — they existed only as hotkeys / command palette.
  - [x] Regression test QA/tests/float-click-outside-deselect.sh (floats a block,
        clicks+drags outside; pre-fix the content is dragged away, post-fix it stays).
        Deselect answer for the reporter: Ctrl+D or Esc.

## Line tool pressing s and e does not change caps, but switches tools instead
- [x] While drawing with line tool and in active drag state:
  - [x] Pressing s changes to smart shape
  - [x] Pressing e changes to eraser
  - [x] This should instead, while dragging change start and end line_caps
  - Fix: `INPUT_build_context` now sets `CTX_DRAWING_IN_PROGRESS` while `TOOL_LINE` is
    dragging, and the dispatched `S` (1706) / `E` (118) bindings forbid that context,
    so the existing cap-cycling `_KEYDOWN` handler owns the keys again.
  
## Mousewheel over color strip does not scroll it
- [x] The color strip used to scroll when mousewheel was over it
- [x] It used to also allow SHIFT or CTRL to scroll by the size of a page (whatever the max color chips were -1 (i think))

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
