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

----

# RICKS ANSWERS:

## GENERAL GUIDANCE:

- KEEP the existing separate twin toolbox buttons - do not mess with the toolbox.
- KEEP the existing bar buttons and configuration - these are super helpful fast 1 ops.
- MAKE SURE that you put every option we can have in the SMART SHAPES - each shape has unique options, especially the dice one.
- ONLY THERE FOR TOOLS WITH OPTIONS - every tool should have at  least 1 option right? Which tools have no options?
- Make sure the docking is flexible, if it can be columnar/rows that's good because we can have it be flexible on left/right/top/bottom/float as the user wants it to be. 
- Make sure it uses universal slider control inputs, wheels, double clicks, middle clicks, etc.
- Make sure the scaling works properly
- While we want flexibility we also want it to not look shimmed in, make sure there are no useless gaps or dead space unless for example a tool has only 1 option, what I mean is lay the panel options out consistently. Any choices / controls that exist should be prioritized left -> right, on a horizontal format. THat prioritizatoin should follow in a vertical format, top -> down, make sense? If a panel cannot contain the options within it's height or width, it needs some facility to scroll/reveal the others. AVOID scrolling if possible, but if no way around it, then better to have - invisible scrollbars with wheel is ideal unless it's a picker of some kind with options in thumbnails, lists, dropdowns, etc. like we normally have every where else.

## PHASES RESPONSE:

1. OK
2. I AM NERVOUS about this since it's already so done, but yes. MAKE SURE all existing functionality stays intact. NO EXCEPTIONS. 
3. YES! GREAT!
4. NO, KEEP

## QUESTIONS ANSWERS:
1. ONLY THERE FOR TOOL OPTIONS - just make sure every tool has at least 1 option - answer ahead of time.
2. I would love it to be consistent and uniform, the UX should be obviously the same as much as possible just don't lose any functionality.
3. NO KEEP AS IS BARS - 1 ops
4. NO KEEP THE TOOLBOX AS IS - 1 ops


## Decisions (from Rick's answers, 2026-11-19)

- **Toolbox and edit / advanced bars stay as they are** (twin buttons, one-op buttons). Tool Options only adds.
- **Shown for every tool that has options**, which is every tool you stay in, so the bar is in
  practice always present while drawing and its space stays reserved. One-shot buttons (SAVE, OPEN,
  CODE, HELP, EXPORT SELECTION) keep the previous tool's options. PAN has only view controls
  (zoom −/+, 100%, fit, center): proposed to show those, Rick to confirm.
- **SMART SHAPES: every option of every kind**, per kind (the 3D cube / dice especially).
- **A normal dock panel**: top / bottom / left / right / float, as a row or a column. Controls in
  priority order, left → right in a row and top → down in a column. No dead gaps. Wrap before
  scrolling; overflow scrolls with the wheel under an invisible scrollbar. Pickers keep their
  usual lists and dropdowns.
- **Universal value inputs** everywhere: wheel, drag, double-click to type, middle-click to reset.
  Correct at display scales 1 / 2 / 3.
- **Phase 2 (Text Bar)**: move the existing Text Bar code into the panel; no rewrite. A parity
  checklist of every control and behavior, plus the existing text / Text Bar QA, must pass before
  and after. Any difference blocks the merge.
- **Phase 4 dropped** (keep the twins and the bar buttons).

## Build notes (phase 1, 2026-11-19)

- **Start from `GUI/SEL-BAR`.** It is already table-shaped: control ids (`SBC_*`) with a kind
  (chip / toggle / slider / button), label, on, value / lo / hi / set / reset, press, tooltip and
  dump, and `SELBAR_layout%` wraps the controls into lines across the width the dock gives, so a
  column dock already gets a narrow, many-line bar. Phase 1 = a per-tool list in `SELBAR_list%`
  (switch on `CURRENT_TOOL%`, the marquee keeps its variant switch unchanged), new ids per tool,
  `SELBAR_wanted%` for every tool with options, and the panel title / dump names. Rename the
  module to Tool Options (`TOPT_`) only once it has outgrown the selection tools.
- **Sliders stay the universal value input:** drag or click the track, wheel (Shift ×10),
  double-click the track to reset, double-click the value to type (`VAL_type%`), middle-click to
  reset.
- **Overflow:** today the bar grows a line per wrap (`DP_H_FIXED`, `SELBAR_h_for%`). Add the
  invisible wheel scroll only for a floating or column bar shorter than its lines.
- **QA geometry:** a bar shown for every tool moves the canvas down in every test. `QA/DRAW.qa.cfg`
  should set `SELECTION_BAR=FALSE`, and the Tool Options tests turn it on with
  `QA-OPTIONS: SELECTION_BAR=TRUE`, as the selection-bar tests already can. Otherwise ~600 tests'
  canvas coordinates shift.
- **The transient row** (`DOCK_row_transient%` + `DOCK_SHIFT_Y`) can go once the bar is shown for
  every tool you stay in. Keep it until then: one-shot buttons and Pan (if Pan shows nothing)
  would still make the bar come and go.

## Status

- **Phase 1a** (branch `tool-options`): `SELBAR_wanted%` = the current tool has a list
  (`SELBAR_list%` switches on `CURRENT_TOOL%`; the marquee's list is `SELBAR_list_select%`,
  unchanged). The dump's `SELBAR` line ends with the tool id.
- **Phase 1b**: the shared painting set, `SELBAR_list_paint%`, for brush / dot (with PIXEL
  PERFECT), eraser / spray / line / rect / ellipse / polygon / bezier, and the filled shapes without
  SIZE / SHAPE. Ids 24-38 (`SBC_P_*`, labels `SBC_L_*` = kind 5). SIZE is an index shown and typed
  in px; SOFT only for a round or slant nib; SIZE / SHAPE hidden with a custom brush up. Symmetry
  chips reach a mode by cycling (`SELBAR_sym_mode`), so a centre the user set is kept, as F7 does.
  Dump line `SELBARP size px shape soft opacity pp aa sym`. QA: `tool-options-paint.sh`.
- **QA**: qa-harness `_qa_cfg_overrides` pins `SELECTION_BAR=FALSE`; the bar tests opt in.
- **Phase 3, line + shapes**: line START / END cap chips (ids 39-48), SPOKES (49), SNAP chips
  15 / 30 / 45 / 90 + PIXEL (50-55, they set `CFG.ANGLE_SNAP_*` and save); rectangle DIVIDE | /
  DIVIDE - (56-57); ellipse SLICES / RINGS (58-59); polygon FINISH / CANCEL (60-61); bezier
  HANDLES / COMMIT / CANCEL (62-64). Decision 1 as built: `LINE_TOOL.BAR_SPOKES / BAR_START_CAP /
  BAR_END_CAP`, `RECT_TOOL.BAR_H_DIV / BAR_V_DIV`, `ELLIPSE_TOOL.BAR_SLICES / BAR_RINGS` take the
  place of the zeros at press, at commit and in the `*_reset` SUBs, so each new shape starts with
  them; keys pressed while dragging change only that shape. Dump line `SELBARS spokes sc ec deg
  px hdiv vdiv slices rings`. QA: `tool-options-shapes.sh`.
- **Phase 3, smart shapes** (ids 65-116): every smart shape shows the KIND chips (one per
  `TOOL_SS_*`, they call `SMART_SHAPES_choose`, the toolbox twin's child pick), OUTLINE /
  FILLED (`SS_BAR_FILLED`; the right button still flips it for one shape - press sites read
  `B2 XOR SS_BAR_FILLED`), then the shape's own options from `SS_*`: polygon SIDES / DEPTH /
  SNAP / LOCK, pie SLICES / HOLE, rounded / tab RADIUS, tab FLAT corners, pill ROUND, pac-man
  SEGMENTS / MOUTH / HOLE, dice D0-D6 + DEPTH / TILT / TURN (the cube reads WIRE / SOLID), the
  LIGHT azimuth / elevation / intensity shared by the 3D shapes, bevel BEVEL / BORDER / INNER /
  OUTER, arrow STEM / HEAD / FLARE, 3D text THICK + DEPTH / TILT / TURN. Middle-click resets to
  the shape's default (`SELBAR_ss_def%`). Dump `SELBARSS`. QA: `tool-options-smart.sh`.
- **Phase 3, fill / spray / picker** (ids 117-141, new cfg keys in `[SELECTION]`):
  - fill SAMPLE chips LAYER / MERGED / ALL LAYERS / REPLACE ALL (`FILL_SAMPLE`; Shift still does
    merged / replace for one click), TOLERANCE (`FILL_TOLERANCE`) + CONTIGUOUS
    (`FILL_CONTIGUOUS`), GRID CELL (908) / ADJUST (909), BLEND chips (`GRADIENT_BLEND_SPACE`).
    A tolerance above 0 or CONTIGUOUS off fills through `FILL_flood_tol`, which takes the magic
    wand's mask (`MAGIC_WAND_mask&`, the same native flood and the same largest-channel metric
    as `WAND_TOLERANCE`) and paints it with the paint colour / drawer / selection / lock rules.
    **Fill Adjust floods stay exact** (the adjust session owns its own region), and DITHER stays
    in Fill Adjust (D) - it is a property of the adjust session, not of a click.
  - spray SPREAD / DENSITY / FLOW % (`SPRAY_SPREAD / DENSITY / FLOW`, 100 = as before), scaled
    after the caps; FLOW shows with the airbrush (AA on, the chip reads AIRBRUSH).
  - picker SAMPLE MERGED / LAYER / REFERENCE (`PICKER_SAMPLE`), AREA 1 / 3X3 / 5X5
    (`PICKER_SAMPLE_SIZE`, the average of the on-canvas pixels), LOUPE zoom (0 = the theme's).
    `PICKER_sample~&` is the one sampler; the loupe's swatch uses it too.
  - Dump `SELBARF`. QA: `tool-options-fill.sh`.
- **Phase 3, brush / eraser / MyPaint / move / crop / view** (ids 142-173):
  - brush MIX (2026) - with it on SMUDGE / LENGTH / RADIUS (`BRUSH_MIX_*`) - and TILE (440,
    shown while the canvas allows it); dot keeps the shared set only.
  - eraser ALL LAYERS (`ERASER_BAR_SMART`, this session): smart erase without Shift; Shift then
    erases the current layer only (`ERASER_smart_now%` = Shift XOR the toggle).
  - MyPaint: SIZE (DRAW's, or the brush's own when SIZE = BRUSH is off), SIZE = BRUSH (2690),
    OPAQUE / PRESSURE / TWIST (the MyPaint Brush Settings' sliders, `MPS_get / MPS_set`),
    BRUSHES / SETTINGS (the two panels). The settings panel stays for the full list.
  - move: FLIP H / V, ROTATE CCW / CW, SCALE 50% / 2X (the Edit menu's 315-320). CONSTRAIN /
    WHOLE LAYER / CLONE from the inventory are not settings DRAW has: not added.
  - the transform overlay, whatever the tool: APPLY / CANCEL (Enter / Esc).
  - crop (it runs on the marquee): W / H of the box, APPLY / CANCEL, TRIM, WHOLE IMAGE. An
    ASPECT lock needs the marquee to keep one while dragging: deferred.
  - zoom and pan (decision: PAN shows the view controls): ZOOM - / + / 100% / FIT / CENTER.
  - Dump `SELBARM`. QA: `tool-options-more.sh`.
- **Docking**: the bar was already a dock panel (`DP_SELBAR`, `DP_H_FIXED`, as the text bar):
  its height is its lines at the width it gets, in a row, a column or floating, at its own
  Scale. A bar given less height than its lines scrolls by whole lines with the wheel off a
  slider, no scrollbar drawn (`SELBAR.scroll`, dump `SELBARV scroll contentH`). QA:
  `tool-options-dock.sh` (top / left / right / bottom / float / 3x; every control inside, no
  dead gap, a control works in each place).
- **Deferred**: the bezier CORNER toggle. `BEZIER.IS_CORNER` is never read, so a chip would do
  nothing; it waits until corner points are built.
