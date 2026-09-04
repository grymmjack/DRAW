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

**REMAINING (all genuinely gated):**
- **2B.2 mouse rebinding** — Rick-gated. Design shipped (`PLANS/MOUSE-REBIND-2B2-DESIGN.md`):
  centralize the ~dozens of scattered `MOUSE.B1/B2/B3` reads behind `MOUSE_intent_active%()`
  (= DRY #1), override storage, mouse-capture UI (4.3). NOT wired unattended — core drawing hot
  path, offscreen can't verify a paint stroke, and no UI yet to set a mouse override.
- **Phase 5 preset letter-key content** — Rick's collision tradeoffs (G bucket, C crop, L lasso,
  P pen, GIMP R/E/F/M, H hand). See the decisions doc.
- **Settings `Ctrl+,`** — ⛔ Windows-blocked: `_KEYDOWN(44)` works on Linux/macOS while Ctrl held
  but Windows delivers comma only via `_KEYHIT ±188`; needs a keyhit-alias + Windows verification.

Reusable-lib / lint-first / zero-warnings / OS-native discipline throughout. See
[[feedback-dry-reuse-libs]], [[feedback-lint-not-build]], [[feedback-zero-warnings-build]],
[[apron-canvas-coord-readers]].
