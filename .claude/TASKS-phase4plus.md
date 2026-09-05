# CUSTOMIZABLE SHORTCUTS — Phase 4+ loop (started 2026-09-04)

Rick's sequence: **(4) scrollbar drag + overridden marker → (1) one Phase-2 migration batch →
(5) presets → (2B.2) mouse rebinding → flagged debt.** Phase record + prior context:
`.claude/TASKS.md`. Branch `customizable-shortcuts` (off v2.0.3 main).

Working rules (Rick, 2026-09-04): **lint after edits, full-build only when a run/screenshot/
test/interaction needs it**; builds must be **green — zero warnings AND infos**; **DRY / reuse
libs** (TI, DIALOG_CTX, shared helpers); GUI runs **offscreen under Xvfb only**; every fix gets
a **QA test** where testable; commit each item. **Only stop the loop for something that genuinely
needs Rick or a Windows box** — otherwise reprioritize blocked items down and keep going.

## 🔨 NOW — loop idle (all autonomous items shipped)

✅ Export feature + build-speed win COMMITTED (build #3 green: 8:07 w/ `-f:OptimizeCppProgram=false` vs ~13min optimized). Nothing left is actionable without Rick or a Windows box — see the two ⛔ items below. Loop stays armed; will re-engage if an item unblocks.

⚑ **FOR RICK (surfaced, not blocking the loop):** Phase 5 preset letter-key content (aseprite/photoshop/gimp/deluxepaint) needs your tradeoff calls — see `PLANS/PRESETS-KEYMAP-DECISIONS.md`: which DRAW default each preset may displace (G→bucket loses grid chords; C→crop displaces ellipse; L→lasso displaces line; P→pen displaces polygon; GIMP R/E/F/M; H→hand). Everything autonomously-defensible is shipped.

- [x] **Scrollbar drag** — DONE. `CTRL_scrollbar_metrics` (shared draw+input geometry) + `CONTROLS_handle_scrollbar` (thumb grab/drag + track paging, grab consumes click). Wired into modal loop. Green build; dialog screenshot shows thumb; 11/11 source-guard test `controls-scroll-marker-source-guards.sh`. Committed.
- [x] **Overridden-row "modified" marker** — DONE. Left accent stripe + highlighted key text on `userOverridden` rows + "= changed from default" legend in the button bar. Screenshot-confirmed legend renders; source-guarded. Committed.
- [x] **Phase 2 migration batch** — DONE (commit 21e14cfa). Music transport keys `{`(123)→428, `}`(125)→427, `*`(42)→433 migrated to central dispatch; legacy handlers removed; CASE 433 guarded on MUSIC_ENABLED for `*` parity. Green build; **dev-mode startup audit: 230 bindings, 0 conflicts**; `seam-music-central.sh` 7/7. (This also clears the "music" half of the Flagged-debt item below.)
- [x] **Phase 5 preset content** — DONE to the autonomous extent (commit 0e48828a). `PLANS/PRESETS-KEYMAP-DECISIONS.md` (per-app analysis + remap-not-alias semantics + the decisions Rick must make) + the one provably-safe remap shipped: photoshop Copy-to-New-Layer→Ctrl+J (`321 106 1 0`; keycode 106 unused ⇒ conflict-free by construction), verified loading in an isolated config (audit 230/0). DRAW already matches these apps on B/E/M/W/V/T/I/Z/L; the meaningful letter-key differences all collide with DRAW draw-tools/chords → **surfaced for Rick** (see NOW). The other three presets stay documented starters.
- [ ] ⛔ **2B.2 mouse rebinding — BLOCKED on Rick (visual/live confirmation of hot-path changes).** Design DONE + committed (`PLANS/MOUSE-REBIND-2B2-DESIGN.md`): the ~6 rebindable behaviors, an additive `MOUSE_intent_active%()` query layer to centralize the ~dozens of scattered `MOUSE.B1/B2/B3` reads, override storage, capture-UI (Phase 4.3) prerequisite, and test strategy. NOT wired unattended: it touches the core drawing hot path (offscreen can't verify a paint stroke) and there's no mouse-capture UI yet to set an override, so end-to-end is untestable here. Rick's live pass unblocks the wiring (= DRY item #1). Autonomous part (design) shipped.
- [x] **DRY #2 — QA source-guard lib** — DONE (commit ad2f603f). `QA/tests/lib/source-guard.sh` (pass/fail/assert_grep/assert_absent/guard_footer); 5 guard tests now source it (~125 dup lines → ~10). All 5 pass standalone (8/11/7/8/16) and through the harness.
- [x] **DRY #3 — dialog hit-test helper** — DONE (commit 401fbfe4). `DIALOG_point_in%(ctx,x,y,w,h)` (non-consuming sibling of `DIALOG_hit%`); replaced the 6 inline box-tests in CONTROLS.BM. Green build; controls-dialog-open + controls-find-filter 15/15 (no hover regression).
- [x] **DRY #4 — FIRE-log test helper** — DONE (commit c0bc0f62). `QA/tests/lib/fire-log.sh` (`assert_action_fires`, reuses harness XTEST keys, skips without `--developer`); `fire-music-central.sh` (behavioral }/{/* → 427/428/433, now GREEN) + `fire-f12-probe.sh`. **It immediately earned its keep: caught that the item-3 music keys never dispatched** (shifted-char forbidMods bug — fixed in c0bc0f62, verified 3/3 FIRE).
- [x] **Flagged debt (autonomous parts)** — DONE. Music `{`/`}`/`*` (item 3 + shifted-char fix c0bc0f62). **F12** (commit 4d4cb907): keycode landmine PROBED → F12=34304; migrated F12+brush→1110 / F12 no-brush→9999; legacy handler removed; keyname fixed. seam-f12-central 5/5; fire-f12-probe FIRES 9999.
- [ ] ⛔ **Settings `Ctrl+,` — BLOCKED on a Windows box.** `_KEYDOWN(44)` works on Linux/macOS while Ctrl held, but Windows delivers comma only via `_KEYHIT ±188`; plain keycode-44 would regress Windows. Needs a keyhit-alias + Windows verification — **Rick owes the Windows test.** Works via legacy today; not doable in this Linux session.
- [x] **Export Customized Controls (Rick, mid-run 2026-09-04)** — DONE. Reused `SHORTCUTS-DUMP.BM` generator: `SHORTCUTS_controls_doc$(fmt)` builds standalone MD/HTML from the LIVE registry (overrides reflected, ★ on customized rows, print CSS in HTML). Dialog: reused `DIALOG_dropdown%` as **"Export as… ▾"** (HTML/Markdown/PDF). MD+HTML native (no deps). **PDF LAME-style optional**: `SHORTCUTS_pdf_engine$` probes PATH for wkhtmltopdf/weasyprint (NOT pandoc — LaTeX hang; bounded `timeout 60`); none found → browser Print→PDF guidance. CLI `--export-controls [dir]`. **3 QB64 gotchas fixed via `-z DRAW.BAS` gate**: `out`→OUT stmt, `""` not an escaped quote (single-quote HTML attrs), no-arg func call w/o parens. Build → verify CLI writes CONTROLS.md/.html + dropdown screenshot → commit.

loop:off
# ^ all autonomously-shippable items done. The 2 open boxes are ⛔ blocked on Rick
#   (2B.2 mouse live-verify) and a Windows box (Settings Ctrl+, keyhit-alias). Flip
#   back to loop:on when either unblocks.
