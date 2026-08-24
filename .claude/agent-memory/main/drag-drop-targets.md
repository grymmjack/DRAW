---
name: drag-drop-targets
description: How DRAW's target-aware file drag-and-drop routes a dropped image by which UI region it lands on
metadata:
  type: project
---

DRAW's improved drag-and-drop (branch `drag-drop`, `INPUT/DROP.BM`) routes a dropped
file by **which UI region the cursor is over at drop time**. Full guide:
`.claude/instructions/draw-drag-drop.md`; design + anchors: `PLANS/DRAG-DROP-PLAN.md`.

**The hard constraint:** [Linux] QB64-PE's OS file-drop exposes only the file list —
**no drop x/y**. The workaround is to read `MOUSE.RAW_X%/RAW_Y%` at the drop frame (the
cursor sits at the drop point) and hit-test with `REGION_hit_test%` (same logical-pixel
space). If a platform reports a stale cursor pos at drop time, routing breaks — a per-OS
manual check is the only way to confirm (see [[qb64pe-acceptfiledrop-cross-platform]]).

Targets: **canvas** → stamp current layer (destructive, undoable via `HISTORY_record_brush`
before-snapshot); **layer panel** → new layer (`DROP_place_on_new_layer`, mirrors
`LAYERXFER_add_layer%` undo discipline — see [[multi-instance-support]]); **brush bin /
drawer** → custom brush in next free slot, full bin starts a new blank page after
auto-saving a dirty set; **menu bar** → open in a new isolated instance
(`INSTANCE_launch_new_with_file`). Shift centers on canvas, else top-left; images larger
than the canvas always use the interactive Import workflow. Apron-map canvas coords with
`LAYERS_canvas_to_buf_x%/y%` (gotcha #14). Reserved-word / `NOT`-is-bitwise care per
[[feedback_qb64pe_not_is_bitwise]].

OS drops can't be synthesized headlessly, so `QA/tests/drag-drop-targets.sh` is a smoke +
source-route regression guard only; real verification is a manual per-OS fleet pass.
