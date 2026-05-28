---
name: reference-anthropic-sandbox-qb64pe-bug
description: "Anthropic Claude Code bug to report: Bash sandbox silently blocks writes to qb64pe's internal/temp scratch dir, causing qb64pe to fail with only 'Press enter to continue' and no error. Failure mode is indistinguishable from a real parse error, costing multiple debugging sessions."
metadata:
  node_type: memory
  type: reference
---

## The bug (to file against Anthropic)

**Title:** Sandbox silently blocks writes to compiler scratch dirs, causing silent build failures with misleading diagnostics

**Where to file:**
- GitHub Issues: https://github.com/anthropics/claude-code/issues
- In-product: `/bug` command (auto-attaches session context)
- Status as of 2026-05-28: not yet filed by user

## Repro (clean, deterministic)

1. Claude Code's Bash sandbox is enabled (default).
2. Run: `/home/grymmjack/git/qb64pe/qb64pe -w -x -f:MaxCompilerProcesses=12 DRAW.BAS -o DRAW.run`
3. Output: lone `Press enter to continue` line. No compiler banner. No `Beginning C++ output...`. No error text. Fast exit. No `DRAW.run` binary produced.
4. Disable sandbox: `/sandbox` → Off (or `dangerouslyDisableSandbox: true` per-call, or `"sandbox": { "enabled": false }` in settings.json).
5. Same command. Now: full `QB64-PE Compiler V4.4.0` banner, ~3 minute compile, valid 16 MB ELF produced.

## Root cause

qb64pe is a two-stage compiler:
1. Transpile `DRAW.BAS` → C++ into `/home/grymmjack/git/qb64pe/internal/temp/qbx.cpp`
2. Invoke g++ on that C++ file to produce the final binary

The sandbox's writable-path allowlist excludes `qb64pe/internal/temp/`. When the transpile stage fails to write `qbx.cpp`, qb64pe falls back to its IDE-pause prompt (`Press enter to continue`) without surfacing the underlying filesystem error.

## Why it matters

**The failure mode is indistinguishable from a real source parse error from inside the tool-call output.** Both produce:
- Fast exit
- No binary
- Minimal output

This means LLMs (and humans) reading the tool output go hunting for a non-existent parse bug, often for hours. The user has explicitly named multiple lost debugging sessions to this exact failure.

## Suggested fixes (either helps)

1. **Surface sandbox denials.** When the sandbox refuses a write that a subprocess needed, append a `[sandbox] denied write to <path>` line to the tool output. Right now denials are silent from the caller's perspective.
2. **Allow per-binary allowlist scoping in `/sandbox`.** "Any subprocess invoked from this binary can write to its own install tree" would cover qb64pe, gcc, cargo, npm install scripts — most compiler/toolchain scratch dirs.

A third option, narrower but still useful: extend the sandbox-allowlist defaults to include known compiler scratch directories (`internal/temp/`, `target/`, `node_modules/.cache/`, etc.). This is a heuristic patch but it handles the common case.

## What we've documented locally

- [[qb64pe-sandbox-limitation]] — the original reference memory describing the symptom + workaround
- [[feedback-sandbox-dotfile-pollution]] — separate-but-related sandbox annoyance (the husk dotfiles)
- [[feedback-vscode-task-for-draw-build]] — why F5 in VSCode works when sandboxed Bash doesn't

## Draft bug report body (for `/bug` or GitHub Issues)

Reproduced verbatim below for paste:

```
**Title:** Sandbox silently blocks writes to compiler scratch dirs, causing silent build failures with misleading diagnostics

**Summary:** Claude Code's Bash sandbox prevents qb64pe (a QB64-PE compiler) from writing to its own `internal/temp/` scratch directory. The result is not a sandbox error — instead, qb64pe falls back to its IDE-pause prompt and emits only `Press enter to continue` with no compiler banner, no error, and no output binary. Both Claude and the user are led to conclude the source has a parse error.

**Repro:**
1. With sandbox enabled (default), run via Bash: `/path/to/qb64pe -w -x DRAW.BAS -o DRAW.run`
2. Observe: lone "Press enter to continue", no DRAW.run produced, exit fast.
3. Disable sandbox via `/sandbox` Off.
4. Same command now prints the full compiler banner, runs for ~3 minutes, produces a 16 MB ELF.

**Why this matters:** the failure mode is indistinguishable from a real parse error from inside the tool-call output, so debugging loops chase ghost source bugs. Multiple sessions lost to this.

**Suggested fixes:**
1. Surface sandbox denials in tool output instead of letting subprocesses fail silently.
2. Allow per-binary scoping in `/sandbox` (any subprocess from this binary can write to its install tree).
```
