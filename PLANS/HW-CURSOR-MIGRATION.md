# Hardware-cursor migration plan — make the OS cursor the default, retire the seams

**Status:** ✅ IMPLEMENTED on branch `hw-cursor` (2026-08-21). Hardware cursor is now
the sole icon-cursor path; software-cursor drawing, the top-overlay pipeline, both
A/B toggles, the OS-stock `_MOUSESHOW` tool path, and the force-full-rebuild-on-move
override are all deleted. GLFW-only (`$IF HWCURSOR` gating removed; Makefile default →
a740g/qb64pe-regen). KEPT: brush/spray rings, custom-brush stamp, picker loupe, SHIFT
crosshair, dirty-rect (feedback-ring erase), OS-stock crosshair/I-beam for the 2
art-less states.

**Measured result (`--bench-render 20`, 2026-08-21):** a canvas mouse-move went from
**6.9ms/frame → 0.57ms/frame — 12× cheaper**; effective CPU while moving @60fps dropped
from **41.4% → 3.4%** of a core. That ~6.3ms/frame was the large-canvas stutter; it's
gone. QA gate + tool batch green (one intermittent tool-ellipse harness flake, passes
in isolation — not a regression).

**Branch context:** `hw-cursor` off `glfw-tests`, PR #701 GLFW build (now required)
**Goal:** default DRAW to the OS hardware cursor for every icon cursor, delete the
software-cursor code that only ever existed to hide software-cursor lag, and
eventually remove the `HARDWARE_CURSOR` A/B toggle — **without** breaking the
canvas-aware cursor feedback that genuinely cannot be an OS cursor.

---

## 0. The load-bearing architectural finding (why this is safe)

`_MOUSECURSOR` is **not** a QB64-PE image layer. It compiles to a native OS cursor:

```cpp
// internal/c/libqb/src/glut-emu.cpp:1355-1357  (MouseSetCustomCursor)
cursor = glfwCreateCursor(&cursorImage, hotspotX, hotspotY);
glfwSetCursor(window, cursor);
```

`glfwCreateCursor`/`glfwSetCursor` → `XcursorImageLoadCursor` (X11), `wl_pointer`
surface (Wayland), `CreateIconIndirect`/`SetCursor` (Windows), `NSCursor` (macOS).
Consequences, all confirmed:

- **It is above the entire framebuffer.** QB64-PE's compositing stack is the four
  `_DISPLAYORDER` entries `_SOFTWARE, _HARDWARE, _GLRENDER, _HARDWARE1` — a per-frame
  draw order, *not* a fixed set of hardware planes. The OS cursor sits on the
  compositor's own cursor plane, above **all** of them.
- **It does not consume a hardware-image slot.** `DEV/EXPERIMENTS/HW_CURSOR_ZORDER_TEST.bas`
  holds a real hardware image (`_COPYIMAGE(...,33)`, handle `-16777214`) and a custom
  `_MOUSECURSOR` at once — orthogonal, no conflict.
- **The compositor moves it — we never repaint under it.** The test can freeze the
  entire render loop (no draw, no `_DISPLAY`) and the cursor still glides. That is the
  whole point: the software-cursor "erase-old / draw-new" dirty-rect dance becomes
  unnecessary for OS-cursor tools.
- **DRAW's canvas is 100% software surfaces** (`_NEWIMAGE(...,32)`); it has **zero**
  hardware images in shipping code. The OS cursor floats above software surfaces just
  as well as hardware ones, so **the canvas does not need to become hardware** for any
  of this. (Hardware-image use is confined to throwaway `DEV/EXPERIMENTS/*.BAS`.)

**The one hard constraint:** an OS cursor is a fixed OS-clamped bitmap with a hotspot.
It cannot be canvas-aware — no zoom-scaled brush ring, no loupe, no full-canvas
crosshair, no live color-chip/coord overlay. Those stay software. This is not a
limitation to engineer around; it's the correct dividing line, and DRAW already draws
it with `POINTER.HW_ICON_ACTIVE%`.

---

## 0a. Empirical profile — the isolated software-cursor tax

`DEV/EXPERIMENTS/HW_CURSOR_PROFILE.bas` (GLFW build, `_UPTIME` clock, 31 timed
rounds/op, per-op iteration count auto-calibrated) times the **exact primitive ops**
the software cursor forces per move, in isolation — not tangled with GUI recomposite
or present. Median µs, Linux/Wayland, real GPU (AMD RX 6600M), quiet machine,
2026-08-20 (tax ops verified GPU-independent — identical under software GL):

**Per-op median (µs), swept by canvas size — note what is O(W·H) vs O(1):**

| op | 320×200 | 640×480 | 1280×800 | 1080p | 1440p | 4K |
|----|--------:|--------:|---------:|------:|------:|---:|
| restore scene (FULL blit) | 67 | 334 | 1073 | 2168 | 3836 | 8618 |
| restore scene (DIRTY rect) | 2.7 | 2.7 | 2.7 | 2.7 | 2.7 | 2.7 |
| overlay CLS | 2.3 | 12.9 | 41.6 | 84.7 | 241 | 1249 |
| cursor sprite blit | 1.2 | 1.2 | 1.2 | 1.2 | 1.3 | 1.2 |
| overlay composite | 68 | 322 | 1067 | 2153 | 3826 | 8607 |
| _MOUSECURSOR install | 16745 | 16750 | 16753 | 16762 | 16757 | 16766 |

**Software-cursor tax per move (ops the OS cursor deletes) and CPU cost:**

| Canvas | tax FULL | tax DIRTY | %core@60 (full/dirty) | %core@240 (full/dirty) | OS cursor |
|--------|---------:|----------:|:---------------------:|:----------------------:|:---------:|
| 320×200 | 0.138ms | 0.074ms | 0.8% / 0.4% | 3.3% / 1.8% | **0ms** |
| 640×480 | 0.671ms | 0.339ms | 4.0% / 2.0% | 16.1% / 8.1% | **0ms** |
| 1280×800 | 2.183ms | 1.113ms | 13.1% / 6.7% | 52.4% / 26.7% | **0ms** |
| 1920×1080 | 4.407ms | 2.241ms | 26.4% / 13.4% | 105.8% / 53.8% | **0ms** |
| 2560×1440 | 7.905ms | 4.072ms | 47.4% / 24.4% | 189.7% / 97.7% | **0ms** |
| 3840×2160 | 18.475ms | 9.860ms | 110.8% / 59.2% | 443.4% / 236.6% | **0ms** |

### What the numbers prove

1. **The tax is two O(W·H) full-surface blits: the scene restore and the overlay
   composite.** Everything else (dirty-rect restore, cursor sprite blit) is O(1) and
   negligible (~1–3µs). So the cost scales with viewport pixels — this is the
   order-of-magnitude story, not a fixed 2.3×.
2. **The OS cursor eliminates 100% of it on a bare move.** DRAW's software path forces
   the FULL scene rebuild on canvas moves today (`DRAW.BAS:606`, `SCENE_DIRTY=TRUE`);
   the OS path renders *nothing* (`DRAW.BAS:635` skip). Per move it is
   `~2–18ms → 0ms` — elimination, not a ratio.
3. **This explains the ~92–100% core saturation the earlier real-world runs saw.** At
   the old `FPS_CURSOR=240`, 1080p full-path = **105.8% of a core just to reposition
   the pointer** — it can't keep up, so it lags and pins a core. Dropping to 60fps
   (already done) cuts it to 26.4%; the OS cursor cuts it to 0.
4. **Even DRAW's "optimized" dirty-rect path still pays a full-surface overlay
   composite** (`tax DIRTY` is ~half of `tax FULL`, dominated by the overlay composite,
   not the cheap 2.7µs restore). The software optimization is only half-done; the OS
   cursor removes the remaining half for free.

### Guardrail this benchmark exposed

`_MOUSECURSOR` install costs **~16.7ms, flat across all sizes AND all platforms** —
measured within noise on Linux Wayland (16.75, AMD RX 6600M), Linux X11 + software GL
(16.76, GitHub CI runner), and **macOS Apple Silicon / NSCursor (16.72)**. Four
different cursor backends, one number ≈ exactly one 60Hz frame: it is a
**platform-independent** QB64PE/GLFW cursor-set sync (`_MOUSECURSOR` blocking ~1
render-thread tick), **not** a Wayland, per-OS, GPU, or offscreen artifact. Because
it is the same everywhere, the dedup guardrail below is **universal** — it does not
relax on any platform. It is paid **once per cursor-icon change**, deduped by
`POINTER.PREV_HW_CURSOR_ID%`/`PREV_HW_CURSOR_SCALE%` (`POINTER.BM:180-185`). **That
dedup is load-bearing:** if a refactor ever calls `_MOUSECURSOR` per frame it would be
~4× *worse* than the software cursor it replaced. Any migration MUST keep install gated
on icon-change only, and QA must assert install-call count stays flat during a drag.

---

## 1. Current state (what exists today)

Software cursor lives almost entirely in `GUI/POINTER.BM` + `GUI/CURSOR.BM`, composited
through `OUTPUT/SCREEN.BM`. There is **no** per-pixel save/restore-under-cursor; flicker
is avoided with a whole-scene cache (`SCENE_CACHE&`) plus a dedicated top overlay
(`SCRN.CURSOR&`).

**Three cursor code paths coexist right now:**

1. **OS named cursor** — `_MOUSESHOW "CROSSHAIR"` etc., gated by
   `CFG.SYSTEM_CURSORS_ENABLED%` (`POINTER.BM:46,138-163`).
2. **OS custom image cursor (the new HW path)** — `_MOUSECURSOR CURSORS(id).hw_img&`,
   gated by `CFG.HW_CURSOR_ENABLED%` + `$IF HWCURSOR` (`POINTER.BM:172-190`,
   builder `CURSOR_ensure_hw%` `CURSOR.BM:174`).
3. **Software-drawn cursor** — `_MOUSEHIDE` then draw the pointer into `SCRN.CANVAS&` /
   `SCRN.CURSOR&` (`POINTER_draw` `POINTER.BM:1365`, `POINTER_render_cursor_overlay`
   `POINTER.BM:1627`, composite `POINTER.BM:1819`).

The `POINTER.HW_ICON_ACTIVE%` predicate (`POINTER.BM:207`) already classifies which
cursors are pure icons (can be OS) vs canvas-aware feedback (must be software), and
`DRAW.BAS:611-636` already skips the full-rebuild-on-move when it's set.

---

## 2. The split: what becomes OS cursor vs what stays software

**Becomes OS cursor (icon cursors — the target of this migration):**
arrow/UI, hand/pan, marquee, move/resize, fill bucket, zoom, dropper *icon*, I-beam,
denied badge — anything that is a fixed bitmap with a hotspot.

**Stays software (canvas-aware, no OS-cursor equivalent):**

| Feedback | Sub | Why it can't be an OS cursor |
|----------|-----|------------------------------|
| Brush footprint ring | `POINTER_draw_brush_preview` `POINTER.BM:997` | radius scales with zoom; larger than OS cursor max |
| Spray radius ring | `POINTER_draw_spray_preview` `POINTER.BM:1101` | same |
| Custom-brush stamp | `POINTER_draw_custom_brush` `POINTER.BM:897` | arbitrary-size, zoom-scaled |
| Picker loupe | `POINTER_draw_picker` `POINTER.BM:968` | samples canvas pixels live |
| SHIFT full-canvas crosshair | `CROSSHAIR_render` `GUI/CROSSHAIR.BM:196` | spans the whole viewport |
| Color-chip / coord overlay | `CURSOR_render_overlays` `CURSOR.BM:351` | live text tied to cursor |
| Shape crosshair (line/rect/ellipse) | `POINTER_draw_shape_crosshair` `POINTER.BM:935` | **decide:** small enough to bake into an OS cursor bitmap? candidate for OS, else stays |

---

## 3. Target architecture (DRY)

Collapse three paths into **one decision, two renderers**:

```
POINTER_render:
  POINTER_build            ' unchanged: sets CURSOR_ID%, canvas-aware flags
  IF cursor_is_canvas_aware% THEN
      _MOUSEHIDE (once)               ' OS cursor off
      <software feedback renderer>    ' rings / loupe / crosshair / overlays only
      POINTER.HW_ICON_ACTIVE% = FALSE
  ELSE
      <install OS cursor for CURSOR_ID%>   ' _MOUSECURSOR, deduped by id+scale
      POINTER.HW_ICON_ACTIVE% = TRUE
      ' NO software draw, NO overlay clear, NO dirty rect
  END IF
```

- **Single source of truth** for "is this cursor canvas-aware?" — promote the logic now
  inside `HW_ICON_ACTIVE%` (`POINTER.BM:207-215`) to a named predicate
  `POINTER_cursor_is_canvas_aware%(id)` used by both the render branch **and** the
  `DRAW.BAS:635` fast-path gate, so they can never disagree.
- **Delete the second toggle dimension.** Today the matrix is
  `{system named} × {hw custom} × {software}`. Target: **OS custom image cursor is the
  only icon path**; named-cursor mode (`SYSTEM_CURSORS`) becomes a fallback for
  platforms/sessions where `_MOUSECURSOR` is unavailable, not a user-facing style
  choice.
- **`SCRN.CURSOR&` overlay + `POINTER_composite_cursor_to_screen0` stop running for
  icon cursors** (they still exist only if a software fallback is compiled).

---

## 4. Phased migration

### Phase 0 — build unblock (DONE)
- `Makefile` `a740g` → `qb64pe-regen` so `_MOUSECURSOR` compiles. ✅
- `DEV/EXPERIMENTS/HW_CURSOR_ZORDER_TEST.bas` proves z-order + freeze. ✅

### Phase 1 — make OS cursor the default, keep software as fallback (no deletions)
1. Extract `POINTER_cursor_is_canvas_aware%(id)` from the `HW_ICON_ACTIVE%` block;
   route both `POINTER_render` and `DRAW.BAS:635` through it.
2. Default `CFG.HW_CURSOR_ENABLED% = TRUE` (already is, `CONFIG.BM:141`) and add the
   `HARDWARE_CURSOR=TRUE` line to `DRAW.cfg.default` (currently missing — `CONFIG.BM`
   writes it but the shipped default file has no line).
3. Guard every software-icon draw sub with an early `EXIT SUB` when
   `POINTER.HW_ICON_ACTIVE%` — so with HW on, they are provably never entered
   (instrument with a `_LOGTRACE` counter during QA to confirm zero calls).
4. **Verify:** run the full QA suite (`QA/draw-qa.sh`, offscreen, small batches per the
   PR701 flake note) with HW on and HW off; diff results. Bench with `--bench-render`.

### Phase 2 — retire the dead software-icon renderers
Once Phase 1 shows zero entry into the icon draw subs across the suite:
- Delete `POINTER_draw` icon branches + `POINTER_draw_pan/_ui_cursor/_marquee/
  _move_cursor/_fill_cursor/_marquee_cursor/_ibeam_cursor/_denied_badge`
  (`POINTER.BM:830-1563`, minus the canvas-aware previews).
- Delete `POINTER_render_cursor_overlay` (`POINTER.BM:1627`) and
  `POINTER_composite_cursor_to_screen0` (`POINTER.BM:1819`) **if** no software fallback
  remains; otherwise keep them behind `$IF NOT HWCURSOR`.
- Retire `SCRN.CURSOR&` allocation and the cursor half of the dirty-rect logic
  (`POINTER_get_dirty_pad%` `POINTER.BM:1589`, `POINTER.PREV_DRAW_X/Y%`, restores at
  `SCREEN.BM:2799,3014`). **Keep** the scene-cache fast paths themselves — GUI/status
  refresh still needs them — they just no longer special-case the cursor.

### Phase 3 — remove the A/B toggle (only after cross-platform sign-off)
- Delete `CFG.HW_CURSOR_ENABLED%` (`CONFIG.BI:412`, `CONFIG.BM:141/1356/2227`), the
  Settings checkbox (`SETTINGS-TABS.BM:158-160`), and the apply hook
  (`SETTINGS.BM:315-328`).
- Fold `SYSTEM_CURSORS` down to an internal auto-fallback (used only when
  `_MOUSECURSOR` is unsupported), not a user toggle.
- Update `CHEATSHEET.md` / Settings docs.

---

## 5. Dead-code inventory (Phase 2/3 targets)

| Symbol | File:line | Notes |
|--------|-----------|-------|
| `POINTER_draw` (icon cases) | `POINTER.BM:1365` | keep preview/crosshair cases |
| `POINTER_draw_pan` … `_denied_badge` | `POINTER.BM:830-1563` | icon subs only |
| `POINTER_render_cursor_overlay` | `POINTER.BM:1627` | drop if no SW fallback |
| `POINTER_composite_cursor_to_screen0` | `POINTER.BM:1819` | drop if no SW fallback |
| `POINTER_get_dirty_pad%` | `POINTER.BM:1589` | cursor dirty-rect |
| `POINTER.PREV_DRAW_X/Y%` | `POINTER.BI:20-21` | prev cursor pos |
| `SCRN.CURSOR&` overlay | alloc `SCREEN.BM` (~755) | icon path only |
| `CFG.HW_CURSOR_ENABLED%` | `CONFIG.BI:412` + 3 sites | Phase 3 |
| Settings "Hardware Cursor" checkbox | `SETTINGS-TABS.BM:158-160` | Phase 3 |

---

## 6. Risks & watch-items

- **Cross-platform cursor size clamps.** Windows clamps custom cursors (typically
  32×32 / DPI-scaled); X11/Wayland allow larger ARGB. `CURSOR_ensure_hw%`
  (`CURSOR.BM:174`) pre-scales by `displayScale%` — verify the scaled bitmap doesn't
  exceed the OS max on Windows/HiDPI, or the OS silently downscales.
- **PR #701 is still open, with known Wayland gaps** (lock keys BUG 1, window class
  BUG 2 per `PLANS/GLFW-PR701-TEST-RESULTS.md`). `_MOUSECURSOR` itself passed, but keep
  a compile-time software fallback until the GLFW backend ships in a released compiler —
  don't delete Phase-2 code on a branch-only toolchain.
- **Default v450 compiler has no `_MOUSECURSOR`.** All of this is `$IF HWCURSOR` /
  `a740g`-only until PR #701 merges. The software path must stay compilable under v450.
- **Screenshot tooling can't see the OS cursor** (it's not in the GL grab) — QA visual
  asserts must not rely on capturing the pointer; test cursor behavior via `inputs.log`
  / state, not pixels.
- **`_MOUSESHOW`/`_MOUSEHIDE` dialog dance** (About, Settings, palette picker, etc. —
  ~15 sites) must still show a usable cursor in modal dialogs; confirm the OS cursor is
  restored correctly on dialog enter/leave (`POINTER_hide_for_dialog` `POINTER.BM:226`).

---

## 7. Verification gates (every phase)

1. `make a740g` compiles clean (regen compiler).
2. `./DRAW.run --bench-render 20` — HW path stays ~2.3× cheaper per canvas move.
3. `QA/draw-qa.sh` gate (calibration + smoke) green; full suite in small offscreen
   batches, HW-on vs HW-off diff = no regressions.
4. Phase-1 instrumentation: zero entries into icon draw subs with HW on.
5. Live human check: `HW_CURSOR_ZORDER_TEST` freeze test; DRAW cursor glides over
   canvas with the render loop at idle FPS.
