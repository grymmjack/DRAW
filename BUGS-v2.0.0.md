# BUGS — v2.0.0 Input-Seam Hardening

> Working branch: `v2.0.0-input-hardening` (off `main`). This file consolidates every
> input/state-seam bug found while mapping the transitions BETWEEN tools, operations, and
> internal states for v2.0.0. Fixes land on the branch, not `main`.
>
> Legend: `- [ ]` open · `- [x]` fixed & verified · `⛔ BLOCKED` needs a Rick decision.

## HOW TO USE
Each bug has: **Symptom**, **Root cause** (file:line), **Repro**, **Fix approach**, **Status**.
When a bug needs a design decision only Rick can make, it is marked `⛔ BLOCKED` and left open
so we can execute it together later — the loop does not stop for it.

---

## OPEN / TO FIX

### BUG-1 — Paste leaves a stale magic-wand selection mask ("wand selects things that aren't there")
- [ ] **Symptom (Rick, 2026-08-24):** after clipboard copy/paste, the magic wand selects
  regions that don't correspond to visible content.
- **Root cause:** one buffer is shared by the clipboard and wand subsystems:
  `MARQUEE.SELECTION_MASK` (`TOOLS/MARQUEE.BI:93`) + `WAND_HAS_SELECTION` + `WAND_MIN/MAX_*`
  bounds + `WAND_EDGE_*` cache.
  - `CLIPBOARD_paste` (`TOOLS/SELECTION.BM:234`) calls `TOOLS_reset_all FALSE` (`:287`), and
    `GUI/GUI.BM:57-60` only resets marquee+wand when the flag is TRUE. So paste **preserves**
    a live wand mask (by design, "usually we preserve selection as clipping mask",
    `GUI/GUI.BM:56`) while it **overwrites `MARQUEE.BOX`** with the paste rect (`:269-279`).
    The mask geometry (`WAND_MIN/MAX_*`) is now stale — it no longer matches `MARQUEE.BOX`
    or any visible content.
  - `MOVE_apply_transform` (`TOOLS/MOVE.BM:618`) then **shifts the stale mask** and adds the
    move delta to `WAND_MIN/MAX_*` for any live `SELECTION_MASK` (`:1035-1057`), and does a
    "mask-aware clear" through it (`:767-792`). The wand outline/selection is dragged to an
    arbitrary location over non-matching pixels.
  - Downstream ops all re-read the stale mask via `WAND_HAS_SELECTION AND SELECTION_MASK < -1`
    (fill FG/BG `GUI/COMMAND.BM:2675,2741`; flips `:3447,3637`; crop `:5218`; clear-selection
    `TOOLS/SELECTION.BM:440`; stroke-sel `GUI/STROKE-SEL.BM:264-368`; save `TOOLS/SAVE.BM:476`;
    image-adjust `GUI/IMAGE-ADJ.BM:162-390`).
  - ADD/SUBTRACT wand clicks MERGE onto the stale mask (`MARQUEE.BM:1111-1114` etc.); only a
    REPLACE-mode click self-heals via `MAGIC_WAND_reset` (`MARQUEE.BM:1036`).
- **Repro:** make a wand selection somewhere → copy something → paste → move/commit the paste
  (or shift-click the wand) → wand geometry is now wrong.
- **Fix approach (decision):** either (a) clear the wand mask on paste when it isn't being
  used as an intentional clip, or (b) scope `MOVE_apply_transform`'s mask shift/clear to
  genuine wand selections rather than any leftover `SELECTION_MASK`. Leaning (a)+(b): on paste,
  if the pasted content is NOT being clipped into an existing selection, call
  `MAGIC_WAND_reset`; and gate MOVE's mask-shift on "this move owns the mask." See Phase D.
- **Fix (applied):** in `CLIPBOARD_paste` (`TOOLS/SELECTION.BM`), call `MAGIC_WAND_reset`
  immediately after `TOOLS_reset_all FALSE` — paste establishes a NEW rectangular selection
  (`MARQUEE.BOX`), so the leftover per-pixel wand mask (with stale bounds) must be dropped. The
  rectangular marquee is preserved; only the wand mask/flags/bounds are cleared.
- **Status:** FIXED (pending build+QA verify). Precise pixel-level repro is hard to automate
  (selection-outline geometry); `seam-copy-then-wand.sh` is a functional smoke of the seam,
  visual confirmation is manual.

### BUG-2 — Content on the canvas that cannot be erased until reload (orphaned TRANSFORM overlay)
- [ ] **Symptom (Rick, 2026-08-24):** visible pixels on the doc that the eraser/tools cannot
  remove; reloading the .draw file clears them.
- **Root cause:** the TRANSFORM overlay is orphaned by an ordinary tool switch.
  - `TRANSFORM_activate` (`TOOLS/TRANSFORM.BM:400`) sets `TRANSFORM.ACTIVE=TRUE`, captures
    `TRANSFORM.SRC_IMG`, stores `PREV_TOOL`. It's menu-activated (Edit→Transform), not a
    toolbar tool.
  - While `TRANSFORM.ACTIVE`, `TRANSFORM_render_overlay` (`OUTPUT/SCREEN.BM:3461-3465`) paints
    a dark tint + the warped preview onto `SCRN.CANVAS&` every frame, *before* the scene-cache
    bake (`SCREEN.BM:3505`). Those pixels live only in `TRANSFORM.SRC_IMG`/preview — **on no
    layer** — so the eraser (writes to `LAYER_current_image&`) can't remove them.
  - Proper exits `TRANSFORM_commit`/`TRANSFORM_cancel` (`TRANSFORM.BM:462`/`442`) free SRC_IMG,
    clear ACTIVE, restore PREV_TOOL, and destroy `SCENE_CACHE&`. But callers are limited:
    ENTER/ESC (`KEYBOARD.BM:329,291`), file import, and the 3 doc-creation paths
    (`DRW.BM:1641,2510,2694`). **The generic tool-switch path `TOOLS_reset_all` (`GUI/GUI.BM:22`)
    has NO `TRANSFORM_*` call.**
  - So: Edit→Transform (overlay up) → press `E`/`B` or click a toolbar tool → `TOOLS_reset_all`
    runs, `TRANSFORM.ACTIVE` stays TRUE → overlay keeps baking into the cache; eraser writes
    under it. Mouse is also hijacked by transform handlers (`MOUSE.BM:4919-4929`), so clicks
    manipulate handles instead of erasing. Only reload (`DRW_load_binary→TRANSFORM_cancel`,
    `DRW.BM:1641`) clears it.
- **Repro:** Edit→Transform a layer → without committing, press `E` (eraser) or click another
  tool → try to erase the transform preview → can't, until reload.
- **Fix approach:** add `IF TRANSFORM.ACTIVE THEN TRANSFORM_commit` (or `_cancel`) to the
  tool-switch reset — top of `TOOLS_reset_all` (`GUI/GUI.BM:22`) or the switch sites
  (`KEYBOARD.BM:124-265`, `GUI/TOOLBAR.BM:362-372`), mirroring the existing `MOVE_reset`-on-
  switch. Decision: commit vs cancel on switch — likely **commit** (matches MOVE's behavior).
  Secondary: confirm a stale selection clip (`BRUSH.BM:66`) isn't silently blocking erases.
- **Fix (applied):** in `TOOLS_reset_all` (`GUI/GUI.BM`), at the very top, `IF TRANSFORM.ACTIVE
  THEN` save the destination tool, call `TRANSFORM_commit`, then restore the destination tool
  (TRANSFORM_commit restores `PREV_TOOL`, which would otherwise clobber the tool the user just
  selected). Commit (not cancel) matches MOVE/TEXT commit-on-switch behavior.
- **Status:** FIXED (pending build+QA verify). Repro `seam-transform-then.sh` confirmed RED on
  baseline (overlay persisted after switch); expected GREEN after this fix.

### BUG-3 — MOVE float buffers leaked on document creation (revised diagnosis: handle leak)
- [x] **Found by audit.** All three doc-creation paths *do* call `MOVE_init` (`DRW.BM:1644` load,
  `:2496` new, `:2680` new-from-clip), which clears `MOVE.ACTIVE` — so the float does NOT render
  on the new doc (my first guess was wrong). BUT `MOVE_init` (`MOVE.BM:22-23`) only **ZEROES**
  `MOVE.SELECTION_IMAGE`/`PREVIEW_BUFFER` — it explicitly assumes the caller already freed them
  (comment `MOVE.BM:48`; `MOVE_reset` frees before calling it). The doc-creation paths call
  `MOVE_init` directly *without* freeing first, so if a paste/move float was live, its two
  buffers leak — including the **canvas-sized `PREVIEW_BUFFER`** — on every Open/New.
- **Repro:** paste (float active) → File→Open/New repeatedly → image handles leak each time.
- **Fix (applied):** free `MOVE.SELECTION_IMAGE`/`PREVIEW_BUFFER` (guarded `< -1`) immediately
  before `MOVE_init` in all three paths (`DRW.BM`). Aligns the three paths and plugs the leak.
- **Status:** FIXED (pending build+QA verify). Note: modifying `MOVE_init` to self-free was
  rejected — `MOVE_reset` frees then calls it, so that would double-free.

### BUG-4 — Doc-creation reset drift (minor inconsistencies)
- [ ] `CUSTOM_BRUSH_reset` is called by New & New-from-clip but **missing from Open**
  (`DRW_load_binary`) — open a file with a custom-brush-in-creation and the state carries.
- [ ] `ZOOM_drag_reset` is called by Open but **missing from New & New-from-clip**.
- [ ] IMAGE_IMPORT uses `_reset` on Open vs `_cancel` on New/New-from-clip — confirm equivalent.
- **Fix approach:** align all three lists (add the missing calls). Low risk, high tidiness.
- **Status:** OPEN — audit finding.

### BUG-5 (candidate) — IMAGE_IMPORT overlay can orphan on tool switch
- [ ] **Found by audit** (not user-confirmed). `IMAGE_IMPORT_reset` is **not** called by
  `TOOLS_reset_all`, so an in-progress placement (`IMG_IMPORT.STATE > IDLE` with a loaded
  `IMAGE`/`PREVIEW_IMG`) survives a tool switch — same seam class as BUG-2 (TRANSFORM). Need to
  confirm whether the import flow intercepts input (like transform does) or is reachable via a
  hotkey mid-placement. If reachable → stale overlay + handle leak.
- **Verified NOT reachable — NOT A BUG.** `KEYBOARD_handle_image_import%` (`KEYBOARD.BM:533`)
  consumes keys while `IMG_IMPORT.STATE > IDLE` and `KEYBOARD_input_handler` early-exits on it
  (`KEYBOARD.BM:3166`); mouse is intercepted too. So tool-switch hotkeys are BLOCKED during an
  import — the overlay cannot be orphaned by a tool switch. Import is properly modal.
- **Status:** CLOSED — not a bug (import is modal; no fix needed).

### BUG-6 (candidate) — POLY_LINE vs BEZIER abandon asymmetry
- [ ] **Found by audit.** Switching away mid-shape: BEZIER uses `BEZIER_cancel_restore` (rolls
  the canvas back, discarding the partial curve); POLY_LINE uses plain `POLY_LINE_reset` (frees
  the undo snapshot but **leaves already-drawn partial segments on the layer**). Inconsistent UX.
  Decide intended behavior (likely: both should discard the uncommitted preview on abandon, OR
  both should keep — but they should match). ⛔ May need a Rick decision on desired UX.
- **Update:** `seam-partial-shape-abandon.sh` (C1) shows abandoning a partial polygon leaves NO
  ghost undo state and Ctrl+Z cleanly undoes the *previous real action* (canvas returns to the
  pre-shape state) — so in practice the abandon is clean and user-safe. The reset asymmetry
  (`POLY_LINE_reset` vs `BEZIER_cancel_restore`) is internal and not visibly harmful. Downgraded.
- **Status:** OPEN — low priority; internal tidiness only. Optional UX decision (should abandon
  roll the canvas back like bezier?). Not blocking; logged for a future pass.

### BUG-7 — Soft AA eraser is dormant (shipped in 2.0.0 but never called)
- [ ] **Found by diagram reconciliation.** The 2.0.0 soft coverage-subtract eraser
  (`PAINT_erase_circle_aa`, `BRUSH.BM:354`) and its selector wrapper `ERASER_draw_at`
  (`ERASER.BM:93-107`, which picks the AA path for round brushes >1px when `CFG.ANTIALIAS%`)
  **have no caller** — the live eraser stroke goes `MOUSE_tool_brush → PAINT_on`
  (`MOUSE.BM:2688-2694`) with a transparent color, i.e. a HARD erase. So the AA-eraser feature
  is effectively dead code; enabling AA does not soften the eraser edge.
- **Verified:** `ERASER_draw_at` has zero callers (confirmed by grep). The live eraser stroke
  goes `PAINT_on` → `PAINT_draw_filled_circle_aa` with a transparent color; `PAINT_blend_pixel`
  (`BRUSH.BM:127-142`) detects alpha=0, sets `_DONTBLEND`, and writes alpha-0 at every coverage
  level → the AA-on eraser HARD-erases the full circle (works, but no soft feather). Severity:
  LOW (AA defaults OFF; eraser still works). The soft coverage-subtract eraser was dormant.
- **Fix (applied):** in `PAINT_on` (stroke interpolation) and the single-stamp path (`BRUSH.BM`),
  when `CFG.ANTIALIAS%` AND the stamp color is transparent (`_ALPHA32(col)=0`) AND round AND
  `radius >= 1`, route to `PAINT_erase_circle_aa` (coverage-subtract soft edge) instead of the
  hard AA circle. Entirely inside the `IF CFG.ANTIALIAS%` branch, so **AA-off is byte-identical**;
  1px/square/AA-off keep the hard erase.
- **Status:** FIXED (pending build+regression). AA-off path unchanged by construction.

### BUG-8 (candidate) — Edit→Transform menu item may invoke the wrong action
- [ ] **Found by diagram reconciliation.** The menu item "TRANSFORM..." (`GUI/MENUBAR.BM:239`)
  reportedly maps to **action 331 (Scale-2x-Horizontal)**, but the interactive transform overlay
  is activated by actions **325–329** (`TRANSFORM_activate(mode)`). If so, choosing Transform
  from the menu does a 2x-horizontal scale instead of opening the overlay — a real mis-wire.
- **Verify:** `grep -n` the menu entry at `MENUBAR.BM:239` and confirm which action ID it passes;
  cross-check `CMD_execute_action` CASE 331 vs 325-329.
- **Update (investigated):** LIKELY BENIGN. "TRANSFORM..." is a **flyout** parent (registered
  with the submenu arrow `CHR$(16)` at `MENUBAR.BM:239`); its flyout children correctly invoke
  `TRANSFORM_ACT_SCALE/DISTORT/PERSPECTIVE/ROTATE/SHEAR` (325-329) at `MENUBAR.BM:3618-3622`. The
  parent's action 331 is almost certainly inert (the submenu intercepts the click). Low priority;
  a quick manual click-the-parent check would fully close it.
- **Status:** OPEN — candidate, likely benign (flyout intercepts). Manual confirm only.

---

## FIXED (v2.0.0-input-hardening branch)

| Bug | Summary | Fix | Verified |
|-----|---------|-----|----------|
| **BUG-1** | Paste left a stale magic-wand mask → wand "selects things that aren't there" | `MAGIC_WAND_reset` in `CLIPBOARD_paste` | compiles; `seam-copy-then-wand` GREEN (functional) + manual |
| **BUG-2** | Orphaned TRANSFORM overlay → "content I can't erase until reload" | `TOOLS_reset_all` commits transform on switch (keeps dest tool) | **`seam-transform-then` + `seam-eraser-reaches-all` GREEN** (were RED pre-fix) |
| **BUG-3** | MOVE float buffers leaked on every Open/New | free `SELECTION_IMAGE`/`PREVIEW_BUFFER` before `MOVE_init` in all 3 doc-creation paths | compiles (leak; not visually testable) |
| **BUG-7** | Soft AA eraser dormant (shipped, never called) | route transparent AA stamp → `PAINT_erase_circle_aa` (AA-off byte-identical) | pending regression |

### Round 2 fixes (deep hunt)
| Bug | Summary | Fix |
|-----|---------|-----|
| **BUG-9** | Body-drag rotate about a nonsense pivot | `TRANSFORM.BM:743` Y arg → `PY0` |
| **BUG-14** | Paint tools wrote raw coords into a promoted apron buffer (systemic) | apron offset in the 3 pixel writers (`BRUSH.BM`) |
| **BUG-15** | MOVE mask-clear ignored apron offset | `+tgtAW/tgtAH` on the `_MEMPUT` (`MOVE.BM:787`) |
| **BUG-16** | Smart eraser sampled/erased other layers at raw coords | same 3-writer apron fix |
| **BUG-17** | Stale `GROUP_ORIGIN` hijacked selection after a group move | `MOVE_init` zeroes it |
| **BUG-18** | Duplicate Layer duplicated only 1 of a multi-selection | snapshot selection before the loop |
| **BUG-23** | Invert Selection left marching-ants stale | set `WAND_EDGE_DIRTY` |
| **BUG-25** | Palette-Ops replace skipped high-slot layers (sparse) | loop `1 TO MAX_LAYERS` |
| **BUG-26** | Text/AI layer data lost/misattributed on save (sparse + raw slot key) | `MAX_LAYERS` + `slotToSeq%` (all sites) |
| **BUG-27** | Lospec dialog `NOT id` bitwise → arrows double-acted | `IF tiConsumed% = 0` |
| **BUG-28** | Custom-brush recolor stamp ignored SCALE | map src through ORIG/dest ratio |
| **BUG-32** | Grayscale preview color-patch tracked the cursor | gate partial-present off when active |

Plus **BUG-4/BUG-6** (deferred → fixed): reset-list alignment + poly-line `cancel_restore`.
Plus **BUG-22 (flip case only)** drop stale wand mask on a flipped commit · **BUG-24** clear-selection
float now erases transparent (matches committed) · **BUG-29** `TEXT_apply` deletes empty text layers.
Still pending: BUG-22 rotate/scale-float mask, BUG-10/11/12 transform, BUG-19 merge-redo.

## CLOSED / NON-ISSUE
- **BUG-5** (IMAGE_IMPORT orphan): not reachable — import is properly modal.
- **BUG-8** (Transform flyout action 331): benign — flyout children invoke 325-329 correctly.

## LOW-PRIORITY / DEFERRED
- **BUG-4**: doc-creation reset drift (CUSTOM_BRUSH missing from Open, ZOOM_drag from New) — minor;
  the CUSTOM_BRUSH-on-Open difference may be intentional (keep loaded brush). Not changed.
- **BUG-6**: POLY_LINE vs BEZIER abandon asymmetry — internal tidiness; C1 shows clean abandon.

---

## ROUND 2 — DEEP HUNT (BUG-9+)

Found by exhaustive multi-agent audit of state-interaction areas the seam pass didn't drill into.
Each verified against source. Severity in brackets.

### BUG-9 [HIGH] — Body-drag ROTATE computes angle about a nonsense pivot — **FIXED**
- Transform → ROTATE, drag inside the quad (not a handle): `TRANSFORM.BM:743` used `TRANSFORM_PX0`
  for BOTH `_ATAN2` args, measuring the angle about `(PX0,PX0)` instead of the pivot `(PX0,PY0)`.
- **Fix:** Y arg → `TRANSFORM_PY0`. Corner-handle rotation was already correct.

### BUG-14 [HIGH] — Paint tools write RAW canvas coords into a promoted (apron) buffer
- After a Move promotes a layer to apron-extended (default `APRON_ENABLED=TRUE`), painting on it
  lands shifted by `(apronW,apronH)` ≈ 50% of canvas — off the visible area. Systemic:
  brush/dot/line/rect/ellipse/polygon/spray/bezier/eraser/smart-shapes + symmetry mirrors.
- **Root cause:** `PAINT_pset_with_symmetry`/`PAINT_blend_pixel` (`BRUSH.BM:55,123`) write
  `PSET(x,y)` in raw canvas coords to `LAYER_current_image&` (`LAYERS.BM:2118`, no apron offset).
  The offset helpers `LAYERS_canvas_to_buf_x/y` (`LAYERS.BM:6557`) exist but are never used by the
  paint primitives. These tools are on the apron whitelist (`MOUSE.BM:28-40`) so they DON'T demote.
- **Fix approach:** route the low-level pixel writes through the apron offset (keep clip/symmetry
  on canvas coords). Careful — hottest path.

### BUG-15 [HIGH] — MOVE's non-rectangular clear ignores apron offset — **FIX PENDING**
- Move a lasso/wand/ellipse selection on a promoted layer: the source region isn't erased where it
  should be (ghost remains; wrong region zeroed).
- **Root cause:** `MOVE.BM:777-790` mask-aware clear computes extended stride but indexes the write
  with RAW canvas coords (no `+tgtAW/tgtAH`). The sibling rect-clear (`:796`) DOES offset.
- **Fix:** add `tgtAW%`/`tgtAH%` to the `_MEMPUT` dest row/col.

### BUG-16 [MED] — Smart eraser samples/erases OTHER layers at raw coords (ignores their apron)
- `ERASER.BM:140-168` iterates all layers, `POINT(cx,cy)`/`PAINT_on` at raw coords; any
  apron-extended layer is sampled/erased off by its own apron. Fix: offset per sampled layer.

### BUG-17 [HIGH] — Stale MOVE.GROUP_ORIGIN hijacks selection after a group move — **FIX PENDING**
- After moving a group, selecting a standalone layer + switching tools silently jumps selection back
  to the group header → painting targets the header (no pixels).
- **Root cause:** `MOVE.GROUP_ORIGIN` set in `MOVE_capture_selection` (`MOVE.BM:117/148`), read
  UNCONDITIONALLY in `MOVE_reset` (`:77-85`) to force-select the header, but **never re-zeroed in
  `MOVE_init`**. `TOOLS_reset_all`→`MOVE_reset` on every tool switch keeps re-selecting it.
- **Fix:** `MOVE.GROUP_ORIGIN = 0` in `MOVE_init`.

### BUG-18 [MED-HIGH] — Duplicate Layer with a multi-selection duplicates only ONE layer — **FIX PENDING**
- `COMMAND.BM:1847-1853` iterates the live `MULTI_SELECT_LAYERS()` while `LAYERS_duplicate` →
  `LAYERS_select` → `MULTI_SELECT_clear` wipes it. After the first dup the rest read FALSE.
- **Fix:** snapshot selected slots into a local array first (like Delete/Merge-Selected do).

### BUG-10 [MED] — TRANSFORM ignores non-rectangular selection masks → destroys unselected pixels
- Transform of a wand/irregular selection transforms the whole bbox; pixels in-bbox-out-of-mask are
  erased. `TRANSFORM_activate` (`TRANSFORM.BM:364`) uses only `MARQUEE.BOX`, never `SELECTION_MASK`;
  commit erases the full rect (`:487`). `HISTORY_FLAG_CLIPPED` is set (`:482`) but never applied.

### BUG-11 [MED] — Apron demote at transform-activate is destructive + not undoable
- `TRANSFORM.BM:352-356` demotes (sacrifices apron pixels) BEFORE any history; early-outs leave the
  demote permanent with nothing recorded. Undo can't restore off-canvas pixels.

### BUG-12 [MED] — Transform result exceeding the canvas is silently clipped (no apron growth)
- `TRANSFORM_compute_preview` clamps dest bbox to canvas (`TRANSFORM.BM:195-198`); rotate/scale/shear
  that pushes a corner off-canvas loses it. Unlike MOVE, transform never grows an apron. (Recoverable
  via undo, but the committed result loses data.) Partly by-design for a fixed canvas.

### BUG-13 [LOW] — `>`/`<` keys dead in non-ROTATE transform modes
- `KEYBOARD.BM:2238` routes to `TRANSFORM_rotate_step` which early-outs unless MODE=ROTATE
  (`TRANSFORM.BM:526`); the ELSE fallback is unreachable while the overlay is active. Silent no-op.

### BUG-19 [MED→HIGH] — Merge redo re-runs against LIVE state → wrong/lost content
- Undo a Merge Visible/Group/Down, toggle a layer's visibility (records no history, doesn't truncate
  redo), then Redo → the merge re-executes live (`HISTORY.BM:2632/2637/2646`) excluding the now-hidden
  layer → data loss / desync. **FIX PENDING** (store the merged after-image, or have visibility/opacity
  mutations discard the redo tail).

### BUG-22 [HIGH] — Float-transform (flip/rotate/scale of a wand/lasso selection) desyncs the mask
- Same class as BUG-1 but for flip/rotate/scale: `CMD_autofloat_for_transform` floats masked pixels,
  transforms only the float, but the mask/bounds are never flipped/rotated/scaled (`COMMAND.BM:2830/3046/3751`);
  commit only translates the mask (`MOVE.BM:1032`). Later masked ops act on the wrong silhouette.
  **FIX PENDING** — stopgap: drop the wand mask on commit of a transformed float (like BUG-1).

### BUG-23 [MED] — Invert Selection leaves marching-ants edge cache stale — **FIXED**
- `MARQUEE.BM:2519` invert branch set bounds/BOX but not `WAND_EDGE_DIRTY` → ants kept the pre-invert
  outline. **Fix:** set `WAND_EDGE_DIRTY = TRUE`.

### BUG-25 [HIGH] — Palette-Ops color replace/delete SKIPS layers in high slots — **FIXED**
- `PALETTE-OPS.BM:514` looped `1 TO LAYER_COUNT%` and indexed `LAYERS()` as a slot; the array is
  SPARSE after a mid-stack delete. **Fix:** loop `1 TO MAX_LAYERS`.

### BUG-26 [HIGH] — Text/AI layer data lost or misattributed on save (sparse array) — **FIXED**
- `.draw` save (`DRW.BM:377/386/566/573`) looped `1 TO LAYER_COUNT%` AND stored the raw sparse slot as
  the layer key; load reads into contiguous slots → editable text/AI data dropped or attached to the
  WRONG layer. Same class in `HISTORY.BM:400`, `FILE-BAS.BM:149/1644/1717` (minor: export name/mode).
  **Fix:** loop `1 TO MAX_LAYERS` + store `slotToSeq%()` (all sites).

### BUG-27 [MED] — Lospec palette dialog: `NOT tiConsumed%` is bitwise (gotcha #19) — **FIXED**
- `API-LOSPEC.BM:158` — `TI_process_key%` returns the focused widget ID, so `NOT id` is always truthy →
  arrows double-acted (scrolled the list while editing the search box). **Fix:** `IF tiConsumed% = 0`.

### BUG-28 [MED] — Custom-brush RECOLOR stamp ignores SCALE
- `CUSTOM-BRUSH.BM:338-369` recolor branch maps `src_px = px` with no `ORIG_WIDTH/dest_w` ratio → stamps
  at 1× while the cursor preview shows the scaled brush. **FIX PENDING** (mirror the eraser branch's ratio).

### BUG-32 [MED] — Grayscale preview not re-applied in cursor-move fast paths
- Grayscale is a present-time pass (`SCREEN.BM:3680`) not baked into the cache; the partial-present fast
  paths (`:2976`, `:3217`) exit before it → a full-color patch tracks the cursor. **FIX PENDING**
  (gate `so_can_partial%`/`can_partial_present%` off when `GRAYSCALE_PREVIEW_ACTIVE%`).

### BUG-16 [MED] — Smart eraser samples/erases other layers at raw coords (apron)
### BUG-24 [LOW] — Clear-Selection fills opaque BG on a float, transparent on a committed selection (`SELECTION.BM:408`)
### BUG-29 [LOW] — `TEXT_apply` rasterizes empty text layers (no empty-delete like commit/cancel)
### BUG-31 [LOW] — Palette-Ops batch delete = N separate undo groups
### BUG-33 [LOW] — dead-code `_DEST 0` in `IMGADJ.BM:1994` test helper (latent gotcha #1)

### Round-2 UNVERIFIED / LOW (need a closer look, logged not fixed)
- **BUG-20** [MED, UNVERIFIED] group membership restored via raw slot index not stable id (`LAYERS.BI:78`).
- **BUG-21** [LOW, UNVERIFIED] AI-generate undo shares the per-frame `HISTORY_saved_this_frame%` guard.
- **BUG-30** [LOW, UNVERIFIED] `GRID_snap%` single-axis uses gridWidth for both axes (`GRID.BM:341`).
- Merge-Visible may composite+delete a visible group header (1px), orphaning its hidden children.
- Nested ungroup skips `LAYERS_enforce_group_contiguity` → possible non-contiguous z-range.
- Direct delete of a symbol parent leaves children with a dangling `symbolParentId&` (benign: ids
  never reused, child just freezes — but untracked).

---

### Second-wave fixes (applied, pending build verify)
| Bug | Summary | Fix |
|-----|---------|-----|
| **BUG-44** [CRASH] | Palette-strip page-scroll → `PAL(-n)` out of range | modulo-normalize the scroll offset |
| **BUG-40** [HIGH] | Command Palette typing leaked into global hotkeys | gate key-dispatch when palette open |
| **BUG-53** [HIGH] | `--option`/`--dev`/`--instance` before a file dropped the file | skip flags in the arg scanner (both branches) |
| **BUG-48** [MED] | Pan leaked through Drawer/EditBar/AdvBar/CharMap | additive `REGION_hit_test%` block |
| **BUG-34** [HIGH] | Modal froze heartbeat → live instance reaped | `STALE_SECS` 12→60 |
| **BUG-35** [MED] | LAYERXFER could send the PREVIOUS layer | clear temp before save + verify after |
| **BUG-50/51** | palette-release tool leak / `OLD_B2` init | set `UI_CHROME_CLICKED%` / add init |
| **BUG-55** [MED] | `--option` ignored with no config file | apply overrides before early exit |

## SECOND WAVE — deep hunt continued (BUG-34+)

Areas the first wave didn't cover (multi-instance, input pipeline, keyboard/dialogs, config, GUI chrome).
Note: multi-instance is an advanced, off-by-default feature (Settings → Allow Multiple Instances).

### BUG-34 [HIGH] — Modal dialogs freeze the instance heartbeat → live instance falsely reaped
- With 2+ windows, leaving a modal (unsaved prompt, Save-As, message box, color picker) open >12s
  freezes the heartbeat (`INSTANCE_tick` is only called from the main loop, `DRAW.BAS:532`; modal
  loops like `MB_modal_loop` don't pump it). `INSTANCE_STALE_SECS=12` → peers reap the modal-blocked
  instance → slot/config/mailbox collision (two instances share `.instance-N.cfg`), dropped
  Send-Layer, double music. **FIX (applied): option (c)** — raise `STALE_SECS` well above modal
  dwell + require consecutive stale reads before reaping.

### BUG-35 [MED] — `LAYERXFER_serialize$` reuses a fixed temp + ignores `_SAVEIMAGE` failure → can send the PREVIOUS layer
- `LAYERXFER.BM:136-149`: fixed temp `layerxfer_out.png`, no pre-delete, `_SAVEIMAGE` return unchecked.
  On a silent save failure with a stale temp present, it reads the OLD PNG → broadcasts the wrong
  layer. **FIX (applied):** KILL the temp before save + require `_FILEEXISTS` after before reading.

### BUG-36 [MED] — File dropped while a modal is open dispatches to the wrong target later
- Drops are queued only by the main loop (`DRAW.BAS:443`); with a modal open the drop is deferred, and
  `DROP_tick` then routes by `MOUSE.RAW_X/Y` = the post-dialog cursor. **FIX PENDING** (discard drops
  while modal, or capture coords at `_FINISHDROP`).

### BUG-37 [LOW-MED] — INSTANCE bootstrap slot-walk: no mailbox re-clear on the claimed slot; can leave `INST.id` unowned
- `INSTANCE.BM:216-231`: mailbox cleared only for the initial id; a walk-claimed higher slot inherits a
  predecessor's undelivered layers; a fully-lost ~32-way race leaves an unowned id. **FIX PENDING**.

### BUG-38 [LOW] — Canvas file-drop can do a non-undoable destructive stamp (`DROP.BM:214-224`) if `HISTORY_saved_this_frame%` already set.
### BUG-39 [LOW, UNVERIFIED] — Paste/Send Layer stores `blendMode%` with no range clamp (`LAYERXFER.BM:120`).

### BUG-40 [HIGH] — Command Palette typing leaks into the global hotkey dispatcher
- Open Ctrl+P, type "line"/"rect"/"50" → the editor silently switches tools, changes opacity/brush
  size, swaps FG/BG under you. `INPUT_dispatch_frame` runs unconditionally (`DRAW.BAS:568`) and
  `CTX_COMMAND_PALETTE_OPEN` is SET (`INPUT.BM:788`) but **no binding uses it as `forbidCtx`**; the
  legacy handler bails on palette-open but the new dispatcher doesn't. **FIX (applied):** gate key-event
  dispatch in `INPUT_dispatch_frame` when the palette (or another free-text/inline-capture mode) is open.

### BUG-44 [HIGH, CRASH] — Palette-strip page-scroll → negative offset → `PAL(-n)` out-of-range crash
- 16-color palette (the norm) + Shift/Ctrl+wheel-up: `PALETTE-STRIP.BM:508-513` wraps with a one-shot
  `IF offset<0` instead of modulo, so page-size (32/64) > pal_count (16) leaves offset negative;
  render does `PAL((offset+i) MOD pal_count)` and QB64 MOD keeps the sign → `PAL(-15)` subscript OOR
  → crash. **FIX (applied):** normalize `((offset MOD n)+n) MOD n` (+ defensive re-normalize).

### BUG-45 [MED] — Undo/redo of a GROUP drag-reorder corrupts layer layout
- `LAYER_PANEL_handle_drop` moves a group block but records a single-layer reorder (`LAYERS.BM:4361`);
  undo relocates only the header, stranding children; parentGroupIdx changes unrecorded. **FIX PENDING**
  (record a structural/block history entry).

### BUG-41 [MED,UNVERIFIED] — open dropdown doesn't zero `ctx.mwheel` (`SETTINGS-WIDGETS.BM:827`) → wheel double-scrolls the dialog behind it.
### BUG-42 [LOW] — new dispatcher ignores `KEYBOARD_SUPPRESS_FRAMES%` (mitigated by `_KEYCLEAR`).
### BUG-43 [LOW] — TI Ctrl+symbol normalization overreaches letters range (`TI-INPUT.BM:522`) → Ctrl+[ acts as Escape.
### BUG-46 [LOW] — Drawer "Load Images" batch wraps around clobbering earlier slots (`DRAWER.BM:4564`) instead of paging.
### BUG-47 [LOW,UNVERIFIED] — Preview follow-mode Alt+click samples a stale canvas coord (`PREVIEW.BM:1617`).

### BUG-48 [MED / HIGH-UX] — Canvas pan leaks through Drawer / Edit Bar / Adv Bar / Char Map / palette
- `MOUSE_handle_panning` (`MOUSE.BM:1390-1424`) uses hand-maintained GUI-exclusion lists that OMIT
  DRAWER/EDITBAR/ADVBAR/CHARMAP (drifted from the sibling b3-dblclick list). MMB / Space+drag over
  those panels pans the canvas behind them. **FIX (applied):** gate the pan on
  `REGION_hit_test% > REGION_CANVAS` (the canonical "over chrome" test), not the drifted lists.
### BUG-49 [LOW] — b3-dblclick reset-zoom exclusion omits Char Map (`MOUSE.BM:1170`) — same class as BUG-48.
### BUG-50 [LOW] — Command-palette click never sets `UI_CHROME_CLICKED%` → release leaks to the tool behind (phantom Shift+RMB anchor). **FIX (applied):** set the flag on palette press (mirrors menubar).
### BUG-51 [LOW] — `MOUSE_init` doesn't init `OLD_B2` (`MOUSE.BM:218`). **FIX (applied):** add `MOUSE.OLD_B2% = FALSE`.
### BUG-52 [LOW] — right-click / shift-constrain fire during an active pan (`MOUSE.BM:4969`). **FIXED** — `MOUSE_handle_right_click` early-returns when `SCRN.panning%`.

### BUG-53 [HIGH] — `--option`/`--developer`/`--instance` before a filename silently drops the file
- `./DRAW.run --option THEME=DARK myfile.draw` never opens myfile. The file-arg scanner
  (`DRAW.BAS:189-218`) skips only a fixed flag whitelist; unrecognized flags fall into the ELSE that
  sets `cmdArg$ = the flag` and stops. **FIX (applied):** skip any `--`/`-` token (and the value of the
  2-token flags) in the scanner so the first non-flag token is the file.
### BUG-54 [MED, latent] — THEME include-order (gotcha #11): `*_init` read `THEME.*` in `SCREEN_init` before `THEME.BI` defaults; safe only because shipped themes define every key. Breaks incomplete/kit themes. **FIX PENDING** (lazy-load, or re-run inits after final THEME_load).
### BUG-55 [MED-LOW] — `--option` ignored when `DRAW.cfg.default` is absent (`CONFIG.BM:376` EXIT SUB before `apply_cli_overrides`). **FIX (applied):** apply overrides + validate before the early exit.
### BUG-56 [LOW] — "0=use theme" sentinel lost on save/load for FONT_PREVIEW_FG/BG/DIVIDER + CANVAS_APRON_COLOR (saved as 000000 → loads as opaque black). **FIX PENDING** (guard `IF <>0` on write).
### BUG-57 [LOW] — `--options-list` may print nothing on Windows. **FIXED** — added `_CONSOLE ON`.
### BUG-58 [LOW] — `PATHS_migrate` re-prompts every launch if the exe dir is read-only (marker written to CWD). **FIX PENDING**.

## THIRD WAVE — peripheral subsystems (BUG-59+)

Exporters, importers, effects math, fonts/TDF, PIXEL-COACH, sound. (Effects engine came back
"exceptionally clean" — no HIGH there.)

### BUG-65 [HIGH, CRASH] — PSD per-layer dimensions never validated → overflow / OOM crash
- `PSD_get_layer_image&` (`QB64_GJ_LIB/PSD/PSD.BM:598-630`) computes `layW*layH` in a LONG and
  `STRING$(pixelCount,0)` with no bounds check; a crafted/huge layer overflows → negative STRING$
  (Illegal function call) or gigabyte alloc (OOM). Only the CANVAS dims are validated. **FIX (applied):**
  clamp layW/layH and compute pixelCount in `_INTEGER64`, bail if oversize.

### BUG-66 [HIGH, CRASH] — Aseprite palette `first_index` unclamped → negative `PAL()` subscript
- `FILE-ASE.BM:604-621`: `firstIdx&` (from an _UNSIGNED LONG) can go negative; loop writes `PAL(-n)`
  → subscript out of range. **FIX (applied):** clamp `firstIdx& < 0 → 0` + lower-bound the write.

### BUG-62 [HIGH] — ANSI "current layer" export uses the sparse-slot guard → blank output
- `FILE-ANS.BM:597`: `IF li <= LAYER_COUNT%` where `li = CURRENT_LAYER%` is a SLOT (sparse); a
  high-slot current layer → blank export. Same class as BUG-25/26. **FIX (applied):** `<= MAX_LAYERS`
  (+ same at `MOUSE.BM:4172/4422`).

### BUG-74 [HIGH] — TDF glyph-width cache (`TDF_CACHE_GW`) not shifted on eviction → glyph widths desync
- `TDF-FONT.BM:933-939` eviction shifts FACE/BLOCK/LOOK but not the parallel `TDF_CACHE_GW` memo →
  after the 5th TheDraw face, glyphs report another face's widths (misaligned layout). CBF/TTF shift
  all parallel arrays; this is the outlier. **FIX (applied):** add the missing GW inner shift.

### BUG-68 [MED, CRASH] — Aseprite chunk count in an INTEGER overflows (`ASEPRITE.BM:1655`) — **FIX (applied):** LONG.
### BUG-70 [LOW] — PSD layer-name truncation uses `MAX_LAYERS`(128) not 64 (`FILE-PSD.BM:425`) — **FIX (applied):** 64.
### BUG-72 [LOW] — `IMAGE_ADJ_rust&` missing the `scaleP<4` div-by-zero guard its siblings have (`IMAGE-ADJ.BM:8153`) — **FIX (applied)**.
### BUG-67 [MED] — ANSI import cursor-forward/down unbounded → INTEGER overflow/corruption (`FILE-ANS.BM:819`) — **FIX (applied):** clamp x/y.
### BUG-60 [HIGH] — QB64/BAS export composites HIDDEN-group children (`FILE-QB64.BM:482`) — **FIX PENDING** (parent-chain visibility walk).

### BUG-59 [HIGH] — `LAYERS_flatten&` ignores group opacity/blend/isolation → every raster export wrong for isolated groups. **FIX PENDING** (factor the renderer's group-stack compositor into a shared routine).
### BUG-61 [MED] — `SAVE_selection` re-implements compositing → apron-squash + hidden-group bugs (`SAVE.BM:456`). **FIX PENDING** (crop from `LAYERS_flatten&`).
### BUG-63 [LOW] — ANSI selection export ignores non-rectangular mask (`FILE-ANS.BM:581`).
### BUG-64 [LOW] — QB64 export copies fonts via Unix `cp` (`FILE-QB64.BM:582`) — breaks on Windows.
### BUG-69 [MED,UNVERIFIED] — Aseprite compressed-cel `expected_size` LONG overflow (adversarial).
### BUG-71 [MED] — procedural-texture effects (wood/marble/…) preview phase ≠ applied (anchor to source-center; cosmetic).
### BUG-73 [LOW,UNVERIFIED] — Crystallize can leave opaque black fringe on alpha edges.
### BUG-75 [LOW] — `MUSIC_play_random_ext` stops music if the extension has 0 tracks (`SOUND.BM:419`).
### BUG-76 [LOW,UNVERIFIED] — `.TDX` values trusted without bounds vs the `.TDF` (`TDF-FONT.BM:827`).
### BUG-77 [LOW,UNVERIFIED] — PIXEL-COACH `imgW/imgH` INTEGER overflow on >32767px image.

## BLOCKED — needs a Rick decision

_(none — no bug required a decision only Rick can make. BUG-6 is an optional UX polish; BUG-4 is
minor tidiness. Neither blocks.)_

---

## RUN SUMMARY (v2.0.0 input-seam hardening — 2026-08-25)

**Branch:** `v2.0.0-input-hardening` off `main`. Not merged — awaiting Rick's review.

**Investigation → 8 bugs found (2 user-reported, 6 by audit/diagram reconciliation):**
- Root cause of both user-reported bugs pinned exactly and fixed + QA-verified.
- BUG-1 paste stale wand mask · BUG-2 orphaned transform (the "can't erase until reload") ·
  BUG-3 MOVE float leak · BUG-7 dormant soft AA eraser — **all fixed**.
- BUG-5 closed (not reachable) · BUG-8 benign · BUG-4/BUG-6 deferred (minor).

**Verification:** clean compile (all 4 fixes); **10/10 new seam tests GREEN**; regression subset
clean (no new failures vs shipped-main baseline). AA-off paths byte-identical by construction.

**Deliverables on the branch:**
- `PLANS/INPUT-SEAMS-AUDIT.md` — source-level map of every tool/operation seam.
- 3 NEW seam diagrams (`GLOBAL/TOOL-SEAMS`, `SELECTION-LIFECYCLE`, `CLIPBOARD-LIFECYCLE`).
- ~60 existing diagrams reconciled to current source (all 70 DOT render clean).
- 10 QA seam tests in `QA/tests/seam-*.sh`.

**Suggested next steps for Rick:** (1) eyeball the soft AA eraser (enable AA, erase over a filled
area — should feather now). (2) Decide BUG-6 (should abandoning a partial poly-line roll the
canvas back like bezier?). (3) Merge the branch when satisfied.
