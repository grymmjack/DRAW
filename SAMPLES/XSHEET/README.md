# X-sheet examples: per-layer holds and keyframe lanes

Three small projects (32 x 32 frames, 12 frames at 12 FPS). In each one, every layer holds one
drawing (or two) and the motion comes from **keyframe lanes**. Open one, press `Num 0` for the
lightbox and `Num 8` for the X-sheet, then click the arrow before a layer's name to see its lanes.

The field guide `docs/XSHEET-HOLDS-AND-LANES.md` explains every gesture.

| File | What to look at |
|------|-----------------|
| `bounce.draw` | **A ball drawn once.** The **ball** layer is held for all 12 frames (one cell with a hold line on the X-sheet). Its lanes do the animating: **Y** falls with EASE IN and rises with EASE OUT. On the floor frame, **SCALE X** goes to 125 and **SCALE Y** to 70, both as HOLD steps, so the squash lasts exactly one frame. **PIVOT Y** sits at the ball's bottom so it squashes onto the floor, not toward its middle. |
| `parallax.draw` | **A group moving as one, with a layer moving faster inside it.** The **scenery** group (hills + trees) has an **X** lane drifting 6 px left. The **trees** have their own **X** lane on top of that, 6 px more, so they move 12 px in all and read as nearer. The **bird** has two drawings, wings up and down, alternating through linked cells. Its **X** lane carries it across with EASE IN-OUT, and an LFO sine **modulator** on **Y** (2 px every 6 frames) bobs it with no keys at all. The **sky** is held for the whole shot. |
| `title.draw` | **A group fading, with one child spinning.** The **card** group's **OPACITY** fades in over frames 1-4 and out over 10-12; both layers inside it fade together. The **star** spins with **ROTATE** (0 -> 330°) and grows with **SCALE X / Y** (30 -> 100 %, EASE OUT). The **plate** flickers toward white through a **TINT** lane with a **Noise** modulator (amount 40, a new value every 2 frames). |

Each `.gif` beside its `.draw` is the batch export (`DRAW NAME.draw --export-anim NAME.gif`). It
is what every exporter writes: the lanes applied, each frame clipped to its cell.

## Try this

- Drag a key on a lane row: sideways moves it in time, up and down changes its value. The canvas
  follows as you drag. `Ctrl+Z` undoes it.
- Right-click a key and change its ease (try HOLD on the bird's X: it jumps instead of gliding).
- In `bounce.draw`, drag the ball cell's right end back to frame 6. Frames 7-12 go blank: the
  hold has let them go.
- Add a lane with **+ LANE**. **ROTATE** on the ball, keyed 0 -> 360, makes it roll.
- Hover a key to see its lane, value, frame and ease.

## Rebuilding

`DEV/xsheet-samples/build.sh` rebuilds these files.

1. `make-art.py` draws the art and writes each one as an Aseprite file: layers, groups, and
   linked cels, which become the holds.
2. A batch DRAW turns each into a `.draw`.
3. `drive.sh` opens each one offscreen with the QA harness and adds every lane on the X-sheet
   the way a user would (+ LANE, double-click, type, right-click for the ease or modulator). It
   checks each lane against DRAW's dump, then saves.
4. A batch DRAW exports the `.gif` previews.
