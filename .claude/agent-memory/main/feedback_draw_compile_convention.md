---
name: feedback-draw-compile-convention
description: "When compiling DRAW (qb64pe / make), always use foreground + 600000ms timeout so the user sees streaming output and the compile is not killed early."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5d441d41-d017-4658-8146-6ebf42a81f5f
---

For any DRAW build/compile command (`make`, `make run`, `make run-logged`, direct `qb64pe -x ... DRAW.BAS`, MCP `compile_and_verify_qb64pe`), always:

1. Run **foreground** — `run_in_background: false` (the default). Do NOT use `run_in_background: true` for compiles.
2. Set an explicit **`timeout: 600000`** (10 min, the Bash tool max). The default 120s has killed in-progress DRAW compiles.
3. Prefer `make run-logged` when the user is actively watching, since it also writes `DRAW.log` they can `tail -f` in a side terminal.

**Why:** DRAW transpiles QB64-PE → C → native, which is slow on a codebase this size. A prior session ran the compile in the default 120s window, the harness killed it, and I re-ran it — wasted minutes of compile work. Background mode also hides the live output from the user in VSCode (their words: "I can't see them in a terminal or anything"), so foreground is what they want even though it blocks my next tool call.

**How to apply:** Before any Bash call that invokes the QB64-PE compiler against DRAW.BAS, set `timeout: 600000` and leave `run_in_background` unset (defaults to false). If I genuinely need to do other work in parallel during a compile, ask the user first rather than silently backgrounding.

Related: [[reference-draw-activity-log]] — the activity-log hook surfaces the timeout marker `[timeout=600000ms]` in `.claude/activity.log`, so if a START entry is missing that marker, the convention has slipped.
