---
name: feedback-lint-not-build
description: While iterating on DRAW code, LINT after edits instead of running a full ~10-min build every time; only full-build when a run/screenshot/test or human interaction is actually needed.
metadata:
  type: feedback
---

While iterating on DRAW source, prefer **linting** over a full compile on every change.

**Why:** a full `qb64pe -w -x DRAW.BAS -o DRAW.run` transpiles the whole ~170k-line
project and takes ~10 minutes. Rick (2026-09-04): "instead of building every time you
make a change can you possibly lint? then if the lint passes assume it will work unless
there is some interaction required or a test?"

**How to apply:**
- After edits, run the qb64pe MCP `lint` tool. Its **Layer B** regex rules are instant
  (`syntaxCheck:false`); its **Layer A** compiler `-z` syntax check is fast for small/
  standalone files but transpiles the whole project for the big entry `DRAW.BAS` — so use
  `syntaxCheck:true` only as a pre-commit/pre-run gate, not every keystroke.
- If lint passes, **assume it will work** and keep moving. Do a full `qb64pe` build ONLY
  when you actually need to (a) run/screenshot the app, (b) run a QA test, or (c) hand a
  binary to Rick to click.
- Batch multiple edits, then do ONE full build before the QA/screenshot step.

[Linux] Observed on Linux; applies to any OS (build cost is the same everywhere).
Related: [[feedback_vscode_task_for_draw_build]] (Rick's canonical build is VSCode F5).
