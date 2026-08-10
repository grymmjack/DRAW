---
name: qb64pe-reserved-words
description: QB64-PE rejects common identifier names like pos — "Name already in use"
metadata:
  type: reference
---

QB64-PE reserves a lot of ordinary-looking words. Using one as a variable,
parameter or field name fails at compile with:

```
Name already in use (pos)
Caused by (or after): FUNCTION Foo% (t AS STRING, pos AS INTEGER)
```

Confirmed the hard way with `pos` (the `POS` function) as a SUB parameter on
QB64-PE 4.5.0. Others that collide: `palette`, `screen`, `color`, `scale`,
`step`, `timer`, `width`, `height`, `key`, `line`, `point`, **`sub`** (the SUB
keyword → error "Expected (" with a weird `SUB = ...` line), **`name`** (the
NAME file-rename statement → "Name already in use (name)"), `type`, `out`.

Prefix or qualify instead: `atPos`, `srcPalette`, `winWidth`, `subDir`, `impName`.

Also not a reserved word but a wrong-name trap: the environment reader is
**`ENVIRON$(v$)`**, NOT `_ENVIRON$` — the underscore form fails with the
misleading "Invalid array name".

Cheapest way to catch it: compile a 6-line standalone file using the name
before wiring it into a large project — a full DRAW build is ~5 minutes, the
probe is seconds. Related: [[qb64pe-logic-operators]].
