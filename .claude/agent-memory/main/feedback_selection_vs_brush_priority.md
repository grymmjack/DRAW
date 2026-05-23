---
name: feedback-selection-vs-brush-priority
description: For hotkeys with competing targets (selection, brush, layer), prefer SELECTION > BRUSH > WHOLE LAYER. Require both ACTIVE flag and valid IMAGE handle to consider a brush truly active (the ACTIVE flag can linger after the buffer is freed).
metadata:
  type: feedback
---

When a single hotkey could plausibly target multiple things (selection, custom brush, current layer), priority order is:

1. **Selection on layer** (`SELECTION_has_active%` + valid `LAYERS(CURRENT_LAYER%).imgHandle&`)
2. **Custom brush** (`CUSTOM_BRUSH_is_active%` **AND** `CUSTOM_BRUSH.IMAGE& < -1`)
3. **Whole current layer**

**Why:** Discovered while building Ctrl+Home/End scale-2x. The user had a Mario brush loaded *and* a marquee from SELECTION FROM LAYER. With brush-first priority, the brush branch always won and the selection scale never fired — but the user's mental model was *"the selection is what I just created on purpose; the brush is persistent state."* User's verbatim summary: *"this should happen universally, even if no selection is present, just whatever is on the current layer, or the selected part of the current layer, either way."*

Also: `CUSTOM_BRUSH.ACTIVE%` returns TRUE from a previous brush load even after the IMAGE buffer is freed. The existing `CUSTOM_BRUSH_is_active%` function (`CUSTOM-BRUSH.BM:70-72`) only checks the ACTIVE flag — it can linger stale. Always pair with `CUSTOM_BRUSH.IMAGE& < -1`.

**How to apply:**
- In any new hotkey dispatcher that touches both brush and selection/layer: use the 3-tier IF/ELSEIF order above.
- The existing uniform 2× scale (`CASE 318` in [GUI/COMMAND.BM](GUI/COMMAND.BM)) puts **brush first** — that ordering is OK there because CASE 318 has no default hotkey and is only invoked from the command palette while explicitly looking at a brush. For *hotkey-triggered* dispatch (where it gets pressed reflexively right after creating a selection), invert to selection-first.
- The pattern is in `CASE 331` / `CASE 333` (Scale 2x H/V) in [GUI/COMMAND.BM](GUI/COMMAND.BM) as the canonical reference.

Related: [[feedback-destructive-in-place-transforms]] for the broader pattern these dispatchers fit into.
