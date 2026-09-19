---
name: draw-debug-build-cost
description: Why F5 (qb64pe-vscode debugger) build is ~9 min / single-core — flattened whole-program + $DEBUG = one monolithic C++ TU. MaxCompilerProcesses & OptimizeCppProgram do NOT help it.
metadata:
  type: reference
---

**[Linux] The F5 debugger build is inherently slow (~9 min for DRAW, measured 545.6s
2026-09-19), and it's NOT the same as a normal build.** Root cause pinned from htop +
`~/git/qb64pe/internal/temp/compilelog.txt`.

**What F5 does now:** default F5 = qb64pe-vscode `QB64DebugSession` (NOT `tasks.json`).
It flattens every `$INCLUDE` into `.DRAW.debug.BAS` (a temp copy, ~182k lines), appends
`$DEBUG`, and compiles that. Flatten is order-faithful (see
[[draw-multidim-array-reorder-compile-speed]]).

**Why it's slow — evidence:**
- compilelog has **only 2 g++ commands**: one COMPILE, one LINK. The compile builds
  `internal/c/qbx.cpp`, which `#include`s `temp/main.txt` (= the ENTIRE flattened program +
  `$DEBUG` instrumentation) as **one monolithic translation unit** → `qbx.o`.
- One TU ⇒ single `cc1plus` pegs ONE core; the other 11 sit idle (htop: load avg ~1.85,
  one core 100%). **`-f:MaxCompilerProcesses=12` cannot help** — you can't split one C++ file.
- The g++ compile command has **NO `-O` flag** (already unoptimized) ⇒
  **`-f:OptimizeCppProgram=false` does nothing** for it. (I wrongly guessed this was the lever;
  the log disproved it.)
- libqb runtime `.o` files ARE cached (just linked at the link step) — not rebuilt. Only the
  program TU (`qbx.o`) rebuilds, which is unavoidable since the program changed.
- The 2× vs a normal build (~4:25) is `$DEBUG` bloat: instrumenting all 182k flattened lines
  ~doubles the single-TU size. `$DEBUG` is global/mandatory for breakpoints — can't scope it.
- The "3 progress bars" = normal QB64-PE **multi-pass transpiler** (forward-ref/SUB-signature
  resolution), NOT 3 builds and NOT a reorder regression (the 2 multi-dim funcs are ordered
  right → 0 extra array passes). PR #778 already minimizes array repasses.

**So the ONLY real levers (all workflow, not flags):**
1. The launcher's `tryUseCachedBuild` already makes an UNCHANGED relaunch instant (byte-identical
   flattened source reuses the exe). Pain is only the first build after an edit.
2. For normal iteration, DON'T use the debugger — use the fast non-`$DEBUG` `tasks.json`
   "EXECUTE: Run" build (~4:25). Reserve F5/debugger for actual step-through.

Don't re-recommend MaxCompilerProcesses or OptimizeCppProgram for the debug build — ruled out
here. Related: [[draw-build-speed]] (the `-O` lever applies to NORMAL builds, where -O IS on),
[[feedback-vscode-task-for-draw-build]].
