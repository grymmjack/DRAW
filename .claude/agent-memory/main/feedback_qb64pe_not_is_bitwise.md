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

Related: [[reference-input-system]] for the input dispatcher specifically.
