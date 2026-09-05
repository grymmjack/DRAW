---
name: browser-geometry-native-vs-viewport
description: Floating-panel (Browser) geometry save/restore must respect native-vs-viewport pixel units and clamp AFTER layout — scale-dependent bugs are invisible at 1x
metadata:
  type: project
---

The floating image Browser keeps geometry in TWO pixel units and mixing them silently corrupts save/restore at display scale > 1 (invisible at 1x, since native == viewport there). Bit us for real (Sept 2026): browser restored centered + shrunk on a 4x HiDPI display; four separate scale-dependent bugs.

**The unit split:** `BROWSER.dispX/dispY/dispW/dispH` are VIEWPORT pixels; `FD_STATE.dialogW/dialogH` are FD NATIVE pixels. `renderScale = USCALE.browser / SCRN.displayScale` relates them (`disp = dialog * renderScale`, `sync_fd_from_display` does the inverse). `MAIN_shutdown` saves `CFG.BROWSER_POS_X/Y = dispX/Y` (viewport) but `CFG.BROWSER_WIDTH/HEIGHT = FD_STATE.dialogW/H` (native) — by design; `BROWSER_init` reads them back into the matching field. All consistent ONLY if every consumer honors the unit.

**The four fixes (all in GUI/BROWSER.BM + DRAW.BAS MAIN_shutdown):**
1. `MAIN_shutdown` overwrote geometry unconditionally → clobbered fixed Width/Height/Left/Top set in Settings. Gate the geometry save on `CFG.BROWSER_AUTOSAVE_GEOMETRY%` (ON = remember live; OFF = leave CFG alone so Settings' fixed values stick).
2. `BROWSER_ensure_initialized`: `BROWSER_compute_display_size` recomputes dispX/Y from `FD_STATE.dialogX/Y`, which `FD_init` just CENTERED — discarding the restored position. Save dispX/Y before and restore after that call (only SIZE is derived there).
3. `BROWSER_init`: called `BROWSER_clamp_size` while dispW/H still held NATIVE px, but clamp_size compares against VIEWPORT dims → shrank wide/tall panels at scale>1. Removed; ensure_initialized clamps the SIZE later in viewport units.
4. `BROWSER_init`: called `BROWSER_clamp_to_work_area` on the restored POSITION with native dispW/H before layout was ready → `maxY = workBottom - nativeH` over-clamped Y (X often slipped under its wrong limit, so "X ok but Y not"). Removed; the first-render `needReClamp` block clamps position in viewport units once dispW/H are the viewport footprint. **Rule: position/clamp the browser LAST — at first render, never at init.**

**Testing note:** ALWAYS verify browser geometry at display scale > 1. Headless: a big Xvfb (e.g. 2560x1440 → DRAW auto-picks 3x) triggers renderScale != 1; 1x (1400x900 → 958x514 window) will pass even when broken. Reproducing the RESTORE needs no graceful exit — set CFG.BROWSER_POS_*/WIDTH/HEIGHT, launch, screenshot; the bug is in BROWSER_init + ensure_initialized, not the save. See [[driving-draw-gui-headless-xdotool]].
