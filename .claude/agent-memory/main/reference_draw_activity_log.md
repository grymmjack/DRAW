---
name: reference-draw-activity-log
description: DRAW has two tailable observability logs — .claude/activity.log (every Bash/Agent tool call) and .claude/make.log (raw qb64pe compile output appended per build).
metadata: 
  node_type: memory
  type: reference
  originSessionId: 5d441d41-d017-4658-8146-6ebf42a81f5f
---

DRAW has two complementary log files the user tails in a side terminal to watch what's happening — they exist because VSCode's Claude Code panel does not surface output from `run_in_background: true` Bash calls (Copilot used to show "hidden terminals" for these).

## 1. `.claude/activity.log` — meta log of every tool call

Project-local, gitignored explicitly via `.claude/activity.log` in `.gitignore` (also covered by the `*.log` rule).

`.claude/settings.local.json` registers a `PreToolUse` + `PostToolUse` hook (`matcher: "Bash|Agent"`) that calls `.claude/hooks/activity-log.sh`. Each invocation appends a human-readable record:

- `=== <ts>  START Bash [BG] [timeout=Nms] ===` — pre-call: desc, cwd, full command verbatim (pre-rtk rewrite). `[BG]` marker when `run_in_background: true`; `[timeout=Nms]` when an explicit timeout was set.
- `--- <ts>  END Bash ---` — post-call: stdout/stderr truncated to ~80 lines / 8 KB, with `!! INTERRUPTED` marker if the call was killed.
- Same shape for the `Agent` tool (subagent type in the START line, agent response in the END).

Tail: `tail -f .claude/activity.log`.

Hook script: `.claude/hooks/activity-log.sh`. It MUST stay silent on stdout (Claude Code parses hook stdout as protocol JSON). Errors go to /dev/null; the script exits 0 even on internal failures so it never blocks tool calls.

## 2. `.claude/make.log` — raw qb64pe compile output

Project-local, gitignored explicitly via `.claude/make.log` in `.gitignore`. The Makefile's `$(OUT)` recipe is wired to `tee -a $(MAKE_LOG)` with `SHELL := /bin/bash` and `.SHELLFLAGS := -o pipefail -c` so compile failures still propagate (otherwise tee's exit code would mask qb64pe's). Every build appends a timestamped banner followed by the full qb64pe stdout+stderr.

Tail: `tail -f .claude/make.log`.

This is the log for *warnings* and *errors* from the QB64-PE → C transpile and the native link step — the things you can't see while a long compile is running but need to debug afterward.

## How to apply

No action needed during normal work — both logs fill automatically. Useful to remember when:

- User asks "what did you just run?" → point at `.claude/activity.log`.
- User asks "did that compile produce warnings?" or a build mysteriously failed → point at `.claude/make.log`.
- A long compile mysteriously dies → check `.claude/activity.log` for `!! INTERRUPTED` and missing `[timeout=Nms]` markers (see [[feedback-draw-compile-convention]]).
- Editing the activity-log hook script: silent stdout, exit 0.
- Editing the Makefile: any new compile target should also `2>&1 | tee -a $(MAKE_LOG)` to keep make.log complete.
