---
name: dock-row-share-overcommit
description: A dock row's set slot widths (@px shares) can add up to more than the row; LAYOUT shrinks them in proportion, so any code that writes one share from the slot's shown width makes the row jump
metadata:
  type: project
---

[Linux, observed 2026-11-16] A row slot's width set by dragging its right edge is saved as `name@px`
in the [DOCK] tree (DOCK_SLOT.share). Nothing keeps the shares within the row: Rick's grafx2
workspace had `BOTTOM.1=HEIGHT:30; editbar@868 | advbar@1837` in a ~1280 px row (saved in a wider
window / at another display scale). DOCK_lay_row gives share slots shrink 1, so LAY shrinks them by
shrink x basis - both show at ~half. The edge drag then set the edit bar's share to its SHOWN width
(468) while the advanced bar kept 1837: the proportional shrink threw the edge far left, and it
"jumped right" once dragged past.

**Why:** shares are bases, not sizes; a mix of an updated share and stale over-wide ones re-divides
the row.

**How to apply:** before changing one share in a row, normalize the row's shares to their shown
widths (DOCK_row_rz_grab), and trade width with the neighbour rather than overflowing.
QA/tests/dock-row-overwide.sh reproduces it with --option DOCK_BOTTOM_1=...@868|...@1837 (keep the
row 48 high in QA's 742 px row, or the solver drops the second bar: the minimums overflow).
Related: [[qa-offscreen-fragile-tests]].
