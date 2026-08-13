# DRAW Render-Order / Z-Order Inventory & Preview-Cursor Bug Diagnosis

Code-derived from `OUTPUT/SCREEN.BM` (`SCREEN_render`, 3621 lines), `GUI/PREVIEW.BM`,
`GUI/POINTER.BM`, `GUI/CURSOR.BM`, `GUI/CROSSHAIR.BM`, `GUI/TOOLTIP.BM`,
`TOOLS/PICKER-LOUPE.BM` (loupe body lives in `GUI/PREVIEW.BM`), and `INPUT/MOUSE.BM` /
`INPUT/INPUT.BI` / `INPUT/INPUT.BM` for the input-side z-order.

**Comments in the source are NOT trusted as spec.** Where a comment claims an ordering
that the code does not actually produce, it is flagged explicitly (see the Preview-Cursor
Bug section — `GUI/POINTER.BM:1601-1602` is a false comment).

---

## 0. The two compositing surfaces

Everything hinges on **which destination** a draw call targets:

| Surface | What it is | When it reaches the window |
|---------|-----------|----------------------------|
| `SCRN.CANVAS&` | The full-resolution back-buffer. Layers, GUI chrome, overlays, marching ants, crosshair, **and the cursor** are all composited here. | Upscaled to screen 0 via one `_PUTIMAGE (0,0)-(_WIDTH(0)-1,_HEIGHT(0)-1), SCRN.CANVAS&, 0` (`SCREEN.BM:3595`, and the per-path equivalents at `2842/2844` and `3084`). |
| **screen 0** (`_DEST 0`) | The actual window. | Painted **directly** by the floating overlays **after** the canvas upscale, then `_DISPLAY`. |

The floating overlays — **preview window, color mixer, image browser, preview tooltip,
preview loupe, and the tooltip reblit** — bypass `SCRN.CANVAS&` and blit straight to
screen 0 *after* the upscale. Anything composited into `SCRN.CANVAS&` (including the
cursor) is therefore **beneath** every screen-0 overlay unless it is separately
re-blitted to screen 0. Only the tooltip does that (`TOOLTIP_reblit_to_screen0`). **The
cursor does not** — that is the bug.

- `PREVIEW_render` → `_DEST 0` at `GUI/PREVIEW.BM:783-784`
- `PREVIEW_render_tooltip` → `_DEST 0` at `GUI/PREVIEW.BM:904-905`
- `PREVIEW_render_loupe` → `_DEST 0` at `GUI/PREVIEW.BM:2025-2026`
- `TOOLTIP_reblit_to_screen0` → `_DEST 0` at `GUI/TOOLTIP.BM:666`
- `COLORMIXER_render` / `BROWSER_render` → blit to screen 0 (same pattern, after upscale)
- `POINTER_render` / `POINTER_render_cursor_overlay` → `_DEST SCRN.CANVAS&` at
  `GUI/POINTER.BM:1317` and `:1577` — **canvas only, never screen 0.**

---

## 1. `SCREEN_render` has THREE exit paths

`SCREEN_render` begins at `SCREEN.BM:2606`. Depending on dirty state it takes one of
three routes, **each of which reproduces the same preview-over-cursor ordering**:

| Path | Range | Trigger |
|------|-------|---------|
| **A. STATUS-ONLY fast path** | `~2709-2884` → `GOTO SkipToPointer` (or its own `_DISPLAY` at `2855`) | `NOT SCENE_DIRTY% AND NOT GUI_NEEDS_REDRAW% AND STATUS_NEEDS_REDRAW%` |
| **B. DIRTY-RECT partial-present path** | `~2892-3114` → own `_DISPLAY` at `3099` (or `GOTO SkipToPointer` at `3114`) | `NOT SCENE_DIRTY% AND SCENE_CACHE& <> 0 AND NOT patternTileMode%` |
| **C. FULL render path** | `~2620-3376` build, then `SkipToPointer:` label at `3378` → `_DISPLAY` at `3614` | `SCENE_DIRTY%` (full scene rebuild) |

Paths A and B are "cursor moved / status ticked, scene unchanged" optimizations that
restore the scene from `SCENE_CACHE&` and redraw only the moving overlays. They still
end with the same **cursor-into-canvas, then preview-onto-screen-0** sequence.

The `SkipToPointer:` label is at **`SCREEN.BM:3378`**. The scene-cache **save** is
**before** it, at **`SCREEN.BM:3364-3376`** (`_PUTIMAGE , SCRN.CANVAS&, SCENE_CACHE&`).
So: everything drawn *before* 3364 is cached; everything drawn *after* 3378 is
per-frame animated overlay (marching ants, cursor, tooltips, popups, floating windows)
and is deliberately kept **out** of the cache.

---

## 2. FULL RENDER ORDER (Path C — the canonical top-to-bottom draw order)

Back-to-front (earlier = further back). All targets are `SCRN.CANVAS&` unless marked
**[screen 0]**. "cache" column = relative to the scene-cache save at `3364`; "Skip" =
relative to `SkipToPointer:` at `3378`.

| # | Element | file:line | Target | vs cache | vs Skip |
|---|---------|-----------|--------|----------|---------|
| 1 | Layer composite (transparency checker → layers → refimg → CRT) | `SCREEN.BM:3253-3280` (`TRANSPARENCY_render` 3254, `RENDER_layers` 3265, `REFIMG_render` 3270, `CRT_render` 3279) | CANVAS | before | before |
| 2 | Grid (behind or on-top of art per `GRID_ON_TOP`) | `3258-3261` / `3283-3287` | CANVAS | before | before |
| 3 | Symmetry guides | `3291-3293` (`SYMMETRY_render_guides`) | CANVAS | before | before |
| 4 | Canvas border | `3300-3305` | CANVAS | before | before |
| 5 | Image-import preview | `3311-3314` (`IMAGE_IMPORT_draw`) | CANVAS | before | before |
| 6 | Crop overlay (+ grid redraw) | `3318-3324` (`CROP_render`) | CANVAS | before | before |
| 7 | Transform overlay | `3328-3332` (`TRANSFORM_render_overlay`) | CANVAS | before | before |
| 8 | Fill-adjust overlay | `3336-3340` (`FILL_ADJ_render_overlay`) | CANVAS | before | before |
| 9 | **Tool previews** (brush/line/rect/ellipse/poly/bezier/spray/smart-shape previews) | `3345` (`RENDER_tool_previews`) | CANVAS | before | before |
| 10 | **GUI composite #1** — blits `SCRN.GUI&` (toolbar, organizer, drawer, editbar, advbar, charmap, palette strip, status, layer panel, text bar, menubar, palette menu, subtool flyout — all rendered into `SCRN.GUI&` at `2628-2675`) over the canvas | `3350` (`_PUTIMAGE , SCRN.GUI&`) | before | before |
| 11 | Crosshair (SHIFT-only assistant) + command-palette gate | `3357` (`RENDER_crosshair_and_command_palette` → `CROSSHAIR_render` at `2382`) | CANVAS | before | before |
| 12 | Scrollbars | `3361-3362` (`SCROLLBAR_render`) | CANVAS | before | before |
| — | **SCENE-CACHE SAVE** | `3364-3376` | — | **=cache** | before |
| — | **`SkipToPointer:` label** | `3378` | — | after | **=Skip** |
| 13 | Selection overlay — marching ants + handles | `3381` (`RENDER_selection_overlay`) | CANVAS | after | after |
| 14 | Smart guides (during move/transform) | `3385-3398` (`SMART_GUIDES_render`) | CANVAS | after | after |
| 15 | Text-layer hover outline | `3401-3451` | CANVAS | after | after |
| 16 | **`POINTER_render`** — brush/tool preview footprint + primary cursor draw | `3455` | CANVAS | after | after |
| 17 | **GUI composite #2** — re-blit `SCRN.GUI&` (full or pointer-dirty-rect partial) so overlays don't bleed onto chrome | `3465-3493` (`_SOURCE SCRN.GUI& : _PUTIMAGE` at `3492`) | CANVAS | after | after |
| 18 | Scrollbars (again, on top of GUI#2) | `3496` | CANVAS | after | after |
| 19 | Contextual status bars (import/refimg/move) | `3500-3509` | CANVAS | after | after |
| 20 | Picker loupe (`TOOL_PICKER` over work area or chrome) | `3512-3516` (`PICKER_LOUPE_render`) | CANVAS | after | after |
| 21 | Layer-panel blend popup | `3519-3521` (`LAYER_PANEL_blend_popup_render`) | CANVAS | after | after |
| 22 | Layer-panel context menu | `3522-3524` (`LAYER_PANEL_ctx_menu_render`) | CANVAS | after | after |
| 23 | Drawer context menu | `3525-3527` (`DRAWER_context_menu_render`) | CANVAS | after | after |
| 24 | Command palette | `3528-3530` (`CMD_render`) | CANVAS | after | after |
| 25 | **`POINTER_render_cursor_overlay`** — redraws the cursor on top of GUI/popups | `3533` | CANVAS | after | after |
| 26 | Drawer wheel tooltip | `3537` (`DRAWER_wheel_tooltip_render`) | CANVAS | after | after |
| 27 | **`TOOLTIP_render`** — main tooltip drawn into the canvas | `3538` | CANVAS | after | after |
| 28 | Crash toast | `3539` (`CRASH_render_toast`) | CANVAS | after | after |
| 29 | Grayscale-preview pass (in-place `_MEM` recolor of work area) | `3548-3593` | CANVAS | after | after |
| — | **CANVAS → screen 0 UPSCALE** | `3595` | screen 0 | after | after |
| 30 | **`PREVIEW_render`** — floating preview window | `3600` | **[screen 0]** | after | after |
| 31 | **`COLORMIXER_render`** — floating color mixer | `3601` | **[screen 0]** | after | after |
| 32 | **`BROWSER_render`** — floating image browser | `3602` | **[screen 0]** | after | after |
| 33 | Preview loupe (picker over work area) | `3604-3607` (`PREVIEW_render_loupe`) | **[screen 0]** | after | after |
| 34 | Preview float tooltip | `3608` (`PREVIEW_render_tooltip`) | **[screen 0]** | after | after |
| 35 | **`TOOLTIP_reblit_to_screen0`** — re-composites the tooltip's canvas region onto screen 0 so it sits above preview/mixer/browser | `3609` | **[screen 0]** | after | after |
| — | `_DISPLAY` | `3614` | — | — | — |

### Path A (STATUS-ONLY) overlay tail — same ordering
`STATUS_render` (2739) → marching ants (2775) → `POINTER_render` (2793) →
`SCROLLBAR_render` (2817) → **`POINTER_render_cursor_overlay` (2819)** → `TOOLTIP_render`
(2820) → upscale (2842/2844) → **`PREVIEW_render` (2849)** → `COLORMIXER_render` (2850) →
`BROWSER_render` (2851) → `PREVIEW_render_tooltip` (2852) → `TOOLTIP_reblit_to_screen0`
(2853) → `_DISPLAY` (2855).

### Path B (DIRTY-RECT) overlay tail — same ordering
marching ants (2989) → `POINTER_render` (3007) → `SCROLLBAR_render` (3020) → loupe (3037)
→ blend popup / ctx menu / drawer menu / cmd palette (3042-3053) →
**`POINTER_render_cursor_overlay` (3055)** → `TOOLTIP_render` (3056) → upscale (3084) →
**`PREVIEW_render` (3087)** → `COLORMIXER_render` (3088) → `BROWSER_render` (3089) →
`PREVIEW_render_loupe` (3092) → `PREVIEW_render_tooltip` (3094) →
`TOOLTIP_reblit_to_screen0` (3095) → `_DISPLAY` (3099).

**In all three paths the cursor overlay is baked into `SCRN.CANVAS&` and upscaled BEFORE
the preview/mixer/browser paint to screen 0. There is no cursor equivalent of
`TOOLTIP_reblit_to_screen0`.**

---

## 3. PREVIEW CURSOR BUG

### Symptom
When the mouse is over the floating **preview window**, the cursor / crosshair is drawn
**underneath** the preview pane — the preview covers the pointer instead of the pointer
riding on top.

### Root cause (precise)
The cursor is composited into `SCRN.CANVAS&`, but the preview window paints **directly to
screen 0 after the canvas has already been upscaled**. So the preview always lands on top
of the cursor:

- `POINTER_render_cursor_overlay` draws the cursor to `_DEST SCRN.CANVAS&`
  (`GUI/POINTER.BM:1577`), called at **`SCREEN.BM:3533`** (Path C), `2819` (Path A),
  `3055` (Path B).
- The canvas is upscaled to screen 0 at **`SCREEN.BM:3595`** (`2842/2844`, `3084`).
- `PREVIEW_render` blits its window buffer to `_DEST 0` at **`GUI/PREVIEW.BM:783-784`**,
  called at **`SCREEN.BM:3600`** (`2849`, `3087`) — i.e. **after** the upscale that
  already carried the cursor to the window.

Draw order on screen 0 is therefore: `[cursor inside upscaled canvas]` **then**
`[preview window]`. Last writer wins → **preview covers cursor.**

### The misleading comment (do not trust it)
`GUI/POINTER.BM:1601-1602` states:

> `' Preview window — draw correct resize/hand/arrow cursor ON TOP of preview.`
> `' This section runs AFTER PREVIEW_render in the pipeline, so z-order is correct.`

This is **false**. The special-case block that follows (`GUI/POINTER.BM:1603-1633`,
guarded by `PREVIEW_hit_window% OR PREVIEW.resizing%`) does choose the correct cursor
glyph and `_PUTIMAGE`s it — but to `SCRN.CANVAS&` (the `_DEST` set at line 1577), and it
runs at `SCREEN.BM:3533`, which is **before** `PREVIEW_render` at `3600`, not after. The
block picks the right cursor and then that cursor is immediately buried by the preview
blit. The intended "on top of preview" outcome is never achieved for the actual pixels.
A parallel comment at `SCREEN.BM:3458-3459` correctly notes the preview is "drawn after
the canvas upscale … like the color mixer" — which is exactly why the cursor loses.

Contrast the **tooltip**, which has the identical structural problem and *solves* it:
`TOOLTIP_render` draws into the canvas (`3538`) and then `TOOLTIP_reblit_to_screen0`
(`3609`, `GUI/TOOLTIP.BM:660-668`) re-blits the tooltip's canvas region straight to
screen 0 **after** the floating windows. The cursor has no such reblit, so it stays
buried.

### Proposed fix (direction only — no code changed)
Give the cursor a screen-0 reblit that runs **after** `PREVIEW_render` /
`COLORMIXER_render` / `BROWSER_render`, mirroring `TOOLTIP_reblit_to_screen0`:

1. Add e.g. `POINTER_reblit_cursor_to_screen0` that redraws the current cursor glyph
   (using `POINTER.CURSOR_ID%` / `CURSOR_FLIP%` + hotspot, or re-blits the pointer
   dirty-rect from `SCRN.CANVAS&`) to `_DEST 0`, scaled by `SCRN.displayScale%`, exactly
   as `TOOLTIP_reblit_to_screen0` does at `GUI/TOOLTIP.BM:660-668`.
2. Call it in **all three paths** immediately **after** the floating-overlay stack and
   **before** `_DISPLAY`: after `SCREEN.BM:3602` (Path C), after `2851` (Path A), after
   `3089` (Path B). It should sit above preview/mixer/browser but below the preview float
   tooltip / `TOOLTIP_reblit_to_screen0` (so tooltips still win over the cursor, matching
   the current "tooltip on top of everything" intent at `SCREEN.BM:3535`).
3. Only reblit when the pointer is actually over a floating window (reuse the existing
   `PREVIEW_hit_window% / COLORMIXER_hit_window% / BROWSER_hit_window%` guards), so the
   common case pays nothing.

The existing cursor-glyph-selection block at `GUI/POINTER.BM:1603-1633` already computes
the correct cursor for the preview case — it just needs to render to screen 0 at the
right point in the pipeline instead of to `SCRN.CANVAS&` before the upscale. Simplest:
route that block (or a new reblit sub) through `_DEST 0` and call it in the screen-0
overlay tail.

**What must render after what:** the cursor overlay must render (to screen 0) *after*
`PREVIEW_render`/`COLORMIXER_render`/`BROWSER_render`, not before the canvas upscale.

---

## 4. Render z-order vs INPUT z-order — cross-check

### Region registration (input hit-test space)
All three floating windows register their input regions at **`ZORDER_PANEL` (=100)** —
the *same* z-order as docked chrome panels:

- `REGION_PREVIEW` (10) → `REGION_set_bounds … ZORDER_PANEL` at `GUI/PREVIEW.BM:337`
- `REGION_COLOR_MIXER` (11) → `… ZORDER_PANEL` at `GUI/COLOR-MIXER.BM:368`
- `REGION_IMAGE_BROWSER` (12) → `… ZORDER_PANEL` at `GUI/BROWSER.BM:1148`

Their bindings are all registered **`dispatched = FALSE`** (metadata only) in
`INPUT/INPUT.BM:502-514`, so the central dispatcher does **not** own them — legacy
`INPUT/MOUSE.BM` code does the actual hit resolution via explicit
`PREVIEW_hit_window% / COLORMIXER_hit_window% / BROWSER_hit_window%` checks.
`ZORDER_` constants live at `INPUT/INPUT.BI:125-131` (`CANVAS 0`, `PANEL 100`,
`FLYOUT 300`, `POPUP_MENU 500`, `MODAL 1000`, `COMMAND_PALETTE 1500`, `TOOLTIP 9999`).

### Mismatch #1 — floating windows sit at panel z-order but render above panels
**Render order:** preview/mixer/browser paint to screen 0 *after* the whole
`SCRN.GUI&` chrome (steps 30-32, well after GUI composites at 10/17). Visually they are
**above** every docked panel.
**Input order:** they are registered at `ZORDER_PANEL`, **equal** to the docked panels.
If a floating window overlaps a docked panel (it can — the preview/mixer/browser float
freely over the work area and can be dragged over chrome), the region system has no
z-order tie-breaker between them; resolution depends on `REGION_hit_test%` iteration
order, not on the visual stacking. A floating window that visually covers a panel is not
guaranteed to win the click. **Seam.**

### Mismatch #2 — inter-floating-window order is reversed between render and input
**Render (bottom→top):** preview (30) < mixer (31) < browser (32). Browser is visually
on top.
**Input:** `INPUT/MOUSE.BM:1153-1155` (and `1242-1258`, `3952-3958`) test
**PREVIEW first**, then mixer, then browser, several of them `EXIT SUB` on the first hit.
That is the **opposite** of the visual top-most-wins order. Where two floating windows
overlap, the click can be claimed by the visually-*lower* preview even though the browser
is drawn on top. Some later sites (`MOUSE.BM:4599-4600`, `5135-5137`, `5155-5159`,
`5176-5187`) *do* special-case "preview only if not over browser," i.e. they hand-patch
browser priority — evidence the base ordering is wrong and is being compensated for
inconsistently. **Seam.**

### Mismatch #3 — cursor visual vs cursor hit-test over preview
Because of the Section-3 bug, when hovering the preview the *displayed* cursor is the one
baked into the canvas (buried), while `POINTER_build` (`GUI/POINTER.BM:222-245`) has
already selected the correct preview resize/move cursor. The **hit-test/behavior** is
correct (input treats the pointer as over the preview) but the **visual** is wrong — a
render/input coherence gap that will read as "the cursor is behind the window."

---

## SEAMS / GAPS (test tasks + fixes)

- **[BUG] Cursor renders under the floating preview window.** `POINTER_render_cursor_overlay`
  (`SCREEN.BM:3533`, draws to `SCRN.CANVAS&`) runs before the canvas upscale (`3595`) and
  before `PREVIEW_render` (`3600`, draws to screen 0). Fix: add a cursor screen-0 reblit
  after the floating overlays in all three paths, mirroring `TOOLTIP_reblit_to_screen0`.
- **[BUG] Same cursor-under-window issue for the COLOR MIXER and IMAGE BROWSER** — they use
  the identical "blit to screen 0 after upscale" pattern (`SCREEN.BM:3601-3602`), so the
  cursor is buried under them too, not just the preview. The fix must cover all three.
- **[FALSE COMMENT] `GUI/POINTER.BM:1601-1602`** claims the cursor block "runs AFTER
  PREVIEW_render … so z-order is correct." It runs *before* and draws to the wrong surface.
  Correct the comment when fixing, so the invariant isn't reintroduced.
- **[INPUT SEAM] Floating windows registered at `ZORDER_PANEL`** (`PREVIEW.BM:337`,
  `COLOR-MIXER.BM:368`, `BROWSER.BM:1148`) but rendered above all panels — equal input
  z-order to the chrome they visually cover. A click on the overlap can hit the panel
  beneath. Consider a dedicated `ZORDER_FLOATING` above `ZORDER_PANEL`.
- **[INPUT SEAM] Inter-floating-window hit-test order is reversed vs render order.**
  Render: preview < mixer < browser (top). Input tests preview first (`MOUSE.BM:1153-1155`,
  `1242-1258`, `3952-3958`) and exits on first hit. Overlapping windows: the lower one can
  steal the click. Several sites hand-patch browser priority (`MOUSE.BM:4599`, `5135`,
  `5155`, `5176`) — inconsistent. Unify to topmost-wins matching render order.
- **[COHERENCE GAP] Cursor visual vs behavior over preview** — behavior/hit-test correct,
  visual buried (consequence of the main bug). Verify fixed once the reblit lands.
- **[VERIFY] Tooltip is correctly on top** in all three paths (`TOOLTIP_reblit_to_screen0`
  at `3609/2853/3095`). Cursor should end up *below* tooltip but *above* preview/mixer/
  browser after the fix — regression-test tooltip-over-cursor still holds.
- **[VERIFY] SHIFT-crosshair over preview** is already suppressed
  (`SCREEN.BM:2377-2379`, `RENDER_crosshair_and_command_palette`) so it does not fight the
  preview; but the *system/custom cursor* is not suppressed and is the actual victim.
  Confirm the fix targets the cursor overlay, not the crosshair assistant.
