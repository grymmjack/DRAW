# QA harness → portable, collaborative, CI-ready

Branch `qa-harness`. Evolve `draw-qa.sh` into a **portable core** (bash runner +
Python reporter) with a thin **driver seam**, so the same harness tests DRAW,
Rust/X11 GUIs, and (later) web — and so writing tests *together* is easy, with
**region boxes** confirming Claude looks where the human thinks.

Decisions (locked): bash+Python core · standalone repo · Rust-GUI(X11) as adapter
#2 · **Linux is homebase** (X11 + Xvfb); Win/Mac are seam-only, nice-to-have ·
CI on GitHub Actions Linux (headless) is a real goal.

Ordered by dependency; the topmost unchecked box is next.

## 🔨 NOW — doing right now
- [ ] ➡️ **Named region registry** — a test declares regions once (`REGION name x y w h`); `snap`/`mark`/`assert` reference by name; persist the name→rect map per test/run so failures and calibration can name what they looked at.

## Phase 1 — analysis & seam map
- [x] Phase 1 audit — classified every `draw-qa.sh` symbol CORE/DRIVER/ADAPTER; wrote `docs/HARNESS-ARCHITECTURE.md` (seam map, driver-interface contract, logical-coordinate rule, offscreen/CI mode, extraction plan).

## Phase 2 — collaborative test authoring (human sees what Claude sees)
- [ ] Auto `-where` proof on FAIL: every failed region assertion writes the full frame with that region outlined + labeled, referenced from the log line (make the DUMP_SNAPS overlay automatic on failure, not opt-in).
- [ ] `--calibrate <test>`: walk each named region, render outlined+labeled frames to a review dir so the human confirms placement before trusting a run (generalize `harness-calibration.sh`).
- [ ] Coord-picker aid: against a running app, click a spot → print logical coords + a starter `REGION` line, so authoring a test's regions is copy-paste, not guesswork.

## Phase 3 — runner / report / ETA / CI (portable core)
- [ ] ETA: persist per-test durations; before a run print per-test ETA + session-total; add `--eta` (dry-run estimate); emit machine-readable progress lines for task-loop watchers.
- [ ] Reporter: de-DRAW `dump-qa-tests.py --html` into a project-agnostic report (header: date/time/project/what-ran; table: test/result/secs/notes); inputs = project name + run-log dir.
- [ ] CI output: JUnit XML + non-zero exit on failure, so GitHub Actions (Linux, Xvfb) can run headless and surface results.
- [ ] Consent/mode: `--mode ask|offscreen|onscreen`; default offscreen when Xvfb is available (also the CI path); print the takeover warning + ETA before using the real screen.
- [ ] CLI `--help`: single test, glob/tag subset, `--all`, `--list`, `--eta`, `--mode`, `--marks` — everything drivable from one run for skills/scripts.

## Phase 4 — extract to a standalone tool (Linux driver first)
- [ ] Create the standalone harness repo skeleton: `core/` (bash runner + assert + mark + config-lock + consent + eta), `report/` (python + junit), `drivers/linux-x11/` (xdotool + spectacle/scrot + Xvfb), and an adapter-manifest format (launch/window/geometry/hooks/blessed-cfg/tests). Document the driver seam so win/mac plug in later.
- [ ] Port CORE out of `draw-qa.sh` into the toolkit; keep DRAW-specific bits in a draw adapter that consumes it.
- [ ] DRAW = adapter #1: `draw-qa` becomes thin (manifest + DRAW geometry/wake hooks + blessed cfg); re-run the DRAW suite through the toolkit and confirm parity with current results.

## Phase 5 — prove cross-project (2nd language, same driver)
- [ ] Minimal Rust GUI (X11) app + adapter #2: reuse the linux-x11 driver, window-relative coords (no viewport model), 2–3 sample tests + a green report — proves same driver / new app / new language. (May pause here for standalone-repo remote decisions.)
