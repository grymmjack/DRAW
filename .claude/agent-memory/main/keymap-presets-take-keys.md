---
name: keymap-presets-take-keys
description: How DRAW.bindings / ASSETS/PRESETS rows apply (BINDINGS_apply full rebuild, preset key wins + unbinds DRAW's, BIND_KEY_NONE, chord-forbid), and QA config isolation (QA-BINDINGS)
metadata:
  type: project
---
Keymap rows (CFG/BINDINGS.BM `BINDINGS_apply`, 2026-11-14) — OS-agnostic:
- Apply is an idempotent full rebuild: `BINDINGS_restore_live_defaults` first (it also compacts away
  `cloned` binds), then the rows.
- An action's Nth row moves its Nth dispatched keyboard bind. A row past the binds it has clones a new one.
- **The preset's key wins.** Any other non-overridden dispatched keyboard bind that could collide is
  unbound: keycode `BIND_KEY_NONE` (-1), mods 0. In developer mode, `[KEYMAP]` lines go to inputs.log.
- Keycode **0 = ANY key** (a wildcard), never "unbound". The old Controls steal wrote 0 and made a
  catch-all. Keyboard rows with 0 now load as NONE.
- A plain key moved onto a chord letter (g/m/z/e/f/w) needs `BINDINGS_chord_forbid~&&`. The chord
  CTX_*_HELD flag is set on the key's own press, which blocked it.
- Legacy (non-dispatched) handlers must stand down for keys a preset took: `BINDINGS_key_taken%`
  (`/ > <` F9 in KEYBOARD.BM). Menus, palette and tooltips show the live key via `BINDINGS_hotkey$`.
- Only deluxepaint.bindings has real rows (68). As of 2026-11-14, aseprite / gimp / mspaint / procreate /
  promotion / illustrator / draw-default are empty, and krita / photoshop have 1 row each.

QA: a normal Linux run gives each test its own XDG_CONFIG_HOME (qa-harness adapters/draw/manifest.sh). It is
seeded from the user's config minus DRAW.bindings / DRAW.cfg, plus a MIGRATED_TO_NATIVE.txt marker.
`# QA-BINDINGS: <repo path>` seeds DRAW.bindings. Before this, QA runs read and wrote the user's real
DRAW.bindings. Test: QA/tests/deluxepaint-keymap.sh. See [[qa-harness-toolkit]].
