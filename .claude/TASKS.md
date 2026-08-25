# v2.0.0 Input-Seam Hardening

Map every input seam BETWEEN tools / operations / internal states, draw the transition
diagrams, write QA tests for every seam, and fix the bugs found. Branch:
`v2.0.0-input-hardening`. Bugs → `BUGS-v2.0.0.md`. Blockers get logged there, not stop the loop.

## 🔨 NOW — doing right now

➡️ B0a. GLOBAL diagram reconciliation (agent running).
➡️ B0b. TOOLS diagram reconciliation (agent running).
➡️ B0a/B0b agents running; next: apply their DOT corrections, then B4/B5/B6.

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

- [ ] B0a. GLOBAL diagrams (MOUSE, KEYBOARD, UI, SOUND-MUSIC) — reconcile + re-render.
- [ ] B0b. TOOLS diagrams (BRUSH, DOT, LINE, RECT, ELLIPSE, POLY-LINE, FILL, SPRAY, ERASER, MARQUEE, MOVE, PAN, ZOOM, CROP, PICKER, TEXT, SAVE-LOAD, CHEATSHEET) — reconcile + re-render.
- [ ] B0c. GUI diagrams (MENUBAR, LAYERS-PANEL, TOOLBOX, ORGANIZER, DRAWER, TOOLTIP, EDITBAR, STATUSBAR, PALETTE-STRIP/OPS, COMMAND-PALETTE, PREVIEW, DIALOG, WIDGETS, CHARMAP, COLOR-MIXER, ABOUT, SETTINGS-DIALOG, SMART-GUIDES) — reconcile + re-render.
- [ ] B0d. UTILITIES diagrams (ASSISTANTS, CROSSHAIR, PICKER-LOUPE, SYMMETRY, PATTERN-TILE, FILL-ADJUST, GRID, BRUSH-SIZE, COLOR-MODE, REFIMG) — reconcile + re-render.
- [ ] B0e. LAYER-OPS diagrams (ADD-DELETE, MERGE, ARRANGE, ALIGN-DISTRIBUTE, MULTISELECT, SYMBOL) — reconcile + re-render.
- [ ] B0f. TRANSFORM-OPS + IMAGE-OPS + FILE-OPS diagrams (QUICK-TRANSFORM, TRANSFORM-OVERLAY, IMAGE-RESIZE-CROP, IMAGE-ADJUSTMENT, IMAGE-IMPORT, EXTRACT-*, LOAD-RECENT) — reconcile + re-render.
- [ ] B0g. Verify ALL diagrams render clean (`dot` no syntax errors across the whole `PLANS/diagrams` tree); regenerate any stale SVG/PNG; note any diagram that couldn't be fully verified.

## Phase B — State machine diagrams (DOT → SVG+PNG via `dot`)

- [x] B1. NEW flagship `GLOBAL/TOOL-SEAMS-STATES.DOT` authored + rendered (SVG+PNG). Shows the hub, 5 tool-classes by seam behavior, special paths, doc-ops, and the 3 bug edges (BUG-1/2/3).
- [x] B2. NEW `GLOBAL/SELECTION-LIFECYCLE-STATES.DOT` authored + rendered — 6-state mask lifecycle, writers/readers, BUG-1 stale-mask edge.
- [x] B3. NEW `GLOBAL/CLIPBOARD-LIFECYCLE-STATES.DOT` authored + rendered — pixel + layer clipboards, paste-float, BUG-1/BUG-3 edges.
- [ ] B4. Update `TOOLS/ERASER-STATES.DOT` for AA soft-eraser + the BUG-2 stranded-pixel finding. Render.
- [ ] B5. Update `TOOLS/BRUSH-STATES.DOT` + `TOOLS/MARQUEE-STATES.DOT` for AA edge-mode + wand/paste interaction. Render.
- [ ] B6. Update `PLANS/STATE-MACHINES-TO-MAKE.md`: check off the 3 new diagrams; add the seam-map section.

## Phase C — QA seam tests (QA/tests/, offscreen)

- [ ] C1. `seam-partial-shape-abandon.sh` — line/rect/ellipse/poly first point placed → switch tool → preview clears, nothing commits, no ghost undo state.
- [ ] C2. `seam-selection-to-draw.sh` — marquee active → brush draws clipped to selection; switch away & back; deselect removes the clip.
- [ ] C3. `seam-copy-then-wand.sh` — reproduce BUG-1 (paste → move/commit → wand geometry wrong). RED until BUG-1 fixed.
- [ ] C4. `seam-paste-then-switch.sh` — paste (floating/clone) → switch tool → overlay commits or cancels cleanly; no un-erasable pixels.
- [ ] C5. `seam-eraser-reaches-all.sh` — reproduce BUG-2 (stranded pixels the eraser can't remove). RED until BUG-2 fixed.
- [ ] C6. `seam-transform-then.sh` — transform overlay active → switch tool / New / Open → overlay cancels, no commit to wrong doc (gotcha #15).
- [ ] C7. `seam-text-then-switch.sh` — text editing → switch tool → rasterizes/commits, no stuck editor.
- [ ] C8. `seam-move-then-switch.sh` — move in progress → switch tool → commits/cancels cleanly.
- [ ] C9. `seam-undo-across-tools.sh` — draw with tool A, switch to B, undo → targets the right op, no cross-tool corruption.
- [ ] C10. `seam-new-open-resets-all.sh` — several tools mid-state → New and Open both fully reset all tool/overlay state.

## Phase D — Fix bugs found

- [ ] D1. Fix BUG-1 (paste stale wand mask). Compile clean. Flip C3 to GREEN.
- [ ] D2. Fix BUG-2 (erase-until-reload stranded pixels). Compile clean. Flip C5 to GREEN.
- [ ] D3. Fix missing-reset seams found in A1–A3 (partial-shape ghost commit, doc-creation gaps). Compile clean.
- [ ] D4. Address remaining seam bugs surfaced by Phase C (or log `⛔ BLOCKED` in BUGS-v2.0.0.md if a Rick decision is needed). Compile clean.

## Phase E — Verify & wrap

- [ ] E1. Full clean compile (`make`) — 0 new warnings.
- [ ] E2. Run all NEW seam tests offscreen; iterate to green (document any proven-flaky).
- [ ] E3. Regression: run existing input-related QA subset offscreen; confirm no new failures vs baseline.
- [ ] E4. Final BUGS-v2.0.0.md consolidation (fixed vs open/BLOCKED); commit diagrams+tests+fixes on branch; write a run summary at the bottom of BUGS-v2.0.0.md.

loop:on
