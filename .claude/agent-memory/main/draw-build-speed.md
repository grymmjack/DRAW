---
name: draw-build-speed
description: DRAW dev builds — skip C++ -O for a ~13min→~7min win. `qb64pe -x DRAW.BAS -o DRAW.run -f:OptimizeCppProgram=false`. The cost is g++ optimizing qbx.cpp (QB64-PE runtime) + the one giant generated .cpp; both are single units so MaxCompilerProcesses barely helps. OPEN: qbx.o is rebuilt every build here (cache not reused) — potential bigger win if fixed.
metadata:
  type: reference
---

**[Linux] DRAW build is slow because of C++ `-O` optimization, not the transpile.** (2026-09-04.)

A qb64pe build = **transpile** BASIC→C++ (~1-2 min; the progress bar) then **g++** compile+link
(the bulk). The g++ cost is optimizing two big single-compilation-units:
1. QB64-PE's own runtime `internal/c/qbx.cpp` (libqb: audio/image/GLFW/etc.), and
2. the ONE giant generated `.cpp` from DRAW's whole ~170k-line program.
Because both are single units, **`-f:MaxCompilerProcesses` barely helps** (nothing to parallelize).

**Dev-build win (measured):**
```
qb64pe -x DRAW.BAS -o DRAW.run -f:OptimizeCppProgram=false
```
→ **~13 min → ~7 min** (skips `-O` on qbx.cpp + the generated .cpp). Ship/release builds DROP the
flag (keep `-O`). Runtime perf of an unoptimized dev binary is irrelevant for editor testing.

**OPEN / potential bigger win:** `internal/c/qbx.cpp` (the runtime) is recompiled on EVERY build
here — the `qbx.o` cache is NOT being reused, so every build pays the multi-minute runtime compile.
Suspect the per-compilation `-f:` temp flags differ from the persistent settings and invalidate the
cache. If the runtime could be compiled ONCE and reused (stable flag set, or a persisted setting),
dev builds could drop well below 7 min (only the generated `.cpp` recompiles). Investigate:
`internal/c/qbx.o` reuse conditions; whether the plain Makefile default (no `-f`) reuses it.

**Related — `-z` is NOT a faster syntax gate** (see [[qb64pe-z-fast-gate]]): a failing `-x` aborts
during transpile just as fast as `-z` (never reaching g++), so for catching errors just run `-x`.
Use the instant Layer-B regex ([[feedback-lint-not-build]]) while typing; full `-x` when you need a
binary. Zero-warnings still applies ([[feedback-zero-warnings-build]]).
