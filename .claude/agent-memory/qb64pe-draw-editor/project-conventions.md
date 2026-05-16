---
name: project-conventions
description: Non-obvious DRAW conventions that come up repeatedly and are not derivable from a single file. Index into the deep-dive docs.
metadata:
  type: project
---

DRAW is a QB64-PE pixel art editor. Build: `make` (Makefile auto-detects OS). Single binary, no runtime deps.

**Why:** Future-you should not relearn the project layout from scratch.

**How to apply:** When asked about an area below, jump straight to the listed file before searching the code.

- Architecture overview, the 23 critical gotchas, all key files → [[copilot-migration]] points to `.claude/instructions/draw-project.md`
- History/undo internals (record kinds, double-save guard, `UI_CHROME_CLICKED%` lifecycle) → `.claude/instructions/draw-undo.md`
- Render pipeline 22 steps, scene cache, blend modes, layer fields → `.claude/instructions/draw-rendering.md`
- Mouse dispatch single-frame flow, `DEFERRED_ACTION%` values, drain-then-process pattern → `.claude/instructions/draw-mouse.md`
- Menubar / command / toolbar / organizer / drawer / preview / edit bar / advanced bar / settings dialog → `.claude/instructions/draw-ui.md`
- `.draw` binary chunk format versions (currently v28), config keys, theme two-tier loader → `.claude/instructions/draw-fileformat.md`
- Exact pixel/scaled dimensions for every chrome element + min-viewport formulas → `.claude/instructions/draw-chrome-geometry.md`
- Sound slot constants, music auto-shuffle, SF2 MIDI → `.claude/instructions/draw-sound.md`

Top recurring rules to internalise (full list and rationale in `draw-project.md`):

1. Never `_DEST _CONSOLE` + PRINT — corrupts the active drawing destination. Use `_LOGINFO/_LOGWARN/_LOGERROR`.
2. Image handles valid only when `< -1`.
3. `_KEYHIT` is unreliable for Ctrl/Alt combos on Linux/SDL2 — use `_KEYDOWN(physicalCode&)` + `STATIC pressed%` guard.
4. Theme color fields MUST be `~&` (`_UNSIGNED LONG`), never `%`.
5. Reset `UI_CHROME_CLICKED%` **inside** `MOUSE_should_skip_tool_actions%`, never before — otherwise a phantom history record fires on release.
6. Guard every history save with `IF NOT HISTORY_saved_this_frame% THEN ... HISTORY_saved_this_frame% = TRUE`. The flag resets in `LOOP_start`.
7. `DRW_load_binary` must reset every new tool/panel state — otherwise stale state leaks across project loads.
8. Per-frame animations render AFTER `SkipToPointer:` in `SCREEN_render`. Placing before defeats the scene cache.
9. Default-hidden panels must set `ManuallyHidden% = TRUE` alongside `show% = FALSE` (auto-hide restore logic).
10. QB64 passes SUB/FUNCTION params by reference; copy any shared-global parameter to a local at function entry before mutation.
