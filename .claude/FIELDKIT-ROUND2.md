# Field-kit cards queued for round 2 (published together at the end of the loop)

Each: title · steps · why it needs Rick (reproduce / judge / decide).

## Key box (X-sheet lane rows)
- **Box-select keys** — open a layer's lanes (two lanes with keys); drag on EMPTY lane space across
  both rows. Judge: the shading / outline / filled keys read clearly in your theme; the crosshair
  shows over empty lane space, the move pointer inside the box.
- **Drag the box** — drag inside it a few frames right, then left past frame 1. Judge: it feels
  right that keys it lands on are replaced, and that it stops at the first frame.
- **Alt+drag copies** — Alt while dragging inside the box (press first, then Alt). Reproduce on the
  real desktop: Alt+press with Alt already down (Xvfb can't deliver that press) - does it copy, and
  does KDE grab Alt+drag as a window move?
- **Copy what you see** — box frames between two keys, Ctrl+C, go to an empty stretch, Ctrl+V. Judge:
  the pasted curve matches the copied one.
- **Paste onto another layer** — copy from layer A, select layer B, Ctrl+V. Decide: is "current
  layer's lanes of the same kind" the right target (vs. the layer under the box)?
- **Ctrl+V precedence** — copy keys, then copy pixels, then Ctrl+V. Decide: pixels win once copied
  later - right?

## Top / bottom docks, Browser columns, colour strip on any edge
- **Dock a bar along the top / bottom** — right-click the Toolbox's (or Edit Bar / Advanced Bar /
  Organizer / Drawer / Swatches / Browser) handle → Dock Along the Top; then another one along the
  bottom; drag a third beside the first. Judge: the rows read as rows (under the menu bar / above
  the colour strip), the canvas shrinks to fit, nothing overlaps; the drawer's bins fit the row.
- **Row width setting** — Settings → Panels (Top/Bottom Docks: Between / Full Width) with a left
  and right column docked. Judge: "between the side docks" is the right default.
- **Browser in a column** — the Browser's handle → Dock Left, then drag it below the layers.
  Reproduce: browsing / thumbnails / scrolling work in a narrow column.
- **Colour strip on the left / right / top** — right-click a blank part of the strip → EDGE →
  Left (then Top, Right, Bottom). Judge: the column of chips, the dropdown ABOVE them, the ▲/▼
  buttons; the docks sit beside it; the palette menu opens beside it. Decide: is the 20 px
  minimum width / one column of chips right, or should a side strip be wider by default?

## Lane thumbnails on the main X-sheet row
- **A ball held and keyed** — draw a ball in frame 1, hold it to the last frame, + LANE > X with keys
  on 1 and 6 frames apart. Judge: the main row shows the ball at each key where the canvas shows it,
  the hold line between them. Header right-click → Lane Thumbnails: Every Frame / Off.
- **A group's composite** — put two keyed layers in a group, give the GROUP a lane (X keys). Judge:
  the group's row shows both layers together at the group's keys (no opacity / blend modes in the
  thumbnail - decide whether that matters).

## X-sheet layer multi-select
- **Select, group, drag** — Ctrl+click two layer names on the X-sheet, Ctrl+Shift+G; drag a third
  name above one of the group's layers, then a child out to the top. Judge: the shading of the
  selected names, the gap bar while dragging; it behaves like the Layers panel (decide if any
  difference matters, e.g. Shift+click is a toggle there too, not a range).

## Blend lane
- **Modes per frame** — duplicate a layer, open the copy's lanes, + LANE > BLEND, right-click
  frame 3 on the BLEND row → Difference; play it. Judge: frames 1-2 normal, 3+ black (difference
  of a picture with itself) on canvas, lightbox, playback and an exported GIF.

## Modulator: curve, per key, envelope, sub-lanes
- **The real wave on the curve** — + LANE > Y, LFO Sine, period 8. Judge: the lane row draws the
  wave itself (bright) over the faint key curve, with a tiny sine glyph right of the first key.
- **One-shot bounce** — a key on a landing frame → From This Key: One Cycle (One-Shot). Judge: one
  bounce then still; the glyph fainter on that key.
- **Envelope** — Modulator Envelope… `6 4 40 3`. Judge: the wave swells, settles, fades before
  the next key; the little dots at the phase ends read as phase ends, not noise.
- **Frequency / amplitude lanes** — on that modulated lane: Add Frequency Lane, key 12 then 2 a
  few frames later; Add Amplitude Lane, key 0 then 4. Judge: the "Y ~FREQ" / "Y ~AMP" rows under Y
  read as belonging to it; the wave speeds up / grows smoothly (no jump where FREQ changes).

## Effect lanes: BLUR, PIXELATE, INVERT, NOISE
- **Each effect** — on a sprite layer: + LANE > BLUR (0 → 4 over 8 frames), PIXELATE (1 → 8),
  INVERT (0 → 100), NOISE (40). Judge each on the canvas, playback and an exported GIF: a blur
  with soft edges, blocks that don't go black at the sprite's edge, a smooth invert ramp, static.
- **Frozen grain** — right-click a NOISE key → From This Key: Frozen Grain. Judge: the grain stops
  changing until the next key. Decide: is mono grain (no colour speckle) right, or do you want a
  colour-noise choice too?
- **Speed** — a big sheet (e.g. 64 frames of 128×128) with a BLUR lane at 8: move a key. Judge:
  the rebuild pause after the drag is acceptable (every frame is re-baked once).

## Top / bottom dock rows (Rick's screenshots, 2026-11-16)
- **Organizer beside the toolbox** — right-click the toolbox handle → Dock Along the Top, then the
  organizer's → Dock Along the Top. Judge: the row stays the toolbox's height; the organizer shows
  its 4 stack tops, and Symmetry / Grid Visibility / Grid Snap / Color Mode sit in a 2×2 grid to
  their right, nothing hanging below the toolbox.
- **Bars as one grid** — dock the Edit bar and the Advanced bar along the top. Judge: their icons
  are an even grid, every column full but the last, no gaps where the dividers were. Decide: is
  losing the divider grouping in a row OK, or do you want a thin line between groups?
- **Resize along the row** — drag a row panel's right edge (e.g. the Workflow buttons in a bottom
  row) wider, then narrower; double-click the edge. Judge: the ↔ cursor shows on the edge; it
  never gets narrower than fits; double-click puts it back; the width survives a restart.
- **Drawer zoom in a row** — Dock Along the Bottom for the Drawer, Ctrl+wheel down / up over the
  bins. Judge: 2, 3… rows of smaller bins, then back to one row; the zoom survives a restart.
- **Organizer one button high** — with the organizer in a top row beside the toolbox, drag the
  row's lower edge up as far as it goes. Judge: the organizer lies flat in one line, Opacity and
  Brush Size on their side; dragging along them sets opacity / brush size left → right.
- **Color pickers sideways** — Dock Along the Top for the Advanced Color Picker and the Color
  Mixer beside the toolbox. Judge: the row stays the toolbox's height (no gap under the toolbox);
  the wheel / color field fits the row; the quantize slider + VARIATIONS, or OLD / NEW + MORE, sit
  to the right; open VARIATIONS / MORE and the rows go further right in columns; every control
  still works there (sliders drag, the hex box types, the gear opens Settings). Decide: is a tiny
  wheel at 2 toolbox buttons usable, or should the row grow for it?
