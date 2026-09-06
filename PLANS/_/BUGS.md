# BUGS

## Filled shapes vanish on an apron-promoted layer (FIXED 2026-09-06)
- [x] Move any layer (promotes it to an apron-extended buffer, gotcha #14), then draw a
      FILLED rectangle / ellipse / polygon — the fill landed in the off-canvas apron
      border and was invisible. Outline paths were already apron-aware; the solid fills
      wrote RAW canvas coords into the promoted buffer.
  - [x] Surfaced deterministically with `SPLASH_ENABLED=0` in QA (an early Move promoted
        the layer), but it is a real user-reachable bug independent of the splash.
  - [x] Fix: offset the fill by `LAYERS(CURRENT_LAYER%).apronW%/apronH%` (clip / opacity
        lock / color resolve stay in canvas coords, matching BRUSH.BM):
    - [x] RECT solid fill + symmetry — `INPUT/MOUSE.BM`
    - [x] ELLIPSE non-AA fill — `TOOLS/ELLIPSE.BM` `ELLIPSE_fill_scanline` (AA path via
          `PAINT_blend_pixel` was already apron-aware)
    - [x] POLYGON fill — `TOOLS/POLY-FILL.BM` `POLY_FILL_scanline`
  - [x] Regression test `QA/tests/apron-fill-after-move.sh` (promote via Move, draw all 3
        filled shapes). Verified: ellipse failed pre-fix, all pass post-fix; tool-rect /
        tool-ellipse / tool-polygon-select / apron-paint-after-move — no regressions.

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

## Pasted/marquee selection keeps stamping; deselect not discoverable (TempodiBasic 2.0.3 report)
- [ ] After copy → paste, the floating pasted selection re-stamps onto the canvas
      when you click outside the selection and then drag around — producing repeated
      accidental stamps (see report: "these lasts stamps on the pictures").
  - [ ] Expected: clicking clearly outside the selection should commit-and-deselect
        (or at least NOT keep the stamp live so a subsequent drag re-stamps).
- [ ] Further operations after a select/paste unexpectedly act on the still-active
      previous selection area instead of the whole image / new intent.
- [ ] Discoverability: tester could not find how to clear the selection. Deselect
      ALREADY EXISTS — `Ctrl+D` or `Esc` (SHORTCUTS.md:264 → MARQUEE_clear). So this
      is partly a docs/discoverability gap (surface it: status-bar hint while a
      selection/float is active, and/or an Edit-menu "Deselect" item), partly the
      real stamping behavior above. Reporter's literal question: "What is the
      sequence or combokey to do for making null the selection area?" → answer: Ctrl+D / Esc.

### ROOT CAUSE (traced 2026-09-06 — do NOT re-derive; verify still current before fixing)
- The behavior is ASYMMETRIC between a plain marquee SELECTION and a paste FLOAT:
  - Marquee selection: click-outside ALREADY deselects. Rect marquee gets it "for
    free" via a bare click (<4px) → `MARQUEE_finish_drag` clears it (INPUT/MOUSE.BM:2111-2113);
    wand/lasso/poly/ellipse call `MARQUEE_clear` explicitly on click-outside in
    replace mode (INPUT/MOUSE.BM:1989, 2010, 2036, 2070).
  - Paste FLOAT: by the v2.0.3 "BUG-B" design (INPUT/MOUSE.BM:3034-3044 in
    `MOUSE_release_move`), a pasted float (`MOVE.IS_PASTE`) stays a PURE float and
    composites onto the layer exactly ONCE, only when FINALIZED. The finalize
    triggers are: deselect (Ctrl+D) / tool-switch / ESC / next paste / save.
    **A plain click-outside is NOT a finalize trigger** — so the float stays live,
    and the next drag re-stamps it. THAT is the stamping in the report. TempodiBasic
    is on 2.0.3 (has BUG-B), so this is the remaining gap BUG-B did not cover.
### PROPOSED FIX (his idea — "a click should remove it"): make "click clearly OUTSIDE the float"
    a finalize trigger — commit the float once + deselect, matching the marquee's
    click-outside behavior. Consistent with the finalize-ONCE model (just another
    trigger alongside ESC/Ctrl+D), so it should not reintroduce the "trail of copies"
    BUG-B fixed. Implement in the MOVE press path (INPUT/MOUSE.BM, TOOL_MOVE dispatch)
    + `MOUSE_release_move` (INPUT/MOUSE.BM:3025); on a bare click outside the float
    bounds, call the existing finalize (MOVE_reset / commit-once) then MARQUEE_clear.
    Distinguish a bare click from a drag (<4px like the marquee) so it doesn't fire
    mid-reposition. ALSO surface deselect discoverability (status-bar hint / Edit menu).
    NOTE: overlaps the paste/float subsystem the SPLASH-OFF investigation is in
    ([[qa-splash-startup-state-dependency]]) — coordinate so the two don't collide.

## Open File dialog truncates filenames in the list (TempodiBasic 2.0.3 report)
- [ ] The Open (OPEN DRAW PROJECT) file dialog's NAME column is too narrow: filenames
      render truncated ("dr...", "fi...", "Un...", "Th...", "Te..."). The user must
      SELECT a file to read its full name at the bottom status line of the dialog.
  - [ ] Expected: filenames readable directly in the list (widen the NAME column /
        let it flex, or elide in the middle, or allow horizontal scroll / tooltip).
  - Location: the QB64_GJ_LIB modal file dialog (includes/QB64_GJ_LIB) as used by DRAW's Open.
  - FIX APPLIED (2026-09-06, lint-clean, pending visual screenshot verify): the Name
    column's floor was a hardcoded scale-1 constant `FD_columns(0).minWidth = 120`
    (FD-API.BM:637) while Type/Size/Modified scale their floors up with the font — so
    at DRAW's ~2x dialog scale Name got crushed to ~4 chars. Fix scales the Name floor
    with the content font to guarantee >=12 visible chars using the row renderer's own
    geometry (FD-API.BM ~553). Verified by math: scale1 11->12 chars (layout unchanged),
    scale2 4->12 chars. NOTE: this is the QB64_GJ_LIB SUBMODULE — commit lands there.
    Optional follow-up: middle-ellipsis to preserve the extension when still truncated.
