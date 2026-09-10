---
name: save-as-draw-and-fd-abspath
description: Save As routes .draw through DRW_save; DRAW's custom file dialog mangles absolute paths typed in the FILENAME field (type basenames in QA)
metadata:
  type: project
---

Two linked facts from the "Save As → test.draw → Save Failed" bug (fixed 2026-09-08).

**1. `SAVE_as` is now format-aware for `.draw`.** File > Save As (action 204 → `SAVE_as`
in `TOOLS/SAVE.BM`) is the *image* path: it hands the typed name to `_SAVEIMAGE`, which
has no encoder for `.draw`, writes nothing, and trips the `SAVE_verify_written%` "Save
Failed" dialog. Fix: `SAVE_as` now detects a `.draw` name after the extension is
finalized and routes it through `DRW_save` (mirroring the opened-`.draw` state from
`TOOLS/LOAD.BM` — sets BOTH `CURRENT_FILENAME$` and `CURRENT_DRW_FILENAME$` so a later
Ctrl+S silent-saves as `.draw`). Note DRAW *has* a proper project-save
(`DRW_save_dialog`, "Save DRAW Project", filter `*.draw`) but **no File-menu item invokes
it** — it's only reached from the "save before opening/exiting?" prompts. `SAVE_quick` is
dead code (no callers) and carries the same latent `.draw`-into-`_SAVEIMAGE` sibling bug.

**2. The custom file dialog (`includes/QB64_GJ_LIB/FILE_DIALOG/`, the `FD_*` widget)
did NOT honor an absolute path typed in the FILENAME field — FIXED 2026-09-09.** The
save-accept in `FD-INPUT.BM` did `resultPath = FD_PLAT_path_join$(currentPath, fn)`
unconditionally, so typing `/tmp/x.draw` while browsing `/home/grymmjack` yielded
`/home/grymmjack//tmp/x.draw`. Fix: guard for an absolute `fn` (leading `/`/`\`, or `X:`
for Windows) and use it as-is. This is a **submodule** change (`QB64_GJ_LIB`) — needs a
submodule commit + pin bump in DRAW. **QA note:** either type a BASENAME (lands in the
dialog's start dir — `$HOME` when the harness rebuilds the cfg with empty `*_SAVE_DIR`), OR
now that abs paths work, type a full absolute path. Both are exercised in tests below.

**3. Added a File-menu "SAVE PROJECT AS..." item (action 203 -> `DRW_save_dialog`)** so the
native `.draw` project format is reachable from the menu (it previously was only reachable
from the "save before opening/exiting?" prompts). Registered in `GUI/MENUBAR.BM` (after
"SAVE AS..."), `CMD_register` + `CASE 203` in `GUI/COMMAND.BM`. The image "SAVE AS..."
(204 -> `SAVE_as`) still exists and now also routes `.draw` via fact #1.

**Bug 1 (grid on New canvas) was a separate, ALREADY-FIXED issue** — commit `3e9338ac`
(#110) added `GRID_reinit_preserve` so New / New-from-* recreate the grid image at the new
canvas size (previously they kept a stale grid image from a prior Crop). Its test is
`QA/tests/grid-reinit-on-new-source-guards.sh`. The residual "pixel grid doesn't show on a
new 16px canvas at 100%" is BY DESIGN: the pixel grid is gated at `SCRN.zoom! >= 4.0`
(`OUTPUT/SCREEN.BM:1690`) because per-pixel lines are sub-pixel below 400%. New canvases
open at `zoom=1.0` (`DRW.BM:2599/2792`); loaded small images auto-zoom-to-fit to ~32x, which
is why grids "only work after loading" for the reporter. Not a bug — zoom in.

Regression tests (all pass): `QA/tests/file-save-as-draw.sh` (Save As -> .draw routes to
DRW_save), `QA/tests/file-save-project-as.sh` (the new menu item, end-to-end via File menu),
`QA/tests/file-save-readonly.sh` (HARDENED: was a false pass — typed an abs path that
mangled to a non-existent dir; now has a WRITABLE control save that must land, proving the
read-only refusal is a real permission denial and regression-guarding fact #1's abs-path fix).
See [[every-fix-needs-a-qa-test]], [[driving-draw-gui-headless-xdotool]],
[[feedback-dry-reuse-libs]].
