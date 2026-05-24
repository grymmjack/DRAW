# DRAW Input System — implementation guide

Quick reference for working with the new unified input dispatch system. Full design in [PLANS/REARCHITECTURE.md](../../PLANS/REARCHITECTURE.md).

## Files

| File | Purpose |
|------|---------|
| [INPUT/INPUT.BI](../../INPUT/INPUT.BI) | TYPEs (`INPUT_BIND`, `REGION_BOUNDS`, `INPUT_EVENT_OBJ`, `DETECTED_EVENT`) + CONSTs (`EVT_*`, `REGION_*`, `MOD_*`, `CTX_*`, `ZORDER_*`, `DEVICE_*`) + shared state |
| [INPUT/INPUT.BM](../../INPUT/INPUT.BM) | `INPUTS_init`, `INPUTS_log`, `INPUT_register*`, `INPUT_update_context`, `INPUT_detect_events`, `INPUT_dispatch_frame`, `INPUT_audit`, `REGION_set_bounds/inactive/clear_all/hit_test`, `INPUTS_register_all` |
| [INPUT/GAMEPAD.BM](../../INPUT/GAMEPAD.BM) | Stub for gamepad-as-mouse emulation |
| [CORE/HELPERS.BI/BM](../../CORE/HELPERS.BI) | Cross-cutting utilities: `SAFE_FREEIMAGE`, `DEST/SOURCE/FONT_SAVE/RESTORE`, `PIXEL_DOUBLE_AXIS`, `SCENE_invalidate`, `MODS_NOW%`, `MODS_only%` |

## Common tasks

### Adding a new keyboard hotkey

```qb64
' In INPUTS_register_all (INPUT.BM):
r% = INPUT_register_key%(<keycode>, <requireMods>, <forbidMods>, <requireCtx>, <forbidCtx>, <actionId>, <dispatched>, "label")
```

Field meanings:
- **keycode**: ASCII (lowercase for letters — case-insensitive match handled), or QB64-PE physical code (Home=18176, End=20224, etc.)
- **requireMods**: bitmask of `MOD_CTRL | MOD_SHIFT | MOD_ALT` that MUST all be held
- **forbidMods**: bitmask of mods that MUST NOT be held (use to exclude `MOD_SHIFT OR MOD_ALT` from a "Ctrl-only" binding)
- **requireCtx**: bitmask of `CTX_*` flags that MUST all be set (use `CTX_G_HELD` for "G chord")
- **forbidCtx**: bitmask of `CTX_*` flags that MUST NOT be set (always include `CTX_TEXT_ACTIVE` to disable while text-tool-typing)
- **actionId**: integer matching a `CASE` in `CMD_execute_action` (existing CMD_register IDs from `GUI/COMMAND.BM`)
- **dispatched**: `TRUE` = new dispatcher fires the action; `FALSE` = metadata only (legacy still owns)
- **label**: shows up in audit / inputs.log / future palette

Convention: every binding includes `CTX_TEXT_ACTIVE` in `forbidCtx` unless it specifically should fire during text entry.

### Adding a new mouse handler

```qb64
' In INPUTS_register_all:
r% = INPUT_register_mouse%(<eventType>, <region>, <button>, <requireMods>, <forbidMods>, <requireCtx>, <forbidCtx>, <actionId>, <dispatched>, "label")
```

`eventType` is one of `EVT_MOUSE_DOWN/UP/CLICK/DBLCLICK/DRAG_START/DRAG_MOVE/DRAG_END/HOVER_ENTER/HOVER_LEAVE/MOVE`.

Inside the action handler, read sub-element from `INPUT_EVENT.mouseX/Y`:

```qb64
CASE ACT_TOOLBAR_CLICK
    DIM btnId AS INTEGER
    btnId% = TOOLBAR_button_at%(INPUT_EVENT.mouseX, INPUT_EVENT.mouseY)
    IF btnId% > 0 THEN TOOLBAR_dispatch_button btnId%
```

`INPUT_EVENT` is shared state populated by the dispatcher before invoking the action. Valid only during the action call.

### Adding a new GUI panel

1. Add a `REGION_<NAME>` constant in [INPUT/INPUT.BI](../../INPUT/INPUT.BI) (range 28-63 reserved for future panels).
2. At the top of the panel's render SUB, after the panel knows its bounds:
   ```qb64
   REGION_set_bounds REGION_<NAME>, x, y, w, h, ZORDER_PANEL
   ```
3. If the panel can hide, the convention `SCREEN_render → REGION_clear_all → panel-render-skipped-when-hidden` handles inactivation automatically — nothing else to do.
4. Add a `CTX_OVER_<NAME>` flag in [INPUT/INPUT.BI](../../INPUT/INPUT.BI) (bits 32-63).
5. Wire it into `INPUT_update_context` (the `SELECT CASE hoverRegion%` block at the end).

### Adding a new context flag

Reserve a bit in [INPUT/INPUT.BI](../../INPUT/INPUT.BI), set it in `INPUT_update_context` based on world state, then bindings can `requireCtx` or `forbidCtx` it.

Bit layout:
- **0-19**: subsystem/mode flags (text active, dialog open, etc.)
- **20-31**: held-key chord initiators
- **32-63**: cursor-region flags (auto-set from `REGION_hit_test` result)

## Invariants — do NOT violate

1. **Every visible panel MUST call `REGION_set_bounds` in its render SUB.** Hidden panels stay inactive via `REGION_clear_all` at top of `SCREEN_render`.
2. **REGION_BOUNDS uses logical (pre-display-scale) pixels** to match `MOUSE.RAW_X/Y` coord space.
3. **Action handlers may read `INPUT_EVENT` shared state** during dispatch only.
4. **First-match-wins via registration order** — register panels in z-order from top (modals → popups → panels → canvas) so the natural priority matches user expectation. Z-order also breaks ties when multiple regions overlap.
5. **Event-type CONST ranges are reserved** (1-9 KB, 10-29 mouse, 30-39 gamepad, 40-49 MIDI, 50-59 tablet, 60-69 touch) — don't renumber.
6. **Don't add `_KEYDOWN(<code>)` polling outside `INPUT_detect_events`** unless implementing a legacy state machine (paint stroke, eraser hold-vs-tap). All new chords should go through the table.

## Developer mode

Enable any of:
- CLI: `./DRAW.run --developer` (or `--dev`)
- CFG: set `DEVELOPER_MODE=TRUE` in your `DRAW.cfg`
- Env: `DRAW_DEVELOPER=1` (planned, not yet wired)

When active: `./inputs.log` is cleared on startup and receives:
- `[INIT]` — startup details
- `[AUDIT]` — conflict scan summary + per-conflict lines
- `[FIRE]` — each dispatched event (verbose; useful for tracing user flows)
- `[CONFLICT]` — pair of bindings that could match simultaneously
- `[CONSISTENCY]` — region with degenerate or off-screen bounds (panel bug)
- `[OVERFLOW]` — event queue overflow (>64 events in one frame — should never happen)
- `[GAMEPAD]` — gamepad detection (stub for now)

## Migration playbook for future sessions

The branch state at last checkpoint (input-rearchitecture):
- Phase 0 ✅ Infrastructure shipped
- Phase 1a ✅ 88 keyboard bindings as `dispatched=FALSE` metadata
- Phase 2 ✅ 14 of 18 GUI panels register regions
- Phase 1b ⏳ Remaining KB bindings: brush size keys, Esc, Enter, arrow keys in special contexts, F-keys 4-9, opacity slider arrows
- Phase 3 ⏳ Mouse event bindings (register every `MOUSE.B1/B2/B3` site as metadata)
- Phase 4 ⏳ Resolve audit-reported conflicts after Phases 1b/3 surface them
- Phase 5 ⏳ Apply `CORE/HELPERS` to existing code (216 `_FREEIMAGE` sites, 8+ `_DEST`/`_SOURCE` save-restore sites, 4 pixel-doubling loops, 50+ dirty-flag pairs)
- Phase 7 ⏳ Continue updating CLAUDE.md as new patterns emerge
- Phase 8 ⏳ Manual QA against [PLANS/TESTS/](../../PLANS/TESTS/)
- Phase 9 ⏳ Merge to main

When converting `dispatched=FALSE` → `dispatched=TRUE`:
1. Move the action body from its inline handler to a `CASE <actionId>` in `CMD_execute_action`
2. Delete the inline `_KEYDOWN`/`STATIC pressed%` block in the legacy SUB
3. Flip the `INPUT_register_*` call's last-but-one arg from `FALSE` to `TRUE`
4. Run with `--developer` and verify no `[CONFLICT]` lines for the migrated binding
