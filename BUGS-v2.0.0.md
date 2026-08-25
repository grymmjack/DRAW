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
- **Fix approach:** if reachable, add `IF IMG_IMPORT.STATE > IMPORT_STATE_IDLE THEN IMAGE_IMPORT_cancel`
  to the tool-switch reset (mirrors the doc-creation paths which already do this).
- **Status:** OPEN — candidate, verify in Phase C (`seam-transform-then.sh` companion).

### BUG-6 (candidate) — POLY_LINE vs BEZIER abandon asymmetry
- [ ] **Found by audit.** Switching away mid-shape: BEZIER uses `BEZIER_cancel_restore` (rolls
  the canvas back, discarding the partial curve); POLY_LINE uses plain `POLY_LINE_reset` (frees
  the undo snapshot but **leaves already-drawn partial segments on the layer**). Inconsistent UX.
  Decide intended behavior (likely: both should discard the uncommitted preview on abandon, OR
  both should keep — but they should match). ⛔ May need a Rick decision on desired UX.
- **Status:** OPEN — candidate, needs UX decision (logged, not blocking).

### BUG-7 — Soft AA eraser is dormant (shipped in 2.0.0 but never called)
- [ ] **Found by diagram reconciliation.** The 2.0.0 soft coverage-subtract eraser
  (`PAINT_erase_circle_aa`, `BRUSH.BM:354`) and its selector wrapper `ERASER_draw_at`
  (`ERASER.BM:93-107`, which picks the AA path for round brushes >1px when `CFG.ANTIALIAS%`)
  **have no caller** — the live eraser stroke goes `MOUSE_tool_brush → PAINT_on`
  (`MOUSE.BM:2688-2694`) with a transparent color, i.e. a HARD erase. So the AA-eraser feature
  is effectively dead code; enabling AA does not soften the eraser edge.
- **Verify:** confirm `ERASER_draw_at` truly has zero callers (`grep -rn ERASER_draw_at`).
- **Fix approach:** route the eraser stroke through `ERASER_draw_at` when `CFG.ANTIALIAS%` AND
  round brush >1px (mirror how the brush picks `PAINT_draw_filled_circle_aa`); keep the hard
  path for 1px/square/AA-off (byte-identical). Must respect selection clip + symmetry like the
  brush AA path.
- **Status:** OPEN — code finding, verify then fix in Phase D. Note in `.claude/agent-memory`
  antialiasing.md that Phase 2c eraser wiring was incomplete.

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

## FIXED

_(none yet — BUG-1/2/3 fixes applied, pending build+QA verification)_

---

## BLOCKED — needs a Rick decision

_(none yet)_
