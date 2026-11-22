# Ch. 17  ↩️ Undo, Redo & History

> **What you'll learn:** How DRAW's unified history system works, why text-local undo is separate, and why you can experiment fearlessly.

---

## History System — Fearless Experimentation

> 🎯 **Goal:** Understand the unified undo/redo system.

DRAW has **one timeline** for everything you do — drawing, transforms, layer ops, palette ops, even the import overlay. Press `Ctrl+Z` to step backward and `Ctrl+Y` to step forward.

### How history is recorded

History records **on mouse release**, automatically. There is no manual save-state command, and there is a guard against double-recording on the same frame. Each entry carries a human-readable label — *"Brush"*, *"Merge Down"*, *"Scale 2x"* — shown in the History palette and used for comments in QB64PE Project Export.

### The History palette

**View > History** shows the whole timeline as a list, one row per undo step:

- The top row is the document as it was opened or created. Below it, one row per step, named after what it did (*BRUSH*, *MERGE DOWN*, *SCALE 2X* ...). Several changes made as one step (a multi-layer flip, an effect on a text layer) are one row.
- The **current state** is highlighted, with a marker at its left. The rows after it are dimmed — they are the steps `Ctrl+Y` would bring back.
- **Click any row** to go straight to that state: DRAW undoes (or redoes) step by step until it gets there. Make a new change while back in history and the dimmed rows go, exactly as with `Ctrl+Z`.
- **UNDO / REDO / CLEAR** buttons sit under the list. CLEAR (also **Edit > Clear History...**) removes every undo step after asking; the picture stays as it is.
- **Right-click** the list: Step Backward, Step Forward, Clear History.
- The wheel scrolls the list (`Shift` + wheel: 10 rows); the list follows the current state as you work.

It is a dock panel like the others: dock it in any column or row, tab it, float it, resize it, close it with its **[x]**, and give it its own **Scale** from its handle's right-click menu. Workspaces remember whether it shows and its scale (`HISTORY_PANEL`, `HISTORY_PANEL_SCALE`).

### The Actions palette — record and replay

**View > Actions** records what you do and plays it back, like Photoshop's Actions:

- **Sets** hold **actions**, and actions hold **steps**. Each set is a file in DRAW's data folder (`ACTIONS/<set name>.dact`) and is saved as you change it. The first time, DRAW writes a starter set, *Default Actions*: Mirror Both Ways, Rotate 180 and Gray Negative.
- **NEW ACTION** asks for a name and starts recording into it. Do what the action should do, then press **STOP**. Commands that change the picture are recorded as steps: Edit, Layer, Canvas, Select, Image and Color commands, from the menus, the command palette or their keys. Undo / redo, View and File commands, picking tools, and the palettes' own buttons are not recorded.
- **REC** records more steps into the selected action. If a step is selected, new steps go in after it.
- **PLAY** plays the selection: a whole set, one action, or an action starting from the selected step. A play is **one undo step** (the History palette shows it as *ACTION: name*), so a single `Ctrl+Z` takes all of it back. A step whose command DRAW no longer has is skipped, and the status bar says how many were.
- Each row has an **on** box. Turn it off and play skips that step, action or set. A step also has a **dialog** box. A step keeps the values its dialog was OK'd with and plays them back without showing the dialog. Turn the dialog box on and play shows the dialog instead, filled in with those values. Hover a step to see its values. A dialog you cancel while recording records no step. Every **Image** and **Effects** dialog keeps its values (all but Remove Background, which always opens), and so do **Remap to Palette** and **Resize Image with Content**. Resize keeps the size you typed, or, if you only used ×2 / ÷2, those presses, so the action scales whatever image it is played on.
- Click a set's or action's triangle to fold it. Double-click a set or action to rename it.
- **NEW SET** / **DELETE** buttons; right-click for Play, Record / Stop Recording, New Set, New Action, Rename, Duplicate, Delete and Reload Action Sets. Deleting a set deletes its file. Deleting an action that has steps asks first.

Both palettes show a title strip when docked (HISTORY / ACTIONS, with a fold triangle and **[x]**). The Actions palette docks, floats, scales and closes like the History palette; workspaces remember `ACTIONS_PANEL` and `ACTIONS_PANEL_SCALE`.

### Canvas recording — a time-lapse of your work

DRAW records how a picture comes together, so you can play it back as a time-lapse:

- **It is on by default** and costs little: a frame is added only when a change is committed (a step, an undo, a redo), and only the part of the picture that changed is kept.
- **The REC badge** at the right of the status bar shows it: a red dot and *REC* while recording, *REC PAUSED* (grey) when paused, *REC OFF* when it is turned off. **Click** it to pause or resume recording for this document; **right-click** it to open the viewer. While paused, nothing is recorded; when you resume, everything that changed meanwhile becomes one frame.
- **The recording is saved inside the `.draw`** (and inside a PNG saved with Ctrl+S), so it travels with the file. Older DRAWs open the file and simply ignore it. **Save As** asks whether to keep the recording in the new file; answer *No* to share a copy without it (later saves of that document leave it out too).
- **View > Canvas Recording...** plays it: PLAY / PAUSE, step to the first or last frame, drag the bar to scrub, change the speed (5 - 160 frames a second). `Space` plays, `←` / `→` step, `Home` / `End` jump, `Esc` closes. **EXPORT APNG...** writes an animated PNG (each frame shown for the chosen speed, the last held two seconds); **EXPORT PNGS...** writes every frame as `name_0001.png ...`. **EXPORT 1X** cycles the export scale (1x, 2x, 4x, 8x, pixel-sharp).
- **Edit > Delete Canvas Recording...** removes the document's recording (it asks first); recording then starts again from the picture as it is. **Edit > Pause Canvas Recording** is the same as clicking the badge.
- **If you don't want any record**, turn off **Edit > Record Canvas** (or Settings > General > Canvas Recording > *Record Canvas*): nothing more is recorded or written. *Recording Limit (MB)* caps a document's recording (default 64 MB); above it the oldest frames are merged in pairs, so the start and the end are always there.

### Multi-layer awareness

When an operation affects multiple layers (a multi-layer select-and-flip, a Smart Erase across visible layers, a group merge, etc.), DRAW records a single composite history step. Smart Erase additionally tracks per-layer erasure so undo / redo behaves intuitively per layer.

### Text-local undo

The text tool has its own 128-state local history while you are editing a text layer. `Ctrl+Z` and `Ctrl+Y` operate on that local history during text entry — typo experiments don't pollute the global timeline. As soon as you commit (`Esc`), the entire edit becomes a single global history entry.

### Try things

The single biggest productivity unlock in DRAW is: **try things**. Symmetry, palette ops, blend modes, custom-brush fills, and transform overlays are all undoable. There is no "save first" anxiety — `Ctrl+Z` always works.

> 💡 **Tip:** When you make a destructive-looking change (palette ops, image adjustments), don't try to remember the parameters. Just `Ctrl+Z` and `Ctrl+Y` to flip-flop and visually compare.

---

➡️ Next: [Chapter 18 — Real-World Pixel Art Workflows](18-workflows.md)
