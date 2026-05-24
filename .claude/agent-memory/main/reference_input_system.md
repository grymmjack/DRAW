---
name: reference-input-system
description: DRAW has a unified input dispatch system in INPUT/INPUT.BI/BM that replaces scattered IF/STATIC keyboard/mouse handlers. Bindings are declared in a table; events flow through a central dispatcher; conflicts are auto-detected in developer mode. Migration is phased — much of the legacy code still owns dispatch until converted.
metadata:
  type: reference
---

DRAW migrated from input-driven dispatch (scattered IF/STATIC blocks in KEYBOARD.BM/MOUSE.BM polluting central handlers) to **event-driven dispatch** (HTML-style: regions register bounds, handlers register for events, central loop matches events to bindings). See [PLANS/REARCHITECTURE.md](PLANS/REARCHITECTURE.md) for the full ~1700-line spec.

## Files

- **[INPUT/INPUT.BI](INPUT/INPUT.BI)** — TYPEs (`INPUT_BIND`, `REGION_BOUNDS`, `INPUT_EVENT_OBJ`), CONSTs (`EVT_*` event types, `REGION_*` regions, `MOD_*` modifier bitmask, `CTX_*` 64-bit context flags, `ZORDER_*` z-order tiers), `DIM SHARED` state
- **[INPUT/INPUT.BM](INPUT/INPUT.BM)** — `INPUTS_init`, `INPUT_register*` family, `INPUT_update_context`, `INPUT_detect_events`, `INPUT_dispatch_frame`, `INPUT_audit`, `REGION_set_bounds/inactive/clear_all/hit_test`, `INPUTS_register_all` (Phase 1+ legacy metadata)
- **[INPUT/GAMEPAD.BM](INPUT/GAMEPAD.BM)** — stub for gamepad = mouse emulation (translates D-pad / sticks / buttons to MOUSE.RAW_X/Y/B1/B2/B3); not yet wired to real `_DEVICEINPUT`
- **[CORE/HELPERS.BI/BM](CORE/HELPERS.BI)** — cross-cutting utilities: `SAFE_FREEIMAGE`, `DEST/SOURCE/FONT_SAVE/RESTORE` (stack-based), `PIXEL_DOUBLE_AXIS`, `SCENE_invalidate`, `MODS_NOW%`, `MODS_only%`

## How to add a new hotkey or click handler

```qb64
' In INPUTS_register_all (INPUT.BM):
r% = INPUT_register_key%(<keycode>, <requireMods>, <forbidMods>, <requireCtx>, <forbidCtx>, <actionId>, TRUE, "label")
```

Wrappers: `INPUT_register_key%`, `INPUT_register_mouse%`, `INPUT_register_wheel%`, `INPUT_register_hover%`.

When `dispatched = TRUE`, the dispatcher fires `CMD_execute_action <actionId>` on match. When `dispatched = FALSE`, it's metadata for audit only; the legacy KEYBOARD.BM / MOUSE.BM handler still owns actual dispatch.

## Developer mode

Three sources OR'd together enable dev mode:
- CLI: `./DRAW.run --developer` or `--dev`
- CFG: `DEVELOPER_MODE=TRUE` in `~/.config/DRAW/DRAW.cfg`
- (Env var support reserved but not yet wired)

When active: `./inputs.log` is cleared on startup, then receives `[INIT]`, `[AUDIT]`, `[CONFLICT]`, `[FIRE]`, `[OVERFLOW]`, `[CONSISTENCY]`, `[GAMEPAD]` entries throughout the session. The `[AUDIT]` runs once at startup and reports every pair of bindings that could mathematically fire on the same input + context state.

## Migration status (commits on branch input-rearchitecture)

- `9d745aa` Phase 0 — infrastructure shipped (zero behavior change)
- `45c2b4d` Phase 1a — 88 keyboard bindings registered as `dispatched = FALSE` metadata (0 audit conflicts)
- `d43e32f` Phase 2a — first panel (status bar) migrated to REGION system
- `1cf8a84` Phase 2b.1 — 6 core panels migrated (edit bar, adv bar, toolbar, layer panel, palette strip, menubar)
- `952329e` Phase 2b.2 — 8 more panels migrated (drawer, organizer, charmap, preview, color mixer, browser, subtool flyout, text bar)
- `fa78a93` Phase 7 — CLAUDE.md + input-system.md instructions
- `b1bd100` Phase 3 + 4 — 72 mouse bindings as metadata, audit wheelDir fix (160 total bindings, 0 conflicts)
- `ad8ce5a` Phase 5a — PIXEL_DOUBLE_AXIS + SAFE_FREEIMAGE adoption in CUSTOM-BRUSH.BM
- `c07d923` Phase 5b — PIXEL_DOUBLE_AXIS adoption in COMMAND.BM CASE 331/333
- `8e0a1b0` Memory update with full commit list
- `e2a472c` Phase 5c — bulk SAFE_FREEIMAGE adoption (215 sites across 17 files)
- `6635665` Phase 5d — SCENE_invalidate adoption (13 same-line sites)

**Remaining work** (future sessions):
- Phase 1b: more keyboard registrations (brush size, Esc, arrows, F-keys 4-9)
- Phase 5 continued: apply remaining CORE/HELPERS to existing code:
  - ~140 remaining _FREEIMAGE sites with COMPLEX surrounding logic (multi-statement IF blocks); need per-site review
  - ~50 multi-line SCENE_DIRTY+FRAME_IDLE pairs → SCENE_invalidate (sites vary widely in pattern)
  - ~10 manual MODIFIERS chains → MODS_only% (small win)
  - ~8 _DEST/_SOURCE manual save-restore sites → DEST_SAVE/RESTORE + SOURCE_SAVE/RESTORE
- Phase 8: manual QA against PLANS/TESTS/
- Phase 9: merge to main

**Current state**: 13 commits on branch, ~3800 LOC added, 0 audit conflicts on 160 metadata bindings, **276 sites using SAFE_FREEIMAGE**. Branch is mergeable as-is. Remaining phases can ship on subsequent branches.

## Key invariants (don't violate)

1. **Every visible panel MUST call `REGION_set_bounds` in its render SUB.** Hidden panels stay inactive via `REGION_clear_all` at top of `SCREEN_render`.
2. **REGION_BOUNDS uses logical (pre-display-scale) pixels** to match `MOUSE.RAW_X/Y` coord space.
3. **Action handlers may read `INPUT_EVENT` shared state** — populated by dispatcher before the action ID is invoked. Valid only during the action call.
4. **First-match-wins via registration order** — register panels in z-order from top (modals → popups → panels → canvas) so the natural priority matches user expectation.
5. **Event-type CONST ranges are reserved** (1-9 KB, 10-29 mouse, 30-39 gamepad, 40-49 MIDI, 50-59 tablet, 60-69 touch) — don't renumber.

## Related memories

- [[feedback-hotkey-grep-sweep]] — the manual approach that drove the need for this rearchitecture. Once this is fully dispatched, that memory becomes obsolete (audit replaces manual grep).
- [[feedback-destructive-in-place-transforms]] — uses `HISTORY_*` helpers; will adopt `SCENE_invalidate` helper as Phase 5 migrates.
