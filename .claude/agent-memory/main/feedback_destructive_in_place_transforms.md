---
name: feedback-destructive-in-place-transforms
description: For DRAW transform-style features (scale, rotate, flip, etc.), prefer destructive in-place layer modification over floating/staging via the MOVE tool. Includes the canonical pattern for bundling layer + selection changes into one undo group.
metadata:
  type: feedback
---

When the user asks for a new transform feature ("scale 2x", "flip", "rotate", "skew"), default to **destructive in-place modification of the layer pixels** — not a floating-selection workflow that requires a separate stamp/commit step.

**Why:** Verbatim from grymmjack while building 2x-scale-horizontal/vertical: *"there is no stamp either - it's automatic application, shouldn't need stamp - you are getting confused by move tool with 'stamp' idea."* He was frustrated I'd routed the new scale operation through `MOVE_capture_selection` / `MOVE.SELECTION_IMAGE` / `MOVE_apply_transform`. The MOVE/floating pattern is for *interactive* drag-style transforms; for hotkey-triggered transforms the user expects: press key → see result immediately on the layer → Ctrl+Z to undo.

**How to apply:**
- Reference template: `CASE 318` (uniform Scale 2x) in [GUI/COMMAND.BM](GUI/COMMAND.BM) — its **layer branch** is the canonical pattern. Selection sub-branch extracts the region, transforms it, clears the original area on the layer, pastes back centered, clipped to canvas. Layer sub-branch snapshots whole layer, transforms, replaces in place.
- **Bundle layer + selection undo into one group** so a single Ctrl+Z restores both. Pattern (used in CASE 331/333 Scale 2x H/V):
  ```qb64
  HISTORY_selection_stage          ' BEFORE any mutation — captures marquee/mask
  ' ... do scaling: mutate layer pixels AND mutate MARQUEE.BOX/MASK/WAND bounds ...
  IF beforeImg& < -1 THEN
      HISTORY_begin_group
      HISTORY_record_transform layerId&, slot%, flags&, beforeImg&, "Scale 2x H"
      HISTORY_selection_commit
      HISTORY_end_group
      HISTORY_saved_this_frame% = TRUE
  END IF
  ```
  The undo loop at `HISTORY.BM:2186` walks all records sharing a `sequence&` so a single Ctrl+Z unwinds the whole group. See [TOOLS/HISTORY.BM](TOOLS/HISTORY.BM) lines 209-226 (group sub) and 1592-1640 (sel capture/apply).
- **Wand-mask scaling is required** when the user has a per-pixel selection (e.g. via SELECTION FROM LAYER). The `MARQUEE.SELECTION_MASK` is a canvas-sized image with alpha>0 where selected. Scale the mask region through the same pixel-doubling pipeline as the layer content, then update `MARQUEE.WAND_MIN_X/Y/MAX_X/Y` and set `MARQUEE.WAND_EDGE_DIRTY = TRUE` to force the marching-ants edge cache rebuild. Otherwise the ants render a rectangle instead of the doubled silhouette.

Related: [[feedback-selection-vs-brush-priority]] for which target a hotkey should prefer when multiple are valid.
