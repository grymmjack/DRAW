---
name: feedback-qb64pe-dynamic-dim-shared
description: With `$DYNAMIC` set, `DIM SHARED arr(0 TO N) AS T` at module level does NOT allocate the array. Reading any element before the first write crashes "Subscript out of range". `ERASE arr` actively deallocates it again. Force allocation in an init routine, and never ERASE if you want to keep using it.
metadata:
  type: feedback
---

DRAW sets `$DYNAMIC` at the top of every `.BAS` file (CLAUDE.md), so
arrays default to dynamic allocation. Under `$DYNAMIC`:

- `DIM SHARED arr(0 TO 65535) AS LONG` at module level **does not
  allocate** the array. The declaration only reserves the symbol.
- Reading `arr(0)` before any write crashes with
  `Runtime error: Unhandled Error #9 — Subscript out of range`.
- The first WRITE to `arr(x)` triggers allocation of the whole array.
- `ERASE arr` is destructive under `$DYNAMIC` — it DEALLOCATES the
  array. The next read crashes again.

**How to apply:**
- Allocate SHARED dynamic arrays in your `_init` SUB with an explicit
  fill loop:
  ```
  DIM i AS LONG
  FOR i = 0 TO 65535
      arr(i) = 0
  NEXT i
  ```
- For per-frame "clear and reuse" patterns, do NOT use ERASE on a
  SHARED array. Either:
  - Track which slots were touched and clear only those; or
  - Use a version-counter pattern (store the frame number written;
    "set this frame" iff stored == current frame) and skip ERASE
    entirely.

Caught in commit `<this commit>` after the SHARED-with-ERASE fix
(commit 3493f3c) for the dispatcher double-fire bug crashed every
test. The runtime error was at the array read site, but the root
cause was `ERASE INPUT_KC_ENQUEUED` deallocating the array on the
preceding line. Switched to a `LONG` version-counter array
(`INPUT_KC_ENQUEUED(kc) == INPUT_KC_FRAME` means "enqueued this
frame") plus an init-time fill loop.

Related:
- [[feedback-qb64pe-not-is-bitwise]] — sibling QB64-PE semantic
  gotcha for `NOT`.
- [[reference-input-system]] for the input dispatcher specifically.
