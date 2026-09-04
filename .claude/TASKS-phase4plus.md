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

➡️ Rick (mid-run) asked for DRY/centralization + chose #2 QA-guard-lib, #3 dialog-hit-test-helper, #4 FIRE-log-helper (NOT #1 mouse-intent-layer — that stays with 2B.2 for his live pass). Folded in below. Next: #2 (pure bash, no build).

⚑ **FOR RICK (surfaced, not blocking the loop):** Phase 5 preset letter-key content (aseprite/photoshop/gimp/deluxepaint) needs your tradeoff calls — see `PLANS/PRESETS-KEYMAP-DECISIONS.md`: which DRAW default each preset may displace (G→bucket loses grid chords; C→crop displaces ellipse; L→lasso displaces line; P→pen displaces polygon; GIMP R/E/F/M; H→hand). Everything autonomously-defensible is shipped.

- [x] **Scrollbar drag** — DONE. `CTRL_scrollbar_metrics` (shared draw+input geometry) + `CONTROLS_handle_scrollbar` (thumb grab/drag + track paging, grab consumes click). Wired into modal loop. Green build; dialog screenshot shows thumb; 11/11 source-guard test `controls-scroll-marker-source-guards.sh`. Committed.
- [x] **Overridden-row "modified" marker** — DONE. Left accent stripe + highlighted key text on `userOverridden` rows + "= changed from default" legend in the button bar. Screenshot-confirmed legend renders; source-guarded. Committed.
- [x] **Phase 2 migration batch** — DONE (commit 21e14cfa). Music transport keys `{`(123)→428, `}`(125)→427, `*`(42)→433 migrated to central dispatch; legacy handlers removed; CASE 433 guarded on MUSIC_ENABLED for `*` parity. Green build; **dev-mode startup audit: 230 bindings, 0 conflicts**; `seam-music-central.sh` 7/7. (This also clears the "music" half of the Flagged-debt item below.)
- [x] **Phase 5 preset content** — DONE to the autonomous extent (commit 0e48828a). `PLANS/PRESETS-KEYMAP-DECISIONS.md` (per-app analysis + remap-not-alias semantics + the decisions Rick must make) + the one provably-safe remap shipped: photoshop Copy-to-New-Layer→Ctrl+J (`321 106 1 0`; keycode 106 unused ⇒ conflict-free by construction), verified loading in an isolated config (audit 230/0). DRAW already matches these apps on B/E/M/W/V/T/I/Z/L; the meaningful letter-key differences all collide with DRAW draw-tools/chords → **surfaced for Rick** (see NOW). The other three presets stay documented starters.
- [ ] ⛔ **2B.2 mouse rebinding — BLOCKED on Rick (visual/live confirmation of hot-path changes).** Design DONE + committed (`PLANS/MOUSE-REBIND-2B2-DESIGN.md`): the ~6 rebindable behaviors, an additive `MOUSE_intent_active%()` query layer to centralize the ~dozens of scattered `MOUSE.B1/B2/B3` reads, override storage, capture-UI (Phase 4.3) prerequisite, and test strategy. NOT wired unattended: it touches the core drawing hot path (offscreen can't verify a paint stroke) and there's no mouse-capture UI yet to set an override, so end-to-end is untestable here. Rick's live pass unblocks the wiring (= DRY item #1). Autonomous part (design) shipped.
- [ ] **DRY #2 — QA source-guard lib** — extract the duplicated `pass`/`fail`/`assert_grep`/`assert_absent` scaffolding (5 test files) into `QA/tests/lib/source-guard.sh`; source it from each. Verify all 5 still pass. Pure bash, no DRAW build. Commit.
- [ ] **DRY #3 — dialog hit-test helper** — add non-consuming `DIALOG_point_in%(ctx,x,y,w,h)` (sibling of consuming `DIALOG_hit%`) in `GUI/DIALOG.*`; replace the 6 inline box-tests in `GUI/CONTROLS.BM`. Build clean; screenshot dialog still renders/hovers. Commit. (Batch build with Flagged-debt.)
- [ ] **DRY #4 — FIRE-log test helper** — add a reusable `assert_action_fires`-style helper to the QA harness (drives `--developer`, greps `inputs.log` for `action=<id>`) so key→action dispatch is CI-testable; back-fill a behavioral music-keys check with it. Commit.
- [ ] **Flagged debt** — resolve the autonomous parts: music `{`/`}`/`*` is **already DONE** (item 3 / commit 21e14cfa). F12 export: resolve the 34304-vs-28416 keycode-variant via a probe + the 9999-vs-1110 id conflict. Settings `Ctrl+,` stays **⛔ BLOCKED** (needs a Windows box to verify the `_KEYHIT ±188` alias — Rick owes the Windows verification). Commit the autonomous F12 fix.

loop:on
