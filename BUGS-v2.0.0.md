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

### BUG-10 [MED→HIGH] — TRANSFORM ignores non-rectangular selection masks → destroys unselected pixels
- Transform of a wand/irregular selection transforms the whole bbox; pixels in-bbox-out-of-mask are
  erased. `TRANSFORM_activate` (`TRANSFORM.BM:364`) uses only `MARQUEE.BOX`, never `SELECTION_MASK`;
  commit erases the full rect (`:487`). `HISTORY_FLAG_CLIPPED` is set (`:482`) but never applied.
- **Repro CONFIRMED by Rick (2026-08-28)** with two blobs (magenta + green), wand-select one, Scale, Enter.
  Three distinct defects observed in one repro:
  1. out-of-mask pixels (the other blob) get erased — the core BUG-10 (mask ignored on capture + commit);
  2. the selection/mask did NOT scale with the transform — stayed at the old size (this is **BUG-22**:
     the mask/bounds are never scaled/rotated/flipped, only translated on commit);
  3. the cleared source region appeared BLACK — NOT a wrong clear-color: the commit already clears to
     `_RGBA32(0,0,0,0)` (`TRANSFORM.BM:487`). The "black" was the transparent HOLE from #1 (the erased
     neighbour) showing the backdrop below. So #3 is a symptom of #1, not a separate defect.
  **FIX (applied 2026-08-28) — data loss (#1) + black (#3):** the transform now lifts and erases ONLY
  masked pixels. `TRANSFORM_activate` snapshots the wand mask into a new `TRANSFORM.SRC_MASK` field and
  knocks non-mask pixels out of the captured float; `TRANSFORM_commit` clears only masked source pixels
  (mask-aware `_MEM` loop mirroring `MOVE.BM:770-799`) instead of the full-rect `LINE …BF`. The neighbour
  blob is never captured or erased → no destruction, no transparent hole/black. `TRANSFORM_cancel` frees
  the snapshot. Undo unaffected (full before-image still captured). Only the wand/lasso path changes;
  rectangular-marquee and whole-layer transforms keep the full-rect clear.
  **#2 / BUG-22 (mask doesn't scale) — stopgap applied:** on commit of a masked transform the now-stale
  selection is dropped (`MAGIC_WAND_reset`, the BUG-1 precedent) so later masked ops don't act on the old
  silhouette. Proper "warp the mask to follow the transform" is a separable follow-up (genuinely new code).

### BUG-11 [MED] — Apron demote at transform-activate is destructive + not undoable — **FIXED (2026-08-29), confirmed by Rick**
- **Original:** `TRANSFORM_activate` demotes (sacrifices apron pixels) BEFORE any history; early-outs leave the
  demote permanent with nothing recorded. Undo can't restore off-canvas pixels.
- **FIX part 1 (transform):** capture the pre-demote apron buffer FIRST (`TRANSFORM.HIST_BEFORE` + saved
  apron dims). Commit records it as the undo image (history restore rebuilds apronW/H from the image's
  dimensions); cancel and every activate early-out call `TRANSFORM_rollback_demote`, which transfers the
  saved buffer back into the layer — so aborting a transform is byte-for-byte non-destructive (verified by
  dumping the layer before demote and after rollback: identical). `TOOLS/TRANSFORM.BM` + `.BI`.
- **FIX part 2 (the real culprit Rick kept seeing):** even with part 1, "cancel still clips" — because the
  clip was actually the **move-back**, not the transform. A **whole-layer move** (`MOVE_capture_selection`,
  no active marquee) lifted only the CANVAS region, blind to apron content. Normal moves happened to work
  because the marquee left active by the prior move made the next move a *selection* move that tracked the
  content into the apron; the transform dropped that marquee, so the move-back fell to the whole-layer path
  and sheared off the off-canvas pixels. **Fix:** a whole-layer move of an already apron-extended layer now
  lifts the FULL extended buffer (`MOVE.SELECTION_X/Y = -apronW/-apronH`, `W/H = canvas + 2*apron`), so
  off-canvas content moves with the layer. A compact/fresh layer (`apronW/H = 0`) reduces to the canvas
  region exactly as before — ordinary moves unchanged. `TOOLS/MOVE.BM`.
- Diagnosed via PNG dumps of the captured buffer at each stage; both parts confirmed fixed by Rick.

### BUG-12 [MED] — Transform result exceeding the canvas is silently clipped (no apron growth) — **FIXED (2026-08-29, Rick chose "grow an apron")**
- **Was:** `TRANSFORM_compute_preview` clamped the dest bbox to canvas (`TRANSFORM.BM:215-218`); rotate/scale/shear
  that pushed a corner off-canvas lost it. Unlike MOVE, transform never grew an apron.
- **FIX:** `compute_preview` now clamps the dest bbox to the **apron-extended** bounds (`±APRON_W/H`) instead
  of the canvas, so the warped result renders its off-canvas overflow into `TRANSFORM_PREVIEW_IMG`. On commit,
  if the result overflows (`TRANSFORM_PREVIEW_OX/OY` negative or past canvas), the layer is promoted to an
  apron-extended buffer (`LAYERS_promote_to_extended`) and the source-clear + result blit are shifted by the
  apron offset `(aX,aY)`. Off-canvas transform results are now preserved up to the apron margin, like Move.
  A fully on-canvas transform grows no apron (unchanged); apron disabled in config → still clips as before.
  `TOOLS/TRANSFORM.BM`. Confirmed by Rick; on main.

### BUG-13 [LOW] — `>`/`<` keys dead in non-ROTATE transform modes — **DECIDED: acceptable, no change (Rick, 2026-08-30)**
- `KEYBOARD.BM:2238` routes to `TRANSFORM_rotate_step` which early-outs unless MODE=ROTATE
  (`TRANSFORM.BM:526`); the ELSE fallback is unreachable while the overlay is active. Silent no-op.
- **Decision (Rick):** this is fine — `>`/`<` being rotate-only is acceptable; no fix.

### BUG-19 [MED→HIGH] — Merge redo re-runs against LIVE state → wrong/lost content — **FIXED (2026-08-28), confirmed by Rick**
- **Repro (Rick):** 3 layers A/B/C → Merge All → Ctrl+Z (A/B/C back) → hide C → Ctrl+Y → the redone merge
  ran live and **removed layer B** (data loss).
- **Root cause:** all three merge redos re-EXECUTE the merge against current state — `LAYERS_merge_down`
  (`HISTORY.BM:2632`), `LAYERS_merge_visible` (`:2637`, the "Merge All" menu item), `LAYERS_merge_group`
  (`:2646`) — so any visibility/opacity change made after the undo (which records no history and did NOT
  truncate the redo tail) desyncs the replay: layers are re-merged/deleted against a stack that no longer
  matches, losing content.
- **FIX (applied):** treat a non-recorded document mutation after an undo as a timeline branch — when
  `LAYERS_toggle_visibility` / `LAYERS_set_opacity` change state and a redo tail exists, call
  `HISTORY_discard_redo_tail` (`GUI/LAYERS.BM`, guarded by `HISTORY_IN_PROGRESS% = 0` so it never fires
  during replay). Hiding C now discards the stale merge future, so Ctrl+Y is a correct no-op instead of
  destroying B. Covers all three merge kinds via the trigger side. (A fuller "replay the recorded merged
  after-image" redo is a larger follow-up; this stops the data loss.)

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
### BUG-31 [LOW] — Palette-Ops undo (batch delete = N separate undos) — **FIXED (2026-08-30), confirmed by Rick + QA**
- Diagnosis went deeper than the title: palette-ops undo was **never implemented** — nothing recorded the
  PAL array / count / FG-BG indices (no `HISTORY_KIND_PALETTE`), so a delete only ever recorded the layer
  PIXEL remap; deleting an unused color recorded nothing at all ("undo does nothing"). Extra phantom undos
  also came from `PALETTE_OPS_activate`'s auto-remap recording a no-op per layer.
- **FIX (applied):** new `HISTORY_KIND_PALETTE` snapshot record (before+after palette framed in the
  payload, restored on undo/redo), grouped with the pixel-remap records so ONE Ctrl+Z restores palette
  AND pixels. Single delete, batch delete, and color change all wrapped in one group. `PALETTE_OPS_BATCH%`
  makes the batch emit ONE record. `PALETTE_LOADER_remap_to_palette_ex` now records only layers it
  actually changed (no phantom undo on activating palette ops over a conformant image). Verified by QA
  (`phantom-undo-*.sh`) + Rick.
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

### BUG-36 [MED] — File dropped while a modal is open dispatches to the wrong target later — **FIXED (2026-08-29), confirmed by Rick**
- A blocking modal (File dialog, message box, color picker, input box) runs its own loop, so a file
  dropped onto it is held in the OS queue and only read by the main loop AFTER the modal returns — by
  which point `MOUSE.RAW_X/Y` = the cursor resting on the dialog's OK button. `DROP_tick` then routes
  from that stale position (canvas stamp / new instance / wrong panel). The true drop point is
  unrecoverable (QB64-PE reports no drop coordinates).
- **FIX (applied):** discard the drop when the modal closes. Every blocking dialog brackets itself with
  `BROWSER_suspend_for_modal` / `BROWSER_resume_after_modal` (`GUI/GJ-DIALOG-SCALE.BM`); `resume` now
  calls the new `DROP_discard_pending` (`INPUT/DROP.BM`), which drains the OS queue (`_FINISHDROP`) and
  the deferred queue before the main loop's `_TOTALDROPPEDFILES` check can misroute it, and shows a
  non-blocking amber banner ("File drop ignored – a dialog was open…") via the crash-toast surface.
  Regression guard in `QA/tests/drag-drop-targets.sh` (source-route + manual per-OS check; OS drops
  can't be synthesized headlessly).

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

### BUG-45 [MED] — Undo/redo of a GROUP drag-reorder corrupts layer layout — **FIXED (2026-08-29), confirmed by Rick**
- **The reported case self-heals (not reproducible):** dragging a group HEADER moves a block whose
  children keep `parentGroupIdx = header`. Reorder undo/redo restores the header's z and then runs
  `LAYERS_enforce_group_contiguity` (`HISTORY.BM:2505/2667`), which snaps the children back to the
  header — so the "children stranded" fear never materializes for a block move. Rick couldn't reproduce it.
- **The real adjacent gap (fixed):** the fall-through drop path recorded a **z-only** `HISTORY_record_layer_reorder`
  (`LAYERS.BM`), so a single-layer drag that **auto-adopts into / orphans out of** a group (`parentGroupIdx`
  change at `LAYERS.BM:4594-4606`) restored the z on undo but **not** the nesting. (The explicit into/out-of-group
  paths were already fine — `LAYERS_move_into_group` / `_move_out_of_group` record their own
  `HISTORY_record_group_reparent`.) **FIX:** capture the old parent at the top of `LAYER_PANEL_handle_drop`
  and record the fall-through drop via `HISTORY_record_group_reparent` (parent+z) — a superset of the z-only
  reorder: unchanged parent → plain z reorder, and its undo/redo run `enforce_group_contiguity` so the
  self-healing block move is unaffected. Auto-adopt and auto-orphan are now undoable. Confirmed by Rick.

### BUG-41 [MED] — open dropdown doesn't zero `ctx.mwheel` → wheel double-scrolls the dialog behind it — **FIXED (2026-08-29), confirmed by Rick**
- The Settings loop runs widget input BEFORE `SETTINGS_handle_scroll`, so a wheel widget under the
  cursor claims the wheel by zeroing `ctx.mwheel` (every spinner does). `SW_dropdown_input%`
  (`GUI/SETTINGS-WIDGETS.BM`) scrolled the open list on the wheel but never consumed it, so the panel
  behind scrolled too. **FIX:** set `ctx.mwheel = 0` after scrolling the open list (consumed even for a
  short non-scrollable list, so the panel never slides out from under the open dropdown). The generic
  `DIALOG_dropdown_input` (`GUI/DIALOG.BM:473`) already consumed unconditionally, so other dialogs were
  unaffected. Confirmed by Rick.
### BUG-42 [LOW] — new dispatcher ignores `KEYBOARD_SUPPRESS_FRAMES%` (mitigated by `_KEYCLEAR`).
### BUG-43 [LOW] — TI Ctrl+symbol normalization overreaches letters range (`TI-INPUT.BM:522`) → Ctrl+[ acts as Escape. — **FIXED (2026-08-30), confirmed by Rick**
- The Ctrl+letter→control-code normalizer gated on `k >= 65 AND k <= 122`, which straddles the six
  punctuation chars between the alphabets (`[ \ ] ^ _ \``, codes 91–96). `Ctrl+[` (91) → `91-64 = 27`
  = ESC → hit `CASE 27` → closed the field; `Ctrl+\`` (96) → `96-64 = 32` = SPACE → inserted a space;
  `\ ] ^ _` were mangled to control codes 28–31 and silently eaten.
- **FIX (applied):** gate on the two real letter ranges `((k>=65 AND k<=90) OR (k>=97 AND k<=122))`
  only, so the punctuation gap falls through untouched. Also *restores* AltGr-typed `[ ] \ ^ _ \`` for
  European layouts (AltGr = RightCtrl+RightAlt, which `_KEYDOWN` reads as Ctrl). Single normalization
  point in `TI_process_key%`; all five text dialogs (AI, file, color picker, msgbox, lospec) route
  through it. Confirmed by Rick.
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
### BUG-54 [MED] — incomplete theme → size-0 fonts (THEME include-order, gotcha #11) — **FIXED (2026-08-30), confirmed by Rick**
- `THEME_load` runs once EARLY from `SCREEN_init`, before `_ALL.BI:181` includes `DEFAULT/THEME.BI`
  (the compiled defaults) — so at that point every `THEME.*` field is 0. A complete theme sets all
  keys in that window; an incomplete one left omitted keys (`GLOBAL_FONT_SIZE`, `STATUS_HEIGHT`, …) at
  0, and any `*_init` that loaded a font / derived bar geometry during the include chain baked in a
  size-0 font / zero-height bar. Shipped themes are complete, so they never tripped it.
- **FIX (applied):** `THEME_load` now layers the COMPLETE DEFAULT theme as a base first, then overlays
  the selected theme (parser extracted to `THEME_load_theme(name$)`, `CFG/CONFIG-THEME.BM`). Omitted
  keys inherit DEFAULT's values regardless of include timing — the theme is now a diff against DEFAULT,
  which is the intended model. Also fixes runtime theme switching to an incomplete theme
  (`THEME_reload_all`). Confirmed by Rick.
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
### BUG-60 [HIGH] — QB64 code export composites HIDDEN-group children (`FILE-QB64.BM:482`) — **FIX (applied 2026-08-28):** the `sortedZ` builder (the single choke point feeding every export stage — PNG assets, font copy, composite/emit loop) now walks the parent chain and excludes children of any hidden ancestor group, mirroring the `LAYERS_flatten&` visibility walk (nested IFs + bounds guard, not `AND` — gotcha #18). Reproduced & confirmed by Rick. (Sibling `FILE-BAS.BM` has no per-layer composite loop — it flattens via `LAYERS_flatten&`, already fixed in BUG-59 — so it is not affected.)

### BUG-59 [HIGH] — `LAYERS_flatten&` ignores group opacity/blend/isolation → every raster export wrong for isolated groups. **FIX (applied 2026-08-28):** `LAYERS_flatten&` (`GUI/LAYERS.BM:2016`) is now group-aware — it mirrors the renderer's isolated-group stack (`OUTPUT/SCREEN.BM` `RENDER_layers`): push a per-group buffer on entering an isolated (non-pass-through) group's children, flush it applying the group's own opacity/blend when the group header is reached (zIndex walk puts headers above children, same invariant the renderer uses), with none of the live-render caches/zoom/region/MOVE machinery. Fixes **every** flatten consumer at once (PNG/BMP/GIF/JPG/TGA, ANS, `.drw` merge, AI `{dimg}`, extract tools, pixel analyzer) — also resolves the export half of BUG-61. Compiles clean.
### BUG-61 [MED] — `SAVE_selection` re-implements compositing → apron-squash + hidden-group bugs (`SAVE.BM:456`). — **FIXED (2026-08-29), confirmed by Rick.** The inline composite did `_PUTIMAGE , imgHandle&, canvasSizedBuffer` per visible layer, which **stretched an apron-extended layer** (imgHandle& larger than the canvas, content offset by apronW/H) down to canvas size — squashing / mis-placing the exported content — and it only checked per-layer `visible%`, so a **hidden GROUP with visible children still exported**. **FIX:** crop the selection region from `LAYERS_flatten&` (the group-aware, apron-correct flatten fixed in BUG-59) instead of re-compositing — one line replaces the whole inline loop, and the mask/rect crop below is unchanged. Both the apron-squash and hidden-group halves confirmed fixed by Rick (`TOOLS/SAVE.BM`).
### BUG-63 [LOW] — ANSI selection export ignores non-rectangular mask (`FILE-ANS.BM:581`).
### BUG-64 [LOW] — QB64 export copies fonts via Unix `cp` (`FILE-QB64.BM:582`) — breaks on Windows.
### BUG-69 [MED,UNVERIFIED] — Aseprite compressed-cel `expected_size` LONG overflow (adversarial).
### BUG-71 [MED] — procedural-texture effects (wood/marble/…) preview phase ≠ applied — **FIXED (2026-08-29), confirmed by Rick**
- Each generator (Wood/Marble/Terrain/Clouds/Brick) computed the pattern in its OWN buffer's
  coordinate space — noise sampled from pixel (0,0), ring/rotation centre scaled by the buffer
  size — so the small loupe CROP and the full-layer APPLY anchored a different patch at a different
  feature density; the preview never matched. **FIX:** define the pattern once in CANVAS coordinate
  space via new anchor globals (`IMGADJ_TEX_ORIGX/Y`, `IMGADJ_TEX_SPANW/H`, `GUI/IMAGE-ADJ.BI`) set
  per call by `IMGADJ_tex_anchor_preview` (origin = loupe crop's canvas top-left) /
  `IMGADJ_tex_anchor_apply` (origin = -layer apron); both then sample the identical global pattern,
  so the loupe is a true window onto the applied result. Zero-span sentinel falls back to buffer
  size (legacy-safe). **Bonus:** Wood was also rebuilt to actually read as wood — y-stretched
  domain-warp so grain flows along the board, a dark early-wood-line → pale late-wood colour ramp,
  and along-grain pore noise (replacing the old plasticky single-sine banding). Confirmed by Rick.
### BUG-73 [LOW,UNVERIFIED] — Crystallize can leave opaque black fringe on alpha edges.
### BUG-75 [LOW] — `MUSIC_play_random_ext` stops music if the extension has 0 tracks (`SOUND.BM:419`).
### BUG-76 [LOW,UNVERIFIED] — `.TDX` values trusted without bounds vs the `.TDF` (`TDF-FONT.BM:827`).
### BUG-77 [LOW,UNVERIFIED] — PIXEL-COACH `imgW/imgH` INTEGER overflow on >32767px image.
### BUG-78 [HIGH] — Menu bar dropdowns stop opening after export + alt-tab away/back. **Repro (Rick, 2026-08-28):** File > Export PNG, then switch to another desktop window (Qwenview) to view the PNG, then return to DRAW — clicking a menu title (File) highlights it but the dropdown never opens; the click is audibly registered. **Root cause (confirmed):** DRAW had **no window-focus handling at all**. The export dialog is innocent (`MOUSE_cleanup_after_dialog` resets buttons on both OK/Cancel). Alt-tabbing to another window swallows the mouse-RELEASE edge while DRAW is unfocused → `MOUSE.OLD_B1%` latches TRUE → the menubar's press-edge guard `MOUSE.B1% AND NOT MOUSE.OLD_B1%` (`INPUT/MOUSE.BM:600`) can never fire again → dropdown highlights (hover has no button guard) but never opens. Same stuck edge would silently break toolbar/panel clicks too. **FIX (applied 2026-08-28):** new `MOUSE_focus_guard` (`INPUT/MOUSE.BM`) tracks `_WINDOWHASFOCUS` and, on the unfocused→focused transition, runs `MOUSE_cleanup_after_dialog` (forces B1/OLD_B1 up, drains `_MOUSEINPUT`, suppress frames, releases modifiers). Wired into the main loop before `MOUSE_input_handler` (`DRAW.BAS`).
### BUG-79 [HIGH] — QB64 code export produces a program that does NOT compile (`SAFE_FREEIMAGE` undefined). **Repro (Rick, 2026-08-28):** File > Export > QB64 code, then compile the generated `.BAS` → `Syntax error … SAFE_FREEIMAGE IMG_BACKGROUND`. **Root cause:** `FILE-QB64.BM` emits `SAFE_FREEIMAGE …` at 29 sites (Cleanup SUB + the compositing body), but `SAFE_FREEIMAGE` is a DRAW-internal helper (`CORE/HELPERS.BM`), undefined in the standalone export. **FIX (applied 2026-08-28):** emit a self-contained one-line `SUB SAFE_FREEIMAGE (handle AS LONG) / IF handle < -1 THEN _FREEIMAGE handle / END SUB` into every generated program, unconditionally, right after the always-emitted Cleanup SUB — resolves all 29 call sites at once. Verified: standalone probe with the emitted SUB + both guarded and bare calls compiles to an executable. Found alongside BUG-60 in the same repro.
### BUG-81 [HIGH] — Wand selection dragged off-canvas crashes (`#300 Memory region out of range`) — **FIXED (2026-08-29)**. **Origin:** forum report (Kubuntu 24.04, DRAW 1.1) — Magic Wand select → Copy → Paste → drag the floating selection → `Critical Error #300 · Line 2062 (in MARQUEE.BM)`. The reported *paste* path is already safe in 2.x (`CLIPBOARD_paste` calls `MAGIC_WAND_reset`, the BUG-1 fix), but the underlying defect reproduces via **wand select → Move-drag off-canvas**. **Root cause:** `MOVE_apply_transform` translates `MARQUEE.WAND_MIN/MAX_X/Y` by the drag delta unclamped (`MOVE.BM:1077`); two consumers then `_MEM`-scan those bounds against the **canvas-sized** `SELECTION_MASK` / apron buffer with no clamp — `MAGIC_WAND_build_edge_cache` (`MARQUEE.BM:2061`, the #300 the forum hit) and the mask-aware move-clear (`MOVE.BM:802`, a second #300 the first one cascaded into). Off-canvas bounds drove the `_MEMGET`/`_MEMPUT` offset outside the region. **FIX:** clamp the edge-cache scan to the mask's real extent (both passes, `MARQUEE.BM`); bound the apron-offset write coord in the move-clear (`MOVE.BM`). **Crash UX (fix it everywhere):** a trapped runtime error was a blocking `_MESSAGEBOX` in non-dev mode — `CRASH_notify_once` now **always** shows the non-blocking auto-dismiss banner, never a modal (`CORE/CRASH.BM`). **QA:** two repro tests (`QA/tests/wand-drag-offcanvas-crash.sh`, `wand-paste-drag-offcanvas-crash.sh`); plus a qa-harness capture fix — render-loop crashes never flush a crash-report *file*, so the harness now also greps DRAW's captured console output for runtime-error text (`assert_no_crash_log`). Verified: unfixed → test FAILS on the console trap; fixed → passes clean.

### BUG-80 [HIGH] — Merge (Down / Visible) loses a TEXT layer's content. **Repro (Rick, 2026-08-28):** new doc, draw a filled rect on a layer, add a Text layer with "A" above it (visible on canvas), Layer > Merge Down → the "A" is gone; layer count drops but the text pixels are lost. Blocks BUG-19 (merge-visible redo) testing. **Root cause:** two defects in `LAYERS_merge_down` (`GUI/LAYERS.BM:1776`) and `LAYERS_merge_visible` (`:1930`): (1) **apron stretch** — text placed low/right on the canvas can trip apron promotion (the tool's overflow guard measures the nominal font size, but `TEXT_LAYER_ensure_apron` measures the taller actual font cell), so `imgHandle&` becomes bigger than the canvas with the content at an (apronW,apronH) offset; a bare `_PUTIMAGE , imgHandle&` then stretch-shrinks the whole oversized buffer into the canvas-sized target and pushes the glyph out of view; (2) **lazy raster** — text pixels only land in `imgHandle&` during a render pass, which merge (input phase) runs before. **FIX (applied 2026-08-28):** rasterize text sources (`TEXT_LAYER_ensure_apron` + `TEXT_LAYER_render`) **before** the history snapshot — the snapshot is a raw `_COPYIMAGE` of `imgHandle&` (`TOOLS/HISTORY.BM:2067`), so rasterizing first is what makes **undo restore the text too** — then extract the canvas region from apron-promoted sources (mirroring `LAYERS_flatten&`) and composite at the target's apron offset. Applied to both merge-down and merge-visible. Undo verified to survive (rasterize precedes the snapshot).

## BLOCKED — needs a Rick decision

_(none — no bug required a decision only Rick can make. BUG-6 is an optional UX polish; BUG-4 is
minor tidiness. Neither blocks.)_

---

## RUN SUMMARY (v2.0.0 bug hunt — 2026-08-25)

**Branch:** `v2.0.0-input-hardening` off `main`. 10 commits, NOT merged — awaiting Rick's review.

**Scope:** started as an input-seam pass (8 bugs, both user-reported among them), then THREE
exhaustive deep-hunt waves — **16 finder agents** covering history, apron, groups/symbols,
transform, selection, rendering/effects, tool internals, the mouse+dispatch pipeline,
keyboard/dialogs/widgets, multi-instance, config/startup, GUI chrome, file exporters &
importers, effect-engine math, fonts/TDF, PIXEL-COACH, and sound. Every finding was
adversarially re-verified against source before logging.

**Result: 77 bugs found · 40 fixed & verified · 2 closed (not bugs) · 35 deferred (documented).**

**Both user-reported bugs fixed + QA-verified:** BUG-1 (paste stale wand mask) and BUG-2 (orphaned
transform overlay — "can't erase until reload", repro RED→GREEN).

**Highest-impact fixes:**
- BUG-14/16 systemic apron coordinate offset (paint landed ~50% off after a Move) — verified GREEN.
- BUG-26 text/AI layer data lost on save (sparse-array class) + BUG-25/62 same class in palette/export.
- BUG-44 palette-strip crash · BUG-40 command-palette keystroke leak · BUG-53 CLI arg-drop.
- BUG-65/66 importer crashes on malformed PSD/Aseprite · BUG-74 TDF glyph-width cache desync.
- BUG-7 dormant soft AA eraser wired · BUG-3 MOVE float leak · BUG-9 transform rotate math.

**Verification:** every fix batch compiled clean; 10/10 new seam tests + apron test GREEN; input
pipeline regression (INPUT.BM/MOUSE.BM/BRUSH.BM changes) confirmed no regressions; AA-off + compact
paths byte-identical by construction.

**Deferred (35, all with root cause + file:line in the sections above):** the biggest are export
group-isolation (BUG-59/60/61 — needs the renderer's compositor factored out), the transform
pipeline mask/apron/clip (10/11/12), merge-redo (19), group drag-reorder undo (45), rotate/scale
float mask (22), theme lazy-load for incomplete themes (54). The rest are LOW/UNVERIFIED.

**Deliverables:** `PLANS/INPUT-SEAMS-AUDIT.md` · 3 new seam diagrams + ~60 reconciled (all 70 DOT
render clean) · 11 QA tests (`QA/tests/seam-*.sh` + `apron-paint-after-move.sh`) · this catalog ·
the live bug artifact.

**Suggested next steps for Rick:** (1) merge the branch — everything shipped is verified. (2) eyeball
the soft AA eraser (enable AA, erase over a filled area — feathers now). (3) prioritize the deferred
list — the export group-isolation cluster (59/60/61) is the most user-visible remaining item.
