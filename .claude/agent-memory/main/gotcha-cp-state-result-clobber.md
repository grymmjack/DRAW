---
name: gotcha-cp-state-result-clobber
description: Never read CP_STATE.result after DRAW_pick_color& returns — it's clobbered when the color mixer is open
metadata:
  type: project
---

[Linux, cross-platform] **After `DRAW_pick_color&` returns, `CP_STATE.result` is unreliable — do NOT read it to detect cancel.**

`CP_STATE` is a singleton shared by the modal color picker and the floating Color Mixer. When the mixer is open, `DRAW_pick_color&` (GUI/GJ-DIALOG-SCALE.BM) re-inits it on close via `COLORMIXER_ensure_initialized` → `CP_init`, and `CP_init` sets `CP_STATE.result = CP_RESULT_NONE` (CP-API.BM:259). So by the time the caller inspects `CP_STATE.result`, it reads `NONE` even though the user clicked OK.

**Contract:** `DRAW_pick_color&` returns the chosen color on OK and the *initial* color on cancel. Detect cancel by comparing the returned color to the initial — the pattern every correct caller uses (e.g. `ORGANIZER_activate_widget`: `IF cmrChosen~& <> PAINT_BG_COLOR~& THEN`). Never `IF CP_STATE.result <> CP_RESULT_OK`.

**Regression history:** `PALETTE_OPS_change_color` (double-click a swatch in Palette Ops mode) read `CP_STATE.result` and silently no-op'd whenever the mixer was open — the edit did nothing to palette or canvas. Fixed 2026-08-13 by dropping the guard and relying on `newColor~& = oldColor~&`. Guarded by QA test `QA/tests/palette-ops-color-edit.sh` (opens the mixer first, then activates Palette Ops, then double-clicks a chip and drives the picker by keyboard — Tab, clear hex, type, Enter, Enter). The test FAILS with the bug present only because the mixer is open, so the setup order matters.

Related: [[reference_input_system]]
