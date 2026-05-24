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

**Current state (Phase 6 complete)**: 39 commits on branch, 206 bindings,
131 dispatched=TRUE (was 1 before P6), letter skip-list size 48,
0 audit conflicts.

`KEYBOARD.BM` SUB count dropped from 18 to 11. Removed entirely:
- `KEYBOARD_brush_size` (P6c)
- `KEYBOARD_layers` (P6d-1, 16 chord handlers)
- `KEYBOARD_handle_clipboard_operations` (P6d-4, 15 chord handlers)
- `KEYBOARD_handle_file_operations` (P6d-5, 5 chord handlers)
- `KEYBOARD_handle_zoom_shortcuts` (P6d-5, 3 chord handlers)
- `KEYBOARD_handle_z_zoom_presets` (P6e)
- `KEYBOARD_handle_marquee_expand_contract` (P6e)
- `KEYBOARD_handle_grid_controls` (P6 final)
- `KEYBOARD_handle_ui_toggles` (P6 final)
- `KEYBOARD_handle_delete_backspace` (P6 final)
- `KEYBOARD_handle_layer_shortcuts` (P6 final, was empty)

Remaining SUBs are all context-aware (tool-specific arrows, text-tool
editing, custom brush transforms, eraser hold/tap, recent files Alt+
1-0, command palette intercept) and don't fit the action-ID model
cleanly — they stay as legacy.

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
- `26a0feb` 6a-i — corrected Phase 1a action IDs (still FALSE)
- `12b7584` 6a-ii — added CASE 1701/1706/1707 + Shift+T binding
- `bc9e954` 6a-iii — flipped 22 tool keys to dispatched=TRUE
- `37350c1` 6b — flipped opacity 1-0 (501-510) and X-swap (517);
  added CASE 517 handler that was registered but never implemented
- `1b83204` 6c — flipped [ and ] (601, 602)
- `b41d919` Removed KEYBOARD_brush_size SUB (fully migrated)
- `de909a4` 6d batch 1 — KEYBOARD_layers removed (Ctrl+L/Shift+N/
  Shift+Del/Shift+D/Shift+R/PgUp/PgDn/Shift+[/]/Home/End/Alt+E/
  Alt+Shift+E/G/Shift+G/Shift+U)
- `4e3f3c2` 6d batches 2+3 — Ctrl+B (new CASE 1101), Ctrl+R/Alt+R/
  Alt+Shift+G, Ctrl+,/Shift+Del/Ctrl+D/Ctrl+M
- `78e85fc` 6d batch 4 — KEYBOARD_handle_clipboard_operations removed
  (Ctrl+Z/Y/Shift+Z/C/Shift+C/Alt+C/X/Alt+X/V/Shift+V/A/Shift+I/H/E/T)
- `f9c940c` 6d batch 5 — KEYBOARD_handle_file_operations +
  KEYBOARD_handle_zoom_shortcuts removed (Ctrl+N/O/S/Shift+S/
  Alt+Shift+S/Shift+Q + Ctrl+0/=/-); new CASE 201 for Open
- `3de3be9` 6e — chord migrations (Z+1..0, M+=/-/++/_, G+R/Shift+R/
  Ctrl+R/O/arrows, Ctrl+Shift+/). KEYBOARD_handle_z_zoom_presets +
  KEYBOARD_handle_marquee_expand_contract removed. New actions
  9001-9013 (G chord), 9100-9109 (Z chord). CTX_G_HELD switched to
  use GRID_G_KEY_ARMED% for chord-sticky semantics.
- `e4b66a7` 6 final — F1-F8/Shift+F5/Tab/F10/F11/Ctrl+F11/\/| migrated;
  KEYBOARD_handle_ui_toggles removed. New actions 8001-8011.
- `b0e22b8` 6 final — grid toggles ('/"/Ctrl+'/;//); 
  KEYBOARD_handle_grid_controls removed. New actions 8101-8105.
- `6539df4` 6 final — DEL/Backspace migrated;
  KEYBOARD_handle_delete_backspace removed.
- `7d2a6a0` 6 final — empty KEYBOARD_handle_layer_shortcuts removed.

Branch is mergeable. The migrated keys are end-to-end dispatched through
the central dispatcher. Verify by running `./DRAW.run --developer`,
pressing any migrated key, then `cat inputs.log` — exactly one [FIRE]
line per press, action ID matches the binding label.

**Remaining work** (small follow-ups):
- Migrate `*` (random track, action 433) and `#` (border toggle, action
  441) — needs CTX_MUSIC_ENABLED for `*` or in-action guard. KEYBOARD_colors
  could then be removed (digits + X already skip-listed; only those
  two remain).
- Migrate `?` (Shift+/ = command palette) — currently inline in
  KEYBOARD_input_handler.
- Migrate `{` and `}` (music prev/next track, actions 428/427) — also
  inline in KEYBOARD_input_handler.
- Migrate KEYBOARD_handle_recent_files (Alt+1-0) — would need 10
  new actions.
- The context-aware KEYBOARD_handle_custom_brush (Home/End/PgUp/PgDn
  with brush-vs-layer dispatch) stays inline by design.
- KEYBOARD_handle_text_tool stays inline (gated by TEXT.ACTIVE,
  intentional context override).
- Other tool-specific arrow handlers (marquee, move, shape modifier)
  stay inline.
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
