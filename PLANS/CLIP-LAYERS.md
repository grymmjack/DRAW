# Clip layers - design note

Status: **proposal, no code yet** (2026-11-12). Item 3 of the Round 3 handoff
(PLANS/ANIMATION.md, "Round 3"). Rick picked "clip layer" over the other options; this note is how
I'd build it. Please read the "Open questions" at the end before I start.

## In one paragraph

A clip layer plays an AnimBrush across the frames instead of stamping it. You place it once;
DRAW works out which cel shows in each frame (start, rate, loop / ping-pong / once / hold) and
draws it into that frame's cell. Change a setting and every frame updates. **Bake to Pixels**
turns it into a normal layer. Later, keyframe lanes (position, scale, rotation, opacity, tint)
attach to the clip, so the Move Brush's moves become live and editable instead of baked.

## What it looks like to use

1. Pick up a walk cycle (hold B + select, or ANIM > AnimBrush > Pick Up).
2. ANIM > Clip > **Place AnimBrush as Clip**, click in a frame. A new layer "walk (clip)"
   appears above the current one. Its first cel lands in the current frame, and the cycle
   runs to the last frame.
3. In the Animation panel's Clip section (or a Clip Settings dialog) set:
   - **In / Out**: the first and last frames it shows in (empty outside them)
   - **Start cel**: which cel shows on the In frame
   - **Every N**: a new cel every N frames (1 = every frame, 2 = on twos)
   - **Mode**: Loop, Ping-pong, Once (gone after the last cel), Hold (stays on the last cel)
   - **Flip** X / Y
4. The Move tool on a clip layer drags the whole clip (every frame).
5. Painting on it is refused with a message, as on a symbol copy:
   "Bake to Pixels to paint on it".
6. Duplicate Layer makes a second instance that shares the same cels, offset with Move.

## The main decision: a generated layer, not a render-time draw

A clip layer keeps an ordinary sheet-sized image (`imgHandle&`). DRAW **rebuilds** that image
from the clip whenever the clip changes, the same way a symbol copy is rebuilt from its parent
(`SYMBOL_render_child`) and a text layer from its words. Nothing else has to know clips exist,
because every consumer already reads `imgHandle&`:

- the canvas render (`RENDER_layers`) and the scene cache
- the lightbox panes, Big Frame, onion skin and playback
- `LAYERS_flatten&`, which every exporter goes through:
  - GIF, APNG, sheet + JSON, PNG sequence, the .bas player (ANIM-EXPORT.BM, 6 calls)
  - PNG / BMP / JPG etc., the ANS export, the pixel analyzer
- the flat PNG inside a .draw

The other way, drawing cels at render time, would mean teaching ~10 composite paths about clips
and keeping them in step forever. Rejected.

Cost: one sheet-sized image per clip layer, which any pixel layer costs too. A rebuild is one
cel blit per frame (64 frames is nothing). It only runs when something changed:

- the clip's settings
- its cels
- the frame layout or count
- undo / redo

Only the cells whose cel changed are redrawn, and the layer is marked `contentDirty%`
(gotcha 10).

## Data

Two levels, like Flash's symbol / instance:

- **Clip sources**: a document-level table. Each source has:
  - a name (the AnimBrush's tag name)
  - the cel strip (image), n, cw, ch
  - the anchor
  - provenance: the bin slot it came from, used only by an explicit "Update from Bin"
- **Clip instances**, one per clip layer. Each instance has:
  - the source index
  - In, Out (0 = to the last frame)
  - start cel, Every N, mode, flip X / Y
  - anchor position (frame coords, relative to the cell's top-left)
  - later: keyframe lanes

  The layer's own opacity, blend mode and visibility apply as for any layer.

```
TYPE CLIP_SRC_OBJ     ' CLIP_SRC(1 TO CLIP_SRC_MAX)
    nm AS STRING * 32: strip AS LONG: n AS INTEGER: cw AS INTEGER: ch AS INTEGER
    ax AS INTEGER: ay AS INTEGER: binSlot AS INTEGER: refs AS INTEGER
END TYPE
TYPE CLIP_INST_OBJ    ' CLIP_INST(1 TO CLIP_INST_MAX), found by layer historyId
    layerId AS LONG: src AS INTEGER: inF AS INTEGER: outF AS INTEGER
    startCel AS INTEGER: every AS INTEGER: mode AS INTEGER: flip AS INTEGER
    px AS INTEGER: py AS INTEGER
END TYPE
CONST LAYER_TYPE_CLIP = 6
```

Which cel shows in frame f (a pure function, unit-tested like TOOLS/ANIM's math):

```
if f < In or f > Out:  none
k = (f - In) \ Every                          ' steps since In
Loop:      cel = (Start - 1 + k) MOD n + 1
Ping-pong: i = (Start - 1 + k) MOD (2n - 2); cel = i < n ? i + 1 : 2n - 1 - i   (n = 1: cel 1)
Once:      i = Start - 1 + k; cel = i < n ? i + 1 : none
Hold:      cel = MIN(Start - 1 + k, n - 1) + 1
```

These are the AnimBrush's own step orders (FWD / PING / ONCE), so a baked stamp and a clip
agree. Reverse is the same with the strip read backwards (one more mode, cheap to add).

## How it fits the sprite-sheet model

| Area | Behaviour |
| --- | --- |
| Frame ops (insert, delete, move, reorder, resize) | A clip layer's pixels don't move with the frames: add it to the "stays put" list in `ANIM_OPS_moves%` with text and symbol copies. Its In / Out are remapped through the plan (`ANIM_SRC`), the way tags are (`ANIM_TG_remap`), then it rebuilds. |
| Frame size / layout / canvas resize | Rebuild. The anchor is relative to the cell, so it stays in place in each frame. |
| Linked cells, SAME layers | Not on clip layers: refused with a message (the clip already decides every cell). |
| Painting, fill, eraser, Paste | Refused, using the same gate as symbol copies (INPUT/MOUSE.BM ~4574). |
| Move tool | Moves the instance's position (all frames). With lanes later: sets the key at the current frame. |
| Merge Down / Flatten / Rasterize | Bake first (the image is already right; the layer becomes IMAGE and the instance goes). |
| Delete layer | The instance goes. A source with no instances is dropped on save. |
| Onion skin, lightbox, Big Frame, playback, exports | Nothing to do: they read the generated image. |
| QB64 source export (FILE-QB64.BM) | It special-cases symbol copies in many places. A clip must go down the plain-image path; that needs checking. |

## Saving (.draw)

- **drAw holds the clip layer as an ordinary IMAGE layer**, with the generated pixels.
  - No `DRW_VERSION` bump: an older DRAW refuses a newer version outright ("File was created
    with a newer version of DRAW"). An older DRAW opens the file and sees the clip baked.
  - Any PNG viewer sees it too.
- **A new ancillary chunk `drCl`** holds:
  - a version
  - the sources (name, n, cw, ch, anchor, the strip's BGRA deflated)
  - the instances, keyed to their layer the same way drAn keys linked cells to layers
  
  It is read after drAw / drAn. Each layer it names becomes `LAYER_TYPE_CLIP` and rebuilds;
  the rebuild should match the pixels already loaded, which a test checks.
- Caveat: an older DRAW that re-saves the file drops drCl. The clip stays as baked pixels and
  nothing is lost. The manual will say so.
- `.dset` and drAb are not affected: clips belong to documents, AnimBrushes to bins.

## Undo

- **Place as Clip**: a LAYER_ADD record plus the instance (and source if new) in its payload.
  Undo removes both.
- **Settings and position edits**: a new `HISTORY_KIND_CLIP = 22`. Its payload is the instance
  record before and after (a few dozen bytes); undo / redo copy it back and rebuild. One record
  per finished edit: a drag is one step, not one per frame.
- **Bake to Pixels**: reuse `HISTORY_KIND_RASTERIZE` (15) the way text layers do, with the
  instance in the payload, so undo brings the clip back.
- **Frame ops**: `HISTORY_KIND_ANIM_FRAMES` snapshots already carry tags and links. They must
  also carry the instance records (In / Out change).
- Note: flipping a symbol copy (action 315) is not an undo step today. Clips won't copy that.

## Commands

Action ids **2620-2629** (free as of today; grep again before allocating, gotcha 17):

| Id | Command | Menu |
| --- | --- | --- |
| 2620 | Place AnimBrush as Clip (click to place) | ANIM > Clip |
| 2621 | Bake Clip to Pixels | ANIM > Clip, Layer menu, layer right-click |
| 2622 | Clip Settings... | ANIM > Clip, layer right-click |
| 2623 | Update Clip from Bin | ANIM > Clip |
| 2624 | Make Clip from Selected Frames (pick up + place) | ANIM > Clip |

- **Layer panel**: a clip badge on the row (like the symbol / text badges).
- **X-sheet**: in phase 2, a clip row shows a bar from In to Out with the cel number in each
  cell; drag its ends to set In / Out.
- **QA dump lines**:
  - `CLIP layer src in out start every mode px py`
  - `CLIPC layer` plus the cel per frame (a string like `1234123412`)
  - `CLIPS src name n cw ch`

## The three document paths (gotcha 15)

Clear the source and instance tables (and free the strips) in all three:

- `DRW_load_binary`
- `DRW_new_canvas`
- `DRW_create_canvas_at_size`

A step in `clip-place.sh` checks it: place a clip, File > New, then no CLIP lines.

## Keyframe lanes later (own spec)

The instance is where lanes attach. Each property (pos X / Y, scale X / Y, rotation, opacity,
tint, origin) gets a list of keys (frame, value, stepped / linear / Bezier). The rebuild
evaluates them per frame and draws the cel through **`MVB_stamp_xf`**, the Move Brush's
transform with nearest sampling, so a live clip and a baked Move Brush look the same.

- Pixel integrity (whole-pixel positions, nearest / RotSprite) belongs in that spec.
- So do seeded LFO / noise modulators.
- So does "record a Move Brush as clip lanes" (the Move panel's values become two keys).

Phase 1 keeps that door open, but ships none of it.

## Phasing

1. **MVP**:
   - sources and instances; the generated layer and rebuild; the cel-for-frame math with a
     unit test
   - Place / Bake / Settings; In, Out, Start, Every N, the four modes, flip; Move drags it
   - painting refused; frame ops remap In / Out
   - drCl save / load; undo (CLIP kind, rasterize, frame-op snapshots)
   - QA dumps; the three document paths; manual section and SHORTCUTS rows
2. **Editing**:
   - the X-sheet clip row with In / Out drag
   - Update from Bin; Make Clip from Selected Frames
   - a Clip Sources list (rename, see which layers use a source)
   - edit a source's cels: open them as a sheet, then Apply
3. **Keyframe lanes and modulators**: the separate spec, then build.

## QA plan (phase 1)

New tests:

- `clip-place.sh`: place, check the CLIPC cel string for each mode, flip, and that In / Out
  frames are empty outside the range
- `clip-math` unit test: CLIP_cel_for for n = 1, 2, 5, every = 1 / 3, every mode, start > 1
- `clip-frameops.sh`: insert, delete, move and resize frames, then In / Out / CLIPC after each
- `clip-save-load.sh`:
  - save, reopen: same CLIP / CLIPC and the same pixels
  - the drAw layer is type IMAGE (chunk read by a Python helper)
  - the flat PNG shows the clip
- `clip-undo.sh`: place / settings / move / bake / frame op, each undone and redone
- `clip-export.sh`: GIF, APNG, sheet and PNG sequence of a clip match the same scene baked
  (RMSE 0)
- `clip-refuse.sh`: brush, fill and eraser on a clip are refused; links and SAME are refused

Existing tests to rerun:

- anim-frame-ops, anim-links, anim-tags, anim-xsheet, anim-lightbox, anim-move
- file-anim-gif / -apng / -sheet / -bas / -chunk
- layer-duplicate, layer-merge, layer-new-delete, animbrush-step-modes

That is about 22 files. I'll give the count and an ETA before running.

## Open questions for Rick

1. **Where the cels live.** You said "a bin brush reference". I'd **copy** the cels into the
   document (a shared source table) and keep the bin slot only so "Update from Bin" knows
   where to look. A live reference to a bin breaks when the bin changes or the file goes to
   someone without your drawer. OK?
2. **Once mode after the last cel**: empty (my pick, since Hold covers "stay on the last
   cel"), or hold?
3. **Where it starts**: In = the frame you click in (my pick), or always frame 1?
4. **Painting on a clip**: refuse with a message (my pick), or offer "Bake and paint"?
5. **Settings UI for phase 1**: rows in the Animation panel (my pick), or a dialog? The panel
   already swaps its rows: frame rows normally, the Move Brush rows (FRAMES, MOVE XYZ, TURN XYZ,
   SIZE %, OPACITY, TINT %, CEL EVERY) while the Move Brush is on. Clip rows would show the same
   way while the current layer is a clip layer.
