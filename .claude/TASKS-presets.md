# App keymap presets — build to done (armed 2026-09-04)

Rick asked for binding-file presets mimicking popular apps + an in-app picker.
Decisions (via AskUserQuestion):
- **Collision policy = SAFEST**: a preset row is included ONLY if its target key is
  currently UNBOUND in DRAW (no DRAW default displaced). Every colliding app key is
  LISTED in the file header + the decisions doc for Rick to rule on later — never
  auto-displaced.
- **Apps**: fill photoshop / gimp / aseprite / deluxepaint; add NEW krita, illustrator,
  procreate, mspaint, promotion.
- **In-app picker**: YES — "Load preset ▾" dropdown in Customize Controls.

Working rules (Rick): lint after edits; full-build only when a run/test needs it;
builds GREEN (zero warnings/infos); DRY/reuse (DIALOG_dropdown%, BINDINGS_*); GUI
offscreen under Xvfb; QA test where testable; every QB64 tool gets ON ERROR; commit
each item. Preset format: `actionId keycode requireMods forbidMods [device button]`
(mods 1=Ctrl 2=Shift 4=Alt). Loader: BINDINGS_load_preset → ASSETS/PRESETS/<name>.bindings.

## 🔨 NOW — doing right now

✅ ALL DONE — picker + 9 preset files + docs shipped. loop:off.

- [x] **Foundation — DRAW keymap snapshot + action-id map.** DONE. Dumped live keymap (SHORTCUTS.tables.md, 236 bound triggers). FREE keys for safe remaps: **Ctrl+I / Ctrl+J / Ctrl+K / Ctrl+U / Ctrl+W** (clean); plain A/G/J/N/U/Y unbound but risky (chords/reserved) → avoid. Confirmed action ids incl. Copy-to-New-Layer=321 (Ctrl+J row `321 106 1 0`). Most app tool-letters COLLIDE with DRAW tools/chords → collision blocks, not rows.
- [x] **Preset picker UI.** DONE (commit 2d44aa5b) — Load preset ▾ dropdown, live load + rebuild, gap-centred legend fix, opens upward. Screenshot-verified. "Load preset ▾" dropdown in the Customize Controls button bar (reuse DIALOG_dropdown%, id CTRL_DD_PRESET); on pick call BINDINGS_load_preset live + CONTROLS_rebuild_vis; hardcode the shipped preset list (no dir SHELL). Offscreen screenshot + source guard.
- [x] **Author all 9 preset files.** DONE — photoshop/gimp/aseprite/deluxepaint filled + krita/illustrator/procreate/mspaint/promotion new. Only safe rows: Ctrl+J→321 (PS), Ctrl+J→707 (Krita); rest documented as collisions. All load via --load-preset, no crash. photoshop/gimp/aseprite/deluxepaint filled; krita/illustrator/procreate/mspaint/promotion new. Each: the provably-safe remaps (target key unbound in DRAW) + a commented COLLISIONS block listing app keys that clash with DRAW defaults (for Rick). Verify each loads via --load-preset (override count > 0, no crash).
- [x] **Update PLANS/PRESETS-KEYMAP-DECISIONS.md** — DONE, recorded picker + safest-policy outcome + new apps. — per-app collision analysis + the decisions Rick still owes, for the new apps too.
- [x] **Verify + commit** — DONE (2d44aa5b). Clean build, 18/18 source guard, 9 presets load, picker screenshot clean. — picker loads a preset live (screenshot), each file parses, green build, guards pass.

loop:off
