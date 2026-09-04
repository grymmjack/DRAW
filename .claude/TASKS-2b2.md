# 2B.2 Mouse rebinding — drive to done (armed 2026-09-04)

Rick armed /task-loop for the full 2B.2 mouse-rebinding feature. Slice A1 (extra
buttons sampled + dispatched; back→Undo / forward→Redo) is DONE and **verified on
real hardware**. Branch `customizable-shortcuts` (off v2.0.3 main).

Working rules (Rick): lint after edits; full-build only when a run/test/screenshot
needs it; builds **GREEN** (zero warnings AND infos); **DRY / reuse** existing
widgets (DIALOG_CTX, TI_*, BINDINGS_*); GUI runs **offscreen under Xvfb**; every
fix gets a **QA test** where testable (source guards for the un-drivable bits);
**every QB64 tool gets `ON ERROR`** (no blocking dialogs — [[feedback-no-error-dialogs]]);
commit each item. **Only stop the loop for something that genuinely needs Rick
(live paint/mouse verify) or a Windows box** — otherwise reprioritize blocked
items down and keep going.

## 🔨 NOW — loop idle (all autonomously-shippable 2B.2 work done)

✅ Shipped this loop: A1 (extra buttons), A2 (rebind UI + persistence), B (paint FG/BG),
B2 pan, Docs. Every autonomous slice is committed + verified as far as offscreen allows.
The 3 open boxes below are all gated on Rick — two on a design decision (B2b pick/sym, C
wheel) and one on real hardware (C2 wheel-tilt probe). Nothing left is workable without him,
so `loop:off`. Flip back to loop:on when a design call is made or the ThinkPad is free for
the wheel-tilt probe.

⚑ **Rick live tests still pending (not blocking):** paint FG/BG button swap + pan drag —
both built + offscreen-verified; confirm on real hardware.

⚑ **FOR RICK (live test, not blocking):** Paint FG/BG button rebinding (Slice B) is built + verified offscreen (rows render with enabled SET…). Confirm on real hardware: (1) left-drag paints FG, right-drag paints BG (defaults unchanged); (2) Customize Controls → filter "paint" → SET… on "Paint with background color" → press LEFT button → now left-drag paints BG, right-drag paints FG; RESET ALL restores.

- [x] **A1 — extra buttons sampled + dispatched** — DONE (commit e595fe5f). Buttons sampled 1..N bounded by _LASTBUTTON (ERR-5-safe); dispatcher widened; back(4)→Undo / forward(5)→Redo defaults. Verified on real hardware ("test: WORKS"). Source guard 11/11.
- [x] **A2 — Customize Controls surfaces + rebinds mouse buttons** — DONE (commit db4c787e). CTRL_bind_visible% (DRY); CTRL_current_key$/CTRL_mouse_bind_str$ render "Button 4 (Back)"; CTRL_assign_key% mouse-capture mode; device-discriminated persistence (device+button in BINDING_OVERRIDE, set_mouse_override/apply/save/parse back-compat, defButton reset). Screenshot confirms MOUSE-category row renders; controls-mouse-row.sh region-diff + source guard 14/14. Capture+persist round-trip = real HW.
- [x] **B — Paint FG/BG button rebinding** — DONE (commit 40c8700a). MB_PAINT_FG/BG behavior binds; MOUSE_intent_button%/MOUSE_button_down% query; MOUSE_update_draw_color wired (single central site; stroke gates fire on either button so swap needs only this). Surfaced with ENABLED SET… (CTRL_bind_rebindable% — else fake rows); mouse-override apply un-gated from dispatched. Screenshot + controls-paint-row.sh + source guard. ⚑ live paint-swap test surfaced for Rick (offscreen can't drag-paint).
- [x] **B2 — Pan rebinding** — DONE (commit 1b44e796). MB_PAN behavior bind (default middle=3); wired the single pan-initiation site (allowB3Pan%) to MOUSE_intent_button%(MB_PAN,3) — the whole start/continue/end lifecycle keys off it, so a rebound button works end-to-end. Source guard 5/5, clean build, no crash. ⚑ pan-drag live test surfaced for Rick.
- [ ] ⛔ **B2b — Pick FG/BG + Sym-center rebinding — needs a design decision (Rick).** Neither fits the simple one-button+mods bind: Pick is spread across chrome-eyedrop / canvas-loupe / picker-tool paths (MOUSE.BM ~1631/3714/5510/5515), and Sym-center fires on Ctrl + EITHER button (MOUSE.BM:4627). Wiring them to a single button+mod would CHANGE their defaults. Options for Rick: (a) keep "either button + modifier" as a special non-rebindable behavior; (b) pick one canonical button per behavior and accept the default change; (c) extend the bind model with an "any-button" flag + a MOUSE_intent_active% (button+mods) query. Surfaced; not autonomously decidable.
- [ ] ⛔ **C — Wheel zoom/brush bindable — needs design (not a clean slice).** The zoom-vs-brush decision is buried in the ~300-line wheel ELSEIF chain in MOUSE.BM (panel scrolls, SS sub-tool wheel params, import-mode, etc.), and making it real needs EITHER a central-dispatch migration of the wheel binds (406/407/601/602 → dispatched=TRUE + remove the legacy branch, double-fire risk on the core zoom interaction) OR surgical query-wiring inside that chain — PLUS a novel wheel-capture UX (a wheel bind is direction+mods, not a button press, so "press to assign" doesn't map). Deferred as a focused effort rather than rushed. CTRL_bind_visible% already excludes wheel (EVT_MOUSE_WHEEL) so nothing fake is surfaced meanwhile.
- [ ] **C2 — Wheel-tilt via _AXIS** — extend the probe (WITH ON ERROR) to map horizontal wheel-tilt to _AXIS; add tilt sampling + bindable tilt events. ⚑ needs Rick real-HW probe (undocumented API) — surface, don't block.
- [x] **Docs** — DONE (commit 7d6e7b77). SHORTCUTS.md MOUSE-rebind table; SHORTCUTS_mousetrigger$ names buttons 4/5+ so the CONTROLS export reflects them (verified via --export-controls); proj-status memory refreshed. The export already walked the live registry, so mouse binds were auto-included.

loop:off
# ^ all autonomously-shippable 2B.2 slices done + committed. The 3 open boxes are
#   gated on Rick: B2b (pick/sym design decision), C (wheel design), C2 (wheel-tilt
#   real-HW probe). Flip to loop:on when a call is made / the ThinkPad is free.
