---
name: feedback-qb64pe-no-declare-sub-function
description: QB64-PE auto-discovers SUBs and FUNCTIONs from anywhere in the include chain — `DECLARE SUB` and `DECLARE FUNCTION` are legacy QuickBASIC cruft and add no value. ONLY `DECLARE LIBRARY ... END DECLARE` (and its `DECLARE DYNAMIC LIBRARY` / `DECLARE STATIC LIBRARY` variants) are still required, because those define FFI bindings rather than forward references.
metadata:
  type: feedback
---

In old QuickBASIC, `DECLARE SUB`/`DECLARE FUNCTION` was mandatory before
a SUB/FUNCTION call because the compiler was single-pass. QB64-PE is
multi-pass and auto-discovers SUBs and FUNCTIONs from the entire
include chain (every `.BI` / `.BM` / `.BAS` reachable from the main
`.BAS`). Adding `DECLARE SUB Foo` declarations is pure noise.

**Apply:** when authoring new DRAW code or editing existing `.BI`
files, do NOT write `DECLARE SUB` / `DECLARE FUNCTION`. Let QB64-PE
auto-discover the routines from their `.BM` definitions.

**Do keep:**

- `DECLARE LIBRARY ... END DECLARE` (FFI to system C libraries)
- `DECLARE DYNAMIC LIBRARY ... END DECLARE`
- `DECLARE STATIC LIBRARY ... END DECLARE`

These are NOT forward references — they're extern declarations for
non-QB64-PE code, and the compiler can't auto-discover them.

**Caveat — submodule exception:** the vendored `includes/QB64_GJ_LIB/`
submodule may contain its own `DECLARE SUB` / `DECLARE FUNCTION`
statements. **Do not strip those** — they're part of the library's
own conventions, used by other consumers, and the lib repo controls
its own style. See [[feedback-qb64-gj-lib-no-consumer-helpers]].

**Caught & fixed:** commit `<this commit>` removed 32 DECLAREs from
DRAW (`CORE/HELPERS.BI`: 12, `INPUT/INPUT.BI`: 20). Zero `DECLARE
LIBRARY` blocks existed in DRAW so nothing needed to be preserved
beyond the rule itself. Build + audit + runtime all clean post-removal.
