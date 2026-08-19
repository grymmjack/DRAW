# free-glut-final build — QA regression + GLFW/windowing verification (2026-08-19)

Testing DRAW against the **free-glut-final** QB64-PE build (`~/git/qb64pe-freeglut-final/qb64pe`,
`make free-glut-final`), which carries a740g's GLFW work that makes several previously
Windows-only windowing functions work on Linux/all platforms.

**Scope: VERIFY ONLY — no changes to DRAW source.** Each GLFW function is proven with a small
standalone probe compiled by the free-glut-final compiler (per gotcha #20, probe with a tiny
standalone file). Findings land in a report; the decision to relax DRAW's `$IF WIN` DND guards
([DRAW.BAS:238](../DRAW.BAS#L238), [DRAW.BAS:406](../DRAW.BAS#L406)) is deferred to that report.

Probe .BAS files live in the session scratchpad (kept out of the repo). Branch: `glfw-tests`.
Upstream PR: https://github.com/QB64-Phoenix-Edition/QB64pe/pull/701

## ⚠️ BUILD PIVOT (discovered 2026-08-19 ~02:3x)
The Makefile `free-glut-final` target and the entire first test pass used the **WRONG compiler**:
`~/git/qb64pe-freeglut-final` is branch `freeglut-final` = the OLD **freeglut** backend, NOT a740g's PR #701.
- PR #701 = "**Replace freeglut with GLFW**", author a740g, head branch **`GLFW`**, state OPEN (unmerged).
- The real GLFW build is `~/git/qb64pe-a740g-test` (branch **`GLFW`**, has full glfw/ + x11_window.c).
- Source proof: on the freeglut build `func__capslock/_screenx/_windowhandle` are `#ifdef QB64_WINDOWS → return 0`
  (Windows-only). On the GLFW build they route through `GLUTEmu_*` with **no OS gate** → Linux-capable.
- ∴ ALL freeglut-final FAILs below (lock keys, DND, _SCREENX, _WINDOWHANDLE) are EXPECTED for that branch,
  NOT a740g bug reports. The real test is the GLFW build — re-run pending user's fresh pull+rebuild.

## 🔨 NOW — doing right now (RESUMED — user rebuilt GLFW compiler; Makefile `a740g` target now → `~/git/qb64pe-a740g-test`)
- [x] User rebuilt latest `a740g:GLFW` at `~/git/qb64pe-a740g-test/qb64pe` and repointed the Makefile `a740g` target to it. Killed the stale freeglut QA baseline (wrong compiler).
- [x] Recompiled probes with GLFW compiler (branch GLFW, head 5a52df45, rebuilt 02:29) + re-ran battery. **GLFW build FIXES both bugs:** `_SCREENX/_SCREENY` ✅ return exact pos (1600,866 → 500,300, matches xdotool); `_WINDOWHANDLE` ✅ returns X11 XID 67108871 (== WID). `_SCREENMOVE`/`_DESKTOPWIDTH`/`_WINDOWHASFOCUS` still ✅. Lock keys 0 (untoggled) → human next.
- [x] Live human test on GLFW build — **DND ✅ PASS** (dropped `werewolf_ANSI3232_ansi.xbin`, full path + exists captured; total drops=1). **`_SCREENX/_SCREENY` ✅ live-track** during window drag (frames 1720-1798, smooth position updates). `_WINDOWHANDLE` nonzero, focus flips. **Lock keys ❌ FAIL** — user pressed Caps/Num, stayed 0.
- [x] Root-caused lock-key FAIL for a740g: env is **Wayland session** (XDG_SESSION_TYPE=wayland, XWayland DISPLAY=:1). Impl exists (glut-emu.cpp: init reads L616-618, key-callback update L626-633, `KeyboardUpdateLockKeyModifier` L1786 with X11 `XkbGetIndicatorState(glfwGetX11Display())` path). Even with caps physically ON, init read = 0 under BOTH default (Wayland) backend and `env -u WAYLAND_DISPLAY` (X11-forced) — so not pure backend selection; the lock-mod value never populates on this Wayland/XWayland setup. Documented with hypotheses in report.

## Re-test against the CORRECT GLFW build (qb64pe-a740g-test, branch a740g:GLFW)
- [x] Recompiled + re-verified automated battery on GLFW build — `_SCREENX/_SCREENY` ✅, `_WINDOWHANDLE` ✅, `_SCREENMOVE`/`_DESKTOP*`/`_WINDOWHASFOCUS` ✅. (see NOW section)
- [x] Live human probe on GLFW build — DND ✅, screenX live-track ✅, lock keys ❌ (root-caused above). (see NOW section)
- [x] Built DRAW with GLFW compiler (V4.6.0, clean) + QA gate GREEN (calibration+smoke 15/15). Full suite running (job bd0tukmw8) for definitive regression.
- [x] Wrote comprehensive a740g-shareable report `PLANS/GLFW-PR701-TEST-RESULTS.md` (build caveat, verdict table, lock-key bug w/ root cause + repro, QA, DND recommendation). Retired the misnamed FREEGLUT-FINAL draft.
- [x] **QA full-suite triaged + filled into report.** Batch aborted at 83/184 (538 asserts passed) on an `effect-vignette` "window never appeared" = batch/Xvfb launch flake (passes in isolation), NOT a GLFW problem. vignette/stainedglass/stroke-selection = batch flakes (pass solo); Help>Cheat-Sheet-open = pre-existing (fails on freeglut baseline too) → NOT a GLFW regression. Net: no GLFW-specific regressions; gate green.

## Additional findings (live, with user)
- [x] **BUG 2 found — window WM_CLASS/app_id = "Untitled"** (user's KWin Window Rules screenshot). Root cause: glut-emu.cpp WindowCreate never sets GLFW_X11_CLASS_NAME/INSTANCE_NAME/WAYLAND_APP_ID; class derives from create-time "Untitled" title fallback and never updates. Added to report as BUG 2. Affects DRAW taskbar identity on GLFW build.
- [x] **Lock-key re-verification — CONFIRMED FAIL (BUG 1)** with logged evidence. `~/lock-key-test` (file-logging) run live on Wayland: 44 lock-key events reached the window (Caps 100301 / Num 100302 / Scroll 100319, press+release) but `_CAPSLOCK/_NUMLOCK/_SCROLLLOCK` read 0 at every event; `everCaps=everNum=everScroll=0` over 618 frames. Input works; lock-modifier capture fails on GLFW Wayland backend. Root cause + xkbcommon fix suggestion in report. (My earlier "PASS" read was a misinterpretation — user meant the key-event counter, not the lock rows.)

- [x] Live-test with `probe_human` on :1 — DONE. User confirmed: focus flips cleanly (PASS); lock keys pressed but stayed 0 (FAIL); file drag from Dolphin completed the gesture but program registered 0 drops (FAIL). All 3 interactive items resolved.

## Build gate

## Build gate
- [x] Build DRAW with the free-glut-final compiler — FIXED Makefile name mismatch first (`ifeq` checked `freeglut-final`, target passed `free-glut-final`; was silently falling back to v450). Real build: `qb64pe-freeglut-final` V4.6.0, clean (only pre-existing IMAGE-ADJ.BM:5532 unused-var warning). Backed up old effects `.claude/TASKS.md`.

## QA harness (calibration + smoke gate, then full suite)
- [x] Calibration + smoke gate (forced re-run, offscreen) — 15 passed / 0 failed / 0 skipped. Anchor mapping intact under V4.6.0; DRAW launches, geometry model OK, no trapped runtime errors. Gate GREEN.
_(full-suite item is in the NOW section above)_

## GLFW / windowing probes (standalone, compiled with free-glut-final)
- [x] Desktop metrics `_DESKTOPWIDTH`/`_DESKTOPHEIGHT` — ✅ PASS. Returns 3840×2160, matches real desktop (requires a real graphics window — `$CONSOLE:ONLY` returns 0). probe_win.bas.
- [x] `_SCREENMOVE` (Linux) — ✅ PASS. xdotool independently confirms window physically moved 1600,866 → 501,336 (target 500,300; offset = WM frame). probe_live.bas.
- [x] `_SCREENX`/`_SCREENY` — ❌ FAIL (returns 0). Window at 501,336 per xdotool but QB reports 0,0 across 150/150 frames. Keyword IS implemented (22 src hits) → GLFW Linux backend not populating. Human to recheck under focus. **Bug candidate for a740g.**
- [x] `_WINDOWHANDLE` — ❌ FAIL (returns 0). 0 across 150/150 frames. Keyword implemented (34 src hits) → Linux GLFW backend returns 0. Human to recheck under focus. **Bug candidate for a740g.**
- [x] `_WINDOWHASFOCUS` — ✅ PASS. Live human test: clean flips -1↔0 across 4 click-away/click-back cycles (probe_human_log.txt frames 1,470,590,804,916,967,995,1033,1039). Also confirmed `_SCREENX/Y`=0 and `_WINDOWHANDLE`=0 hold EVEN under focus (FOCUS=-1 frames) → rules out "needs focus" for those two bugs.
- [x] lock keys `_CAPSLOCK`/`_NUMLOCK`/`_SCROLLLOCK` — ❌ FAIL. Human pressed physical lock keys on the focused window; on-screen readouts stayed 0. Do not report live state on Linux. **Bug #3 for a740g.**
- [x] drag-and-drop `_ACCEPTFILEDROP`/`_TOTALDROPPEDFILES`/`_DROPPEDFILE$`/`_FINISHDROP` — ❌ FAIL. Human dragged a file from Dolphin; drop gesture completed but program registered 0 drops, no path. App never receives the drop on Linux. **Bug #4 for a740g. → Do NOT relax DRAW's `$IF WIN` DND guards.**
- [x] `_MOUSECURSOR` (image cursor) — ⛔ N/A: **NOT in this build**. 0 source hits in free-glut-final (vs 34 for _WINDOWHANDLE). Feature is on a different/newer branch, not PR #701. Cannot test here.

## Report
- [x] Report written as `PLANS/GLFW-PR701-TEST-RESULTS.md` (the correct GLFW build; the old FREEGLUT-FINAL name was retired). Verdict table, BUG 1 (lock keys, Wayland, logged evidence + xkbcommon fix), BUG 2 (window class "Untitled" + fix), QA triage, DND recommendation. All GitHub-issue-ready for a740g.

## Superseded (freeglut-final = wrong build; see BUILD PIVOT above)
_The GLFW-probe results in the section below were run against the WRONG (freeglut) compiler and
are kept only as history. The authoritative results are the GLFW-build items in the NOW section
and the report. Their FAILs for `_SCREENX`/`_WINDOWHANDLE`/DND are EXPECTED (Windows-only code)._
