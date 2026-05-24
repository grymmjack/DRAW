# Manual QA — Input Rearchitecture (branch `input-rearchitecture`)

This checklist exists to verify the 20-commit input rearchitecture branch doesn't regress any user-facing behavior before merging to `main`. The work is deliberately gated on `--developer` so normal usage should feel identical to before.

**Strategy**: smoke-test normal usage first (should feel like main), then exercise dev mode (should produce expected `inputs.log` output), then exercise every recent feature in main to verify no regressions.

---

## Setup

```bash
cd ~/git/DRAW
git checkout input-rearchitecture
make clean && make           # foreground, 600000ms timeout per project convention
```

Verify: clean compile, `DRAW.run` binary appears in the project root.

---

## Part 1 — Normal mode (no `--developer` flag)

Launch normally — this exercises the "zero behavior change for normal users" guarantee.

```bash
./DRAW.run
```

### 1.1 — Startup
- [ ] App opens without crash
- [ ] No `inputs.log` file appears in the project directory (`ls inputs.log` → `No such file or directory`)
- [ ] Toolbar, menubar, layer panel, palette strip, edit bar, adv bar all render correctly
- [ ] Status bar at bottom shows tool name + canvas coords

### 1.2 — Basic drawing
- [ ] Press `B` → switches to Brush tool (status bar updates)
- [ ] Left-click + drag on canvas → paints a stroke
- [ ] Right-click + drag → paints with BG color
- [ ] Middle-click + drag → pans the canvas
- [ ] Ctrl+Wheel → zooms in/out centered on cursor

### 1.3 — Recent feature regression checks
These are the features touched by recent main commits — they should all still work identically.

#### G-chord grid resets (commits 6f239f4 + d43e32f earlier)
- [ ] Hold `G` + press `R` → grid offset resets to (0,0) — no tool switch
- [ ] Hold `G` + press `Shift+R` → grid SIZE resets to theme default (10×10) — no tool switch
- [ ] Hold `G` + press `Ctrl+R` → both offset + size reset — no tool switch (and reference image does NOT toggle)
- [ ] Tap just `R` (no G held) → switches to Rectangle tool
- [ ] Tap `Shift+R` (no G held) → switches to Rectangle Filled tool
- [ ] Tap `Ctrl+R` (no G held) → toggles reference image

#### Asymmetric grid (1px axis support — commit bb212a8)
- [ ] Open Settings → set Grid Width = 2, Grid Height = 1 → Apply
- [ ] Canvas shows VERTICAL bands every 2 pixels, NO horizontal lines (Atari 2600 style)
- [ ] Open Settings → set Grid Width = 1, Grid Height = 2 → Apply
- [ ] Canvas shows HORIZONTAL bands every 2 rows, NO vertical lines (Apple II hi-res style)
- [ ] Reset Grid Width = 10, Grid Height = 10 → normal grid restored

#### Marquee handle floor (commit 449569b)
- [ ] Create a 2×1 or 3×2 marquee selection
- [ ] Resize handles around the marquee are 3×3 pixels (small enough to see the selection)

#### Settings Apply bar visibility (commit 548b1ce)
- [ ] Open View menu → hide Edit Bar
- [ ] Open Settings → Apply (without changing anything)
- [ ] Edit Bar stays hidden (does NOT reappear)
- [ ] Show Edit Bar via View menu → it appears
- [ ] Open Settings → Apply → it stays visible

#### Per-axis scale (commits 449569b + earlier)
- [ ] Open a project with a sprite (or use Mario template at `ASSETS/TEMPLATES/320x200-2x1 Pixels.png`)
- [ ] Right-click layer → SELECTION FROM LAYER → marching ants around sprite
- [ ] Press `Ctrl+Home` → sprite doubles in width, ants follow new silhouette
- [ ] Press `Ctrl+End` → also doubles in height, ants follow
- [ ] Press `Ctrl+Z` → single undo restores both layer pixels AND original ant shape

### 1.4 — Tool keys (sample)
Quick sanity: each tool key still switches tools.
- [ ] `B` → Brush, `D` → Dot, `F` → Fill, `L` → Line, `P` → Polygon, `R` → Rectangle, `C` → Ellipse
- [ ] `E` → Eraser (tap), Hold `E` while drawing → temporary eraser
- [ ] `M` → Marquee, `W` → Magic wand, `V` → Move, `T` → Text, `Z` → Zoom, `I` → Picker, `S` → Smart shapes

### 1.5 — Held-key modifiers
- [ ] Hold `Space` → cursor switches to pan; drag pans the canvas
- [ ] Hold `Alt` while painting → temporarily switches to color picker
- [ ] `Z + 1` → zooms to 100%, `Z + 2` → 200%, ..., `Z + 0` → 3200%
- [ ] `M + =` (with selection active) → expands marquee by 1px
- [ ] `M + -` → contracts marquee by 1px

### 1.6 — Layer panel
- [ ] Click a layer → selects it
- [ ] Right-click a layer → context menu appears
- [ ] Double-click a layer name → rename mode
- [ ] Drag a layer up/down → reorders
- [ ] Wheel over layer panel → scrolls list

### 1.7 — Palette
- [ ] Left-click a swatch → sets FG color
- [ ] Right-click a swatch → sets BG color
- [ ] Wheel over palette strip → cycles palettes

### 1.8 — File operations (sanity)
- [ ] `Ctrl+S` → save dialog
- [ ] `Ctrl+O` → open dialog
- [ ] `Ctrl+N` → new canvas
- [ ] `Ctrl+Z` / `Ctrl+Y` → undo / redo
- [ ] `Ctrl+C` / `Ctrl+X` / `Ctrl+V` → copy / cut / paste with a selection
- [ ] `Ctrl+A` → select all
- [ ] `Ctrl+D` → deselect

### 1.9 — Performance sniff test
- [ ] Paint a continuous stroke for ~10 seconds — no visible lag, no stutter, FPS feels normal
- [ ] Switch tools rapidly (`B B B F F F`) — instant response
- [ ] Open and close panels (Layer panel via Ctrl+L, command palette via Ctrl+P) — no delay

**If all of Part 1 passes**: normal-mode behavior is unchanged. ✅

---

## Part 2 — Developer mode (`--developer` flag)

```bash
rm -f inputs.log         # start fresh
./DRAW.run --developer
```

### 2.1 — Startup output
After launch (before doing anything else), quit and check:
```bash
cat inputs.log
```
Expected output (exact timestamps will differ; counts after Phase 6a-c):
```
[<time>] [INIT] DRAW 1.5.0 developer mode active
[<time>] [INIT] 0 input bindings registered
[<time>] [AUDIT] Scanning 167 bindings for conflicts
[<time>] [AUDIT] Complete: 0 conflicts found
[<time>] [INIT] After registration: 167 bindings
[<time>] [INIT] dispatched=TRUE: 36, letter skip-list size: 31
[<time>] [GAMEPAD] 3 input device(s) detected (stub — no translation active)
```

- [ ] `inputs.log` appears in project directory
- [ ] `[INIT]` line shows version + dev mode
- [ ] `[AUDIT]` reports **0 conflicts** on **167 bindings**
- [ ] `[INIT] dispatched=TRUE: 36, letter skip-list size: 31` confirms Phase 6a-c migration
- [ ] No `[CONFLICT]` lines anywhere
- [ ] No `[CONSISTENCY]` warnings anywhere
- [ ] `[GAMEPAD]` line shows device count (your machine's input devices)

### 2.2 — F12 dispatched=TRUE proof
This is the one binding wired through the new dispatcher.
```bash
rm -f inputs.log
./DRAW.run --developer
# press F12 a few times
# quit
cat inputs.log
```
Expected: in addition to the startup lines, you'll see alternating `[FIRE]` and `[DEBUG]` pairs per F12 press:
```
[<time>] [FIRE] evt=1 region=0 action=9999 label=F12 dev debug dump (dispatched=TRUE proof)
[<time>] [DEBUG] F12 fired via central dispatcher: evt=1 key=28416 mods=0 ctx=... mouseXY=(...)
```

- [ ] Pressing F12 produces `[FIRE]` lines
- [ ] Each `[FIRE]` is followed by `[DEBUG]` (action handler invoked)
- [ ] `mouseXY` matches roughly where your cursor was

### 2.3 — Audit sanity check
Try deliberately introducing a duplicate binding to verify the audit detects conflicts.

Easiest test: in `INPUT/INPUT.BM`, find the `INPUTS_register_all` SUB and duplicate any line (e.g. duplicate the "Undo" registration). Rebuild and run.

```bash
# After deliberately duplicating a binding in INPUT.BM:
make clean && make
rm -f inputs.log
./DRAW.run --developer
# quit immediately
cat inputs.log
```
Expected:
```
[AUDIT] Scanning 162 bindings for conflicts
[CONFLICT] (51) Undo <-> (162) Undo
[AUDIT] Complete: 1 conflicts found
```

- [ ] Audit detects the duplicate
- [ ] Restore the duplicate, rebuild, re-verify audit returns to 0 conflicts

### 2.4 — Phase 6a–c migration smoke test

35 keys have been flipped from `dispatched=FALSE` (legacy-only metadata)
to `dispatched=TRUE` (central dispatcher owns dispatch). In dev mode each
should produce **exactly one** `[FIRE]` line per press, and the
corresponding behavior should match what main does.

```bash
rm -f inputs.log
./DRAW.run --developer
```

**Tool keys (Phase 6a-iii)** — press each in turn, verify tool switches:
- [ ] `B` → Brush. `[FIRE] action=101`
- [ ] `D` → Dot. `[FIRE] action=102`
- [ ] `F` → Fill. `[FIRE] action=103`
- [ ] `L` → Line. `[FIRE] action=105`
- [ ] `P` → Polygon. `[FIRE] action=106`
- [ ] `Shift+P` → Polygon Filled. `[FIRE] action=107`
- [ ] `R` → Rectangle. `[FIRE] action=108`
- [ ] `Shift+R` → Rectangle Filled. `[FIRE] action=109`
- [ ] `C` → Ellipse. `[FIRE] action=110`
- [ ] `Shift+C` → Ellipse Filled. `[FIRE] action=111`
- [ ] `M` → Marquee. `[FIRE] action=112`
- [ ] `V` → Move. `[FIRE] action=113`
- [ ] `T` → Text (VGA default). `[FIRE] action=114`
- [ ] `Shift+T` → Text Tiny5. `[FIRE] action=115`
- [ ] `E` → Eraser (tap, not hold). `[FIRE] action=118`
- [ ] `W` → Magic Wand. `[FIRE] action=117`
- [ ] `I` → Picker. `[FIRE] action=104`
- [ ] `S` → Smart Shapes (single tap activates). `[FIRE] action=1706`
- [ ] `S` `S` quickly (within 600ms) → Smart Shapes cycle. Two `[FIRE] action=1706` lines.
- [ ] `Q` → Bezier. `[FIRE] action=122`
- [ ] `K` → Spray. `[FIRE] action=1702`
- [ ] `Z` → Zoom. `[FIRE] action=1701`
- [ ] (After clicking inside a TOOL_SS_BEVEL_RECT shape) `I` → bevel inner style. `[FIRE] action=104`
- [ ] (Same) `O` → bevel outer style. `[FIRE] action=1707`

**Context guards still work**:
- [ ] In Magic Wand mode (`W`), pressing `F` does **not** switch tool (no `[FIRE]` for action 103)
- [ ] With MOVE active + floating selection, `V` fires **action 316** (flip vertical), not action 113

**Opacity / X swap (Phase 6b)**:
- [ ] `1` → opacity 10%. `[FIRE] action=501`
- [ ] `2` → opacity 20%. `[FIRE] action=502`
- [ ] ... through ...
- [ ] `0` → opacity 100%. `[FIRE] action=510`
- [ ] `X` → swap FG/BG colors. `[FIRE] action=517`
- [ ] While drawing a 3D dice (TOOL_SS_3D_CUBE + dragging), digit keys do **not** fire opacity (CTX_SS_DRAGGING in forbidCtx)
- [ ] While holding `Z`, `1`..`0` fires Z-zoom-preset (still legacy), NOT opacity

**Brush size (Phase 6c)**:
- [ ] `[` → brush size −. `[FIRE] action=601`
- [ ] `]` → brush size +. `[FIRE] action=602`

**Double-fire check** (the biggest regression risk):
- [ ] After pressing each key once, the `inputs.log` shows **one** `[FIRE]` per press (not two)
- [ ] Tool actually switched only once (no double-execution side effects like double `SOUND_play` on `M`/`W`)

---

## Part 3 — Long-soak QA

Spend 15-30 minutes using DRAW as you normally would for actual art work. Specifically:

- [ ] Open a real `.draw` project file
- [ ] Paint with multiple tools, switch tools often, use chords
- [ ] Add/remove layers, reorder them, change opacity
- [ ] Use marquee selections, lift them into MOVE, transform
- [ ] Use the custom brush capture + stamp flow
- [ ] Open and close panels (color mixer, drawer, character map, image browser)
- [ ] Export to PNG and verify the output file
- [ ] Save the project, close, reopen — verify all state restores correctly

**At no point should you experience**:
- Cursor lag
- Tool switches not firing
- Modifier combos behaving unexpectedly
- Panels not responding to clicks
- Settings dialog clobbering panel visibility
- Any visible regression from main

If you DO see anything weird in dev mode, `cat inputs.log | grep -E '\[CONFLICT\]|\[CONSISTENCY\]|\[OVERFLOW\]'` to see warnings.

---

## Part 4 — Sign-off

- [ ] All Part 1 (normal mode) items pass — no regression
- [ ] All Part 2 (dev mode) items pass — new infrastructure works
- [ ] Part 3 long-soak passes — no soak-time regressions
- [ ] You're ready to merge

If anything fails: capture the symptom, the `inputs.log` (if dev mode), and report back. Most failures will be either (a) a missed legacy handler that needs a context exclusion, or (b) a panel that forgot `REGION_set_bounds` in its render SUB.

## Merge command

```bash
git checkout main
git merge --no-ff input-rearchitecture
# or if you want to squash:
# git merge --squash input-rearchitecture && git commit
git push origin main
```

After merge, the `input-rearchitecture` branch can be deleted:
```bash
git branch -d input-rearchitecture
git push origin --delete input-rearchitecture
```
