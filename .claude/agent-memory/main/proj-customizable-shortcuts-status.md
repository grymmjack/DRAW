---
name: proj-customizable-shortcuts-status
description: Status of the customizable-shortcuts branch (rebind system). Phases 0-4 done & Rick-verified; Phase 4 polish + more Phase 2A migrations (music, F12) + DRY infra done 2026-09-04. Remaining = 2B.2 mouse (Rick-gated), Phase 5 preset letter-keys (Rick), Settings Ctrl+, (Windows).
metadata:
  type: project
---

Feature branch **`customizable-shortcuts`** (off v2.0.3 main). Plan:
`PLANS/CUSTOMIZABLE-SHORTCUTS.md`. Loop record: `.claude/TASKS.md` +
`.claude/TASKS-phase4plus.md`. Builds fully green (zero warnings/infos). Registry-driven
rebinding on the central `INPUT/INPUT.BM` dispatch table + `CFG/BINDINGS.BM` override engine.

**DONE + Rick-verified (2026-09-04, earlier):** Phases 0-3 + 4.1/4.2 UI
(`GUI/CONTROLS.BI/BM`, Edit > Customize Controls / palette, action 2360). Rebind capture
modal, FIND box = reused TI widget, warn+steal conflict, RESET ALL live. See git history.

**This session (2026-09-04, Phase 4+ loop — all committed on branch):**
- **Phase 4 polish:** scrollbar DRAG (`CTRL_scrollbar_metrics` shared draw+input geometry +
  `CONTROLS_handle_scrollbar` thumb-grab/track-paging) + overridden-row "modified" marker
  (left stripe + highlighted key on `INPUT_BINDS().userOverridden` rows + button-bar legend).
- **Phase 2A migrations (more keyboard subsystems → central dispatch):**
  - **Music transport** `{`(123)→428, `}`(125)→427, `*`(42)→433; CASE 433 guarded on
    MUSIC_ENABLED. **GOTCHA caught by the FIRE test:** `{`/`}`/`*` are SHIFTED chars so Shift
    is held — `forbidMods` must NOT include MOD_SHIFT (I'd copied `allMods%` from the
    unshifted opacity keys → the bindings matched nothing). Fixed to forbid Ctrl/Alt only.
  - **F12 export** — keycode landmine RESOLVED by empirical probe: **F12 = 34304** under GLFW
    (= F11 34048 + 256; the registry's old 28416 and the char-insert 134144 NEVER fire).
    Two context-disjoint bindings: F12+CTX_CUSTOM_BRUSH_ACTIVE → 1110 (dialog export, the
    menu accelerator), F12 no-brush → 9999 (dev-dump). Legacy `_KEYDOWN(34304)` handler
    removed; `SHORTCUTS-DUMP` keyname fixed 28416→34304.
- **DRY infra (Rick asked mid-run; he picked #2/#3/#4, deferred #1 to 2B.2):**
  - #2 `QA/tests/lib/source-guard.sh` — shared pass/fail/assert_grep/assert_absent/guard_footer
    (5 guard tests now source it).
  - #3 `DIALOG_point_in%()` — non-consuming hover sibling of `DIALOG_hit%`; replaced 6 inline
    box-tests in CONTROLS.BM.
  - #4 `QA/tests/lib/fire-log.sh` — `assert_action_fires <id>` reads the `--developer` FIRE log
    (`inputs.log`) so key→action dispatch is CI-testable. **Reuse the harness's XTEST keys**
    (`xdotool key --window`/XSendEvent does NOT reach SDL2/_KEYDOWN — that's why ad-hoc driver
    scripts never fire; the harness runs openbox for focus + XTEST). Run behavioural dispatch
    tests with `DRAW_EXTRA_ARGS=--developer ./draw-qa.sh tests/fire-*.sh`.
- **Phase 5 presets:** `PLANS/PRESETS-KEYMAP-DECISIONS.md` (analysis; a preset row REMAPS an
  action's key, it does NOT alias). One provably-safe remap shipped: photoshop Copy-to-New-Layer
  → Ctrl+J (`321 106 1 0`; keycode 106 unused ⇒ conflict-free). DRAW already matches these apps
  on B/E/M/W/V/T/I/Z/L; the real letter-key diffs all collide with DRAW draw-tools/chords → need
  Rick's tradeoff calls.

**2B.2 mouse rebinding — LARGELY DONE this session (2026-09-04, loop `.claude/TASKS-2b2.md`).**
The design's pessimism was overblown — the FG/BG choice turned out to be ONE central site
(`MOUSE_update_draw_color`), not dozens, because stroke-start gates fire on either button.
- **A1 (commit e595fe5f)** — extra buttons sampled 1..N via `_MOUSEBUTTON`, bounded by
  `_LASTBUTTON(<[MOUSE] device>)` (⚠ `_MOUSEBUTTON(n)` past the device count raises ERR 5, NOT 0;
  bare `_LASTBUTTON` also ERR 5 — needs the device number). Dispatcher button loop widened to
  `MOUSE_MAX_BTN`. Defaults: back(4)→Undo, fwd(5)→Redo. **Rick-verified on real hardware.**
  Extra buttons are NOT offscreen-testable (synthetic X11 button events don't map to GLFW
  physical `_MOUSEBUTTON` indices) → source-guarded + real-HW.
- **A2 (commit db4c787e)** — Customize Controls surfaces mouse rows + mouse-capture rebind;
  overrides are device-discriminated (`device`+`button` in `BINDING_OVERRIDE`; `set_mouse_override`
  / apply / save+parse 6-field back-compat / `defButton` reset). Screenshot-verified.
- **B (commit 40c8700a)** — Paint FG/BG rebindable: `MB_PAINT_FG/BG` behavior binds
  (dispatched=FALSE, QUERIED not dispatched) + `MOUSE_intent_button%`/`MOUSE_button_down%`;
  `CTRL_bind_rebindable%` enables SET… for non-dispatched behaviors (else fake rows).
- **B2 pan (commit 1b44e796)** — `MB_PAN` (default 3); one wire at `allowB3Pan%` covers the whole
  pan lifecycle.
- **Docs** — SHORTCUTS.md MOUSE rebind table; the CONTROLS export already walks mouse binds
  (fixed `SHORTCUTS_mousetrigger$` to name buttons 4/5+).
- **C2 wheel-tilt — DONE (2026-09-04, plain-trigger per Rick).** Horizontal tilt sampled via
  `_WHEEL(MOUSE_TILT_WHEEL)` (index 4 on Rick's mouse, Rick-confirmed working) pumped through
  `_DEVICEINPUT(MOUSE_DEV)` once/frame in `MOUSE_update_state` — a SEPARATE queue from
  `_MOUSEINPUT`, so absolute x/y + legacy vertical `_MOUSEWHEEL` are undisturbed (verified:
  effect-dropdown-wheel still scrolls). Tilt → `EVT_MOUSE_WHEEL` event, wheelDir encoded **±2**
  (`WHEEL_TILT_RIGHT/LEFT` in INPUT.BI) so one INTEGER carries vertical (±1) AND tilt (±2), zero
  schema change to the matcher. Greenfield (no legacy tilt handler) ⇒ two default binds
  **dispatched=TRUE**: tilt-right→brush+ (602), tilt-left→brush- (601), over canvas. `SGN` =
  plain trigger, not magnitude. Index validated vs `_LASTWHEEL` (disables if absent, avoids the
  `_WHEEL`-past-count ERR 5 = same trap as `_MOUSEBUTTON`). Config key **`MOUSE_TILT_WHEEL`**
  (default 4, 0=disable) for other mice — full 6-site wiring incl. `--options-list`. **Rebindable
  + persisted** in Customize Controls: rows visible under MOUSE ("Wheel Tilt Right/Left", SET…
  enabled), the rebind modal CAPTURES a tilt gesture (samples `_WHEEL` directly — its own loop,
  so main-loop `MOUSE_TILT` is stale), persisted via new `BINDINGS_set_wheel_override` +
  `wheelDir`/`eventType` on `BINDING_OVERRIDE` (an action can hold an independent button AND wheel
  override) + 8-field save/parse (back-compat 4/6/8). Verified offscreen: controls-tilt-row.sh +
  mouse-wheel-tilt-source-guards.sh (24/24). **⚑ Rick real-HW test pending:** tilt actually
  resizes brush + the SET…→tilt capture round-trip (synthetic wheel can't reach GLFW under Xvfb).
  **CORRECT FIX (2026-09-04, Rick found the right API):** horizontal tilt = **`_MOUSEWHEEL(1)`** —
  `_MOUSEWHEEL` gained an optional `axis&` param (0=vertical, 1=horizontal; a newer QB64PE feature,
  not in the stable wiki yet, alongside the DOUBLE-precision change). Read it INSIDE DRAW's existing
  `_MOUSEINPUT` drain in `MOUSE_drain_update_state`, right beside the vertical `_MOUSEWHEEL`. The
  entire `_DEVICEINPUT`/`_WHEEL(n)` device-controller path I first used was the WRONG tool: it
  processes ONE queued event per call, so mouse-movement events (`_WHEEL(1)/(2)` = relative X/Y)
  buried the tilt and `_WHEEL(4)` read 0. `_MOUSEWHEEL(axis)` needs no device number, no
  `_LASTWHEEL` bound, no separate pump, no queue-sharing hazard. Config is now **`MOUSE_TILT_AXIS`**
  (default 1). Verified: `_MOUSEWHEEL(axis)` compiles (`DEV/mwaxis.run`), vertical wheel unbroken,
  guard 22/22. **✅ Rick-CONFIRMED working on real HW (2026-09-04): tilt resizes brush.** Per-tilt
  log gated to developer mode. **LESSON:** for extra mouse-wheel axes use `_MOUSEWHEEL(axis&)` (axis
  0=vertical, 1=horizontal — newer QB64PE), never the `_DEVICEINPUT`+`_WHEEL(n)` device API.
- **STILL OPEN (gated):** **B2b Pick-FG/BG + Sym-center** — need a design decision (pick is
  multi-site: chrome-eyedrop/canvas-loupe/picker-tool; sym fires on Ctrl+EITHER button — neither
  fits one button+mod without changing defaults). **C plain vertical wheel zoom/brush rebind** —
  still legacy-owned (MOUSE_handle_wheel, ~300-line ELSEIF chain, dispatched=FALSE metadata); needs
  a dispatch migration or intent-query wiring — the risky part, deferred. Tilt (the new capability)
  is the shipped piece. **⚑ Rick live tests pending:** paint FG/BG swap + pan drag.
- **Rule learned:** every QB64 tool/probe gets `ON ERROR GOTO EH` (no blocking dialogs) —
  [[feedback-no-error-dialogs]].
- **Phase 5 preset letter-key content** — Rick's collision tradeoffs (G bucket, C crop, L lasso,
  P pen, GIMP R/E/F/M, H hand). See the decisions doc.
- **Settings `Ctrl+,`** — ⛔ Windows-blocked: `_KEYDOWN(44)` works on Linux/macOS while Ctrl held
  but Windows delivers comma only via `_KEYHIT ±188`; needs a keyhit-alias + Windows verification.

Reusable-lib / lint-first / zero-warnings / OS-native discipline throughout. See
[[feedback-dry-reuse-libs]], [[feedback-lint-not-build]], [[feedback-zero-warnings-build]],
[[apron-canvas-coord-readers]].
