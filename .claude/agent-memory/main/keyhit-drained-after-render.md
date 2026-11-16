---
name: keyhit-drained-after-render
description: DRAW.BAS's per-frame k& = _KEYHIT almost never sees a key - KEYBOARD_input_handler_loop drains _KEYHIT after every render; read keys from INKEY$ / _KEYDOWN edges
metadata:
  type: project
---

`KEYBOARD_input_handler_loop` (INPUT/KEYBOARD.BM, post-render) drains `_KEYHIT` every frame,
and the Ctrl/Alt branch of `KEYBOARD_input_handler` drains it too. So the `k& = _KEYHIT` at the
top of the DRAW.BAS loop only catches keys that land in the short gap between that drain and the
next frame start. In a 25-key QA run it saw 2 keys. DRAW really reads keys through INKEY$ (a
separate queue) and `_KEYDOWN` edges (the INPUT dispatcher).

Found 2026-11-07 (Animation 1.4): numpad frame keys hooked on DRAW.BAS's `_KEYHIT` never fired.
Fix: fire from `_KEYDOWN` / device-queue edges in `NUMPAD_poll`, and drop the INKEY$ twin
(TOOLS/ANIM-VIEW `ANIM_numpad_tick` / `ANIM_numpad_code%`).

Also: a raw `xdotool key alt+period` is too quick for `_KEYDOWN` polling. Use the harness `key`,
which holds the modifier first.

**Why:** cost a debug round (file-log probes) to find out why no key reached the hook.
**How to apply:** never put a new key hook on DRAW.BAS's `k&`. Use a `_KEYDOWN` edge (or a
dispatcher binding) and filter INKEY$ in KEYBOARD_input_handler. Related: [[reference_input_system]].
