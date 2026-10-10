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

**DRAW side**: `DRAW/QA/draw-qa.sh` is now a **thin wrapper** (since 2026-08-12) that
`exec`s `$QA_HARNESS/bin/qa --adapter adapters/draw "$@"` (sets `DRAW_ROOT` to the
checkout; `QA_HARNESS` defaults to `~/git/qa-harness`). Same CLI, DRAW's
`QA/tests/*.sh` run verbatim, default offscreen. The pre-extraction single-file
harness (with all the Phase 1–3 upgrades — ETA, live `--status`, `qa-report.py`,
JUnit/CI, `--mode` self-wrap, full `--help`) is in git history before that date and
was the port source. First real dogfood: `./draw-qa.sh tests/smoke.sh` → 5/0 green. Two bugs fixed during the port: driver `wid` unbound under `set -u`
without a pid; WM-less-Xvfb needs `windowfocus --sync` (SDL2 apps self-focus; plain
X11/minifb windows don't). See [[draw-command-palette-registration]] for a related
QA-testability gotcha.

**[Linux] Never edit a test file or the harness while a suite is running** (2026-10-09). The runner
sources `adapters/draw/manifest.sh` ONCE at start and runs under `set -u`, and bash reads a test
script as it executes it. A test edited mid-run to use a variable added to the manifest after the
runner started (`MENU_DX`) died with "unbound variable" and **killed the whole runner** at test
163/309 - no Results line, just stops. Batch test/harness fixes until the run ends, or run the
suite from a separate worktree. DRAW tests should use harness variables that already exist
(`LP_W`, `VIEWPORT_W`, ...) rather than ones only in an unpushed harness commit.

**Menu-bar coordinates move with the layer panel** (QA layout: layers docked LEFT, full height -
the menu bar starts where they end). The harness pin `LAYER_PANEL_WIDTH` is 120 since 2026-10-09
(was 100; DRAW's minimum became 108). Fixed menu clicks are written as `$(( x + LP_W - 100 ))`
(the x they were measured at with 100); `open_effect` uses `MENU_DX` in the manifest. Better
still, read `MROOT` / `MENU` lines from `DOCK_DUMP` (see `cheatsheet-menu-open.sh`).

**Per-test watchdog (qa-harness a4eb1b3, 2026-10-09, [Linux] verified):** tests run in a subshell; past
`# QA-TIMEOUT: <s>` (header) or `QA_TEST_TIMEOUT` (default 600s) the test's process tree is killed and it
FAILs "TIMED OUT after Ns", the run continues. Before this a hung test (one run sat 30 min in `formats2`)
left the whole run in limbo. State a test may change comes back via a state file: core counters +
the adapter's `ADAPTER_STATE_VARS` (DRAW: `DRAW_PID DRAW_WID`). A test that legitimately runs > 10 min
must declare `# QA-TIMEOUT:`. `./DEV/qa-dash.sh` shows the current test's own timer vs its usual time
and flags STALLED? past ~3x.

**Cross-platform drivers (2026-10-09; harness 4c59d19..51e8aa7, DRAW branch `qa-cross-platform`).** `bin/qa` picks
`drivers/{linux-x11,macos,windows}` by uname; tests never call OS tools (guard test `qa-no-os-tools-in-tests`).
Both mac and Windows use a compiled `qa-io` helper (a Python call per input was ~0.3s). README "Platforms" has setup.
- [macOS] Jobs run inside `~/Applications/QA Runner.app` via `drivers/macos/qa-run [--wait] CMD` (TCC grants live on the app;
  rebuilding it invalidates them). A child of QA Runner shows in `lsappinfo` AS "QA Runner" - that is the app itself, not a bug.
  Two input faults, found by logging raw QB64 mouse events (a tiny `.bas` writing each `_MOUSEINPUT` to a file is the decisive probe):
  (1) a GLFW app launched by another process gets NO mouseMoved until switched away and back -> `driver_window_ready` does Cmd+Tab x2;
  (2) a drag whose down / moves / up come from separate processes is dropped and input stops -> one `qa-io serve` per launch posts all input.
  Held buttons/modifiers persist in `~/.qa-runner/io-state`.
- [Windows] `drivers/windows/qa-run` runs the job via a Scheduled Task (`/IT` as desktop user `grymm`) from `C:\qa-runner`
  (bin, portable ImageMagick 7, harness copy, DRAW clone) - the desktop user can't read the SSH user's profile. Over SSH the shell is
  cmd: run scripts with `ssh thinkpad '"C:\Program Files\Git\bin\bash.exe" -s' <<EOF`. Portable IM7 rejects `magick convert` - shim
  is `exec magick "$@"`. QA config: DISPLAY_SCALE = 2 x content scale, HIDPI_AWARE=0, SCREEN_HEIGHT=516 (see [[qb64pe-glfw-windows-window-shrink]]).
  DRAW runs `*_COMMAND` options through cmd.exe: the adapter swaps `fixture.sh` for its `.cmd` twin, backslashed.
- Farm: `DEV/farm-check.sh qa [mac|thinkpad|titan] [REF] [REGEX]`; `DEV/qa-dash.sh` probes every host (Git Bash for thinkpad).

**Dashboard lives in the harness (2026-10-10, harness 2e3c3bf):** `bin/qa-dash` (any adapter; DRAW's `DEV/qa-dash.sh`
is a wrapper passing title / tests / known failures / target). It reads only results dirs: the runner writes
`status.json` with app, app_root, tests_dir, known_failures, target_file, pid, host + `run-plan.txt`, and records
the dir in `~/.cache/qa-harness/results-dirs`. Adapter vars `ADAPTER_APP_ROOT`, `ADAPTER_KNOWN_FAILURES`,
`ADAPTER_TARGET_FILE`. Farm panels read `~/.cache/qa-dash/farm/<host>.json` incl. `os` + `known_failures`.
