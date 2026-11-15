---
name: qb64-hex-literal-sign-extend
description: Unsuffixed QB64 hex CONSTs with the top bit of 16/32 set are negative and sign-extend - a 64-bit flag constant like &H...8000 becomes FFFFFFFFFFFF8000
metadata:
  type: feedback
---

An unsuffixed QB64-PE hex literal takes the smallest type that holds its digits, signed:
`&H0000000000008000` is the INTEGER -32768, so as an `_UNSIGNED _INTEGER64` it is
`FFFFFFFFFFFF8000` - every bit from 15 up. (Same trap at bit 31: `&H80000000` is a
negative LONG.) Leading zeros do not change the type. Suffix 64-bit flag constants:
`&H0000000000008000&&`. Verified with a probe on Linux (QB64-PE v4.6); the rule is the
compiler's, so it holds on every OS.

**Why:** CTX_FILL_ACTIVE (INPUT/INPUT.BI, bit 15) shipped unsuffixed on 2026-11-15. As a
forbid-context on the W binding it matched CTX_OVER_CANVAS (bit 32) and the rest, so W
stopped picking the Magic Wand over the canvas; apron-selection-ops caught it (wand E/F
modifiers fell through to the Eraser / Fill keys). Bits 0-14 and 16-30 are safe unsuffixed.

**How to apply:** any new `CTX_*` / flag CONST at bit 15, 31 or 63 gets `&&` (or `~&&`).
Probe a literal with a 6-line `$CONSOLE:ONLY` program and `PRINT HEX$(u)` into an
`_UNSIGNED _INTEGER64` (it waits for a key at exit - run it with `</dev/null` and a timeout).
