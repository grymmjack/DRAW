---
name: feedback-qb64pe-not-is-bitwise
description: QB64-PE's NOT operator is bitwise, not boolean. `NOT 1` returns `-2` (still truthy!), so `IF NOT x THEN` only works correctly when `x` is exactly 0 or -1. For non-boolean flags, always write `IF x = 0 THEN` or `IF x THEN`.
metadata:
  type: feedback
---

QB64-PE NOT is a bitwise complement, inherited from QuickBASIC. It does
NOT do boolean negation in the C/Python sense:

```
NOT 0  = -1   (truthy)
NOT 1  = -2   (truthy!)
NOT -1 =  0   (falsy)
NOT 5  = -6   (truthy)
```

So `IF NOT x THEN ...` does what you expect only when `x` can only be 0
or -1 (i.e., the result of a comparison like `x = TRUE`). For any flag
that takes integer values (a counter, a one-shot marker like 1 to mean
"yes"), `IF NOT x THEN ...` will succeed for almost every non-zero value.

**Why:** QB64 inherits QuickBASIC semantics where NOT is the bitwise
complement of an INTEGER. There is no separate boolean type.

**How to apply:** when checking a flag for "is this set?", use the
explicit comparison:
- `IF flag = 0 THEN`     — "flag is not set"
- `IF flag <> 0 THEN`    — "flag is set"
- `IF flag THEN`         — "flag is set" (works because any non-zero is truthy)

NEVER use `IF NOT flag THEN` unless `flag` is the result of a comparison
that returns exactly 0 or -1.

Caught in `4644c53` — the double-fire fix in INPUT_detect_events used
`IF NOT kcEnqueued(kc&) THEN` first, which silently bypassed the dedup
every time (because NOT 1 = -2 ≠ 0 = truthy). Replaced with
`IF kcEnqueued(kc&) = 0 THEN` and the dedup worked correctly.

Pre-existing code in DRAW uses `IF NOT pressed%` only for STATIC INTEGER
flags that hold exactly TRUE (-1) or FALSE (0) — those work fine because
the values are always exactly -1 or 0. Be careful when introducing flags
that hold positive small values (1, 2, ...) — they break the idiom.

**CFG fields loaded from DRAW.cfg are the highest-risk case, and it bit us
again on 2026-08-01.** `CFG.X% = VAL(configValue$)` on a cfg line written as
`X=1` stores **1**, not -1 — so `IF NOT CFG.X% THEN EXIT` exits when the
feature is ON. It's especially nasty because it works during development: with
no line in the user's cfg, the field keeps its compiled-in `= TRUE` (-1)
default and `NOT` behaves. The bug only appears once the key is actually
written to a config file. `PALETTE_MENU_SHOW_CHIPS` shipped this way and the
chips silently never rendered under the QA config.

Two rules for any new CFG boolean:
1. Normalize on load — `CFG.X% = (VAL(configValue$) <> 0)` yields -1/0, which
   is also what `MENU_ITEMS().checked%` expects.
2. Never toggle with `CFG.X% = NOT CFG.X%`. With a value of 1 that flips
   1 → -2 → 1, both non-zero, so the toggle never turns the feature off.
   Write the explicit `IF CFG.X% = 0 THEN CFG.X% = TRUE ELSE CFG.X% = FALSE`.

Related: [[reference-input-system]] for the input dispatcher specifically,
[[reference_qa_harness_capture]] — the QA config is what exposed this class of
bug, because it writes every key explicitly instead of relying on defaults.
