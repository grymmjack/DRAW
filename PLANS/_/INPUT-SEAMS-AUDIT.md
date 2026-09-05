# Input-Seam Audit — v2.0.0

> Source-level map of every transition BETWEEN tools / operations / internal states.
> Built during Phase A of the `v2.0.0-input-hardening` loop. Feeds the seam diagrams
> (Phase B) and QA seam tests (Phase C). Bugs found → `BUGS-v2.0.0.md`.

---

## 0. The tool-switch chokepoint

`SUB TOOLS_reset_all (includeMarquee AS INTEGER)` — `GUI/GUI.BM:22-64`. Called on essentially
every tool switch. What it resets:

| Group | Resets called |
|-------|---------------|
| Crop | `CROP_cancel` (if `CROP.STATE = CROP_STATE_ACTIVE`) |
| Shape tools | `LINE_reset`, `RECT_reset`, `ELLIPSE_reset`, `POLY_LINE_reset`, `BEZIER_cancel_restore` |
| Smart shapes | `SS_POLYGON/PIE_DONUT/RR/TAB/PILL/PACMAN/CUBE/BEVEL/ARROW/TEXT_reset` (all 10) |
| Interactive | `MOVE_reset`, `SPRAY_reset`, `ZOOM_drag_reset`, `TEXT_reset`, `ERASER_reset` |
| Special modes | `FILL_deactivate`, `PICKER_deactivate` |
| Marquee (opt-in) | `MARQUEE_reset` + `MAGIC_WAND_reset` **only when `includeMarquee% = TRUE`** |

`MARQUEE_reset` (`TOOLS/MARQUEE.BM:18`) also calls `FREEHAND_SEL_reset`, `POLY_SEL_reset`,
`ELLIPSE_SEL_reset` — so the marquee variants are covered whenever the marquee is reset.

### ⚠️ GAPS in `TOOLS_reset_all` (the bug edges)

| Missing reset | Consequence | Bug |
|---------------|-------------|-----|
| **`TRANSFORM_commit`/`_cancel`** | `TRANSFORM.ACTIVE` survives a tool switch → overlay keeps baking onto the canvas → un-erasable pixels until reload | **BUG-2** |
| **`CUSTOM_BRUSH_reset`** | custom-brush in-progress state (create/transform) can survive a switch | (investigate) |
| **`IMAGE_IMPORT_reset`** | import placement state can survive a switch (modal flow — lower risk) | (investigate) |
| Marquee+wand preserved by default | stale `SELECTION_MASK`/`WAND_*` bounds carried across paste/move | **BUG-1** |

---

## A1 — Every `CURRENT_TOOL%` change site + reset behavior

131 assignment sites across 28 files; the ones that constitute a *user-facing tool switch*
(and therefore a seam) are:

### Primary switch sites (call `TOOLS_reset_all FALSE`)

| Site | Trigger | Resets | Notes |
|------|---------|--------|-------|
| `INPUT/KEYBOARD.BM:127-274` | tool hotkeys (b/f/d/l/p/r/c/q/m/w/v/i/k/z/t) | `TOOLS_reset_all FALSE` after setting `CURRENT_TOOL%` | changes tool **first**, then resets; re-activates FILL/PICKER; `v`→`MOVE_capture_selection` |
| `GUI/TOOLBAR.BM:362-372` | toolbar button click | guards `CROP_cancel` + `MOVE_reset` **before** switch, then `TOOLS_reset_all FALSE` | resets MOVE **before** tool change (opposite order to keyboard) |
| `GUI/SUBTOOL-FLYOUT.BM:213-214` | sub-tool flyout pick | `TOOLS_reset_all FALSE` | |

### Special / implicit switch sites (do NOT go through the normal guard)

| Site | Sets tool to | Reset behavior | Risk |
|------|-------------|----------------|------|
| `TOOLS/SELECTION.BM:234` `CLIPBOARD_paste` | `TOOL_MOVE` | `TOOLS_reset_all FALSE` — **preserves** wand mask, overwrites `MARQUEE.BOX` | **BUG-1** stale mask |
| `INPUT/KEYBOARD.BM:208` `s`/`S` | smart shape (via `SMART_SHAPES_activate_remembered`/`cycle_next`) | **no `TOOLS_reset_all`** here — relies on the SS activate path | verify SS activate resets prior tool state |
| `TOOLS/TRANSFORM.BM` | restores `PREV_TOOL` on commit/cancel | `TRANSFORM_commit`/`_cancel` restore tool | fine *when* called; orphaned on tool-switch (**BUG-2**) |
| temp-picker (`I`, Alt) | `TOOL_PICKER` then restores `PREVIOUS_TOOL%` | picker activate/deactivate | verify restore path |
| `TOOLS/IMAGE-IMPORT.BM`, `INPUT/FILE-ASE/PSD.BM`, `TOOLS/REFIMG.BM`, `TOOLS/CROP.BM` | modal/import flows | their own reset/commit | mostly modal; note for completeness |

### Ordering asymmetry (latent seam)
- **Keyboard**: `CURRENT_TOOL% = X : TOOLS_reset_all FALSE` — MOVE/shape resets run *after* the
  tool already changed.
- **Toolbar**: `IF old=MOVE AND MOVE.ACTIVE THEN MOVE_reset : CURRENT_TOOL% = X : TOOLS_reset_all` —
  MOVE committed *before* the change.
- If any `*_reset`/`*_apply` reads `CURRENT_TOOL%` to decide behavior, the two paths differ.
  → covered by QA `seam-move-then-switch.sh` (C8) and `seam-partial-shape-abandon.sh` (C1).

---

## A2 — Stateful tools & their reset contracts

All frees go through `SAFE_FREEIMAGE` (`CORE/HELPERS.BM:18`, guards `handle < -1`) or inline
`< -1` guards — **no bare `_FREEIMAGE`; no unguarded frees anywhere in the reset surface.**

| Tool | Reset SUB | In-progress state | Handles freed | Seam behavior / gap |
|------|-----------|-------------------|---------------|---------------------|
| LINE | `LINE.BM:224` | drag + coords, caps, spokes | none | clean; commits only on release |
| RECT | `RECT.BM:74` | drag + coords, filled, divisions | none | leaves `CENTER_X/Y` (harmless) |
| ELLIPSE | `ELLIPSE.BM:71` | drag + coords, slices, rings | none | leaves `CENTER_X/Y` (harmless) |
| POLY_LINE | `POLY-LINE.BM:23` | HAS_LAST, POINT_COUNT, `HISTORY_BEFORE_IMG` | snapshot | **seam uses plain `reset` — leaves partial pixels on layer** (asymmetric vs Bezier) |
| BEZIER | reset `:39` / `cancel_restore` `:59` | STATE, points, `HISTORY_BEFORE_IMG` | snapshot | seam uses `BEZIER_cancel_restore` → **rolls canvas back** (discards partial curve) |
| MARQUEE | `MARQUEE.BM:18` | ACTIVE/drag/resize/move flags | (mask via wand) | leaves `BOX.*` geometry, `VARIANT`, `MAGIC_WAND_MODE` (intentional); chains the 3 sel-variant resets |
| MAGIC_WAND | `MARQUEE.BM:1036` | mask + WAND_* bbox + edge cache | `SELECTION_MASK` | complete; sole clearing primitive for the shared mask |
| MOVE | `MOVE.BM:65` → apply `:618` | float img, preview, IS_PASTE, clone, multi-arrays | SELECTION_IMAGE, PREVIEW_BUFFER, multi-originals/previews, ORIGINAL/SCALE_ORIGINAL | **commit-on-reset** (bakes float via `MOVE_apply_transform`); `GROUP_ORIGIN` not re-zeroed in init (smell) |
| TEXT | `TEXT.BM:252` → commit + init | editing text, cursor/sel, preview cache | TEXT_PREVIEW_CACHE | **commit-on-reset** (bakes text); preserves font handles (intentional) |
| SPRAY | `SPRAY.BM:91` | ACTIVE, `HISTORY_BEFORE_IMG` | snapshot | complete |
| ERASER | `ERASER.BM:58` | smart per-layer snapshots, saved FG | ERASER_SMART_BEFORE_IMG(all) | complete |
| TRANSFORM | cancel `:442` / commit `:462` | **ACTIVE, SRC_IMG, PREVIEW_IMG, PREV_TOOL** | SRC_IMG, PREVIEW_IMG, SCENE_CACHE | **no `*_reset`; `TOOLS_reset_all` calls neither → orphaned on switch (BUG-2)** |
| SS_* (10) | `SS-*.BM` | DRAGGING (+ a few extras) | only SS_POLYGON frees `HISTORY_BEFORE` | complete; commit on release |
| CROP | reset `:21` / cancel `:485` | STATE, PREV_TOOL | none (borrows marquee) | seam uses `CROP_cancel` (restores tool + `MARQUEE_reset`) |
| CUSTOM_BRUSH | `CUSTOM-BRUSH.BM:38` | ACTIVE, IMAGE, PREVIEW_CACHE, stash | IMAGE, PREVIEW_CACHE | **not in `TOOLS_reset_all`** (persists by design); stash IMAGE never freed by reset |
| IMAGE_IMPORT | `IMAGE-IMPORT.BM:51` → init | STATE, IMAGE, PREVIEW_IMG, placement | IMAGE, PREVIEW_IMG | **not in `TOOLS_reset_all` → overlay state persists across switch (candidate BUG-5)** |

### Seam-gap summary (feeds Phase B diagrams + Phase D fixes)
- **Live-overlay / handle-leak on tool switch:** TRANSFORM (BUG-2), IMAGE_IMPORT (BUG-5 candidate).
- **Asymmetric abandon:** BEZIER rolls back the canvas; POLY_LINE leaves partial pixels (BUG-6 candidate — decide intended UX).
- **Commit-on-reset (bakes work):** MOVE + TEXT (intended); TRANSFORM would commit but is never reached via reset.
- **Latent field smells:** MOVE `GROUP_ORIGIN`, RECT/ELLIPSE `CENTER_X/Y`, MARQUEE stale `BOX.*`.

## A3 — Document-creation reset diff (New / Open / New-from-clipboard)

Three paths must reset ALL tool/panel state (gotcha #15): `DRW_load_binary` (Open, `DRW.BM:625`),
`DRW_new_canvas` (New, `:2385`), `DRW_create_canvas_at_size` (New-from-clipboard/AI, `:2607`).

| Reset | Open (load_binary) | New (new_canvas) | New-from-clip (create_at_size) |
|-------|:--:|:--:|:--:|
| `TRANSFORM_cancel` | ✓1641 | ✓2510 | ✓2694 |
| `MARQUEE_reset` | ✓1642 | ✓2495 | ✓2679 |
| `MAGIC_WAND_reset` | ✓1645 | ✓2497 | ✓2681 |
| `BEZIER_reset` | ✓1643 | ✓2511 | ✓2695 |
| `CROP_reset` | ✓1646 | ✓2498 | ✓2682 |
| `ERASER_reset` | ✓1647 | ✓2517 | ✓2701 |
| LINE/RECT/ELLIPSE/POLY_LINE/SPRAY | ✓ | ✓ | ✓ |
| SS_* (all 10) | ✓ | ✓ | ✓ |
| `PAN_reset` | ✓1674 | ✓2518 | ✓2702 |
| `FILL_ADJ_reset` | ✓1675 | ✓2519 | ✓2703 |
| PREVIEW/COLORMIXER/CHARMAP/PALETTE_OPS | ✓ | ✓ | ✓ |
| `TEXT_cancel` | ✓824 | ✓2544 | ✓2728 |
| `AI_JOB_cancel` | ✓838 | ✓2558 | ✓2742 |
| `DRAWER_reset` | ✓1177 | ✓2435 | ✓2621 |
| IMAGE_IMPORT | ✓1676 (`_reset`) | ✓2428 (`_cancel`) | ✓2617 (`_cancel`) |
| `ZOOM_drag_reset` | ✓1672 | ✗ | ✗ |
| `CUSTOM_BRUSH_reset` | ✗ **missing** | ✓2433 | ✓2620 |
| **MOVE float** (`SELECTION_IMAGE`/`ACTIVE`) | ✗ **none** | ✗ **none** | ✗ **none** |

### ⚠️ Gaps found
1. **MOVE float not discarded by any doc-creation path** → **BUG-3**. `MOVE_reset` *commits*
   (via `MOVE_apply_transform`, `MOVE.BM:66-69`) so it's wrong here; the correct primitive is
   `MOVE_cancel_transform` (`MOVE.BM:1131`) which discards. None of the three call it, so a live
   paste/move float (`MOVE.SELECTION_IMAGE < -1`, `MOVE.ACTIVE = TRUE`) survives Open/New and
   composites onto the NEW document the next time Move is selected.
2. **`CUSTOM_BRUSH_reset` missing from Open** (present in New & New-from-clip). Inconsistency.
3. **`ZOOM_drag_reset` missing from New & New-from-clip** (present in Open). Minor (zoom drag box).
4. IMAGE_IMPORT uses `_reset` on Open but `_cancel` on New/New-from-clip — verify equivalence.

## A4 — Selection lifecycle & the shared SELECTION_MASK

**The one shared buffer** coupling selection, wand, move, paste, and every region-scoped op:
`MARQUEE.SELECTION_MASK AS LONG` (`TOOLS/MARQUEE.BI:93`) — canvas-sized 32-bit image, white =
selected. Companions: `MARQUEE.WAND_HAS_SELECTION`, `WAND_MIN/MAX_X/Y` (bbox),
`WAND_EDGE_X()/Y()` (outline cache). Consumer idiom everywhere:
`IF MARQUEE.WAND_HAS_SELECTION AND MARQUEE.SELECTION_MASK < -1`.

Lifecycle:
```
 (rect/freehand/poly marquee)          (magic wand click)
        │  mouseup                              │
        ▼                                       ▼
   MARQUEE.BOX set                    MAGIC_WAND_select_* writes SELECTION_MASK,
   MARQUEE.ACTIVE=TRUE                sets WAND_HAS_SELECTION + WAND_MIN/MAX bbox
        │                                       │
        └──────────── merged on mouseup ────────┘  (MARQUEE.BM:645-745, 2841-2937)
                          │
             ┌────────────┼─────────────────────────────┐
             ▼            ▼                              ▼
   drawing clipped   MOVE float (V / paste)      region ops read mask:
   (BRUSH.BM:66      MOVE_capture_selection       fill FG/BG, flips, crop,
    SELECTION_is_    masks through SELECTION_MASK  stroke-sel, save, img-adjust
    point_inside%)   MOVE_apply_transform SHIFTS   (all gate on WAND_HAS_SELECTION)
                     mask (+delta) MOVE.BM:1035
                          │
                          ▼
                   clear: MAGIC_WAND_reset (frees mask, clears flags, REDIMs edge caches)
```

**Writers of the mask:** `MAGIC_WAND_select_with_mode` (`MARQUEE.BM:1080`), `_select_merged`
(`:1603`), `_select_all_color_merged` (`:1861`), the marquee→mask merge (`:645-745`), MOVE shift
(`MOVE.BM:1035-1057`), HISTORY restore (`HISTORY.BM:1765-1773`).
**Readers:** BRUSH clip (`BRUSH.BM:66`), fill FG/BG (`COMMAND.BM:2675,2741`), flips
(`:3447,3637`), crop (`:5218`), clear-sel (`SELECTION.BM:440`), stroke-sel (`STROKE-SEL.BM:264`),
save (`SAVE.BM:476`), img-adjust (`IMAGE-ADJ.BM:162-390`).
**Reset:** `MAGIC_WAND_reset` (`MARQUEE.BM:1036`) is the sole clearing primitive; REPLACE-mode
wand self-heals by calling it first, but ADD/SUB modes MERGE onto the existing mask.

**Seam risk:** any transition that leaves `WAND_HAS_SELECTION=TRUE` with a mask whose
`WAND_MIN/MAX` no longer matches visible content → phantom selection (**BUG-1**).

## A5 — Clipboard lifecycle

Two independent clipboard stores:
1. **Pixel clipboard** `CLIPBOARD AS CLIPBOARD_OBJ` (`TOOLS/SELECTION.BI:16`): `IMAGE`, `WIDTH`,
   `HEIGHT`, `VALID`, `SOURCE_X/Y`. Filled by `CLIPBOARD_copy` (`SELECTION.BM:65`) / `_cut`
   (`:143`) / `_copy_merged` (`:327`); synced to OS via `_CLIPBOARDIMAGE`.
2. **Layer clipboard** (cross-instance) `TOOLS/LAYERXFER.BM`: `LAYERXFER_extract_layer&` (`:34`)
   / `LAYERXFER_add_layer%` (`:94`); uses `_CLIPBOARDIMAGE` + `_CLIPBOARD$` metadata. Builds
   NEW layers, does not touch the wand mask.

```
Copy/Cut ──▶ CLIPBOARD.IMAGE (reads through SELECTION_MASK if WAND_HAS_SELECTION)
                 │
Paste (Ctrl+V) ──▶ CLIPBOARD_paste (SELECTION.BM:234)
                 │   • allocates MOVE.SELECTION_IMAGE + MOVE.PREVIEW_BUFFER
                 │   • CURRENT_TOOL% = TOOL_MOVE, MOVE.ACTIVE=TRUE, MOVE.IS_PASTE=TRUE
                 │   • overwrites MARQUEE.BOX to paste rect, MARQUEE.ACTIVE=TRUE
                 │   • TOOLS_reset_all FALSE  ← PRESERVES wand mask (BUG-1)
                 ▼
      float renders ONLY while CURRENT_TOOL%=TOOL_MOVE AND MOVE.ACTIVE
                 │
      commit: MOVE_reset → MOVE_apply_transform (IS_PASTE ⇒ clone mode, never clears layer)
```

**Paste-as-new-layer / Copy-to-new-layer:** `COMMAND.BM:972-1039` (320/321). **Paste Layer:**
`LAYERXFER_add_layer%` (`COMMAND.BM:1873`). **New-from-Clipboard:** `COMMAND.BM:2394`.

**Seam risks:**
- Paste preserves a stale wand mask and MOVE drags it → **BUG-1**.
- Paste float is MOVE-tool-scoped; on doc-creation it isn't discarded → **BUG-3**.
- Paste engages clone mode (`IS_PASTE`); if `MOVE.CAPTURED_LAYER` is hidden/locked the commit
  can land off-screen (secondary hardening noted by agent).
