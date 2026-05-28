---
name: feedback-qb64pe-compile-output-capture
description: "Per user directive: don't use MCP compile_and_verify_qb64pe for DRAW — its SIGTERM behavior is misleading. Just run qb64pe directly via Bash and infer parse errors from DRAW.run absence + fast exit."
metadata:
  node_type: memory
  type: feedback
---

**User directive (explicit):** Do NOT use `mcp__qb64pe__compile_and_verify_qb64pe` for DRAW builds. Just run the compiler directly via Bash.

## How to read a direct `qb64pe` compile

QB64-PE's TTY error display erases the actual error text and leaves only "Press enter to continue" when stdout isn't a real terminal. So the visible output is uninformative. **Trust the file system and timing, not the log:**

| Signal | Meaning |
|---|---|
| Bash exits in <10s with no DRAW.run | **Parse error.** QB64-PE rejected the source. Find the bug by reading code (look for reserved-word collisions in DIM names — `STEP`, `COLOR`, `SCALE`, etc.) |
| Bash takes 1-5 minutes and produces DRAW.run | **Success.** |
| Bash exits in <10s WITH DRAW.run | Build was a no-op (no source changes since last build). |

**Working invocation:** `/home/grymmjack/git/qb64pe/qb64pe -w -x -f:MaxCompilerProcesses=12 DRAW.BAS -o DRAW.run < /dev/null > log 2>&1` — match the user's VSCode task flags. `-q` and `-m` add nothing useful and may obscure things.

## Why the MCP tool is misleading for DRAW

- **SIGTERM does not mean "real error"** — it just means the compile exceeded the MCP's ~2-minute window. A clean DRAW build takes 2-5 minutes; the MCP will SIGTERM most successful builds.
- **First call may return useful errors if they happen in the first 2 min of parsing,** but you can't tell the difference between "real parse error" and "MCP timed out before completing the full compile" from the MCP output alone.
- The user has spent multiple sessions getting frustrated when I bounce between MCP and Bash trying to disambiguate. Just go direct.

## DIM name reserved-word collisions encountered

When a DIM uses a name that collides with a QB64-PE keyword, the compile dies with "Name already in use" or a syntax error. Known bad names: `STEP`, `COLOR`, `SCALE`, `LINE`, `PAINT`, `SCREEN`, `KEY`, `FILES`, `DEF`. When `Press enter to continue` is the only output and the compile died fast, **grep the recent diff for `DIM <reserved>`** as the first hypothesis.

Related: [[feedback-draw-compile-convention]] — foreground+timeout convention for streaming output.
