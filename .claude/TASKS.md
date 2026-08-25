# v2.0.0 Input-Seam Hardening

Map every input seam BETWEEN tools / operations / internal states, draw the transition
diagrams, write QA tests for every seam, and fix the bugs found. Branch:
`v2.0.0-input-hardening`. Bugs → `BUGS-v2.0.0.md`. Blockers get logged there, not stop the loop.

## 🔨 NOW — doing right now

➡️ BUG-1/2/3 fixes applied + compile clean. BUG-2 verified GREEN (transform test); C1 GREEN. Committing fixes, then authoring remaining Phase C seam tests (C2/C3/C4/C5/C7/C8/C9/C10).

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
- [ ] C2. `seam-selection-to-draw.sh` — marquee active → brush draws clipped to selection; switch away & back; deselect removes the clip.
- [ ] C3. `seam-copy-then-wand.sh` — reproduce BUG-1 (paste → move/commit → wand geometry wrong). RED until BUG-1 fixed.
- [ ] C4. `seam-paste-then-switch.sh` — paste (floating/clone) → switch tool → overlay commits or cancels cleanly; no un-erasable pixels.
- [ ] C5. `seam-eraser-reaches-all.sh` — reproduce BUG-2 (stranded pixels the eraser can't remove). RED until BUG-2 fixed.
- [x] C6. `seam-transform-then.sh` — transform overlay active → switch tool → overlay dismissed (committed). **GREEN after BUG-2 fix** (was RED on baseline).
- [ ] C7. `seam-text-then-switch.sh` — text editing → switch tool → rasterizes/commits, no stuck editor.
- [ ] C8. `seam-move-then-switch.sh` — move in progress → switch tool → commits/cancels cleanly.
- [ ] C9. `seam-undo-across-tools.sh` — draw with tool A, switch to B, undo → targets the right op, no cross-tool corruption.
- [ ] C10. `seam-new-open-resets-all.sh` — several tools mid-state → New and Open both fully reset all tool/overlay state.

## Phase D — Fix bugs found

- [x] D2. **BUG-2 FIXED + VERIFIED** — `TOOLS_reset_all` commits an active TRANSFORM before switching (preserving destination tool). Compiles clean; `seam-transform-then.sh` GREEN.
- [x] D1. **BUG-1 FIXED** — `CLIPBOARD_paste` calls `MAGIC_WAND_reset` after `TOOLS_reset_all FALSE` (drops stale wand mask; keeps paste rect). Compiles clean; pixel-repro hard (smoke + manual).
- [x] D3. **BUG-3 FIXED** — free MOVE float buffers before `MOVE_init` in all 3 doc-creation paths (leak fix). Compiles clean.
- [ ] D4. Address remaining seam bugs surfaced by Phase C (or log `⛔ BLOCKED` in BUGS-v2.0.0.md if a Rick decision is needed). Compile clean.

## Phase E — Verify & wrap

- [ ] E1. Full clean compile (`make`) — 0 new warnings.
- [ ] E2. Run all NEW seam tests offscreen; iterate to green (document any proven-flaky).
- [ ] E3. Regression: run existing input-related QA subset offscreen; confirm no new failures vs baseline.
- [ ] E4. Final BUGS-v2.0.0.md consolidation (fixed vs open/BLOCKED); commit diagrams+tests+fixes on branch; write a run summary at the bottom of BUGS-v2.0.0.md.

loop:on
