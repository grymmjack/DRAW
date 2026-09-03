---
name: apron-canvas-coord-readers
description: Any op that reads a layer's imgHandle& at RAW canvas coords is wrong once the layer is apron-promoted (gotcha #14). The Magic Wand shipped this bug (v2.0.3 BUG-E).
metadata:
  type: project
---

Gotcha #14 (apron offset) applies to READERS, not just writers. When a layer is
apron-promoted (`LAYERS(i).apronW% > 0`), its `imgHandle&` buffer is LARGER than the
canvas and canvas coord `(cx,cy)` lives at buffer coord `(cx+apronW, cy+apronH)`. Any
code that samples `LAYER_current_image&` (or a layer buffer) using raw canvas coords
reads the wrong pixel after a paste/move/transform promotes an apron.

**Shipped as BUG-E (v2.0.3, Windows tester Feedbacks.pdf):** `MAGIC_WAND_select_with_mode`
(`TOOLS/MARQUEE.BM`) builds a canvas-sized mask and floods from the click at canvas
coords, but `_SOURCE`d the raw apron buffer → "wand fails / selects a jagged wrong region
after a paste/move cycle." A FRESH wand works (no apron yet); it only fails AFTER a cycle
that promotes an apron — that's the signature.

**Fix pattern:** when `apronW%>0 OR apronH%>0`, `_PUTIMAGE` the canvas-sized window OUT of
the apron buffer into a fresh canvas-sized copy, point `_SOURCE` at the copy so all coords
are canvas coords again, and `SAFE_FREEIMAGE` it at EVERY exit path. Commit `4c2b7d01`.

**Still-latent suspects (NOT fixed — audit if a similar bug reports):** the merged-read
wand variants `MAGIC_WAND_select_merged` and `MAGIC_WAND_select_all_color_merged` in the
same file. They likely read a canvas-sized COMPOSITE (not the raw layer buffer) so are
probably unaffected — but confirm before trusting. Any new tool that does
`POINT`/`_MEM`/pixel-scan on `LAYER_current_image&` at canvas coords is a candidate.

Offscreen note: this workflow (wand→copy→paste→move→deselect→wand) canNOT be driven under
the Xvfb QA harness (marquee copies come back empty, wand clicks land on transparent).
Guarded at source instead: `QA/tests/paste-move-wand-source-guards.sh`. Related:
[[feedback_destructive_in_place_transforms]] (scale the wand mask alongside content).

[Linux] Observed on Linux; the bug is platform-agnostic (coord math, no OS APIs).
