# Tool Options bar — draft plan (2026-11-19)

Rick: "we can save some more room having options for each tool like photoshop - a context
sensitive bar". Draft for review; nothing is built yet beyond the rename.

## The idea

One dock row, **TOOL OPTIONS**, whose contents follow `CURRENT_TOOL%`. It grows out of the
Selection Bar (`GUI/SEL-BAR`, `DP_SELBAR`), which already is this for the selection tools, and
the Text Bar, which already is this for the text tool. Settings that today sit in menus, the
edit / advanced bars or separate panels get one obvious home per tool.

**Always shown, always reserved.** The row stays (with the tool's name and a hint when a tool has
nothing to set), so picking a tool never moves anything. That's the "reserved" feel Rick prefers,
and it **removes** a state rather than adding one: the transient top row (`DOCK_row_transient%`,
the shift that keeps the canvas still when the Selection Bar comes and goes) is no longer needed.

## Every painting tool (left part of the row)

`SIZE` · `SHAPE` (round / square / custom brush) · `EDGE` (pixel-perfect / anti-alias: today the
shared button, action 959 / 960) · `PRESSURE` (on / off, → Pen Control) · `SYMMETRY`

## Per tool (right part)

| Tool | Options | Today |
|------|---------|-------|
| BRUSH | SOFT · MIX (RADIUS / LENGTH / SMUDGE) · PATTERN TILE | `BRUSH_SOFT`, `BRUSH_MIX_*` (menu / Brush Palette), View > Pattern Tile Mode |
| DOT | the common set only | — |
| LINE | START CAP · END CAP · STICKY END CAP · SPOKES | line caps (keys only) |
| RECT / ELLIPSE / POLYGON | OUTLINE ⇄ FILLED (merges the "filled" twin tools) · CORNER (rect) | separate toolbox buttons |
| SMART SHAPES | KIND · SIDES / RADIUS / ANGLE (per kind) · OUTLINE ⇄ FILLED | shape-specific keys |
| BEZIER | CLOSE PATH · SHOW HANDLES · COMMIT / CANCEL | keys |
| FILL | TOLERANCE · CONTIGUOUS · SOLID / GRADIENT / DITHER · PRESET · BLEND SPACE | `FILL_DITHER`, `FILL_PRESETS`, `GRADIENT_BLEND_SPACE` (Settings / menus) |
| SPRAY | RADIUS · DENSITY · DOT SIZE | — |
| ERASER | SIZE · SHAPE · SOFT | shares the brush's |
| PICKER | SAMPLE: LAYER / MERGED · SETS: FG / BG | modifier keys |
| MYPAINT | BRUSH (set ▾ name) · SIZE · OPAQUE · TWIST · SIZE FROM BRUSH · MOUSE PRESSURE | MyPaint Brush Settings panel (stays for the full list) |
| MARQUEE / LASSO / POLY LASSO / WAND | today's Selection Bar: MODE chips · SHAPE · FEATHER · ANTIALIAS · GROW · SMOOTH · FROM CENTER; wand: TOLERANCE · CONTIGUOUS · SAMPLE MERGED | `GUI/SEL-BAR` |
| MOVE / TRANSFORM | FLIP H / V · ROTATE ±90 · SCALE ½ / 2× · CONSTRAIN · WHOLE LAYER · CLONE · APPLY / CANCEL | Edit menu, keys |
| TEXT | today's Text Bar: FONT ▾ · SIZE · STYLE · ALIGN · SYNC STYLE | `TEXT_BAR` (folds in, phase 2) |
| CROP | ASPECT ▾ · W × H · APPLY / CANCEL | — |
| ZOOM / PAN | ZOOM − / + · 100% · FIT | View menu |

## What it frees

- View menu: TOOL OPTIONS replaces SELECTION BAR (done) and the TEXT BAR toggle (phase 2).
- Edit / advanced bars: the per-tool buttons (the edge button, flips / rotates) can leave them,
  or stay. Rick's call.
- Toolbox: the filled-shape twins (rect / ellipse / polygon filled) could become one button each.

## Phases

1. **Generalize the bar.** `SELBAR_wanted%` → shown for every tool. Each tool gets a list of controls
   built from the widgets the bar already has (chips, toggles, sliders, the universal value input),
   and a per-tool table rather than per-tool code. Selection tools keep exactly what they have.
   QA: `sel-bar`, `selbar-value-input`, `sel-bar-tips`, plus one test per tool group (controls
   present, a change sticks, an undo works).
2. Fold the Text Bar in. It becomes the text tool's options, with one row instead of two.
3. Add the new per-tool controls tool by tool (FILL, LINE, SPRAY, PICKER and CROP first: they have
   settings with no home today).
4. Optional: drop the filled-shape twins from the toolbox, and the duplicated bar buttons.

## Open questions for Rick

1. Always shown (recommended: no jumping, one state fewer), or only for tools with options?
2. Fold the Text Bar in (phase 2), or keep it separate?
3. Should the edge button and flips / rotates leave the edit / advanced bars once they're here?
4. Merge the outline / filled twin tools into one tool with an OUTLINE ⇄ FILLED option?
