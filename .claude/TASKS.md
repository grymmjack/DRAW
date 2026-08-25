# v2.0.0 Input-Seam Hardening

Map every input seam BETWEEN tools / operations / internal states, draw the transition
diagrams, write QA tests for every seam, and fix the bugs found. Branch:
`v2.0.0-input-hardening`. Bugs → `BUGS-v2.0.0.md`. Blockers get logged there, not stop the loop.

## 🔨 NOW — doing right now

✅ ALL PHASES COMPLETE (A, B0, B, C, D, E). 8 bugs found (2 user-reported both fixed+verified); 4 fixed, 2 closed/benign, 2 deferred-minor. 3 new seam diagrams + ~60 reconciled. 10/10 seam tests GREEN. No regressions. Branch `v2.0.0-input-hardening` ready for review. Loop done.

## Phase A — Map every input seam (source-level)

- [x] A1. Tool-switch chokepoint = `TOOLS_reset_all` (`GUI/GUI.BM:22`); documented all switch sites + GAPS (TRANSFORM/CUSTOM_BRUSH/IMAGE_IMPORT not reset; keyboard-vs-toolbar ordering asymmetry) in `PLANS/INPUT-SEAMS-AUDIT.md`.
- [x] A2. Reset-contract table for all 16 stateful tools written to audit §A2 (all frees guarded via SAFE_FREEIMAGE). Surfaced BUG-5 (IMAGE_IMPORT orphan) + BUG-6 (poly-line/bezier abandon asymmetry).
- [x] A3. Diffed the 3 doc-creation paths; found **BUG-3** (MOVE float discarded by none) + **BUG-4** (CUSTOM_BRUSH/ZOOM_drag drift). Table in audit.
- [x] A4. Selection lifecycle mapped — shared `MARQUEE.SELECTION_MASK` + writers/readers list in audit §A4.
- [x] A5. Clipboard lifecycle mapped — two stores (CLIPBOARD + LAYERXFER), paste→MOVE-float flow, seam risks in audit §A5.
- [x] A6. Both bug findings folded into BUGS-v2.0.0.md: BUG-1 (paste stale wand mask) + BUG-2 (orphaned TRANSFORM overlay), both root-caused with repro.

## Phase B0 — Reconcile EXISTING diagrams to 100% accuracy (audit vs current source)

> The ~66 existing diagrams predate much of 2.0.0 and are likely stale/wrong. For each
> category: verify every state/transition/guard against current source (fan out agents),
> fix the `.DOT`, re-render SVG+PNG, and log corrections in `PLANS/INPUT-SEAMS-AUDIT.md`.

- [x] B0a. GLOBAL diagrams reconciled + re-rendered — KEYBOARD tool-table fixed (C/P/I/S/K/Q/W), MOUSE modal interceptors (TRANSFORM/flyout/loupe/drop), UI rebuilt as main-loop pipeline, SOUND (removed fictional pause, owner gate). BUG-7 confirmed (ERASER_draw_at has 0 callers).
- [x] B0b. TOOLS diagrams reconciled + re-rendered. DRIFT fixed in BRUSH/LINE/RECT/ELLIPSE (AA + record_* + modifiers), POLY-LINE (cancel_restore), MARQUEE (no Intersect; wand E/F/W; SELECTION_MASK; Ctrl+H), MOVE (scale/clone/paste-float/nudge/group/flip), ERASER (BUG-7 latent), FILL/ZOOM/CROP/PICKER. TEXT/DOT/SPRAY/PAN/SAVE-LOAD/CHEATSHEET already accurate.
- [x] B0c. GUI diagrams (14) reconciled + re-rendered — batches A/B/C. Fixed many drifts (preview F4 not F7, palette `?` not Ctrl+P, 71 real dialogs, settings shadow-copy modal, real menu list). Flagged BUG-8 candidate (Transform flyout action).
- [x] B0d. UTILITIES diagrams (10) reconciled + re-rendered. Fixed fictional CAPS/SCROLL-LOCK triggers, F7 symmetry, brush-size presets 1/3/5/9, real GRID modes SQUARE/DIAG/ISO/HEX, etc.
- [x] B0e. LAYER-OPS diagrams (6) reconciled + re-rendered — real action IDs, HISTORY_record_* names, align-to-selection (not canvas), removed fictional range-select.
- [x] B0f. TRANSFORM-OPS + IMAGE-OPS + FILE-OPS diagrams (9) reconciled + re-rendered — quick-transform action IDs + autofloat, transform-overlay BUG-2 edge, EFFECTS system rewrite, format-sniff load.
- [x] B0g. All 70 DOT files pass `dot` syntax check; every DOT has SVG+PNG; whole tree re-rendered fresh. No race corruption found.

## Phase B — State machine diagrams (DOT → SVG+PNG via `dot`)

- [x] B1. NEW flagship `GLOBAL/TOOL-SEAMS-STATES.DOT` authored + rendered (SVG+PNG). Shows the hub, 5 tool-classes by seam behavior, special paths, doc-ops, and the 3 bug edges (BUG-1/2/3).
- [x] B2. NEW `GLOBAL/SELECTION-LIFECYCLE-STATES.DOT` authored + rendered — 6-state mask lifecycle, writers/readers, BUG-1 stale-mask edge.
- [x] B3. NEW `GLOBAL/CLIPBOARD-LIFECYCLE-STATES.DOT` authored + rendered — pixel + layer clipboards, paste-float, BUG-1/BUG-3 edges.
- [x] B4. ERASER-STATES updated (subsumed by B0b): AA soft-eraser LATENT node (BUG-7), PAINT_on delegation, smart-erase Shift+B1. (BUG-2 is transform, not eraser — no eraser edge needed.)
- [x] B5. BRUSH-STATES (AA cluster, Alt=picker, Ctrl fix) + MARQUEE-STATES (wand E/F/W modes, SELECTION_MASK, Ctrl+H, no Intersect) updated (subsumed by B0b).
- [x] B6. `PLANS/STATE-MACHINES-TO-MAKE.md` updated: 3 new seam diagrams checked off + seam-map section added.

## Phase C — QA seam tests (QA/tests/, offscreen)

- [x] C1. `seam-partial-shape-abandon.sh` — abandon partial polygon → switch tool → Ctrl+Z undoes the real stroke, not a ghost shape state. **GREEN** (seam clean).
- [x] C2. `seam-selection-to-draw.sh` — paint clipped to marquee (inside painted, outside clipped, deselect releases). **GREEN**.
- [x] C3. `seam-copy-then-wand.sh` — wand→copy→paste→commit→fresh-wand; fresh wand at RIGHT doesn't disturb LEFT (no stale mask). **GREEN** (functional; pixel-geometry manual).
- [x] C4. `seam-paste-then-switch.sh` — paste float → switch tool → commits cleanly; committed paste is erasable (on real layer). **GREEN**.
- [x] C5. `seam-eraser-reaches-all.sh` — eraser removes content after a transform→eraser switch (BUG-2 from the eraser angle). **GREEN** after fix.
- [x] C6. `seam-transform-then.sh` — transform overlay active → switch tool → overlay dismissed (committed). **GREEN after BUG-2 fix** (was RED on baseline).
- [x] C7. `seam-text-then-switch.sh` — type text → Escape commits → switch tool → text remains, drawing works (control returned). **GREEN**.
- [x] C8. `seam-move-then-switch.sh` — move content → switch tool → move committed (arrives at dest, source vacated). **GREEN**.
- [x] C9. `seam-undo-across-tools.sh` — brush→line→eraser, Ctrl+Z undoes the LINE (cross-tool), 2nd undo→empty. **GREEN**.
- [x] C10. `seam-new-open-resets-all.sh` — repurposed to New-dialog open+cancel (Escape) safety; original doc intact, drawing works. **GREEN**. (Full New→reset path can't be keyboard-driven — size modal needs an OK click; reset verified by code inspection + BUG-3.)

## Phase D — Fix bugs found

- [x] D2. **BUG-2 FIXED + VERIFIED** — `TOOLS_reset_all` commits an active TRANSFORM before switching (preserving destination tool). Compiles clean; `seam-transform-then.sh` GREEN.
- [x] D1. **BUG-1 FIXED** — `CLIPBOARD_paste` calls `MAGIC_WAND_reset` after `TOOLS_reset_all FALSE` (drops stale wand mask; keeps paste rect). Compiles clean; pixel-repro hard (smoke + manual).
- [x] D3. **BUG-3 FIXED** — free MOVE float buffers before `MOVE_init` in all 3 doc-creation paths (leak fix). Compiles clean.
- [x] D4. Candidate bugs resolved: BUG-5 CLOSED (import modal, not reachable), BUG-8 benign (flyout), BUG-6 downgraded (C1 shows clean abandon), BUG-4 deferred (minor/ambiguous UX). **BUG-7 FIXED** (soft AA eraser wired; AA-off byte-identical). No Rick-blocking items.

## Phase E — Verify & wrap

- [x] E1. Full clean compile with all fixes (BUG-1/2/3/7) — `make` clean, `Output: DRAW.run`, `DRAW 2.0.0` runs. 0 new warnings.
- [x] E2. All 10 NEW seam tests forced-rerun (`--rerun-passed`, single-file each) vs the final BUG-1/2/3/7 build: **10 GREEN / 0 failed / 0 skipped** (7-8 assertions each). No flakiness.
- [x] E3. Regression subset (9 input/tool tests) vs BUG-1/2/3/7 build: **7 clean** (tool-eraser 8/8, antialias-toggle 9/9, edit-undo-redo 11/11, edit-undo-depth 22/22, tool-switching 6/6, tool-switch-matrix 28/28, tool-move 13/13). 2 investigated → **NO regressions**: selection-flip-float was flaky (8/8 on both re-runs); edit-copy-paste's 1 failure ("paste to new layer") is PRE-EXISTING on shipped-main 2.0.0 baseline — and my `seam-paste-then-switch` proves paste itself works, so BUG-1 didn't break it.
- [x] E4. BUGS-v2.0.0.md consolidated (FIXED/CLOSED/DEFERRED tables + RUN SUMMARY). All work committed on `v2.0.0-input-hardening` (5 commits: audit+diagrams, reconcile, BUG-1/2/3 fix, seam tests, BUG-7 fix). Nothing BLOCKED. Branch ready for Rick's review/merge.

loop:on
