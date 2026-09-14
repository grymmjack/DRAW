---
name: linux-display-scale-detection
description: DRAW's DPI/display-scale seam (SCREEN_DPI_DIVISOR) and the Linux/KDE fractional-scaling detection added for tester report #4 (opt-in, LINUX_HIDPI_SCALE)
metadata:
  type: project
---

**The DPI seam already existed but only fired on Windows.** `SCREEN_DPI_DIVISOR` (SCREEN.BI,
init 1.0) converts raw `_DESKTOPWIDTH/HEIGHT` → true logical pixels; `SCREEN_desktop_w&/h&`
divide by it, and ALL sizing/auto-scale reads those (never raw `_DESKTOPWIDTH`).

- **Windows**: `SetProcessDPIAware` + `GetDpiForSystem` (DECLARE LIBRARY user32, SCREEN.BI)
  → divisor = dpi/96, gated on `CFG.HIDPI_AWARE%` (default TRUE), set in SCREEN_init BEFORE
  the first desktop query. DRAW becomes DPI-aware via the RUNTIME call (no manifest — an
  exe-manifest check will say "not DPI-aware" and be MISLEADING).
- **macOS**: `_DESKTOPWIDTH` returns usable pixels (mode is in points); divisor stays 1.0; fine.
- **Linux (was the gap)**: X reports full PHYSICAL pixels even when the desktop is fractionally
  scaled (KDE "Global Scale", Kubuntu), so auto-scale came out wrong for a Kubuntu user.

**Added (branch `feature/linux-display-scale`, 2026-09-13):** `SCREEN_detect_linux_dpi_scale!`
(SCREEN.BM) reads, in order: env `QT_SCALE_FACTOR`, `GDK_DPI_SCALE`, `GDK_SCALE`,
`QT_SCREEN_SCALE_FACTORS` (first `=<factor>`), then `Xft.dpi` via a guarded `xrdb -query`
(96=100%, 144=150%). Folds into `SCREEN_DPI_DIVISOR`. New cfg **`LINUX_HIDPI_SCALE`,
DEFAULT OFF** (opt-in) — the env half is verified on Linux (1.5→1.5, 2→2, DP-1=1.25→1.25,
1.0→none), but the graphical/xrdb path is **UNVERIFIED on real KDE hardware** because SSH
sessions have no display-scale context. Compiles clean Linux+Windows.

**Why:** shipping an unverifiable change to the core sizing path ON by default is unsafe;
off-by-default = zero regression, always-logged, one flag to test. Flip the default only
after visual verification on a real fractional-scaled KDE session.

**[Linux] X11 vs Wayland is the crux (verified 2026-09-14).** The correction is X11-only by
nature: on **X11** the server hands the app the full PHYSICAL grid, so a 150% desktop must
divide down (`raw=3840x2160`→divisor 1.5). On **Wayland** (author's KDE 4K@150%) the
compositor PRE-SCALES and `_DESKTOPWIDTH` already returns the LOGICAL `2560x1440` (=3840/1.5),
so detection MUST return 1.0 — a divisor there would halve the UI (double-scale bug). Same
code, opposite-but-correct per session. Wayland's fractional scale is a compositor-internal
`wl_output` value a GLFW/QB64 app can't query, and it's NOT exported as QT_SCALE_FACTOR/Xft.dpi
— so on Wayland detection correctly finds nothing. The env-var paths are what KDE/Qt-on-X11
actually export; xrdb/Xft.dpi is the last-resort fallback.

**MERGED to main via PR #121 (2026-09-14)** with the `VAL("TRUE")=0` parse fix and QA guard.
Fullscreen branch `fix/fullscreen-and-toggle-all` merged main in cleanly (different SCREEN.BM
regions — the single seam pays off).

**Test technique (non-obvious, reusable):** `DRAW_HEADLESS=1` runs `SCREEN_init`'s HIDPI block
(SCREEN.BM ~653, logs `detected display-scale=X -> divisor=Y`) and THEN clean-exits (code 3) at
the no-display guard (~705) BEFORE opening a window — a perfect "init+log+exit" probe, no GUI,
no teardown. Inject scale via env (`QT_SCALE_FACTOR=1.5` etc.) + `--option LINUX_HIDPI_SCALE=TRUE`,
grep the log. QA test: `QA/tests/linux-display-scale.sh` (5 cases, passes offscreen). CAVEAT: a
bare Xvfb (no WM/session) can't STORE X resources — `xrdb`/`xprop` writes to `RESOURCE_MANAGER`
silently no-op — so the Xft.dpi fallback is NOT testable headless (headless skips it anyway);
verify that one branch only on a real X11 session.

**How to apply:** any DPI/scale work extends this ONE seam; never read raw `_DESKTOPWIDTH`
for sizing. See [[draw-display-scale-system]] and [[thinkpad-two-windows-profiles]] (why
SSH probes can't see the graphical scale context).
