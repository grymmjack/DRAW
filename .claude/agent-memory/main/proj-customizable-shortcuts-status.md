---
name: proj-customizable-shortcuts-status
description: Status of the customizable-shortcuts branch (rebind system). Phases 0-3 + 4.1/4.2 done & Rick-verified as of 2026-09-04; remaining = minor Phase 4 polish, Phase 5 presets, Phase 2B.2 mouse.
metadata:
  type: project
---

Feature branch **`customizable-shortcuts`** (rebased onto v2.0.3 main 2026-09-04). Plan:
`PLANS/CUSTOMIZABLE-SHORTCUTS.md`. Builds fully green. Registry-driven rebinding on the
central `INPUT/INPUT.BM` dispatch table + `CFG/BINDINGS.BM` override engine.

**DONE + Rick-verified (2026-09-04):**
- Phases 0-1: `SHORTCUTS.md` (self-generating via `--dump-shortcuts`), CHEATSHEET retired,
  `MOD_PRIMARY` + macOS ⌘ (stock `_KEYDOWN` 100311/100312), category/override metadata.
- Phase 2A: 5 keyboard subsystems migrated to central dispatch (tools, flip, transforms,
  effects, quit); conflict audit 0/227.
- Phase 3: rebind ENGINE (`BINDINGS_set_override`/`_find_conflict%`/`_reset_all`,
  `DRAW.bindings` override persistence).
- **Phase 4.1/4.2 UI** — `GUI/CONTROLS.BI/BM`, Edit > Customize Controls / palette,
  action `ACTION_CUSTOMIZE_CONTROLS = 2360` (2300 collided with ANS_ACT_EXPORT — gotcha #17).
  Registry list by category, greyed SET on non-dispatched rows, **FIND box = TI widget**
  (reuse, not hand-rolled), rebind capture modal (Ctrl/Shift/Alt checkboxes + press-key,
  lowercase-normalised), **warn+steal** conflict (steal unbinds the loser via keycode 0),
  RESET ALL restores defaults **live**.
- Engine fix (2026-09-04): rebinding used to leave the OLD key working (legacy handler
  re-awoke when its key dropped from the skip-list). Fixed by snapshotting each binding's
  compiled default (`INPUT_BIND.defKeycode/defRequireMods/defForbidMods`) and keeping the
  DEFAULT key skip-listed + restoring from it on reset. See [[apron-canvas-coord-readers]]-style
  gotcha discipline.
- QA: `controls-dialog-open.sh`, `controls-find-filter.sh` (green). Rebind-applies path is
  live-verified (offscreen key capture unreliable; mutates DRAW.bindings).

**REMAINING:** minor Phase 4 polish (scrollbar DRAG — wheel works; an overridden-row
"modified" marker); Phase 5 preset CONTENT (gimp/aseprite/photoshop/dpaint keymaps — needs
Rick's conflict-tradeoff calls; preset SYSTEM `--load-preset` already works); Phase 2B.2
mouse-behavior rebinding (make `MOUSE.BM` registry-driven for FG/BG/pan/pick/zoom); Phase 6
wrap. Flagged keyboard debt: F12 export (9999-vs-1110 id + 34304/28416 keycode variant),
Settings Ctrl+`,` (needs Windows keyhit-alias), music `{}/*` (need CMD ids).

Builds via VSCode F5 (see [[feedback_vscode_task_for_draw_build]]); lint-first loop
([[feedback-lint-not-build]]); zero-warnings ([[feedback-zero-warnings-build]]); reuse libs
([[feedback-dry-reuse-libs]]).
