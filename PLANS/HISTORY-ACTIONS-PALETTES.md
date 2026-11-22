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

Built (QA `actions-palette.sh`, 42 checks): the tree with ON / DIALOG boxes and fold triangles,
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
Not yet: insert stop, a hotkey per action, Batch, tool strokes (phase 3).

Design notes as planned:

Photoshop's Actions panel: **sets -> actions -> steps**.

- Tree rows: set (folder), action, step. Disclosure triangle per set / action. Per row: an
  ENABLED checkbox (off = skipped on play) and a DIALOG toggle (step shows its dialog on play).
- Bottom buttons: STOP, RECORD, PLAY, NEW SET, NEW ACTION, DELETE. Right-click: rename,
  duplicate, delete, play from here, insert stop (later), assign key (later).
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
- Later: hotkey per action (bindings), command palette entries, Batch (a folder of files).

## 3. Canvas recording (time-lapse)

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

