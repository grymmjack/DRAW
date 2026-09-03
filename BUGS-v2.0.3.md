# DRAW v2.0.3 — paste / move / wand bug-bash

Source: external beta-tester report (Windows, v2.0.1 — `Feedbacks.pdf`, 2026-09-01).
Cluster: the **Magic Wand → Copy → Paste → Move → Flip** workflow. Reproduced /
root-caused against the current main build (v2.0.2). Branch: `bugfix-v2.0.3-paste-move-wand`.

Status key: 🔎 reproducing · 🐛 confirmed+root-caused · 🔧 fixing · ✅ fixed (pending verify) · 🏗 shipped · ❔ not reproduced

## Fix-pass status (2026-09-02)
- **A/B/C — FIXED** (commit e94e237b), build clean. Verification caveat: the
  offscreen Xvfb harness **cannot reliably drive this workflow** (mouse-event
  timing vs keyboard events, float grabbing, menu/selection coordinates all
  misbehave). BUG-B shows no stamp trail offscreen; A/C are correct by
  construction. **These want hands-on confirmation on the real app** (where the
  tester found them). Regression guards for existing move/paste/wand behavior were
  run against the new build.
- **D/E — root-caused, NOT yet fixed.** Both fixes carry real regression risk to
  the shared move/selection path and need a live repro to do safely — best paired
  with Rick or verified on the real app. Details below.

Repro note: BUG-A reproduced offscreen with screenshots; B–E are root-caused from
source (the multi-step floating-move interactions are finicky to drive under Xvfb,
and the tester already demonstrated each on Windows with screenshots). The wand
itself works on first use (verified offscreen: full-canvas + shape selects correctly)
— consistent with the tester (their wand worked initially; E is only *after* a cycle).

---

## BUG-A — Paste lands at the raw mouse-cursor position  🐛
Copy then Paste via the **Edit menu** drops the copy at top-left (cursor is over the
menu); via Ctrl+V it pastes wherever the pointer sits. Tester wants paste to place a
floating selection positioned by a **click**.
- **Repro:** ✅ offscreen — moved mouse to a target, Ctrl+V → the paste float appeared
  centered on the mouse position, not at the source or canvas centre.
- **Root cause:** `GUI/COMMAND.BM:994` `CASE 305 : CLIPBOARD_paste MOUSE.X%, MOUSE.Y%`
  → `TOOLS/SELECTION.BM:258-261` centres the paste on the mouse: `pasteX = mouseX -
  CLIPBOARD.WIDTH/2`. Via a menu, `MOUSE.X/Y` maps to wherever the cursor was over the
  menu → top-left. **Fix direction:** paste as a floating selection at the canvas
  centre (or the original copy location), let the user drag/click to place — OR only
  use `MOUSE.X/Y` when the paste is invoked by a canvas action, not a menu/hotkey.

## BUG-B — Move stamps unwanted copies (no Alt)  🐛
After moving a pasted selection and releasing, moving again stamps a NEW copy on every
drag/pause ("brush effect", ~a dozen copies). Stamping should require **Alt** ("Hold
ALT+DRAG: Stamp copies").
- **Repro:** 🔎 partial offscreen (float-move drives inconsistently under Xvfb);
  tester's Windows screenshots are definitive.
- **Root cause:** `TOOLS/SELECTION.BM:330-331` — a paste forces `MOVE.CLONING=TRUE` +
  `MOVE.IS_PASTE=TRUE` (permanent clone mode). `TOOLS/MOVE.BM:1054`
  `IF MOVE.CLONING AND moveDidChange% THEN MOVE.CLONE_STAMPED=TRUE` → every move-commit
  in clone mode leaves a stamp. `IS_PASTE` is consumed after the first commit
  (MOVE.BM:646-648, intended to make later moves "normal"), but the float stays in
  clone mode so repeated drag+release keep stamping. **Fix direction:** after the paste
  is first placed, a plain drag should REPOSITION the single instance; only Alt+drag
  should stamp. Re-evaluate CLONING = Alt-held for every post-placement move (don't let
  the initial paste's clone flag persist across releases).

## BUG-C — Paste does not preserve transparency  🐛
A pasted selection's transparent pixels **occlude** the image underneath instead of
showing through (opaque composite).
- **Repro:** 🔎 (needs a non-rect / transparent-margin selection; tester's screenshots
  show it clearly).
- **Root cause:** `TOOLS/MOVE.BM:770` + `:819-827` — the float composites with
  `_DONTBLEND` ("Must use _DONTBLEND so alpha=0 pixels actually overwrite existing
  content"). Correct for a *move* (vacated region must clear), but wrong for a *paste*:
  the pasted bbox's transparent pixels overwrite (erase) the underlying image.
  Same family as gotcha #16. **Fix direction:** when `MOVE.CLONING` is a paste (not a
  same-layer move that must clear its origin), composite the float with `_BLEND` (or
  per-pixel skip alpha=0), so transparent paste pixels show the layer through.

## BUG-D — Flip during a floating paste ghosts / fuses  🐛 root-caused
Flip works on a fresh paste, but moving the pasted area first and then Flip yields a
**fusion of the original + flipped** (doubled/ghosted shape).
- **Root cause:** the move commits on RELEASE and KEEPS the float. `MOUSE_release_move`
  (plain path) calls `MOVE_apply_transform` — which BAKES the float onto the layer at
  the current position — then keeps the float active as an identical overlay
  (`MOVE_sync_base`, no re-capture). Normally the overlay sits exactly over the baked
  pixels (invisible). The Flip-H/V float handler (`GUI/COMMAND.BM:2879-2895`) flips only
  `MOVE.SELECTION_IMAGE` (the overlay); the baked UNFLIPPED pixels stay on the layer →
  you see baked-unflipped + overlay-flipped = the fusion. (`CMD_autofloat_for_transform`
  is a no-op here — it early-exits when `MOVE.ACTIVE`, COMMAND.BM:5830.)
- **Fix direction (risky — verify live):** the clean fix is the same root as BUG-B —
  make a paste float **stay floating until a terminal commit** (deselect / tool-switch /
  ESC / paste-again) instead of baking on every release. Then flip flips a pure float
  (no baked pixels underneath) and plain-drag repositions (no stamp). This is an
  architectural change to `MOUSE_release_move`'s commit model and touches ALL moves
  (paste + marquee); it needs a live repro + regression pass before shipping.

## BUG-E — Magic Wand fails after a deselect+reselect cycle  🐛→lead
After paste/move/deselect, re-picking a same-color area with the Wand **fails to select
the contiguous shape** — grabs a jagged, wrong region. Most severe.
- **Repro:** 🔎 pending the full cycle; the wand works on FIRST use (verified offscreen).
- **Root cause (lead):** a stale per-pixel magic-wand mask with old `WAND_MIN/MAX`
  bounds survives the paste/move/deselect cycle and is re-read by later region-scoped
  ops — the EXACT class documented at `TOOLS/SELECTION.BM:296-302` ("makes the wand
  later 'select things that aren't there'"). Paste calls `MAGIC_WAND_reset`, but the
  cycle the tester runs (wand → copy → paste → move → deselect → wand) evidently leaves
  the mask stale on a path that isn't cleared. Find the deselect/commit path that skips
  `MAGIC_WAND_reset` and clear it there too.

---

## Fix-pass ordering (proposed)
1. **BUG-A** (paste position) — contained, high-visibility; also underpins B/C/D.
2. **BUG-C** (transparency) — one-line-ish blend fix in the clone composite.
3. **BUG-B** (stamping) — clone-flag lifecycle across moves.
4. **BUG-D** (flip ghost) — floating-flip composite.
5. **BUG-E** (wand stale mask) — deselect-path reset. Most severe; verify carefully.
Each gets a QA guard (Rick's standing rule) where offscreen-testable.

## Tester's theory
A–D stem from paste-at-pointer; paste should place on a user click. (E is separate — a
stale wand mask.) Tester: *"Don't be scared, yours is a masterpiece."*
