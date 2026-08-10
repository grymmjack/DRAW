---
name: qb64pe-shared-dynamic-udt-array
description: Declare a shared dynamic array-of-UDT with REDIM SHARED, not DIM SHARED () AS UDT
metadata:
  type: reference
---

[QB64-PE] To share a **dynamic array of a UDT** across modules, declare it in the `.BI` with
`REDIM SHARED name(0, 0) AS SOME_TYPE` (seed dimensions, grown later), **not**
`DIM SHARED name() AS SOME_TYPE`.

With the `DIM SHARED () AS UDT` form, a SUB that only *reads* the array fails to compile with
`Array 'NAME' (SINGLE) not defined` — QB64 treats the bare reference as an implicit SINGLE array
under `OPTION _EXPLICITARRAY`, because the module-level declaration didn't register the type. A SUB
that `REDIM ... AS UDT`s it compiles (the inline `AS UDT` re-declares), which makes the failure look
like it's only in the reader — misleading.

DRAW's own convention confirms this: every shared dynamic UDT array uses `REDIM SHARED` in its `.BI`
(e.g. `TOOLS/EXTRACT-IMAGES.BI` `REDIM SHARED EXTRACT_COMPS(0) AS EXTRACT_COMPONENT_OBJ`,
`TOOLS/MOVE.BI`, `PIXEL-COACH/COACH.BI`). Inside SUBs, resize with `REDIM [_PRESERVE] name(...) AS UDT`.
Hit while adding the ANSI cell grid (`OUTPUT/FILE-ANS.BI` `REDIM SHARED ANS_CELLS(0,0) AS ANS_CELL`).

Related: [[qb64pe-reserved-words]], [[feedback_draw_compile_convention]].
