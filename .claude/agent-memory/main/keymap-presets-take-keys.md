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
- Every shipped preset has real rows (2026-11-15). draw-default stays empty on purpose: it means factory keys.

QA: a normal Linux run gives each test its own XDG_CONFIG_HOME (qa-harness adapters/draw/manifest.sh). It is
seeded from the user's config minus DRAW.bindings / DRAW.cfg, plus a MIGRATED_TO_NATIVE.txt marker.
`# QA-BINDINGS: <repo path>` seeds DRAW.bindings. Before this, QA runs read and wrote the user's real
DRAW.bindings. Test: QA/tests/deluxepaint-keymap.sh. See [[qa-harness-toolkit]].

2026-11-15 — all 9 presets are filled. Sources for each:
- Aseprite: data/gui.xml.
- Krita: krita/kritamenu.action, krita.action, plugins/tools/tools.action, and the tool factory headers.
- Pro Motion: cosmigo onlinehelp keyboardShortcuts.htm. It uses a German layout, so ß / ´ fall on US - / =.
- Procreate: Handbook keyboard page.
- Photoshop, GIMP, Illustrator and MS Paint: standard defaults.

Gotchas, verified with GUI tests on [Linux]:
- **Ctrl+Shift+punctuation** arrives as the UNSHIFTED key: Ctrl+Shift+' = 39 with mods 3. A row with 34 + Ctrl never fires.
- A `Ctrl+]` row with forbid 0 allows Shift (the printable non-letter rule), so it steals Ctrl+Shift+]. Write forbid 6.
- **Legacy-only actions** (no dispatched bind, e.g. Settings on Ctrl+,): a row now ADDS a dispatched bind (pass 3).
  The old pass 2 only re-pointed a display-only metadata bind, so the new key did nothing.
  A legacy handler on a key a row takes must stand down: `BINDINGS_combo_taken%` (Ctrl+, Settings vs GIMP fill FG).
- **Checks:**
  - `QA/keymap-presets.sh` is standalone. It runs --load-preset + --export-controls on a private Xvfb + XDG config,
    and checks that rows = applied, plus key -> action pairs.
  - GUI tests: tests/keymap-{gimp,krita,photoshop,aseprite}.sh (QA/keymap-lib.sh).
- Don't `pkill -f "Xvfb :N"` inside a Bash command: the pattern matches the command's own shell and kills it. Kill by PID.
