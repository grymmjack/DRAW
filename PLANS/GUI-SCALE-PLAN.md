# GUI scale independent of canvas scale — DONE

**Shipped.** VIEW > GUI SCALE +/-/RESET, command palette "GUI Scale: …",
`GUI_SCALE` in DRAW.cfg. Verified: chrome renders 2x while the canvas scale and
viewport are untouched, and hit-testing resolves correctly at 2x.

Two notes for anyone extending it:

- Chrome pixels are **magnified, not redrawn**, so text is chunky at 2x. Making
  it crisp means the per-widget approach (real scale on every metric and font),
  which is a much larger change — see "Thread a scale through every widget".
- At 2x the chrome eats proportionally more of the viewport, so the menubar can
  overflow and the palette strip wraps. That is inherent to the feature, not a
  bug, but the menubar overflow indicator is worth a look at high GUI scales.

The original plan follows.

---



Plan for decoupling chrome size from canvas magnification, so a large-pixel
document (TheDraw fonts, big art) can use a low display scale — maximum canvas
pixels on screen — while the UI stays readable.

Approach chosen: **scale the GUI surface**. Chrome keeps drawing at 1:1 into its
own smaller surface, which is then blitted magnified. No widget is edited.

---

## What the code actually looks like today

This is the part that matters, because the obvious assumption is wrong.

`OUTPUT/SCALE.BI` presents a per-widget scale model (`USCALE.toolbar`,
`USCALE.dialog`, `USCALE.preview`, …) which looks like it already solves this.
**It does not cover the core chrome.** Count of `USCALE.` references:

| module | uses |
|--------|------|
| `GUI/MENUBAR.BM` | 0 |
| `GUI/STATUS.BM` | 0 |
| `GUI/TOOLBAR.BM` | 0 |
| `GUI/LAYERS.BM` | 0 |
| `GUI/PALETTE-STRIP.BM` | 0 |
| `GUI/TEXT-BAR.BM` | 0 |

The main chrome is drawn at **fixed logical pixel sizes** (8px fonts, constant
row heights from `THEME.*`). Its apparent size comes entirely from
`SCRN.displayScale%`, which magnifies the *whole framebuffer*:

```
winW = SCRN.w& * SCRN.displayScale%      (OUTPUT/SCREEN.BM:416)
```

So there is no chrome scale knob to redirect. Adding a second master to
`SCALE_resolve_all` would move dialogs, toolbar icons and the file dialog, and
leave the menubar, status bar, layer panel, palette strip and text bar exactly
as they are. That is why this needs a different approach.

## The seam that makes it tractable

Chrome already renders into its **own surface**, `SCRN.GUI&`, which is composited
onto `SCRN.CANVAS&` as a separate step:

```
_PUTIMAGE , SCRN.GUI&, SCRN.CANVAS&        (OUTPUT/SCREEN.BM:2678)
```

If `SCRN.GUI&` is allocated smaller and that blit *stretches*, every widget
scales as a unit with no widget code changed.

```
SCRN.GUI&    guiW x guiH        chrome draws 1:1, docks to guiW/guiH
    |
    |   _PUTIMAGE stretched by guiScale
    v
SCRN.CANVAS& SCRN.w x SCRN.h    full viewport
    |
    v   window magnified by displayScale
```

Chrome pixels are magnified rather than redrawn, so text is chunky at 2x. For a
pixel-art editor that reads as intentional; if it ever needs to be crisp, that
is the (much larger) per-widget approach and is a separate task.

## Modules that write to `SCRN.GUI&`

These, and only these, lay out in GUI-logical space:

```
GUI/MENUBAR.BM          GUI/PALETTE-STRIP.BM    GUI/SUBTOOL-FLYOUT.BM
GUI/STATUS.BM           GUI/TEXT-BAR.BM         GUI/CHARMAP.BM
GUI/LAYERS.BM           GUI/ORGANIZER.BM        OUTPUT/SCREEN.BM
```

`GUI/TOOLBAR.BM` does **not** appear — confirm where the toolbar's `_DEST` is
set (SCREEN.BM appears to set it before calling the render sub) before assuming
which space it lays out in. Same check needed for the drawer and preview panel.

`GUI/CROSSHAIR.BM`, `GUI/POINTER.BM` and the tool overlays draw in *canvas*
space and must keep using `SCRN.w&` / `SCRN.h&`. There are 159 `SCRN.w&`/`SCRN.h&`
references across `GUI/*.BM`; a blanket rename is wrong — only the modules above
get retargeted.

## Staged plan

Each stage is independently verifiable, and stage 1-3 are no-ops at
`GUI_SCALE = 1` — that is the regression test: **at scale 1 the app must be
pixel-identical to today.**

### 1. Plumbing (no behaviour change)

- `CFG.GUI_SCALE%` — 0/1 = follow canvas (today's behaviour), 2..4 = fixed
  chrome scale. Add to `CFG/CONFIG.BM` read/write, `DRAW.cfg.default`, and the
  `--config-upgrade` path.
- `SCRN.guiScale%`, `SCRN.guiW&`, `SCRN.guiH&` in `OUTPUT/SCREEN.BI`.
  `guiW = SCRN.w& \ guiScale`, `guiH = SCRN.h& \ guiScale`.
- Resolve in `SCALE_resolve_widgets` alongside the existing masters.

### 2. Allocate and composite

- `SCRN.GUI& = _NEWIMAGE(SCRN.guiW&, SCRN.guiH&, 32)` — **three** sites:
  `SCREEN.BM:411`, `:489`, `:745`. All three must agree or the surface will be
  reallocated at the wrong size on window resize.
- Make the composite blit stretch. The full-surface one is easy; the **dirty-rect
  copies are the real work** — they are currently 1:1 and must map GUI-space
  rects to canvas-space:
  `SCREEN.BM:2796, 2805, 3007, 3344, 3478, 3483, 3486`.
  Getting one wrong shows up as a torn or misplaced chrome strip, and only on
  the partial-update path (i.e. not on a full redraw), so test with the scene
  cache active — move the mouse without dirtying the canvas.

### 3. Retarget chrome layout

- In the modules listed above only, `SCRN.w&` → `SCRN.guiW&`, `SCRN.h&` →
  `SCRN.guiH&`. Identical at scale 1.
- Watch for chrome that positions relative to the *canvas* (smart guides, the
  crosshair, tool previews) — those stay in canvas space.

### 4. Input

- GUI hit-testing needs `MOUSE.RAW_X \ guiScale`. Prefer deriving new
  `MOUSE.GUI_X/GUI_Y` fields in `MOUSE_input_handler` over dividing at every
  call site — there are far too many hit tests to touch individually, and one
  missed division is a control that silently stops responding.
- `INPUT/INPUT.BM` regions (`REGION_set_bounds`) are registered from render subs
  in GUI space, so they are consistent automatically — but the dispatcher
  compares against raw mouse coords, so it must use the GUI coords too.

### 5. Runtime control

- Action ID in `CMD_init` + handler (grep for duplicates first — see gotcha 17).
- Menu entry under VIEW, and a Settings control.
- On change: `SCALE_resolve_all`, reallocate `SCRN.GUI&`, `GUI_NEEDS_REDRAW%`,
  `SCENE_DIRTY%`.

## Risks

- **Dirty-rect blits** (stage 2) are the highest-risk item: wrong maths there
  corrupts the display only on cached frames, which is exactly the path casual
  testing misses.
- **Odd divisions.** A viewport of 801px at guiScale 2 gives guiW 400, which
  blits back to 800 — one column short. Either clamp the viewport to a multiple
  of guiScale or let the stretch cover it; decide deliberately rather than
  discovering a 1px seam later.
- **Panel auto-hide** thresholds compare panel sizes against viewport width; at
  a large gui scale, chrome eats proportionally more room and panels may
  auto-hide sooner. Expected, but verify it does not oscillate.
