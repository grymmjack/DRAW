---
name: qb64pe-macos-numpad-digits
description: [macOS] QB64-PE gives keypad digits no codes of their own - KP_0 is plain 48, so DRAW's numpad frame keys (INPUT/NUMPAD) can't work on a Mac; KP_Add / Enter / * / / do
metadata:
  type: project
---

[macOS, observed 2026-11-17 on the farm Mac, QB64-PE main-repo GLFW build] A 9 s QB64 probe
(`_KEYHIT`, `INKEY$`, `_KEYDOWN` 100256-100290 / 200000-200030 / 48 / 53 / 20992) driven by
qa-io keycode 0x52 (KP_0) and 0x57 (KP_5):
- KP_0 -> keyhit 48, inkey "0", `_KEYDOWN(48)`; **no** `_KEYDOWN(100256+n)` or `(200000+n)`. Same
  with the CGEvent NumericPad flag set, and with QB64-PE's emulated Num Lock toggled on (keypad
  Clear = keycode 0x47 -> keyhit 100300). A real keypad goes through the same Cocoa char path.
- KP_Add -> keyhit 43 **and** `_KEYDOWN(100270)`: the operator keys do get their numpad codes.
- QB64-PE source: internal/c/libqb/src/keyboard.cpp - digits become VK+QBVK_KP0+n / QBK+n only on
  the key path; on macOS the char callback ("0") wins. glut-emu.cpp:1854 emulates Num Lock on macOS.

So on a Mac DRAW's numpad frame keys (Num 0 lightbox, Num 1-9 frames, Num 8 X-sheet ...,
INPUT/NUMPAD, ported from bu1ld0r) read as main-row digits (layer opacity). 97 QA tests press
keypad digits; they carry a [macOS] known-failures entry. The laptop / Alt frame keys are the
Mac way until QB64-PE reports the digits (Rick to decide whether to raise it with a740g).

Before this, the macOS and Windows qa-io had **no KP_ keys at all** (the tests' KP presses were
silently dropped on both). Added 2026-11-17: KP_0..9, KP_Add/Subtract/Multiply/Divide/Decimal/
Enter (+ Num_Lock / Clear on macOS). [Windows] works: scan codes reach GLFW as KP_* (anim-cycling-
frames passed checks it never could before). Installed on mac (~/.qa-runner/bin/qa-io, old kept
as qa-io.prekp) and thinkpad (C:\qa-runner\bin\qa-io.exe, old qa-io.prekp.exe); in ~/git/qa-harness
uncommitted. Related: [[farm-qa-environment-gaps]], [[keyhit-drained-after-render]].
