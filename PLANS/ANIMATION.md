# Animation

Branch `animation`. Rick's sketch: `PLANS/ANIMATION.drawy` (export: `PLANS/DRAW ANIMATION FEATURE.PNG.png` / `.svg`).
Requirements gathered 2026-11-07 with the Animation Field Kit (round 1: 31 questions, all answered).
Open questions for round 2 are at the end.

## The model: the canvas is the sprite sheet

> Rick (Q-06): "I want to be able to edit like a big sprite sheet, and zoom in and all tools work
> already in that context, the frames are just WxH cropped sections of each cell ... Toggle it on
> and off, and flip around that way both stay pure. No compromise to the existing, and only
> additive tools for animators."

- **A frame is a W×H cell of the canvas**, in reading order (Q-02 B). The document stays one
  canvas with one layer list; nothing about layers, tools, undo or export changes.
- **Layers span the whole sheet**, so each layer's cell *is* "that layer's drawing on that frame"
  (Q-01 A: shared layers, one drawing per layer per frame).
- **Two views of the same pixels** (Q-05 A, Q-06 B):
  - **Sheet view** = DRAW as it is today, plus a frame grid overlay (cell borders, numbers,
    current cell).
  - **Lightbox view** (toggle, menu + key) = Rick's sketch: a strip of cells on top, the transport
    bar, then 3 / 5 / 7 editor panes (Q-08 A), current frame in the middle, every pane drawable
    (Q-07 B) — a stroke goes to the cell under it.
  - **X-sheet view** (later phase) = frames × layers grid for timing (Q-05 A).
- Animation metadata (frame size, holds, FPS, loop, tags, notes, links) lives beside the pixels,
  not in them.

Why this is cheap: no frame store, no swapping layer buffers, ~300 `LAYERS(CURRENT_LAYER%)` call
sites untouched. Frame operations (insert / delete / reorder) are cell pixel moves across all
layers, recorded in the one history.

## Decisions (round 1)

| Q | Decision |
| --- | --- |
| 01 | Shared layers; each layer's cell is its drawing for that frame |
| 02 | Frames are W×H cells cut from the canvas (sprite sheet) |
| 03 | Linked drawings, with Unlink (exact form in the sheet model: round 2) |
| 04 | Global FPS + per-frame hold ×1 ×2 ×3 … |
| 05 | Lightbox default, X-sheet one click away |
| 06 | Lightbox is a separate view toggle; the panel can be open in sheet view |
| 07 | All editor panes are drawable |
| 08 | Editor zoom = pane count 3 / 5 / 7 |
| 09 | Onion skin: frames before / after, opacity, red / blue tint |
| 10 | Strip scrolls to keep current in view; wheel scrolls it; seek bar shows position |
| 11 | Key map as planned (numpad-only codes; guards; Preview as its own loop) |
| 12 | Strip selection = layers panel rules: click current, Ctrl+click toggle, Shift+click range, drag reorder |
| 13 | Laptop keys: Alt+, / Alt+. prev / next, Alt+Home / Alt+End first / last, Alt+/ play |
| 14 | `+` = copy of the last frame; Shift++ = blank |
| 15 | Preview: wheel and Ctrl+wheel zoom, double middle click = 100%, middle-drag pans |
| 16 | Shrinking the total asks first when it would delete drawn frames; always undoable |
| 17 | All frame ops: insert before/after, duplicate, delete, drag reorder, reverse, paste as new vs over, copy/paste between DRAW windows, apply effects/flip/move/palette swap to selected frames |
| 18 | A selection stays put (same place in the cell) on frame change |
| 19 | Reference layers: visible while drawing / in the lightbox, left out of export |
| 20 | Loop forward / backward / ping-pong, play once, play selected frames or a tagged range, named tags saved in the file |
| 21 | Playback: current pane plays, strip follows, Preview window plays too |
| 22 | Drawing is blocked while playing |
| 23 | Color cycling runs with animation, in the lightbox and in GIF / BAS export |
| 24 | No MP4; PNG sequence instead |
| 25 | Export: animated GIF, BAS, sprite sheet PNG + frame rects (JSON / BAS), PNG sequence, APNG / WebP, scale 2× / 4× nearest |
| 26 | Import: animated GIF, Aseprite frames (+ overpaint fix), sprite sheet slicing, PNG sequence |
| 27 | BAS: both a self-contained DATA player and a .bas + sprite sheet PNG |
| 28 | Older DRAW can't open animated files; plain files unchanged (round 2 suggests better) |
| 29 | Build order as below |
| 30 | Aseprite overpaint bug: fix now on main (frame 1 only); frames properly in phase five |
| 31 | Also: a sound / music track to time against, frame notes on the X-sheet, an "Animate" workspace preset |

## Phases (revised for the sheet model)

1. **Frames on the sheet.** Frame size, frame grid overlay, current frame, numpad + laptop keys,
   ANIM menu, Animation panel (frame W×H, FPS, hold, loop), add / duplicate / insert / delete /
   reorder as cell moves with undo, playback (Preview window + current cell), save / load.
2. **Lightbox.** Strip + transport + 3/5/7 drawable panes, strip selection, copy / cut / paste
   frames, onion skin, apply-to-selected-frames, reference layers.
3. **Out the door.** Animated GIF (holds, loop modes, color cycling), PNG sequence, sprite sheet +
   rects, APNG, BAS (both forms), export scale, full-screen Preview.
4. **X-sheet.** Frames × layers grid, holds, links, tags / ranges, frame notes.
5. **Bring it in.** Animated GIF, Aseprite frames, sprite sheet slicing, PNG sequence.
   Later: soundtrack, "Animate" workspace.

## Code notes (survey of main @ bb3a8e08)

- Layers: `DRAW_LAYER` `GUI/LAYERS.BI:57`, `LAYERS(1 TO MAX_LAYERS)` (256), canvas size
  `SCRN.canvasW& / canvasH&`. Drawing target `LAYER_current_image&` (`GUI/LAYERS.BM:2376`).
- History: kinds 0-20 `TOOLS/HISTORY.BI:16`; CANVAS_RESIZE (18) snapshots every layer - the model
  for whole-sheet frame moves. Group records with `HISTORY_begin_group / end_group`.
- .draw: `DRW_VERSION% = 30`, payload deflated into the PNG `drAw` chunk; loader rejects newer
  versions (`TOOLS/DRW.BM:686`). Pixels written with per-pixel POINT/PSET (slow).
- GIF: reusable `GIF_lzw$`, `GIF_gce$` (per-frame delay), `GIF_frame$`, `GIF_subblocks$`,
  NETSCAPE loop block, `IDX_index_image$` (`OUTPUT/FILE-GIF.BM`, `OUTPUT/PAL-INDEX.BM`). The
  current exporter is palette-cycling only.
- BAS: `CYCX_export_bas%` (`OUTPUT/FILE-CYCLE-BAS.BM`) DATA + `_DEFLATE$` + `_BASE64ENCODE$`
  scaffold and player loop.
- Playback tick precedent: `PCYC_tick%` (`DRAW.BAS:922`, `GUI/PALETTE-CYCLE.BM:168`).
- Multiple views precedent: tile mode renders `RENDER_layers` per tile (`OUTPUT/SCREEN.BM:3383`);
  Preview renders to its own image (`GUI/PREVIEW.BM:507`). Mouse→canvas assumes one view
  (`INPUT/MOUSE.BM:205`) - lightbox panes need a per-pane mapping.
- Keys: `_KEYHIT` merges numpad into main-row codes; `_KEYDOWN(100256+n)` (NumLock on) /
  `200000+n` (off) are numpad-only. Dispatcher table handles codes ≤ 65535
  (`INPUT/INPUT.BM:1083`). Space = hold-to-pan (`INPUT/MOUSE.BM:5155`).
- **Numpad: port bu1ld0r's handling** (Rick: "it has great numpad handling"; `~/git/bu1ld0r`
  `UI/UI.BM` "the numpad: views", `UI/UI.BI` `npHeld()/npT#()`, notes in its CLAUDE.md "The numpad"):
  `NumpadOf(k&)` = which numpad key a plain code could have come from (digits . + - * / Enter, or
  End / arrows / Home / PgUp / Ins / Del / 19456 with Num Lock off); `NumpadHeld(b)` =
  `_KEYDOWN(100256+n) OR _KEYDOWN(200000+n)` (Num Lock state never matters - also covers Wayland
  reading it as off); `NumpadDev` drains `_DEVICEINPUT` once a frame and marks a press by the
  keyboard device's ids (`NumpadId`: X11 key code + 1) so a tap quicker than a frame isn't missed;
  `NumpadSent(k&)` = that numpad key is held or was pressed < .25 s ago. Typing in a box / text
  tool gets the plain key. Its test `tools/test/numpad.sh` holds and taps every keypad key with
  Num Lock on and off via xdotool and checks a `--keylog` - port it as a QA test. Caveat for DRAW
  (cross-platform): `NumpadId` values are Linux/X11; on macOS / Windows use `_KEYDOWN` alone or
  find their device ids.
- Menu: insert ANIM between AI and HELP (`GUI/MENUBAR.BM:246-265`; last root is pinned right).
  Workspaces with `ROOTS=` lists must add it. Free action ids: 2500-2599.
- Full-screen Preview: own loop like the Pixel Analyzer (`GUI/PIXEL-ANALYZER.BM`).
- Reset animation state in every document path: `DRW_load_binary`, `DRW_new_canvas`,
  `DRW_create_canvas_at_size`, `FILE_ASE_load`, `FILE_PSD_load`, plain-PNG `DRW_load_from_png`.
- Aseprite: `load_specific_layer_image&` paints every frame's cel into one image
  (`includes/QB64_GJ_LIB/ASEPRITE/ASEPRITE.BM:1707-1793`); per-frame loader
  `load_specific_layer_image_enhanced&(file, layer, frame)` exists.

## Decisions (round 2, 2026-11-07 15:18)

| R | Decision |
| --- | --- |
| 01 | Yes: the canvas is the sprite sheet, frame N = Nth W×H cell in reading order, layers span the sheet |
| 02 | Gutter and margin, both set in the panel, default 0 |
| 03 | Columns fit the canvas width; adding past the last cell grows the canvas by a row (undoable) |
| 04 | Insert / delete / reorder move pixels: the sheet is always in play order, one undo step |
| 05 | Phase 1: a per-layer "same on every frame" switch; phase 4: per-cell links (hatched), Unlink |
| 06 | Strokes clip to the cell in the lightbox, free in sheet view; a toggle for both |
| 07 | Changing frame size on a drawn sheet asks: Re-slice or Resize frames |
| 08 | `+` on a plain picture: it becomes frame 1 (frame size = canvas), frame 2 added beside it |
| 09 | Onion skin in the lightbox only |
| 10 | Animation data in its own PNG chunk; older DRAW opens the file as a plain sheet |
| 11 | APNG in phase 3; WebP later if still wanted |
| 12 | Soundtrack in sync with playback / scrub / BAS export, plus its waveform along the X-sheet |

## Round 3: clips, keyframes, personas (planning-chat handoff, 2026-11-12)

Rick's handoff from a planning chat, checked against this plan and the code. Status per item and
his decisions (2026-11-12, all four as recommended):

| # | Handoff item | Already built | New work | Decision |
| --- | --- | --- | --- | --- |
| 1 | AnimBrush pickup (**done**, see the commit "Hold B + select") | ANIM > AnimBrush > Pick Up / Pick Up Merged (any selection shape, wand too); a strip / X-sheet selection of 2+ frames = those frames; clicking a tag selects its span | Hold the Brush key (B) while making a selection = pick up + Brush tool (2+ frames: AnimBrush, else a still brush like Ctrl+B; a tap still switches to Brush). The key follows the Brush tool's binding. Name the brush after the selected tag (shown in the status bar and on a bin; saved in .dset / .draw) | No selection: **all frames** (was: the selection's frame to the last) |
| 2 | Single-cel "DPaint mode" | Done: ANIM > Big Frame + X-Sheet (49cad8d9), one pane under the X-sheet, Num * cycles 1 / 3 / 5 / 7 panes; same frames, two views | - | - |
| 3 | AnimBrushes as clips / symbols | Stamps bake pixels (follow / click / all frames, orders fwd / rev / ping-pong / once, start cel Alt+[ / Alt+]); Move Brush bakes a moving stamp. Symbols are layer-level (a static picture + per-child position / scale / rotation / opacity / blend) | **Clip layer**: a layer type holding a bin brush reference + clip settings (start offset, rate, loop / ping-pong / once / hold), drawn into every frame's cell at render time; Bake to pixels; later keyframe lanes. Render, every exporter, .draw, undo and the QA dump must learn it | **Clip layer** |
| 4 | Keyframe lanes | Move Brush is the baked form: two keys per move (start / end), ease none / in / out / in-out, line / drawn / live path, Z, turn X / Y / Z, size, opacity, tint, whole-pixel positions, nearest sampling | Lanes on clip layers in the X-sheet: pos X / Y, scale X / Y, opacity, tint, rotation, origin; stepped / linear / Bezier; seeded LFO / noise modulators | Spec first (below, to write) |
| 5 | Brush file format | PNG strip + frame data in DRAW's PNG chunk (Load: GIF, APNG, sheet); sets in .dset; sprite sheet export writes Aseprite-style JSON (frameTags); documents read Aseprite / TexturePacker JSON on open | Save an AnimBrush; export it as GIF / APNG / sheet + JSON; read Aseprite / TexturePacker JSON in AnimBrush Load | **Chunk stays native**, JSON on export / import only |
| 6 | Personas | Workspaces: menus (ROOTS= / HIDE_ITEMS=), keys, toolbars, panels; `--workspace NAME`; switcher (2400) + status badge; Animate, Annotate, Default, Simple ship | Sprite and Scene presets, a one-click switch button, ANIM menu split (60 rows + 2 flyouts scroll) | **Workspaces are the personas** (no rename) |

Order: 1 (hold-B pickup, all-frames range, tag names) -> clip layer design note -> clip layer ->
keyframe / modulator spec -> personas. Reference: Pro Motion NG anim painting
(https://www.cosmigo.com/promotion/docs/onlinehelp/animPainting.htm) - its "keyframes" are
light-table markers only, so property lanes would be new.
