# QA harness → portable, collaborative, CI-ready

Branch `qa-harness`. Evolve `draw-qa.sh` into a **portable core** (bash runner +
Python reporter) with a thin **driver seam**, so the same harness tests DRAW,
Rust/X11 GUIs, and (later) web — and so writing tests *together* is easy, with
**region boxes** confirming Claude looks where the human thinks.

Decisions (locked): bash+Python core · standalone repo · Rust-GUI(X11) as adapter
#2 · **Linux is homebase** (X11 + Xvfb); Win/Mac are seam-only, nice-to-have ·
CI on GitHub Actions Linux (headless) is a real goal. Note: QB64-PE apps don't
expose a window id yet — match by title/pid/geometry, never a WID.

Ordered by dependency; the topmost unchecked box is next.

## 🔨 NOW — doing right now
- ✅ **All tasks complete.** The QA harness is built out (Phases 1–3), extracted into the standalone `~/git/qa-harness` toolkit (Phase 4), and proven against a second language via a Rust demo (Phase 5). Both adapters run green through `bin/qa`.

## Phase 1 — analysis & seam map
- [x] Phase 1 audit — classified every `draw-qa.sh` symbol CORE/DRIVER/ADAPTER; wrote `docs/HARNESS-ARCHITECTURE.md` (seam map, driver contract, logical-coord rule, offscreen/CI mode, no-window-id + capture-backend rules).

## Phase 2 — collaborative test authoring (human sees what Claude sees) ✅
- [x] Named region registry — `region name x y w h [desc]` + `snap name [label]`; snap_region records each snap's rect + region name.
- [x] Auto `-where` proof on FAIL — failed asserts re-capture + outline the region in red and log its name/desc. **Fixed a real regression:** offscreen capture used spectacle (grabbed the real desktop via the portal); now `WAYLAND_DISPLAY unset → scrot`.
- [x] `--calibrate <test>` — renders each declared region outlined (green) + labeled to `QA/calibrate/` so the human confirms placement before trusting a run.
- [x] Coord-picker — `--pick` (alias of `--probe`): hover+hold to MARK a point; two marks print a copy-paste `region x y w h` line. `--help` lists all modes.

## Phase 3 — runner / report / ETA / live-status / CI (portable core)
- [x] **ETA** — `run_test_file` records each test's duration to `results/durations.tsv`; `_eta_for` takes the median of the last 10 runs (robust to one-off hangs); before every run the entrypoint prints `ETA — N test(s), est. total m:ss, done ~HH:MM:SS` (clock time via `date -d`), cached-passed tests shown as skip (0s); `--eta` is a dry run (estimate + per-test breakdown, no launch). Verified: smoke 0:19 / palette 0:25 / total 0:44.
- [x] **Live status/progress** — `results/status.json` + `status.txt`, rewritten atomically (tmp+mv) before each test and at start/done: phase, current i/N + name, passed/failed/skipped, elapsed, remaining (suffix-sum of per-test ETAs), and **eta clock time**. `--status` / `--status --json` query it; every write also emits a machine-readable `PROGRESS i/N test=… elapsed=…s remaining=…s eta=HH:MM:SS phase=…` line to the stream. Verified live (offscreen smoke: starting→running→done).
- [x] **Reporter** — harness now emits a structured per-run TSV (`results/run-*.tsv`: `name⇥result⇥secs⇥notes`, one row per test, first failure reason captured as the note) so the reporter reads data not colored logs. New project-agnostic `QA/qa-report.py` (`--project NAME --run TSV|--results DIR --out FILE`, pure stdlib, theme-aware) renders header (project · run date/time · N tests, pass/fail/skip, total time) + table (test/result/secs/notes, failures first). Auto-generated to `results/report.html` at end of every run; `--report` also opens it (`xdg-open`). Project name via `QA_PROJECT` env (default DRAW). Verified end-to-end (3-test offscreen run) + mixed pass/fail/skip demo.
- [x] **CI output** — `qa-report.py --junit FILE` writes JUnit/surefire XML from the same per-run TSV (one `<testcase>` each; `fail`→`<failure message=…>`, `skip`/`cached`→`<skipped>`; attrs+body XML-escaped, validated with `xmllint`). Every run emits `results/junit.xml` beside `report.html`; the runner's final `[[ $FAIL -eq 0 ]]` gives the non-zero exit CI needs. Documented the headless invocation + a ready-to-drop GitHub Actions workflow (Xvfb, artifact upload, junit-report action) in `docs/HARNESS-ARCHITECTURE.md`.
- [x] **Consent/mode** — `--mode ask|offscreen|onscreen` (+ `--offscreen`/`--onscreen`). Default is offscreen when Xvfb is present (shared-machine-friendly + the CI path). Offscreen **self-wraps**: the script re-execs under `xvfb-run` (`WAYLAND_DISPLAY` unset, `QA_IN_XVFB=1` anti-recursion guard, screen = current display geometry or `QA_XVFB_RES`); `--eta` skips the launch. Onscreen prints a takeover warning **with the ETA** and confirms on a TTY unless `--onscreen` was explicit; `ask` prompts per run. Mode shown in the banner. Verified: `./draw-qa.sh --rerun-passed tests/smoke.sh` self-wrapped into Xvfb (3840×2160) and passed invisibly.
- [x] **CLI `--help` full coverage** — header usage block regrouped (Selecting tests incl. shell-glob subsets · Estimate & report `--eta`/`--report`/`--status` · Run mode `--mode`/`--offscreen`/`--onscreen` · Authoring aids · Debugging · Maintenance) + an Env line (`QA_XVFB_RES`/`QA_PROJECT`/`QA_CAPTURE`). `--help`/`-h` now prints line 2 → a `--- end usage ---` sentinel (robust to length) with the `# ` stripped. Verified.

## Phase 4 — extract to a standalone tool (Linux driver first)
- [x] **Standalone harness skeleton** — new local repo `~/git/qa-harness` (remote deferred = your call): `core/` (runner + region-diff asserts), `drivers/linux-x11/` (xdotool + spectacle/scrot + Xvfb), `report/qa-report.py` (moved in verbatim — already project-agnostic), `adapters/` (tiny per-app manifest; `adapters/draw` reference), `bin/qa` loader. Defines the full seam: driver interface, adapter-manifest contract, logical-coord rule, no-window-id degrade, capture-backend rule. `ARCHITECTURE.md` carries the per-symbol port checklist. Wiring verified (`bin/qa --adapter … ` sources driver→adapter→core). Committed (40270b6).
- [x] **Port CORE out of `draw-qa.sh`** — faithful extraction into `qa-harness/core/` (`runner.sh` + `assert.sh` + `input.sh`), the linux-x11 driver bodies, and the DRAW adapter (`adapters/draw/manifest.sh`), per the ARCHITECTURE.md checklist. All 30 test-facing names preserved (DRAW's ~97 tests need zero edits). Two bugs found + fixed while verifying: driver `wid` unbound under `set -u` when called without a pid; WM-less-Xvfb input-focus (added `adapter_focus`). Committed (673821f).
- [x] **DRAW = adapter #1 (parity)** — DRAW's suite runs through `bin/qa --adapter adapters/draw`; verified subset (smoke + brush-size + ui-palette-menu-chips) = **20 passed / 0 failed, exit 0**, byte-for-byte the same assertions/pixel-diffs as `draw-qa.sh`. `draw-qa.sh` stays in the DRAW repo as the reference; the toolkit consumes DRAW's `tests/` unchanged.

## Phase 5 — prove cross-project (2nd language, same driver)
- [x] **Minimal Rust GUI (X11) app + adapter #2** — a tiny NEW demo app proves the seam holds for a second language/coordinate-model. `examples/rust-demo` (minifb/X11, 480×320, 3 buttons + canvas, click/R/G/B/C, title `qa-demo`); `adapters/rust-demo/manifest.sh` (window-relative 1:1, no viewport — the deliberate contrast with DRAW) + `tests/buttons.sh` + `tests/keys.sh`. Runs through the SAME linux-x11 driver + core as DRAW: **8 passed / 0 failed, exit 0**, region diffs catch every click/key change (4371–7258 px), green report generated. Committed (673821f).
