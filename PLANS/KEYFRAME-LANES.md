# Keyframe lanes and modulators on clip layers (clip phase 3)

Status: **spec, building** (2026-11-12). Phase 3 of PLANS/CLIP-LAYERS.md ("Keyframe lanes
later (own spec)"), item 4 of the Round 3 handoff in PLANS/ANIMATION.md. Rick: "keep going with
the next phases" (2026-11-12). The questions below have recommended answers that are being built.
They are listed for the field kit, so Rick can overrule any of them.

## What it is

A clip layer already plays its cels in place: the same X / Y in every frame. A **lane** makes one
property of the clip change over the frames: it moves, grows, turns, fades or takes a colour.
Each lane is a list of **keys** (a frame and a value). Between keys the value is interpolated.
A **modulator** adds a repeating wobble on top of a lane (LFO) or a seeded jitter (noise).

The rebuild already redraws a clip layer from its settings in every frame. Lanes only change how
each cel is drawn into its frame, so render, onion skin, playback, the X-sheet thumbnails, Bake and
every exporter keep reading the layer's pixels unchanged.

This is the clip-layer form of the Move Brush. The Move Brush bakes a moving stamp with two keys
(start and end) and an ease. A lane keeps the keys, so the move can be changed later.

## Properties (lanes)

| Lane | Unit | Default | Notes |
| --- | --- | --- | --- |
| X, Y | px, added to the clip's X / Y | 0 | whole pixels after interpolation |
| SCALE X, SCALE Y | % | 100 | nearest sampling; one SCALE box sets both while they are equal |
| ROTATE | degrees | 0 | about the pivot; nearest sampling (RotSprite later) |
| OPACITY | % | 100 | multiplies the cel's alpha |
| TINT | % toward the clip's tint colour | 0 | the tint colour is a clip setting (not keyed) |
| PIVOT X, PIVOT Y | px in the cel | cel centre | where SCALE and ROTATE turn about |

Sound lanes (the clip's sounds, see "Sound"): **VOLUME** (%, 100) and **PAN** (-100 left .. 100
right, 0).

## Keys

- A key is (frame, value, ease). **Frames are counted from the clip's IN** (key frame 0 = IN), so
  sliding the clip on the X-sheet or editing IN moves its keys with it. (Q1)
- **Ease** is the curve from this key to the next: HOLD (stepped), LINEAR, EASE IN, EASE OUT,
  EASE IN-OUT - the Move Brush's eases, so a clip and a baked Move Brush move alike. Bezier
  handles come later. (Q2)
- Before the first key the lane holds the first key's value; after the last, the last key's.
- A lane with no keys has its default value (and costs nothing in the rebuild).
- Values are SINGLE; positions are rounded to whole pixels after the curve, so a slow move steps
  one pixel at a time and never smears.

## Modulators

One per lane, optional, added to the keyed value:

- **LFO**: SINE, TRIANGLE, SQUARE, SAW; amount (in the lane's unit), period (frames), phase
  (frames).
- **NOISE**: amount, period (frames between new random values; smoothed between them), seed.
  Seeded value noise: the same frame always gets the same value, so renders, exports and undo are
  stable. (Q4)

Typical uses: a firefly bobbing (Y, SINE 3 px over 12 frames), a flame flickering (OPACITY,
NOISE 20 % every 2 frames), a leaf swaying (ROTATE, TRIANGLE 15 degrees).

## Editing

- **Animation panel** (clip rows, under SOUND): a **LANE** row - `<` `>` pick the lane, a value
  box (the lane's value at the current frame), **KEY** (add / update a key here), **DEL** (remove
  the key here), and an ease chip (cycles HOLD .. IN-OUT for the key at or before this frame).
  Then a **MOD** row: OFF / LFO / NOISE, the shape, AMOUNT, PERIOD, PHASE-or-SEED boxes.
- **Auto-key** (Q3): typing, dragging or wheeling the lane's value box on a frame sets a key on
  that frame (a new one, or the one already there). A lane with no keys takes its first key that
  way. One undo step per change, a drag is one step (the panel's press key, like the other boxes).
- **Canvas**: the Move tool on a clip with X / Y keys sets a key at the current frame (auto-key)
  instead of moving the whole clip. Without X / Y keys it moves the clip as now.
- **X-sheet**: a clip with keyed lanes gets one read-only **LANES** row under its layer (like its
  SOUND row) with a diamond on each frame that has a key in any lane; the current lane's keys are
  filled. Dragging a diamond along the row moves those keys in time (later item, L7).
- **ANIM > Clip Layer > Lanes**: Clear This Lane, Clear All Lanes, Copy Lanes / Paste Lanes (onto
  another clip layer).

## Sound

The clip's sound cues already become generated soundtrack clips (phase 2). VOLUME and PAN lanes
give each generated clip a gain and pan: the lane's value **at the frame the sound starts**. The
mix (`ANIM_SND_mix`, the BAS export's audio) applies them per clip. A sound does not change volume
while it plays (a held note keeps its level). Pitch would need resampling: left out. (Q5)

## Rendering

`CLIP_rebuild` draws each frame's cel through one transform: scale X / Y, rotate about the pivot,
whole-pixel translate, opacity, tint, flip - nearest sampling into the frame's cell, clipped to
the cell. The Move Brush's `MVB_stamp_xf` does the same maths for a brush stamp; its core is
split out as `XF_draw` (source image, destination, centre, scale X / Y, rotation Z, the 3D turns,
opacity, tint amount + colour) so both share it, and the Move Brush tests check it still bakes
the same pixels. A clip with no keyed lanes and no modulators keeps today's fast path (a plain
`_PUTIMAGE`).

## Saving and undo

- The lanes belong to the **instance** (each clip layer moves on its own, even on a shared
  source). `CLIP_state$` adds the instance's lanes, so every clip undo record carries them and
  undo / redo need no new history kind.
- drCl **version 3** appends, per written instance, its lanes: count, then per lane: property,
  modulator (kind, shape, amount, period, phase, seed), key count, keys (frame, value, ease), and
  the tint colour. A version-2 reader stops before them (the clip shows without its moves; drAw
  still has the baked pixels).
- Bake to Pixels bakes the lanes too (it is the layer's pixels).

## QA

- Lane maths in `TOOLS/CLIP-MATH.BM` (pure): `CLIP_lane_value!(lane, frame)` with eases and both
  modulators; unit cases in `QA/unit/clip-unit.bas`.
- Dump lines: `CLIPL slot lane nkeys f:v:e ...` (each keyed lane), `CLIPLM slot lane kind shape
  amount period phase seed`, `CLIPLV slot lane v1 v2 ...` (the lane's value per frame, for the
  first 64 frames).
- Tests: `clip-lanes.sh` (panel keys, auto-key, eases in the pixels, undo, save / reload),
  `clip-lanes-mod.sh` (LFO / noise, stable across reload), `clip-lanes-canvas.sh` (Move tool keys),
  `clip-lanes-sound.sh` (volume / pan in the generated clips and the mix).

## Questions (recommended answers being built)

| # | Question | Built |
| --- | --- | --- |
| Q1 | Keys counted from the clip's IN, or absolute document frames? | **From IN** (a slid clip keeps its moves) |
| Q2 | Bezier handles now? | **No**: HOLD / LINEAR / the Move Brush's three eases; Bezier later |
| Q3 | Auto-key (changing a value on a frame sets a key), or an explicit KEY press only? | **Auto-key**, plus KEY / DEL buttons |
| Q4 | Noise: seeded and stable, or new every playback? | **Seeded**, the same every time |
| Q5 | Sound pitch lane? | **Not now** (needs resampling); volume and pan only |
| Q6 | Lanes per clip layer or per source? | **Per clip layer** |

## Phasing (the checklist items)

1. L1 This spec.
2. L2 Lane maths + modulators + unit test.
3. L3 Lanes data: instance lanes, `CLIP_state$`, drCl v3, the three document paths, dumps.
4. L4 Rendering through `XF_draw` (shared with the Move Brush; MVB tests unchanged).
5. L5 Animation panel LANE + MOD rows, auto-key, ease chip, menu commands.
6. L6 Move tool sets X / Y keys on a keyed clip.
7. L7 X-sheet LANES row (diamonds; drag keys in time).
8. L8 Sound lanes: VOLUME / PAN on the generated clips and in the mix.
9. L9 Record a Move Brush as a clip with lanes (ANIM > Move Brush > Apply as Clip).
10. L10 Docs (manual, SHORTCUTS, draw-animation, draw-fileformat drCl v3) + a phase-3 field kit.
