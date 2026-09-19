---
name: draw-multidim-array-reorder-compile-speed
description: Define 2D+ open-array-param SUB/FUNCTIONs after a call site to avoid QB64-PE transpiler recompile passes; 1D never matters
metadata:
  type: project
---

[Linux] Compile-speed rule from mkilgore's (offbyone's) DRAW patch `f307ac0` +
QB64-PE PR #778 (`compiler-speedup` branch at `~/git/qb64pe`, HEAD `67ed34495`
"Only recompile when an array dimension can actually be resolved").

**Rule:** a `SUB`/`FUNCTION` taking an **open multi-dimensional array param**
(`matrix() AS INTEGER` used `matrix(x,y)`) must be **defined AFTER at least one
call site** in compile order. The transpiler learns an open array's dimension
count only from a call site; if the definition is compiled first it emits
wrong-dimension C++ then does a full recompile pass. Reordering below a call site
avoids that. Paired with PR #778 it roughly halves transpile time.

**1D open arrays do NOT matter** — they're never "pinned" (`nelereq = 0`), so the
compiler's `resolvable` counter stays 0 and it never recompiles for them. Only
genuine 2D+ params are candidates.

**Current DRAW state:** the ONLY two 2D+ open-array-param routines are already
ordered correctly (both fixed by mkilgore): `GJ_IMGADJ_ApplyOrderedMatrix&`
(`GUI/IMGADJ.BM`, below its `DitherOrdered2x2/4x4` callers) and
`EXTRACT_save_component` (`TOOLS/EXTRACT-IMAGES.BM`, below `EXTRACT_progress_dialog`).
A full sweep found 26 other open-array routines but all 1D → not candidates. Only
worry about this when adding a NEW 2D+ open-array param routine.

**Flatten safety:** the F5 debugger's flattened build (`.DRAW.debug.BAS`) preserves
this ordering — `qb64pe-vscode`'s `flatten` (`src/core/flatten.ts`) is faithful
depth-first `$INCLUDE` expansion, no hoisting/sorting. Verified: defs stay after
their call sites in the flattened file.

Documented as gotcha #29 in `.claude/instructions/draw-project.md`. Related:
[[draw-build-speed]], [[qb64pe-z-fast-gate]], [[feedback-lint-not-build]].
