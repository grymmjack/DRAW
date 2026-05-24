---
name: feedback-hotkey-grep-sweep
description: DRAW hotkeys are scattered across many SUBs and inline blocks (no central dispatch table). Before adding any new chord involving a letter or arrow key, grep _KEYDOWN(<keycode>) AND SELECT CASE "<letter>" across the whole file to find every existing handler that could conflict.
metadata:
  type: feedback
---

DRAW does NOT have a single keyboard dispatch table. Hotkey handlers live in many places:

- `KEYBOARD_tools` (INKEY$-based tool switches: B, F, D, L, P, R, C, E, M, W, V, T, Z)
- `KEYBOARD_layers` (Ctrl+Letter layer ops, Ctrl+Shift+[/], Ctrl+Home/End originally)
- `KEYBOARD_colors` (1-0 opacity)
- Inline blocks inside `KEYBOARD_input_handler` for everything else: Ctrl+R = REFIMG_toggle, Ctrl+Alt+R = random palette, Ctrl+Shift+? = grid-from-brush, Ctrl+Shift+Q = export QB64, etc.
- Special context handlers: text-tool char mode, image-import preview, file-dialog input, etc.

**Why this matters:** Verbatim from grymmjack when the G+R chord first shipped: *"it isn't working. it's loading a reference image."* I'd added `IF GRID_G_KEY_ARMED% THEN EXIT SUB` to `KEYBOARD_tools` but missed the Ctrl+R handler at `INPUT/KEYBOARD.BM:2507`, which fires independently on Ctrl+R regardless of what `KEYBOARD_tools` does. Same shape happened earlier with Ctrl+Home/End layer-arrange conflict.

**How to apply** before adding a chord involving letter `X` or key code `K`:

1. `grep -nE '_KEYDOWN\(<K>\)|_KEYDOWN\(<K+upper-lower offset>\)' INPUT/KEYBOARD.BM` — find every inline block. For letters, both lowercase (97-122) and uppercase (65-90) ASCII codes appear because `_KEYDOWN` reports the current case.
2. `grep -nE 'CASE "x", "X"' INPUT/KEYBOARD.BM` — find the tool-switch case if there is one.
3. For Ctrl-modified chords: check the inline blocks for `MODIFIERS.ctrl%` + your keycode.
4. For each conflicting handler, add `AND NOT <your-chord-armed-flag>` (e.g. `AND NOT GRID_G_KEY_ARMED%`) to its gate condition, OR add an early-exit at the SUB top if the chord initiator is held.

Doing this sweep ONCE up front saves the "ship → bug report → fix one more → ship → bug report" cycle. The reference for the G-chord pattern is in `INPUT/KEYBOARD.BM` lines ~3147-3290 (G-armed flag + chord block) and the suppressions at lines 2507 (Ctrl+R) and `KEYBOARD_tools:80` (early exit).

Related: [[feedback-destructive-in-place-transforms]] (for the HISTORY group pattern that goes alongside any hotkey that bundles changes).
