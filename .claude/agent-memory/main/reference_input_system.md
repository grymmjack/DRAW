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
- `b4f164c` Memory update with Phase 5c/5d
- `fa3dce8` Phase 5e — collapse 4-line _FREEIMAGE blocks (38 sites, -114 LOC)
- `20d75ee` Phase 5f — collapse 3-line _FREEIMAGE blocks (31 sites, -58 LOC)
- `0d314f8` Phase 5g — first dispatched=TRUE binding (F12 dev debug proof of concept)

**Remaining work** (future sessions):
- Phase 1b: more keyboard registrations (brush size, Esc, arrows, F-keys 4-9)
- Phase 5 continued: ~297 remaining _FREEIMAGE sites have complex surrounding logic
  (multi-statement IF blocks with extra conditions/statements) — per-site review needed
- ~50 multi-line SCENE_DIRTY+FRAME_IDLE pairs → SCENE_invalidate (varied patterns)
- ~10 manual MODIFIERS chains → MODS_only% (small win)
- ~8 _DEST/_SOURCE manual save-restore sites → DEST_SAVE/RESTORE
- Migrate dispatched=FALSE bindings to dispatched=TRUE one at a time
  (must remove corresponding legacy inline handler at same time to avoid double-fire)
- Phase 8: manual QA against PLANS/TESTS/
- Phase 9: merge to main

**Current state (Phase 6a-c complete)**: 26+ commits on branch, 167 bindings,
36 dispatched=TRUE (was 1 before P6; now 22 tool keys + 11 opacity/X + 2
brush-size + 1 F12 proof), letter skip-list size 31, 0 audit conflicts.

Phase 6 added two new infrastructure pieces in INPUT.BI/BM:
- `INPUT_LETTER_DISPATCHED(0 TO 127) AS INTEGER` — set by INPUT_register%
  when a dispatched=TRUE EVT_KEY_PRESS binding lands on 0..127 keycode
  (A-Z normalized to a-z). Lookup index = ASC(LCASE$(keypress$)).
- `INPUT_DISPATCH_DEPTH AS INTEGER` — depth counter, incremented at top
  of CMD_execute_action, decremented at end. Lets KEYBOARD_tools and
  KEYBOARD_colors early-exit when called from INKEY$ (depth=0) but
  proceed when CMD_execute_action calls back into them (depth>0).
- New CTX_SS_DRAGGING bit for 3D dice / SS polygon dragging — digit
  opacity bindings forbid it so digits feed dice type / polygon sides
  instead of opacity during drag.

Phase 6 commits:
- `26a0feb` Phase 6a-i — corrected Phase 1a action IDs (still FALSE)
- `12b7584` Phase 6a-ii — added CASE 1701 (Zoom tool switch), 1706
  (Smart Shapes activate/cycle with STATIC double-tap), 1707 (Bevel
  outer style); added Shift+T → 115 binding
- `bc9e954` Phase 6a-iii — flipped 22 tool keys to dispatched=TRUE
- `37350c1` Phase 6b — flipped opacity 1-0 (501-510) and X-swap (517);
  added CASE 517 handler that was registered but never implemented
- `1b83204` Phase 6c — flipped [ and ] (601, 602)
- `b41d919` Removed KEYBOARD_brush_size SUB (fully migrated)

Branch is mergeable. The migrated keys are end-to-end dispatched through
the central dispatcher. Verify by running `./DRAW.run --developer`,
pressing any migrated key, then `cat inputs.log` — exactly one [FIRE]
line per press, action ID matches the binding label.

**Remaining work** (future sessions):
- Phase 6d: Ctrl+letter ops (Ctrl+S/O/N/Z/Y/C/X/V/A/D/T/L/P/B/E/R, plus
  Ctrl+Shift+S, Ctrl+=, Ctrl+-, Ctrl+0, Ctrl+Home, Ctrl+End, etc.).
  Each currently has STATIC pressed% + _KEYDOWN guard scattered across
  KEYBOARD.BM SUBs. Per-chord migration: add binding dispatched=TRUE,
  remove legacy STATIC block. Best done one chord at a time with QA.
- Phase 6e: Chord bindings (G+R, G+Shift+R, G+Ctrl+R, G+O, G+arrows,
  M+=, M+-, M++, M+_, Z+0..9). Multi-key state machines. Complex.
- Migrate * (random track) and # (border toggle) — needs CTX_MUSIC_ENABLED
  or in-action guard.
- Remove KEYBOARD_colors entirely once * and # migrated (digits + X
  already skip-listed; * and # are only remaining live cases).
- Phase 8: full QA against PLANS/TESTS/input-rearchitecture-qa.md
- Phase 9: merge to main

## Key invariants (don't violate)

1. **Every visible panel MUST call `REGION_set_bounds` in its render SUB.** Hidden panels stay inactive via `REGION_clear_all` at top of `SCREEN_render`.
2. **REGION_BOUNDS uses logical (pre-display-scale) pixels** to match `MOUSE.RAW_X/Y` coord space.
3. **Action handlers may read `INPUT_EVENT` shared state** — populated by dispatcher before the action ID is invoked. Valid only during the action call.
4. **First-match-wins via registration order** — register panels in z-order from top (modals → popups → panels → canvas) so the natural priority matches user expectation.
5. **Event-type CONST ranges are reserved** (1-9 KB, 10-29 mouse, 30-39 gamepad, 40-49 MIDI, 50-59 tablet, 60-69 touch) — don't renumber.

## Related memories

- [[feedback-hotkey-grep-sweep]] — the manual approach that drove the need for this rearchitecture. Once this is fully dispatched, that memory becomes obsolete (audit replaces manual grep).
- [[feedback-destructive-in-place-transforms]] — uses `HISTORY_*` helpers; will adopt `SCENE_invalidate` helper as Phase 5 migrates.
