# X-sheet: per-layer holds + automation lanes

Branch `xsheet-holds-lanes` (from v2.8.0), started 2026-11-16.

Rick: "can DRAW support per layer hold times? i don't see a way to do that?" ...
"i also would love to see automation lanes exposed for all the automations / properties;
x, y, scale, rotation, opacity, tint, volume, pan, etc. like disclosure lanes under each
layer in x-sheet if it's enabled" ... "then i could see ease in, ease out, ease in/out,
linear, etc. in a bezier curve/plot".

## Decisions (Rick, 2026-11-16)

| Question | Answer |
|----------|--------|
| Lane rows shown | Only the lanes in use, plus a **+ LANE** add menu |
| Which layers get lanes | **All layer types** - pixel layers, groups and clips |
| Shrinking a hold: the cells let go | **Go blank** |
| Lane text | The **Tiny5** font, **UPPERCASE** labels (consistent with the rest of the X-sheet) |

## Phase 1 - per-layer holds (done)

A layer's drawing held for N frames is N linked cells in a row (one link group), so saving,
undo, frame operations and paint-through all come from the existing linked-cells code.

- Drag a cell's right end on its X-sheet row to stretch / shrink that layer's hold.
- A held run draws as one cell: thumbnail, hold line with a tick per frame, end bar.
- Right-click a cell: Hold for N Frames... · Release Hold · Link / Unlink Cells · Layer Menu...
- ANIM > Hold for N Frames... (2610) / Release Hold (2611), command palette too.
- QA: `QA/tests/anim-layer-holds.sh`. Internals: `.claude/instructions/draw-animation.md`
  "Per-layer holds".

## Phase 2 - lane disclosure rows (clips first) - done for clips

- A `▸` / `▾` disclosure before a clip layer's name (`TOOLS/ANIM-XLANE`, QA `clip-lane-rows.sh`).
- Open: one row per lane in use - name in the name column (Tiny5, UPPERCASE: `X`, `Y`,
  `SCALE X`, `ROTATE`, `OPACITY`, `TINT`, `VOLUME`, `PAN` ...), then along the frames:
  - keys as diamonds (the ease reads from the curve; ease-shaped diamonds: not yet),
  - the value as a **plotted curve** between keys, drawn with its ease: LINEAR a straight
    segment, IN / OUT / IN-OUT the eased curve, HOLD a step,
  - the row's value range scaled to the row height (the value now at the name column's
    right; min / max labels: not yet),
  - a modulator drawn as a faint wave over the curve.
- Last row: **+ LANE** - a menu of the lanes not shown yet.
- Edit in place: double-click empty = add a key at the curve's value; drag a diamond horizontally
  = retime, vertically = value (Shift: one axis); double-click = type the value; right-click
  = ease (HOLD / LINEAR / IN / OUT / IN-OUT), delete key, modulator...
- One undo step per edit (the CLIP_KEY undo the LANES row uses now).
- Later: draggable bezier handles for custom eases.

## Phase 3 - lanes on every layer type

- Pixel layers and groups get the same lanes (X, Y, scale, rotate, pivot, opacity, tint;
  volume / pan only where there is sound).
- Applied **non-destructively at render** through the clip transform path (`XF_draw`):
  the layer's pixels never change.
- Every path must apply them: canvas, lightbox panes, onion skin, playback, full-screen
  preview, flatten / merge, every exporter (GIF, APNG, PNG sequence, sheet, `.bas`).
- Saved in the `.draw` file (a new drAn version / chunk); undo with the lane edits.

### Phase 3 design (2026-11-16, after reading the render pipeline)

Every view of the frames reads the **composite**: the canvas (`RENDER_layers`), the lightbox
panes, onion skin and playback (they cut cells out of the composite), the Preview window
(`CANVAS_CONTENT_SRC&`), and every export plus the full-screen preview (`LAYERS_flatten&`).
So, like a clip layer (whose `CLIP_rebuild` writes its transformed cels into its own buffer),
a laned layer is shown through a **display copy**:

- `TOOLS/LAYER-LANES` (`LL_`): a table keyed by layer `historyId` - per lane keys + modulator
  in the clip encoding (8-byte keys, rel = frame - 1), and a tint colour. Lanes X, Y,
  SCALE X / Y, ROTATE, OPACITY, TINT, PIVOT X / Y (no VOLUME / PAN: pixel layers and groups
  have no sound). Pivot default = the cell's middle.
- `LL_display&(slot)`: the layer's pixels with each frame cell drawn through that frame's
  lanes (`XF_draw`, the clip path) - the layer's own, then each enclosing group's, inner to
  outer - **clipped to the cell** (a frame is its cell; what moves out of it is not shown).
  Gutters / margins are copied as they are. Cached per slot by a signature (lanes, layout,
  history position, image handle) and rebuilt while the layer's `contentDirty%` is set, so a
  stroke shows as it is painted.
- The renderer swaps it in where it picks `layerRenderSource&` (not during a Move preview),
  the trivial one-layer fast path bails for laned layers, and `LAYERS_flatten&` uses a
  freshly built one (exports never see a stale cache).
- Groups: a group's lanes apply to **each child** (composed with the child's own), not to the
  group's isolated buffer - so a faded group fades each child, which differs from an isolated
  group's single fade where children overlap (field kit: decide).
- The layer's pixels never change; painting a laned layer paints its own pixels (the stroke
  appears transformed, as in any non-destructive transform - field kit: decide).
- Undo: a lane edit is a history record of the layer's lanes blob before / after.
- Saved in a `drLL` PNG chunk (historyId, lanes blob); older DRAWs skip unknown chunks.

