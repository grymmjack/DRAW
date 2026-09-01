---
name: qa-offscreen-fragile-tests
description: The 10 fragile offscreen tests were re-pinned + merged (2026-09-01); the full offscreen suite always surfaces ~12 DIFFERENT tail/load flakes per run — verify by re-running failures in isolation
metadata:
  type: project
---

**RESOLVED 2026-09-01** — all 10 fragile test files re-pinned on `hotfix/qa-realign`,
merged to main (merge `9141a9b0`; commits `37491d4d`, `131ca9db`). Every fix was
test-hygiene, no product code touched. Final full offscreen suite: **1782 pass /
12 fail / 1 skip**, and **all 12 failures re-ran GREEN in isolation** (46/46).

**KEY INSIGHT — the full offscreen suite is never green in one run.** Each ~216-test
run surfaces a DIFFERENT set of ~12-13 failures: a tail-end Xvfb crash (`app process
has died` cascade — was tool-text in the v2.0.2 run, util-assistants in this one) plus
load-induced timing flakes. The FIRST run's 13 failures (10 files) and this run's 12
(4 files) barely overlap. **Verification method: re-run each failing file in isolation
(`draw-qa.sh --rerun-passed tests/X.sh`); if it passes alone, it's an environment/load
flake, not a bug.** Don't chase "green in one full run" — it's not achievable offscreen.

**Reusable QA-harness patterns learned (durable):**
- **Layer-panel eye icons**: `EYE_X = LP_X + 7 = 7` (viewport); **x=16 hits the LOCK
  icon, not the eye**. Row centres `ROW_N_Y = 26 + N*20` (row0=26, row1=46). New
  layers (Ctrl+Shift+N) go on TOP = row 0. From `tests/harness-calibration.sh`.
- **Menu bar HELP is RIGHT-ALIGNED** (`GUI/MENUBAR.BM:693`, `barX+barW-pw-PAD`) →
  viewport x~429 in the QA window, NOT the sequential left-to-right position.
- **Idle-fragile Ctrl keychords** (Ctrl+S=202, Ctrl+Shift+/=907): `_KEYHIT` is
  unreliable for Ctrl combos on Linux/SDL2 (gotcha #6). Ctrl+S needs `wake_draw`
  first; Ctrl+Shift+/ (keycode 63 `?`) won't dispatch offscreen AT ALL (every
  xdotool spelling dropped) → invoke the action via the command palette instead.
- **Paste onto a new layer**: Ctrl+V must land while the new layer is active —
  clicking the panel FIRST makes an in-place paste place nothing. Commit a paste
  float by switching tools (`key b` → apply-transform), not Enter (Enter re-centers).
- **When a canvas overlay isn't visibly rendered** (grid over transparent canvas at
  100%; select-all ants under a non-selection tool), verify via the STATUS BAR text
  region or a functional proof (draw+delete), not a canvas pixel-diff. Select-all
  ants DO render with the Marquee tool active.
- **Mid-drag key detection** (line caps `s`/`e`): hold the key while jiggling the
  mouse (forces active render frames that consume the key) + bounded retry.
- **Complex sample docs** (`DEV/_/DRAW Splash.draw`): 20 locked layers, non-320x200
  canvas, loads zoomed → brush edits at default CANVAS_CX/CY miss/don't commit. For
  a save/reload roundtrip use a coord-free edit (add-layer) + verify via the panel.

--- Original triage (2026-08-31), kept for the per-test fixes ---

Full offscreen suite after v2.0.2 (2026-08-31): **1781 pass / 13 fail / 1 skip**.
All 13 failures are **QA test-fragility, not product regressions** — features were
verified working by hand. Rick chose "ship v2.0.2 now, fix tests after," so this is
a pending follow-up hotfix (own branch).

**Why they fail (root causes, all confirmed):**
- **Stale hardcoded coords** — the menu bar's HELP root is *right-aligned*
  (`GUI/MENUBAR.BM:693`, `barX + barW - pw - PAD`), so `cheatsheet-menu-open`'s
  `click 387` now lands on EFFECTS. `input-seam-regressions` hardcodes the canvas
  corner (`CN_X=314;CN_Y=135`) instead of deriving `$CANVAS_OFFSET_X/Y` (canvas is
  centered, corner ≈ 320,157). Fix: derive from manifest geometry vars, never magic
  numbers. Same class as the Effects-menu offset 41→65 fixed during the field kit.
- **Marquee-visibility pixel diffs are fragile by design** — the select-all
  marching-ants outline does not snapshot reliably (visible with the *marquee* tool
  active, marginal with brush). `keyboard-chords` author already left a comment
  saying they deliberately DON'T assert the marquee renders. Select-all itself WORKS
  (proved: draw + Ctrl+A + Delete cleared 384k px). Rewrite these asserts to
  **functional proofs** (select→delete/fill), not marquee pixels: `input-seam`,
  `edit-stroke-selection`, `edit-copy-paste` (paste-in-place over identical content
  = 0 diff — offset the paste or clear the original first).
- **Threshold margin** — `brightness-contrast-preserve-blacks` /
  `color-balance-preserve-blacks` get `mean 16` vs a `≤8` gate: a size-7 brush
  stroke measured in a 16px band catches anti-aliased edge pixels. Preserve-Blacks
  works (dialog preview shows black preserved). Fix: measure a pure-interior sample
  or relax the gate.
- **Press-and-hold drag** — `tool-line-caps` mid-drag `s`/`e` cap keys: the harness
  hold-drag didn't register offscreen so `s` switched tools; needs a robust hold.
- `file-draw-roundtrip`, `layer-groups` — recheck under the same lens.

The 10 files (13 asserts): cheatsheet-menu-open, edit-copy-paste, edit-stroke-selection,
file-draw-roundtrip, input-seam-regressions, layer-groups, tool-line-caps,
util-grid-from-brush, brightness-contrast-preserve-blacks, color-balance-preserve-blacks.

Note: the full 216-test offscreen suite may not have been run in a while (the field
kit only re-ran the ~74 effect/image-adj tests), so some of this drift predates v2.0.2.
See [[qa-harness-toolkit]] and [[every-fix-needs-a-qa-test]].
