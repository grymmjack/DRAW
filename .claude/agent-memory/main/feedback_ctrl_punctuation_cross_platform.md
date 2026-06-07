---
name: feedback_ctrl_punctuation_cross_platform
description: Ctrl+punctuation hotkeys (e.g. Ctrl+, for Settings) need BOTH _KEYDOWN(ascii) and _KEYHIT VK detection — a Windows-only fix using _KEYHIT alone silently breaks Linux/macOS
metadata:
  type: feedback
---

Ctrl+**punctuation** keys are reported differently per platform, so a handler must detect them BOTH ways or it silently dies on one OS:

- **[Windows]** SDL/QB64 SUPPRESSES the comma's ASCII while Ctrl is held → `_KEYDOWN(44)` stays FALSE; the key only arrives via `_KEYHIT` as the virtual-key code (comma = **188** / VK_OEM_COMMA, delivered as ±188). See [[windows-dpi-and-ui-scale]].
- **[Linux/macOS]** `_KEYHIT` is unreliable for Ctrl+combos (CLAUDE.md gotcha #6) and may never report the key, but `_KEYDOWN(44)` IS reliable while held.

**Why:** commit f88b191 fixed Ctrl+, Settings on Windows by (a) flipping the central INPUT.BM binding for `ACTION_SETTINGS` to `dispatched=FALSE` and (b) adding a manual `KEYBOARD_input_handler` check using ONLY `LAST_KEYHIT_RAW& = 188 OR -188 OR 44`. That disabled the central dispatcher's reliable `_KEYDOWN(44)` edge path ([INPUT/INPUT.BM:884](../../../INPUT/INPUT.BM#L884)) — which is what made it work on Linux — and the `_KEYHIT`-only replacement never fires on Linux. Net: Ctrl+, opened Settings on Windows but went dead on Linux.

**How to apply:** in any Ctrl+punctuation handler, OR both detectors together — `_KEYDOWN(<ascii>) OR LAST_KEYHIT_RAW& = <VKcode> OR -<VKcode> OR <ascii>` — gated by the modifier, with a STATIC edge guard (since `_KEYDOWN` is level-triggered) that re-arms in an outer ELSE when the combo isn't held. Fixed for Settings at [INPUT/KEYBOARD.BM:3148](../../../INPUT/KEYBOARD.BM#L3148). Probe codes per platform with [DEV/keytest.bas](../../../DEV/keytest.bas). Related: [[reference_input_system]], [[feedback_hotkey_grep_sweep]].
