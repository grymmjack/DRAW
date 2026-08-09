---
name: qb64pe-logic-operators
description: QB64-PE AND/OR do not short-circuit and NOT is bitwise — use _ANDALSO/_ORELSE/_NEGATE instead
metadata:
  type: reference
---

QB64-PE's classic logic operators are **bitwise and eager**. Three modern
keywords fix that; all verified on QB64-PE 4.5.0 (Linux).

| Want | Do NOT use | Use |
|------|-----------|-----|
| Short-circuit AND | `AND` | `_ANDALSO` |
| Short-circuit OR | `OR` | `_ORELSE` |
| Logical NOT | `NOT` | `_NEGATE` |
| Inline conditional | — | `_IIF(cond, a, b)` |
| Boolean literals | hand-rolled `CONST TRUE = -1` | built-in `_TRUE` / `_FALSE` |

Also built in: `_LESS` = -1, `_EQUAL` = 0, `_GREATER` = 1 — the return domain of
`SGN`, `_STRCMP` and `_STRICMP`.

DRAW defines its own unprefixed `TRUE`/`FALSE` in `_COMMON.BI` behind
`$IF FALSE = UNDEFINED AND TRUE = UNDEFINED`. That does NOT collide with the
built-ins (different identifiers — no underscore) and evaluates to the same
0/-1, so it is correct, not broken. With ~7,300 uses across the codebase a mass
rename would be churn with no behavioural gain; prefer `_TRUE`/`_FALSE` in new
code and leave the existing ones alone.

Docs: <https://qb64phoenix.com/qb64wiki/index.php/ANDALSO> ·
[ORELSE](https://qb64phoenix.com/qb64wiki/index.php/ORELSE) ·
[NEGATE](https://qb64phoenix.com/qb64wiki/index.php/NEGATE) ·
[IIF](https://qb64phoenix.com/qb64wiki/index.php/IIF)

**Why it matters — both bite silently:**

`AND`/`OR` evaluate BOTH sides always, so a guard does not protect what
follows it:

```qb64
IF idx >= 1 AND arr(idx).field THEN   ' arr(idx) runs even when idx = 0
```

With `arr` DIM'd `(1 TO n)` that raises ERR 9 "Subscript out of range". Worse,
the global `ON ERROR` handler does `RESUME NEXT`, so the branch may then execute
anyway with a bad index — the IF result is unreliable, not just noisy.

`NOT` is bitwise, so it only behaves logically on exactly 0/-1:

```
NOT 0  = -1 (true)     NOT -1 = 0 (false)     NOT 1  = -2  ← STILL TRUTHY
```

Any `IF NOT someFunction%` is wrong when that function returns an id, count or
handle rather than TRUE/FALSE. `_NEGATE 1` = 0, `_NEGATE 7` = 0. Correct.

**Verify, don't assume** — a probe with `ON ERROR` + a counter settles it in
30 seconds. See [[qb64pe-reserved-words]] for the related name-collision trap.
