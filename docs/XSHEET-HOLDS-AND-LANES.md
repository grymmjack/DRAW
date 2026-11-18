# Field Guide: Per-Layer Holds and Keyframe Lanes on the X-sheet

*DRAW, branch `xsheet-holds-lanes` (unreleased) · written 2026-11-16*

This guide covers four things:

1. **Per-layer holds.** One layer keeps a drawing on screen for several frames while the
   other layers keep changing.
2. **Keyframe lanes.** A layer, a group or a clip moves, scales, turns, fades or tints over
   the frames. Each change is a curve you can see and edit, and the layer's pixels are never
   touched.
3. **Recording.** Arm a layer (its red dot) and the tools you already use - Move, Transform,
   Flip, opacity - key its lanes instead of changing pixels. In the lightbox an armed layer
   gets a **transform widget** for moving, scaling, turning, fading and tinting it.
4. **The LANES page** of the Animation panel: every lane's value on the current frame, so
   you can key everything with the X-sheet hidden. Plus **Settings → Animation**.

It assumes you already have an animation: a canvas set up as frames (**File → New
Animation…**, or **ANIM → Add Frame**). If the X-sheet is new to you, see the X-sheet table in
`SHORTCUTS.md`.

---

## The X-sheet in 30 seconds

- `Num 0` turns the lightbox on. `Num 8` turns the **X-sheet** on: a grid with frames across
  and layers down, the top layer first.
- Each column is one *tick*. A frame held for 3 ticks is three columns wide.
- The **HOLD** row at the bottom times **every** layer: it sets how long the whole frame stays
  up.
- The holds in this guide work on **one layer**, for when only the background should stay
  still.
- Labels on the X-sheet are in the Tiny5 font, in UPPERCASE.
- The layer names work like the Layers panel's: `Ctrl` / `Shift`+click adds a layer to the
  selection (a group with `Ctrl`: the group and all in it), `Ctrl+Shift+G` / `Ctrl+Shift+U`
  group / ungroup it, and dragging a name up or down moves the layer in the stack - into a
  group when you drop it above the group's header or one of its layers, out when you drop it
  outside. One undo step.

---

## Part 1 - Per-layer holds

### What a hold is

A layer **held** for N frames shows one drawing in N frames in a row. Under the hood those
cells are **linked**: one drawing shared by all of them, so painting any of them paints them
all.

On the X-sheet a held run looks like **one cell**: the drawing's thumbnail, then a **hold
line** along the rest of the run with a tick at each frame, then a bar at the end.

### Making a hold

| Do this | What happens |
|---------|--------------|
| **Drag a cell's right end** to the right along the layer's row | That drawing now covers every frame you drag across. The cells it covers take its drawing. One undo step. |
| **Right-click a cell → Hold for N Frames…** | Type the length: the hold starts at this frame. A hold never runs past the last frame. |
| **ANIM → Hold for N Frames…** | The same, for the current layer and frame. It is also in the command palette (`?`). |

Hover a cell's right end (the *grip*, the last few pixels) and the tip says **Held: frames s - e**
or **Frame n's drawing** with "Drag the end to hold it longer / shorter". A drag that starts
there changes the hold; one that starts anywhere else in the cell moves the drawing.

### Shortening or removing a hold

| Do this | What happens |
|---------|--------------|
| **Drag a held run's right end back** | The run gets shorter. The frames it lets go are **blank** (they do not get their old drawings back). |
| **Right-click a cell in the run → Release Hold (s-e)** | Back to one frame. The rest of the run goes blank. |
| **ANIM → Release Hold** | The same, for the current layer and frame. |

Each is one `Ctrl+Z`.

### The cell menu

Right-click any cell of a pixel layer on the X-sheet for:

- **Hold for N Frames…** (`Drag Right End` reminds you of the gesture)
- **Release Hold (s-e)**, shown only when the cell is in a held run
- **Link Cells** / **Unlink Cells** for the selected frames
- **Layer Menu…**, the layer's usual menu

### Tips

- **Painting a held frame changes the whole run.** That is the point: fix a background once.
- To change one frame inside a run, select it and **Unlink Cells** first, or shorten the run.
- Holds are saved in the `.draw` file as linked cells, so older 2.8 builds open them as links.
- Frame operations (insert, delete, move frames) keep the runs, the same way they keep links.

---

## Part 2 - Keyframe lanes

### What lanes are

A **lane** is one property of a layer that changes over the frames. It holds **keys** (a
frame and a value), and the value moves from one key to the next along an **ease**.

| Lane | Unit | Default | Notes |
|------|------|---------|-------|
| **X**, **Y** | pixels | 0 | Whole pixels, rounded half up, so a slow move steps one pixel at a time |
| **SCALE X**, **SCALE Y** | percent | 100 | About the pivot |
| **ROTATE** | degrees | 0 | About the pivot |
| **OPACITY** | 0-100 | 100 | 0 = gone in that frame |
| **TINT** | 0-100 | 0 | How far toward the tint colour |
| **PIVOT X**, **PIVOT Y** | pixels in the frame | the frame's middle | Where scale and rotate turn about |
| **VOLUME**, **PAN** | percent | 100 / 0 | **Clips with sounds only** |
| **BLEND** | a blend mode | the layer's own | **Pixel layers only.** Each key is a mode, held to the next key |
| **BLUR** | radius, pixels (0-32) | 0 | An effect lane (below). Spreads the edges too |
| **PIXELATE** | block size, pixels (1-64) | 1 (none) | An effect lane |
| **INVERT** | 0-100 % | 0 | An effect lane: how far toward the inverted colours |
| **NOISE** | 0-100 | 0 | An effect lane: a mono grain, new each frame or held |

#### The BLEND lane

**BLEND** switches the layer's blend mode per frame: Normal on frames 1-4, Difference on 5-8,
Screen from 9. Its keys never ease - a mode lasts until the next key (the HOLD ease, always).

- **Add it:** the lanes arrow, then **+ LANE > BLEND** - a key on the current frame at the
  layer's own mode.
- **Key a mode:** right-click the BLEND row on a frame. The menu lists every mode (the one on
  that frame checked); pick one and it is keyed there. **Delete Key** and **Remove Lane** are
  under them.
- The row shows each span's short mode name; its value box takes a typed name (`diff`,
  `multiply`, `screen`) or a number.
- Before the first key and on the gutters between frames, the layer uses its own blend mode
  (the Layers panel's). No modulator on this lane.
- Groups and clips have no BLEND lane (a group composites its own way). The `.bas` exporter
  writes the layer's own mode only.

#### Effect lanes: BLUR, PIXELATE, INVERT, NOISE

These change the layer's look per frame, not where it is. A blur that fades in as something
comes into focus, a pixelate that dissolves a sprite into blocks, a flash of inverted colours on
a hit, TV static over a screen.

- **Add one:** **+ LANE** lists them under the others, after a divider. They don't take up rows
  until you add them, and the Animation panel's LANES page lists them only once they're added.
- They work like any lane: keys, eases, double-click to type a value, drag, a modulator
  (a flickering **NOISE**, a pulsing **BLUR**).
- **Order:** on each frame the layer is moved first (X, Y, scale, rotate, opacity, tint), then
  **PIXELATE**, **BLUR**, **NOISE** and **INVERT**, in that order. Pixelate before blur, so a
  blur still softens the blocks.
- **BLUR** works in whole pixels and spreads the picture's edges (they fade out), so a blurred
  sprite gets a soft outline. It stays inside the frame.
- **PIXELATE** blocks start at the frame's top-left corner. A block over an edge takes the
  average of its pixels, so the edge goes see-through, not black.
- **NOISE** puts a new grain on every frame (static). For a still grain, right-click a key:
  **From This Key: Frozen Grain**. The grain then holds until the next key, and each frozen key
  has a grain of its own. Each layer has its own grain too.
- On a **group** they apply to each layer in it.
- Clip layers have no effect lanes. The `.bas` exporter doesn't write effect lanes; every image
  export does (they are in the picture).

Before the first key, a lane holds the first key's value. After the last key, it holds the
last key's value.

### Which layers can have lanes

- **Pixel layers** (also text and image layers) can.
- **Groups** can. A group's lanes apply to **every layer in it**, on top of each child's own
  lanes (inner first, then each enclosing group). Move a group and everything in it moves.
- **Clip layers** use the clip's own lanes, which already existed (see the manual, "Moving a
  clip - keyframe lanes"). Their keys count from the clip's **IN** frame. Everyone else's
  count from frame 1.

### Non-destructive

Lanes **never change pixels**. DRAW shows the layer through a copy in which each frame is
drawn through that frame's lanes. That copy is what you see everywhere:

- the canvas, the lightbox panes, onion skin, playback, the Preview window and full-screen
  preview;
- **every export**: animated GIF, APNG, PNG sequence, sprite sheet, the `.bas` player,
  flatten / PNG, and the picture inside the `.draw` file.

Each frame is **clipped to its own cell**. Whatever moves out of the frame is not shown; it
does not spill into the next cell.

### Opening a layer's lanes

On the X-sheet every pixel layer, group and clip has a small **arrow** before its name:

- `▸` dim: no lanes yet. `▸` bright: it has lanes. `▾`: the lane rows are open.
- **Click the arrow** to open or close the lanes. This is a view setting only, so it is not
  an undo step.

When the lanes are open, you get one **row per lane in use**, plus a final **+ LANE** row.

### Adding a lane

**Click + LANE**: a menu lists the lanes this layer is not using yet. Pick one, and it gets
**a key on the current frame** at its value there (its default if nothing moves it yet). Then
add more keys.

When you add **TINT** to a pixel layer or group, its tint colour starts as your **FG
colour**.

### Reading a lane row

```
 X          4 │ · · · · ·◆─────────╮· · · · · · · · · ·
              │                     ╰──────◆━━━━━━━━━━━━
              │      the curve          key   held after
```

- The name is at the left. The **value on the current frame** is at the right of the name
  column.
- The **dotted line** is the lane's default value (0 for X, 100 for SCALE, and so on).
- The **solid curve** is the keyed value, drawn with its eases:
  - **LINEAR** is a straight line.
  - **EASE IN** starts slow. **EASE OUT** ends slow. **EASE IN-OUT** does both, giving an
    S curve.
  - **HOLD** is a step: the value stays put until the next key.
- **Keys** are drawn by their ease, so you can read the timing at a glance:

  | Shape | Ease (from this key to the next) |
  |-------|------|
  | ◆ diamond | LINEAR |
  | `[>` flat left, pointed right | EASE IN |
  | `<]` pointed left, flat right | EASE OUT |
  | ● circle | EASE IN-OUT |
  | ■ square | HOLD |

  A key is filled when it sits on the current frame of the lane you last picked.
- Each lane has its own **colour** (X red, Y green, SCALE orange / yellow, ROTATE blue …):
  the curve, its keys and the lane's name. The picked lane is drawn full strength, the others
  a little fainter. Change them in **Settings → Animation**.
- The curve is **anti-aliased**: smooth slopes, not pixel stairs.
- With a **modulator** (below) on, the line is what the layer really does: the keys plus the
  modulator's own wave, drawn between the frames too, so you see its shape. The bare key curve
  stays underneath, faint. A small picture of the wave sits just right of each key the
  modulator starts from (fainter for a one-shot), and an envelope's phases show as dots on
  the line.
- The row's height covers the lane's range: its keys and default plus a margin. OPACITY and
  TINT always show 0-100.

**Lane thumbnails on the layer's own row.** Once a layer has lanes, its main row (the one
with its name) shows its cells **through the lanes** - what the canvas shows on that frame -
and adds a thumbnail at **each frame a lane has a key**, with the hold line running on
between them. A ball drawn once in frame 1 and held, keyed across the frame, shows the ball
at each key where it is. A **group** with lanes shows all its layers together at its keys.
Right-click the X-sheet's header (the frame numbers) → **Lane Thumbnails**:

| Choice | Thumbnails |
|--------|------------|
| **Off** | the row as before: the drawing, then the hold line |
| **Keyframes** (default) | at each frame a lane of the layer (or of a group it is in) has a key |
| **Every Frame** | at each frame the lanes change the layer - not where nothing moves |

Also **Settings → Animation → Lane Thumbnails** (`XSHEET_LANE_THUMBS` in DRAW.cfg).

### Editing in place

| Gesture | Effect |
|---------|--------|
| **Double-click** an empty spot on a lane row | A key on that frame at the value the curve has there. It takes the ease of the key before it, so the curve keeps its shape. |
| **Double-click a key** | Type its value. |
| **Drag a key** left / right | Change *when* it happens. A key can't be dropped onto another key in the lane. |
| **Drag a key** up / down | Change its *value*. The canvas follows as you drag. |
| `Shift` while dragging | Lock to whichever direction you moved most. |
| Let go | One undo step, and the key's frame becomes current. |

### Selecting, moving and copying keys

Drag a box over the lane rows to work on a whole stretch of time at once — across several lanes and
even several layers' lanes.

| Gesture | Effect |
|---------|--------|
| **Drag on empty lane space** (the pointer is a crosshair there) | A box over those frames × those lane rows: the keys inside are selected (filled in the selection colour). Rows in between that aren't lanes are skipped. Start the box on empty space — a press on a key drags that key. |
| **Drag inside the box** (a move pointer) | Every selected key moves by the frames you drag, on every lane in the box. Keys it lands on are replaced; no key goes before its layer's first frame or past the last. One undo step. |
| **Alt** while dragging inside the box | A copy instead: the keys stay where they were too. |
| **Click** empty lane space, or **Esc** | Clears the box. Selecting is not an edit: there is no undo step for it. |
| **Ctrl+C** | Copies the box's keys — *what you see*: where the box starts or ends between keys, a key is added at that edge with the value the curve has there, so the pasted stretch has exactly the same curve. |
| **Ctrl+X** / **Delete** | Copies and removes / just removes the box's keys. One undo step for every lane in it. |
| **Ctrl+V** | Pastes at the **current frame**, replacing the keys in the stretch it covers; the pasted stretch is then selected. Copied from **one** layer, it goes into the **current layer's** lanes of the same kind (X onto X, OPACITY onto OPACITY) — so select another layer first to give it the same motion; its lanes open. Copied from **several** layers, each lane goes back into its own layer at the new time. |

Ctrl+V pastes keys only while they are the last thing you copied: a picture Ctrl+C / Ctrl+X takes it
back. The same four are on **ANIM → Copy Keys / Cut Keys / Paste Keys / Delete Keys** and in the
command palette.

### The lane menu (right-click a lane row)

**On a key:**

- **Value…**
- **Hold (a Step)**, **Linear**, **Ease In**, **Ease Out**, **Ease In-Out**. An ease applies
  from this key to the next.
- **Delete Key**

**Between keys:**

- **Add Key Here**
- **Key Here at Value…**

**Always:**

- **No Modulator**, **LFO Sine**, **LFO Triangle**, **LFO Square**, **LFO Saw**, **Noise**
- **Modulator Amount (n)…**, **Modulator Period (n Frames)…** and **Modulator Envelope
  (…)…**, shown once a modulator is on
- **Add Frequency Lane (Period over Time)** and **Add Amplitude Lane (Amount over Time)**,
  once a modulator is on and the lane doesn't have that row yet (below)
- On a key, with a modulator on: **From This Key: Modulator On**, **From This Key: One Cycle
  (One-Shot)**, **From This Key: Restart the Wave** - what the modulator does from this key to
  the next (below)
- **Tint Color = FG Color**, on the TINT lane
- **Edit in Animation Panel**, on clips only (the panel's LANE row edits this lane)
- **Remove Lane**: its keys and modulator go, and so does the row

Every change is one `Ctrl+Z` / `Ctrl+Y`.

### Modulators - movement without keys

A modulator adds a repeating wobble on top of the lane's keyed value:

- **LFO Sine / Triangle / Square / Saw**: a wave. **Amount** is how far it swings, in the
  lane's unit. **Period** is the number of frames per wave.
- **Noise**: a seeded jitter that is the same every time it plays. It gets a new random value
  every *period* frames and eases between them.

New modulators start with a visible amount: 2 px on X / Y, 10 % on SCALE, 15° on ROTATE, 30
on OPACITY. The period starts at 12 frames.

**Per key: on, one-shot, restart.** Each key says what the modulator does from that key to the
next one (right-click the key):

| From This Key: | What happens until the next key |
|----------------|----------------------------------|
| **Modulator On** (checked: the default) | The wave runs. Uncheck it and the lane is only its keys for this stretch |
| **One Cycle (One-Shot)** | One wave from this key, then flat: a single bounce, a single shake |
| **Restart the Wave** | The wave starts over at this key (otherwise it keeps the lane's own clock, as if it had been running all along) |

Before the first key the modulator runs only when the first key is plain (on, repeating, no
envelope), which is how every lane behaved before these existed.

**Envelope (ADSR).** **Modulator Envelope…** shapes how strong the wave is, starting again at
each key it is on from. Type four numbers:

| | | |
|-|-|-|
| **A** attack | frames | from nothing up to the full amount |
| **D** decay | frames | down to the sustain level |
| **S** sustain | % | the level it holds at |
| **R** release | frames | down to nothing, ending at the next key (or at a one-shot's end) |

`0 0 100 0` is no envelope. `6 4 40 3` swells in over 6 frames, settles to 40 % and fades out
over the 3 frames before the next key. Dots on the line mark where each phase ends.

**Frequency and amplitude lanes.** A modulator's period and amount can change over time too.
**Add Frequency Lane** puts an **X ~FREQ** row under the lane (for X), and **Add Amplitude
Lane** an **X ~AMP** row. Each starts with one key, on the frame you right-clicked, at the
modulator's own period or amount. Key them like any lane:

- **~FREQ** is the period in frames per wave (1 to 999). Lower is faster. The wave speeds
  up or slows down smoothly, without jumping, because it counts the waves done so far.
- **~AMP** is the amount. Key it from 0 up for a wobble that grows, down to 0 for one
  that dies away.

Without keys of their own (before the first, after the last), they hold their nearest key.
Their right-click menu has only **Remove Lane**, which removes that row; the modulator
keeps its own period or amount. Removing the lane itself removes them too.

| Effect | Recipe |
|--------|--------|
| A firefly bobbing | **Y**, LFO Sine, amount 3, period 12 |
| A torch flickering | **OPACITY**, Noise, amount 20, period 2 |
| A sign swinging | **PIVOT Y** 0 (the top edge), **ROTATE**, LFO Sine, amount 10, period 16 |
| Breathing | **SCALE Y**, LFO Sine, amount 4, period 24 |
| A hit shake that dies away | **X**, LFO Square, amount 3, period 2, key on the hit frame: **One-Shot** off, envelope `0 0 100 6`, a key 6 frames later |
| A single bounce on landing | **Y**, LFO Sine, amount 4, period 6, key on the landing frame: **One Cycle (One-Shot)** |
| A shiver that speeds up | **X**, LFO Sine, amount 1, period 12, **Add Frequency Lane**: keys 12 then 2 |
| A wobble that settles | **ROTATE**, LFO Sine, amount 20, period 8, **Add Amplitude Lane**: keys 20 then 0 |

### Recipes

**Slide a character in from the left, easing to a stop**

1. Select the character's layer. On the X-sheet, open its arrow, then **+ LANE → X**.
2. Double-click its key on frame 1 and type `-40`.
3. Double-click the X row on frame 8, then double-click the new key and type `0`.
4. Right-click frame 1's key → **Ease Out**.

**Fade a whole group out at the end**

1. Open the group's arrow, then **+ LANE → OPACITY** on the frame where the fade starts. The
   key is 100.
2. Double-click the last frame on the OPACITY row, then double-click that key and type `0`.

Every layer in the group fades.

**A held background that drifts slowly (parallax)**

1. Paint the background on frame 1 and drag its cell's right end to the last frame. It is now
   held.
2. **+ LANE → X**: key frame 1 at `0` and the last frame at `-6`.

The one drawing slides 6 px over the shot.

**A bouncing ball with a squash**

- **Y**: keys at the top and the floor. Use **Ease In** going down and **Ease Out** going up.
- **SCALE Y**: 100, then 70 on the floor frame, then 100. Use **HOLD** if you want it snappy.
- **PIVOT Y**: the frame's bottom edge, so it squashes onto the floor.

### Things to know

- **You paint the layer's own pixels.** On a laned layer the stroke goes into the unmoved
  drawing and appears *through* the lanes as you paint. If the layer is moved or scaled on
  this frame, your stroke lands where the pixels really are. To touch up a drawing, paint on
  a frame where its lanes are at rest (X / Y 0, SCALE 100, ROTATE 0), or remove the lane
  first.
- **Transforms and the Move tool move the pixels**, not the lanes - unless the layer is
  **armed** (Part 3): then they key its lanes.
- **The Animation panel's LANES page** shows every lane of any layer type (Part 4); the
  clip-only LANE / KEYS / MOD rows are still there on a clip's own page.
- **Older DRAWs** open a file with layer lanes with the layers unmoved: they skip the lanes'
  `drLL` chunk, and the pixels were never changed. Clip lanes are unaffected.
- On pixel layers and groups, lanes follow the **frame numbers**. Inserting or deleting
  frames does not shift their keys.
- Hover the arrow or a key for a tip: the key's lane, value, frame and ease.

---

## Part 3 - Recording: arm a layer, use your tools

### Arming

A layer that is **armed** records: what you do to it becomes keys on its lanes, on the
current frame, and its pixels stay as they are.

- Click the **dot** on the layer's X-sheet row (after the lock), or the dot left of its
  opacity bar in the **Layers panel**. The Layers panel shows the dots only when the
  document is an animation (more than one frame).
- Or right-click the layer (Layers panel, or its X-sheet cell) → **ARM FOR RECORDING**, or
  **ANIM → SET UP → ARM LAYER FOR RECORDING**. **DISARM ALL LAYERS** turns every one off.

| Dot | Means |
|-----|-------|
| 🔴 red | armed - recording |
| 🟣 purple | not armed, but the layer has keys |
| ○ faint ring | not armed, no keys yet (click it to arm) |

Arming lasts for the session. It is not saved in the file.

### What records

On an armed layer, on a frame inside the layer's In..Out:

| You do | It keys |
|--------|---------|
| **Move tool** drag (canvas or a lightbox pane), arrow-key nudges | X, Y |
| **Transform** → Scale / Rotate, then commit | X, Y, SCALE X / Y, ROTATE (the overlay is reproduced, then cancelled) |
| **Flip Horizontal / Vertical** (`Home` / `End`) | SCALE X / Y, negated - a flip is a negative scale, no separate lane |
| Layers panel **opacity** bar / slider / wheel, `1`-`0` keys, the X-sheet opacity box | OPACITY |

- One gesture is one undo step, even a long drag.
- While a lane is being changed, a **purple dot** shows on its X-sheet row and on the LANES
  page, and its key / curve moves with the value live. The dot fades about 1.5 s after you
  stop.
- A selection or a multi-layer selection still moves pixels, as before.

### The transform widget

While the current layer is armed, the **current frame's lightbox pane** shows a box round
the frame's drawing, placed as its lanes place it. (A pixel layer: its drawing's bounds; a
clip: its cel; a group: the whole cell.)

```
            o   ← knob: rotate
   ■────────■────────■
   │                 │
   ■        ┼        ■   ┼ pivot
   │                 │
   ■────────■────────■
  OPACITY ▕████────▏ 100   TINT [■] ▕──────▏ 0
```

| Handle | Drag to | With `Shift` |
|--------|---------|--------------|
| a corner | scale W and H (the opposite corner stays put) | uniform |
| an edge middle | scale W or H alone | - |
| the knob above the box | rotate about the pivot | 15° steps (`Ctrl`: the angle snap - Snap Degrees, or Pixel Art Angles) |
| the crosshair | move the pivot (the drawing doesn't move) | - |
| inside the box | move (the Move tool's armed drag) | - |

- Dragging a handle past the other side flips the drawing (a negative scale).
- A tip shows the value on hover, and **old → new** while you drag.
- Each drag is one undo step.

**The bar under the box:**

- **OPACITY** slider - drag it, or click its number and type a value.
- **TINT chip** - `Shift`+click: the tint colour = your FG colour now (a TINT of 0 becomes 50
  so you see it). Click: the tint *follows* your FG colour - the Color Mixer opens and the
  chip gets a red ring; pick colours and the layer follows. Click again to stop. One undo
  step per mouse release.
- **TINT** slider and its number - how much tint.

**Fading the widget:** `Ctrl+Alt+Shift+wheel` over the widget makes it fainter / stronger
(elsewhere that gesture still fades the grids). `Ctrl+Alt+Shift+middle-click` over it puts it
back to its default opacity, set in **Settings → Animation**.

---

## Part 4 - The LANES page and Settings → Animation

### The Animation panel's LANES page

With the X-sheet hidden you can still see and key every lane. On an animation, the
Animation panel's status row has a **LANES** chip whenever the current layer can have lanes
(a pixel layer, a group or a clip). Click it:

```
 LANES: FRAME 3 OF 8          [LANES]
 [<KEY] [ < ] [ > ] [KEY>]
 ▌X                     [◆]  [   12]
 ▌Y                     [◇]  [    0]
 ▌SCALE X               [◇]  [  100]
 …                                      (every lane)
 EASE  [ EASE OUT                    ]
 MOD   [ SINE      ] [   2] [   12]
```

| Part | Click | Also |
|------|-------|------|
| `<KEY` / `KEY>` | the previous / next frame with a key on any lane | |
| `<` / `>` | the previous / next frame | |
| a lane's **name** | picks it (EASE and MOD follow it) | the bar at its left is the lane's colour |
| its **key button** | adds a key on this frame / removes the one there | shows the key's ease shape, or an outline when there's none |
| its **value** | type a value | drag up / down to scrub (`Shift` ×10), wheel ±1 (`Shift` ±10), middle-click = the default |
| **EASE** | the next ease for the picked lane's key on this frame (`Shift`: the one before) | |
| **MOD** | the next modulator (`Shift`: the one before) | AMOUNT / PERIOD: click to type |

Every change keys the current frame and is one undo step. Click **LANES** again for the frame
controls.

### Settings → Animation

**Edit → Settings → ANIMATION**, or **ANIM → SET UP → ANIMATION SETTINGS…**:

| Setting | What it does | DRAW.cfg key |
|---------|--------------|--------------|
| **Default Zoom: Show All Frames** | the X-sheet's default zoom fits every frame across (off: a thumbnail a tick). The slider and `Ctrl+wheel` still zoom; double-click the slider for this default. | `XSHEET_FIT_ALL` |
| **X-Sheet: Lane Thumbnails** | Off / Keyframes / Every Frame: thumbnails drawn through the lanes on a laned layer's main row, at each key or each frame the lanes change it (also the X-sheet header's right-click menu) | `XSHEET_LANE_THUMBS` (OFF / KEYFRAMES / EVERY) |
| **X-Sheet: Contrast** | the X-sheet's grid, guides, dotted lines and faint marks: up = stronger (and the greys lighter), down = softer, 0 = the theme as is (-80..100). Also `Ctrl+Alt+Shift+wheel` over the X-sheet; `Ctrl+Alt+Shift+middle-click` there resets it. | `XSHEET_CONTRAST` |
| **Transform Widget: Opacity %** | the widget's opacity at start and after `Ctrl+Alt+Shift+middle-click` (10-100) | `ANIM_WIDGET_OPACITY` |
| **Keyframe Lanes: Line Thickness** | how thick the lane curves are, 1-4 px (default 2); they stay anti-aliased at any width | `ANIM_LANE_THICKNESS` |
| **Keyframe Lane Colors** | one colour per lane; **Default Colors** puts them back | `ANIM_LANE_COLORS` (RRGGBB list, lane order; `0` = the theme's text colour) |

The X-sheet's zoom slider (the header's LAYER cell) is now always there, from "every frame
fits" up to 4× the default, with a notch at the default.

---

## Gesture card

```
X-SHEET ─ HOLDS                         X-SHEET ─ LANES
drag cell's right end   stretch/shrink   click ▸ before a name   open / close
R-click cell            hold menu        click + LANE            add a lane
ANIM > Hold for N…      type a length    dbl-click lane row      key at the curve
ANIM > Release Hold     back to 1 frame  dbl-click a key         type its value
                                         drag key ←→ / ↑↓        when / value (Shift: one axis)
                                         R-click lane row        ease · delete · modulator · remove
                                         drag empty lane space   a box: select keys
                                         drag inside the box     move them (Alt: copy)
                                         Ctrl+C / X / V, Del     copy / cut / paste at the frame / delete

RECORDING                               TRANSFORM WIDGET (armed, lightbox)
click a row's dot        arm / disarm    corner / edge           scale W+H / W / H (Shift: uniform)
Move / nudge             X Y keys        knob                    rotate (Shift: 15°, Ctrl: snap)
Transform commit         X Y SCALE ROT   crosshair               pivot
Home / End               flip (−SCALE)   TINT chip               Shift: FG now · click: follow FG
opacity bar / 1-0        OPACITY key     Ctrl+Alt+Shift+wheel    fade the widget (+middle: reset)
                                        ...over the X-sheet     its contrast (+middle: reset)

ANIMATION PANEL ─ LANES                 KEY SHAPES
LANES chip               page on / off   ◆ linear  [> in  <] out
value: drag/wheel/click  scrub/step/type ● in-out  ■ hold
middle-click value       the default
```

---

## See also

- `SHORTCUTS.md` - the X-sheet table, the clip lanes rows, recording and the transform widget.
- `docs/MANUAL/09-brushes-drawer.md` - clip layers and their lanes in the Animation panel.
- `SAMPLES/XSHEET/` - example projects that use holds and lanes (see its README).
