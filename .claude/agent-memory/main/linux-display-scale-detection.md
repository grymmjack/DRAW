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

**How to apply:** any DPI/scale work extends this ONE seam; never read raw `_DESKTOPWIDTH`
for sizing. See [[draw-display-scale-system]] and [[thinkpad-two-windows-profiles]] (why
SSH probes can't see the graphical scale context).
