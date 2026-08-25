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
- **Status:** OPEN — root-caused. QA repro test = `QA/tests/seam-copy-then-wand.sh`.

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
- **Status:** OPEN — root-caused. QA repro test = `QA/tests/seam-eraser-reaches-all.sh`.

### BUG-3 — MOVE float survives document creation → composites onto the NEW document
- [ ] **Symptom (found by audit, not yet user-confirmed):** if a paste/move float is active and
  you Open a file or File→New, the floating pixels from the OLD document appear on the NEW one
  the next time the Move tool is selected.
- **Root cause:** `DRW_load_binary` / `DRW_new_canvas` / `DRW_create_canvas_at_size` all reset
  ~20 subsystems but **none reset the MOVE float**. `MOVE_reset` can't be used (it *commits* via
  `MOVE_apply_transform`, `MOVE.BM:66-69`), so they skip MOVE entirely — but they also never
  call `MOVE_cancel_transform` (`MOVE.BM:1131`) to discard it. `MOVE.ACTIVE` stays TRUE and
  `MOVE.SELECTION_IMAGE` (< -1) survives; the next `MOVE_reset` (on selecting Move) composites
  that stale image onto the new document's current layer.
- **Repro:** paste something (float appears) → File→Open another .draw → press `V` → old paste
  stamps onto the new file.
- **Fix approach:** add `IF MOVE.ACTIVE THEN MOVE_cancel_transform` (+ free `SELECTION_IMAGE`/
  `PREVIEW_BUFFER`) to all three doc-creation paths, near the other resets. Discard, not commit.
- **Status:** OPEN — root-caused by audit. QA repro = part of `seam-new-open-resets-all.sh` (C10).

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

---

## FIXED

_(none yet)_

---

## BLOCKED — needs a Rick decision

_(none yet)_
