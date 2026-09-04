# CUSTOMIZABLE SHORTCUTS — Phase 4+ loop (started 2026-09-04)

Rick's sequence: **(4) scrollbar drag + overridden marker → (1) one Phase-2 migration batch →
(5) presets → (2B.2) mouse rebinding → flagged debt.** Phase record + prior context:
`.claude/TASKS.md`. Branch `customizable-shortcuts` (off v2.0.3 main).

Working rules (Rick, 2026-09-04): **lint after edits, full-build only when a run/screenshot/
test/interaction needs it**; builds must be **green — zero warnings AND infos**; **DRY / reuse
libs** (TI, DIALOG_CTX, shared helpers); GUI runs **offscreen under Xvfb only**; every fix gets
a **QA test** where testable; commit each item. **Only stop the loop for something that genuinely
needs Rick or a Windows box** — otherwise reprioritize blocked items down and keep going.

## 🔨 NOW — doing right now

➡️ Item 3 (music-key migration) CODE-COMPLETE + lint clean (INPUT.BM/KEYBOARD.BM/COMMAND.BM), source-guard test written. Building to verify dispatch behavior (--developer FIRE log), then commit.

- [x] **Scrollbar drag** — DONE. `CTRL_scrollbar_metrics` (shared draw+input geometry) + `CONTROLS_handle_scrollbar` (thumb grab/drag + track paging, grab consumes click). Wired into modal loop. Green build; dialog screenshot shows thumb; 11/11 source-guard test `controls-scroll-marker-source-guards.sh`. Committed.
- [x] **Overridden-row "modified" marker** — DONE. Left accent stripe + highlighted key text on `userOverridden` rows + "= changed from default" legend in the button bar. Screenshot-confirmed legend renders; source-guarded. Committed.
- [ ] **Phase 2 migration batch** — ➡️ **Music transport keys** `{`(123)→428 Prev, `}`(125)→427 Next, `*`(42)→433 Random migrated to central dispatch (dispatched=TRUE; legacy handlers in KEYBOARD_input_handler + KEYBOARD_colors removed; CASE 433 guarded on MUSIC_ENABLED for `*` parity). CMD actions pre-existed; MUSIC_next/prev self-guard on MUSIC_ENABLED. Build → --developer FIRE-log verify (action=427/428/433) → conflict audit → commit. (Note: TASKS.md's "427/428/433 not in CMD_execute_action" was STALE — they exist.)
- [ ] **Phase 5 preset content** — draft starter keymaps (aseprite / photoshop / gimp / deluxepaint) as far as is autonomously defensible using the shipped `.bindings` format + `--load-preset`. Where a foreign key genuinely collides with a DRAW chord and the tradeoff is a judgment call, leave that binding out and list it for Rick rather than guessing. Commit what's defensible.
- [ ] **2B.2 mouse rebinding** — make `MOUSE.BM` honor registry overrides for the enumerated rebindable behaviors (FG/BG paint button, wheel zoom-vs-brush-size, Alt+click pick, Ctrl+click symmetry-center, pan trigger). Registry-driven, not CMD-fire. Conflict audit; test where possible; build clean. Commit.
- [ ] **Flagged debt** — resolve the autonomous parts: music `{`/`}`/`*` (add the missing 427/428/433 CMD ids then migrate) and F12 export (resolve the 34304-vs-28416 keycode-variant via a probe + the 9999-vs-1110 id conflict). Settings `Ctrl+,` stays **⛔ BLOCKED** (needs a Windows box to verify the `_KEYHIT ±188` alias — nobody has a Windows machine in this session; Rick owes the Windows verification). Commit the autonomous fixes.

loop:on
