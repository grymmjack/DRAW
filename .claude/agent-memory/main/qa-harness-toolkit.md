---
name: qa-harness-toolkit
description: DRAW's QA harness was extracted into a standalone cross-app toolkit at ~/git/qa-harness (core/driver/adapter seam); draw-qa.sh stays as the reference.
metadata:
  type: project
---

DRAW's `QA/draw-qa.sh` was abstracted into a **standalone, app-agnostic GUI test
toolkit** at `~/git/qa-harness` (separate local git repo, **no remote yet** — that
decision is deferred to Rick). Built 2026-08-12.

**Architecture** = core + driver + adapter (see `qa-harness/ARCHITECTURE.md`):
- `core/` (portable bash): `runner.sh` (logging/tally, ETA, live status, per-run
  results+report, run modes/consent, CLI, `qa_main`), `assert.sh` (named region
  registry + region-diff visual assertions + AE calibration + where-on-fail),
  `input.sh` (test-facing input aliases).
- `drivers/linux-x11/driver.sh`: the ONLY OS-specific layer — xdotool input
  (SDL2-safe key chords), spectacle/scrot capture (WAYLAND_DISPLAY-conditional),
  xwininfo client-area bounds, Xvfb offscreen.
- `adapters/<app>/manifest.sh`: ~30-line per-app contract — launch/quit, window
  match (title/pid, **no window id needed**), `adapter_to_screen` (logical→screen),
  blessed cfg, hooks (`adapter_focus`/`adapter_pre_input`/`adapter_is_alive`/
  `adapter_crashlog_dir`). `adapters/draw` (viewport×DISPLAY_SCALE) + `adapters/
  rust-demo` (window-relative 1:1) are the two proofs.
- `bin/qa --adapter <dir> [--offscreen] [tests…]` loads driver→adapter→core.
- `report/qa-report.py`: project-agnostic HTML + JUnit from a run TSV.

**Proven**: DRAW's suite runs green through `bin/qa` (parity with `draw-qa.sh`),
and a tiny Rust/minifb demo (`examples/rust-demo`) runs green through the SAME
driver+core — two languages, two coordinate models.

**DRAW side**: `DRAW/QA/draw-qa.sh` is unchanged as the working reference (and got
all the Phase 1–3 upgrades: ETA, live `--status`, `qa-report.py`, JUnit/CI,
`--mode` offscreen self-wrap, full `--help`). DRAW's `QA/tests/*.sh` run unmodified
under both. Two bugs fixed during the port: driver `wid` unbound under `set -u`
without a pid; WM-less-Xvfb needs `windowfocus --sync` (SDL2 apps self-focus; plain
X11/minifb windows don't). See [[draw-command-palette-registration]] for a related
QA-testability gotcha.
