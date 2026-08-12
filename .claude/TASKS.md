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
- [ ] ➡️ **CI output**: JUnit XML + non-zero exit on failure, so GitHub Actions (Linux, Xvfb) can run headless and surface results.

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
- [ ] CI output: JUnit XML + non-zero exit on failure, so GitHub Actions (Linux, Xvfb) can run headless and surface results.
- [ ] Consent/mode: `--mode ask|offscreen|onscreen`; default offscreen when Xvfb is available (also the CI path); print the takeover warning + ETA before using the real screen.
- [ ] CLI `--help` full coverage: single test, glob/tag subset, `--all`, `--eta`, `--mode`, `--status` (extend the header help added in Phase 2).

## Phase 4 — extract to a standalone tool (Linux driver first)
- [ ] Create the standalone harness repo skeleton: `core/` (bash runner + assert + mark + config-lock + consent + eta + status), `report/` (python + junit), `drivers/linux-x11/` (xdotool + spectacle/scrot + Xvfb), and an adapter-manifest format (launch/window/geometry/hooks/blessed-cfg/tests). Document the driver seam so win/mac plug in later.
- [ ] Port CORE out of `draw-qa.sh` into the toolkit; keep DRAW-specific bits in a draw adapter that consumes it.
- [ ] DRAW = adapter #1: `draw-qa` becomes thin (manifest + DRAW geometry/wake hooks + blessed cfg); re-run the DRAW suite through the toolkit and confirm parity with current results.

## Phase 5 — prove cross-project (2nd language, same driver)
- [ ] Minimal Rust GUI (X11) app + adapter #2: reuse the linux-x11 driver, window-relative coords (no viewport model), 2–3 sample tests + a green report — proves same driver / new app / new language. (May pause here for standalone-repo remote decisions.)
