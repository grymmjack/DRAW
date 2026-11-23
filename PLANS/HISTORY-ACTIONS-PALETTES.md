# History palette, Actions palette, canvas recording

Rick 2026-11-22: "are we able to accommodate macros? where i can record actions stop then
replay? like photoshop actions" / "need a new macro palette" / "like photoshop actions has" /
"and a history palette for undo" / "if we could add canvas recording and playback that'd be
awesome too" / "the palettes need scale, resize, dock, etc."

Rick also: "common red x to close, and recall support for workspaces, universal controls/
adjustments, etc. etc." - every panel convention, none skipped: the red X in the title bar,
workspace recall (shown / docked / scale), the universal value input (`VAL_*`: wheel +/-1,
Shift+wheel +/-10, middle / double-click reset, double-click to type), tooltips, sounds, QA dump lines.

Both palettes are **dock panels** (like the Brush Palette, `GUI/BRUSH-PANEL`): docked in a
column or row, tabbed, floated, resized, per-panel Scale (panel surface), remembered in the dock
tree and workspaces, theme keys through `[PANEL]` (Theme Edit can reach every part). Default hidden;
View menu toggles. Action ids 2700-2729 (free range checked 2026-11-22).

## 1. History palette (`GUI/HISTORY-PANEL`, `DP_HISTORY`) - DONE 2026-11-22

Built: DP_HISTORY = 14 (natives shifted to 15..22), REGION_HISTORY 39, actions 2700 (View > History)
/ 2701 (Edit > Clear History), CFG HISTORY_PANEL / HISTORY_PANEL_SCALE, dump HISTP / HISTPB / HISTPR,
QA tests/history-palette.sh. UNDO / REDO / CLEAR buttons under the list as well as the right-click
menu. No kind icons yet.


Photoshop's History panel over DRAW's unified history (`TOOLS/HISTORY`).

- Row 0 = the document as opened / created ("OPEN" / "NEW"), then one row per **undo step**:
  records sharing a `sequence` (a `HISTORY_begin_group` group) are one row.
- Row text = the record's `label`, else a name from its kind (+ tool): BRUSH, LINE, FILL,
  NEW LAYER, ... Small tool/kind icon at the left when one exists.
- The current state is highlighted; states after it (redo) are dimmed, as Photoshop does.
- Click a row = undo / redo to that state (HISTORY_undo / _redo until there). Wheel scrolls;
  the list follows the current state after a new step.
- Right-click: STEP BACKWARD / STEP FORWARD / CLEAR HISTORY (asks).
- A new step while back in history drops the dimmed rows (already how history works).
- Later: snapshots, history brush (not planned now).

## 2. Actions palette (`GUI/ACTIONS-PANEL` + `TOOLS/ACTIONS`, `DP_ACTIONS`) - phase 1 DONE 2026-11-22

Built (QA `actions-palette.sh`, 74 checks with phase 2, stops, keys and Batch): the tree with ON / DIALOG boxes and fold triangles,
STOP / REC / PLAY / NEW SET / NEW ACTION / DELETE, right-click (play, record / stop, new set,
new action, rename, duplicate, delete, reload), double-click rename, wheel + scroll strip, its
own Scale, float, [x], View > Actions, workspace keys `ACTIONS_PANEL` / `ACTIONS_PANEL_SCALE`,
command palette entries `Actions: ...` (2702-2708), status bar `REC ACTION: <name>` while
recording, a play = one undo step labelled `Action: <name>` (HISTORY groups nest now:
`HISTORY_GROUP_DEPTH`). `CMD_execute_action` is a wrapper (depth counter + record hook) around
`CMD_execute_action_run`. Run setting `--option ACTIONS_DIR=<folder>` (QA: never the user's).
File lines are `SET` / `ACTION <on> <open> <name>`, `STEP <cmd> <on> <dialog> <name>`, `PARAM`.
The command palette now puts an exact name match first (typing "Invert" ran Invert Selection).
Phase 2 started 2026-11-22: the kit in TOOLS/ACTIONS (`ACTS_prm_lng&` / `ACTS_prm_put` /
`ACTS_dlg_silent%` / `ACTS_dlg_cancel`: KEY=value PARAM lines; a cancelled dialog records no
step) and two dialogs wired - Posterize (LEVELS / DITHER / STRENGTH) and Resize Image with
Content (typed: W / H; only X2 / /2 pressed: DOUBLE = net presses, so it scales any image).
A wired dialog: read each value, `DO WHILE ctx.done = 0` (skipped when silent), put / cancel
after. Then all of IMAGE-ADJ (70 dialogs, wired by a script: each state variable read with
`ACTS_prm_num#`, put under its own name in upper case; values are DOUBLE so fractional
sliders survive) and Remap to Palette (DITHER / STRENGTH). Remove Background is left out (it
picks colours off the image, so a replay of fixed values is not meaningful). Other dialogs
outside these still open on play.
History and Actions show a dock title strip (`DOCK_slot_titled%`) even as a lone tab.
Then Canvas Resize (W / H; skips the input box when silent) and Stroke Selection (COLOR as
FG / BG / TRANS so it follows the colours at play time, TYPE, WIDTH).
Inventory 2026-11-22 (every recordable command - Edit / Layer / Canvas / Select / Image / Color -
traced to a dialog or input box): all the image dialogs above are wired; the input boxes go
through `ACTS_ask$(key, ...)` (text values: `ACTS_prm_str$` / `ACTS_prm_put_str`): Rename Layer
(NAME), Tag Frames... (NAME), Frame Note... (NOTE), Hold for N Frames... (FRAMES), Clip Layer:
Rename Clip Source (NAME). Not recorded at all (`ACTS_recordable%`) - windows and file pickers,
an action would stop on them each play: Settings, Customize Controls, Animation Settings, the
TheDraw font browser, the Pixel Art Analyzer, text style import / export, AnimBrush Load,
Soundtrack / Add Sound. Left asking on purpose: Remove Background (it picks colours off the
image), yes / no confirmations (a question, not a value: Delete Set..., the max-layers alert).
Insert stop (2026-11-22): a step whose command is `ACTS_CMD_STOP` (-1), its name the message
(`STEP -1 <on> 0 <message>`). Insert Stop... (menu 9110, command 2709 `Actions: Insert Stop...`):
on an action at its end, on a step after it, while recording at the record point. Play shows
the message (`DRAW_message_box_ex%`: a message box with its own labels - CONTINUE | STOP);
STOP sets `ACTS.halted` and ends the play there (a set's later actions too); what ran stays,
one undo step. No dialog box on its row; double-click edits the message. Dump ACTP ... halted.
QA actions-palette.sh 5c.
Action keys (2026-11-22): 20 slots, commands 2740-2759 (`ACTP_ACT_KEY1`; 2710-2713 are canvas
recording's), each registered in `INPUTS_register_all` as an unbound dispatched key bind, so a
slot's key is an ordinary user override (`BINDINGS_set_override`, DRAW.bindings) - conflicts,
steal, Customize Controls all apply. An action holds a slot (`ACTS_KEY`, file line `KEY <slot>`
after its ACTION); Assign Key... (menu 9111) takes its slot or a free one and opens Controls'
Rebind Key box (`CTRL_assign_key%`) on that slot's bind, labelled `Action: <name>`
(`ACTS_keys_sync` on every change); CLEAR + OK or Clear Key (9112) unbinds it; deleting the
action / set lets its key go (`ACTS_keys_free`); a duplicate gets no key. Controls lists a slot
only while an action holds it. The key shows dim at the row's right. The box writes
`DOCK_DUMP.ctrlkey` for QA (modal). A set file moved to another machine keeps its slots but
the keys live in that machine's DRAW.bindings. Dump `ACTPK node slot key`. QA 5d.
Batch (2026-11-22): `ACTS_batch%(action, inDir, outDir, ext)` lists the folder first (png bmp jpg
jpeg gif tga qoi hdr pcx draw; outDir may be inside it), then per image `DRW_load` + `ACTS_play`
(one undo step; `ACTS.batch` makes stops go on) + `BATCH_export%` (so the formats are --export's).
GUI Batch... (menu 9113, `ACTP_batch`): two typed folders (remembered this run), PNG | DRAW |
Cancel; the document open is saved to the cache as a .draw first and loaded back after (file
names, dirty flag, zoom / pan restored; undo history lost - noted in the manual). CLI
`--action SET/NAME` (or NAME) plays on the FILE before its exports; with `--batch-in DIR
[--batch-out OUT] [--batch-format EXT]` the folder instead (exit 1 if any failed or none).
QA actions-palette.sh 5e (GUI), actions-batch.sh (CLI, 9 checks). Dump ACTP ... batchFail.
Phase 3, first slice (2026-11-22): tool steps. `STEP -2` (`ACTS_CMD_TOOL`), PARAM TOOL= X1= Y1=
X2= Y2= (rect / ellipse FILLED=, ellipse SLICES= RINGS=) COLOR= (DRAW_COLOR, the colour it drew
with - FG or BG by button) SIZE= (BRUSH_SIZE.CURRENT index); a brush stroke PTS="x,y x,y ..." (up
to `ACTS_PTS_MAX` = 4000 points). Recorded: `MOUSE_dispatch_tool_release` - an undo step saved
by the release = a step (`ACTS_tool_did CURRENT_TOOL%`); fill at its click (MOUSE.BM, around
`MOUSE_tool_fill`); brush points by `ACTS_tool_track` before each hold dispatch. Played
(`ACTS_tool_play%`): colour / size set for the step and put back, sounds off, FILL_ADJ off,
`HISTORY_saved_this_frame%` cleared; line / rect / ellipse = the tool state + its own release
(`MOUSE_release_line` / `_rect` / `_ellip`: one undo record each, inside the play's group);
fill = a made-up press at X1,Y1 into `MOUSE_tool_fill` (the real MOUSE put back); brush =
`ACTS_brush_play%`: the points as line segments through `MOUSE_release_line` with
`HISTORY_IN_PROGRESS%` set (no record each), then one `HISTORY_record_brush` "Brush Stroke".
Panel: no dialog box on a tool step; the tooltip notes it. QA actions-palette.sh 5f.
Phase 3, the rest (planned):
- More tools: eraser (the brush path with transparent colour, smart erase across layers),
  dot, spray (its random dabs: record the dabs, not the seed), polygon / filled polygon (the
  vertex list), smart shapes (their parameters are tool state like ellipse SLICES), bezier
  (control points), text (layer + string + font: better as its own step kind), MyPaint (the
  stroke's points + pressure through `mp_*`), move / transform (their matrices).
- The brush, faithfully: record pressure / tilt per point (TABLET) and replay through
  `MOUSE_brush_paint_to` with the pen state fed in, so pressure size / opacity and the
  stabilizer reproduce; pixel-perfect after.
- Options per step: the tool bar's values that matter (line caps / spokes, AA, custom brush
  and drawer paint mode by name), so a played step does not depend on the bar at play time.
- Relative coordinates (Photoshop-like "allow tool recording" choices): canvas px as now, or
  fractions of the canvas, so an action recorded on 320x200 scales onto another size in Batch.
- Edit a tool step's values (double-click: X1..Y2, colour) in the panel.

Design notes as planned:

Photoshop's Actions panel: **sets -> actions -> steps**.

- Tree rows: set (folder), action, step. Disclosure triangle per set / action. Per row: an
  ENABLED checkbox (off = skipped on play) and a DIALOG toggle (step shows its dialog on play).
- Bottom buttons: STOP, RECORD, PLAY, NEW SET, NEW ACTION, DELETE. Right-click: rename,
  duplicate, delete, play from here, insert stop (done), assign key (done).
- **Recording** hooks the top level of `CMD_execute_action` (a depth counter: commands that call
  commands record once). Not recorded: undo / redo, the Actions panel's own commands, app chrome
  (panel show / hide, settings, quit). Recording shows a red dot on the RECORD button and in the
  status bar.
- **Playing** runs the enabled steps in order as ONE undo step (`HISTORY_begin_group`). A step
  whose command cannot run (needs a selection, ...) is skipped and noted in the status bar.
  Decided (Rick 2026-11-22): "Skip is fine, makes sense." / "Yes record dialog with per step toggle
  like photoshop" - a step keeps the dialog values it was recorded with and replays them silently;
  its DIALOG toggle (per step) shows the dialog instead, filled with those values.
- **Steps, phase 1**: commands (`ACTION <id>`). Phase 2: dialog values captured per command,
  replayed without the dialog unless its DIALOG toggle is on. Phase 3: tool strokes (recorded
  canvas-space pointer input fed back through the tools - Photoshop's "Allow Tool Recording").
- **Files**: `<data>/ACTIONS/<set name>.dact`, readable text, one step per line, e.g.
  `ACTION 318 ; Scale 2x`. Saved on every change. A starter set (DEFAULT ACTIONS) is seeded once.
- Later: hotkey per action (bindings), command palette entries, Batch (a folder of files) - all done 2026-11-22.

## 3. Canvas recording (time-lapse)

**Phase 1 done 2026-11-22** (`TOOLS/CANVAS-REC`, `CREC_`; see the drRc section of
`.claude/instructions/draw-fileformat.md`): frames on settled history states (changed rect of
the flatten, deflated), the REC badge (click pause / resume, right-click the viewer), Edit >
Record Canvas / Pause / Delete..., Settings > General > Canvas Recording (`CANVAS_RECORDING`,
`CANVAS_RECORDING_MB` = 64), the drRc chunk (no .draw version change - an own chunk, like drAx),
thinning by merging the oldest pairs, View > Canvas Recording... (play / scrub / speed, export
APNG with sub-rect frames, PNG sequence, scale 1-8x; the same from the CLI: `--export-recording
X.apng|X.png`, `--recording-fps`, `--recording-scale`, OUTPUT/BATCH). Actions 2710-2713. QA:
`canvas-recording.sh` (22 checks), `canvas-recording-playback.sh` (draws a 23-step scene, exports
it from the CLI: the last frame = the saved picture pixel for pixel; keeps the .apng / .gif). `canvas-recording-save.sh`: Save As Yes /
No (drRc kept / left out, a later Ctrl+S too: dump `CRECT ... omit`), the viewer's EXPORT APNG / GIF /
PNGS / CLOSE buttons (modal: geometry in DOCK_DUMP + `.crecv`); it found `name.apng` saving as
`name.apng.png` (CYCX_save_dialog$ now keeps any type its filter lists - the animation APNG and
DeluxePaint `.iff` dialogs had it too). `canvas-recording-big.sh`: 4096x4096 timing. Save As (and a first save) asks whether to keep it
in the file (`CREC_ask_keep`; No = this document saves without it). GIF export (2026-11-22):
`CREC_export_gif%` - viewer EXPORT GIF... and `--export-recording X.gif`; exact colours when <= 256
(255 + transparent), else the animation GIF's median cut (`ANIM_MC_cut%`, split out of
`ANIM_MC_palette%`); opaque = changed-rect frames (dispose none), with transparency = whole
frames (dispose to background); 1/100 s timing (<= 50 fps), the last 2 s, no loop (like the APNG).
Cost measured 2026-11-22 (QA `canvas-recording-big.sh`, dump `CRECT capMs flatMs diffMs`, Linux, Xvfb):
a 4096x4096 picture, one capture after a dab = 34 ms with 3 layers (flatten 28, compare 6),
~98 ms with 12 layers (flatten 91, compare 6); a 1024 canvas is 1/16 of that. The full-canvas
compare is not the cost (6 ms at 64 MB); the flatten is, and it grows with the layer count.
It runs once a step, after 0.15 s with no button held, so it is not felt while drawing. If it
ever is: a flatten limited to a rect (LAYERS_flatten& clipped - groups, aprons, lanes and blend
kernels all take a source rect) with the rect from the history records (x1..y2 of the region
kinds; a whole-layer kind = the full canvas).

Separate from macros. Every committed canvas change saves the changed rect of the composite;
a viewer plays / scrubs it, export through the animation exporters (GIF / APNG / PNG sequence).
Decided (Rick 2026-11-22): "We can keep it always on if it's low overhead? A rec button to make it
obvious though. And make it toggle for users... Some artists dislike the idea of a written
history/record of their choices." / "Inside the .draw file would be great because then it would
just go with it and always be there available."

- **On by default, low overhead**: a frame only when a history step commits (no timer), only the
  changed rect of the composite, compressed in the background of the next idle frames. A size cap
  (e.g. 64 MB a document) thins the oldest frames rather than stopping.
- **A REC button** in the status bar, always visible: red dot = recording, click = pause / resume
  for this document. Paused shows plainly (grey, "REC PAUSED").
- **A toggle for users** who want no record at all: Settings `CANVAS_RECORDING` (default TRUE); off
  = nothing is recorded and nothing is written, the REC button shows OFF. Plus **Delete Recording**
  (asks) for a document that already has one, and Save As offers to leave it out.
- **Inside the .draw file**: its own PNG chunk (like `drAn`), a new .draw version; files without it
  open as before, older DRAWs skip the unknown chunk. A recording travels with the file.
- Viewer: play / scrub / speed, export through the animation exporters (GIF / APNG / PNG sequence).

## Order

1. History palette - done.
2. Actions palette, phase 1 - done (DP_ACTIONS = 15 shifted the natives to 16-23).
3. Actions phase 2 (dialog values), per dialog as needed.
4. Canvas recording.
5. Actions phase 3 (tool strokes).

