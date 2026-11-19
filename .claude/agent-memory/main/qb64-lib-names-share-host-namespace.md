---
name: qb64-lib-names-share-host-namespace
description: A QB64-PE library's SUB/FUNCTION locals, params and routine names share one case-insensitive namespace with the host program's CONSTs, SUBs and globals - prefix every lib local/param (mx..., not s / x) and never name a SUB like a CONST
metadata:
  type: feedback
---

Seen building QB64_GJ_LIB/MOUSE_PRESSURE (2026-11-18, untagged: QB64-PE language rule, any OS):
- SUB `MEXP_wheel` clashed with `CONST MEXP_WHEEL` -> "Name already in use" (names are
  case-insensitive, suffixes don't separate them). Renamed to `MEXP_scroll`.
- A library local `s` clashed with the unit test's `FUNCTION S$` -> the same error, but only
  in the host that defined `S$`. So a lib can compile in its own example and break in a consumer.
- Passing an INTEGER variable to a SINGLE BYREF param fails to compile - wrap it in `CSNG()`.

**Why:** QB64 has no module scope; an included lib's names collide with whatever the host defines.
**How to apply:** in any `includes/QB64_GJ_LIB/**` module, prefix every local and parameter with a
short module tag (`mxX#`, `mxN%`), and keep SUB / FUNCTION names distinct from the module's CONSTs.
Related: [[feedback-qb64-gj-lib-no-consumer-helpers]].
