---
name: feedback_pkill_f_self_match_hang
description: Never use pkill -f / pgrep -f with a pattern that can appear in the matcher's own command line — it self-matches and can SIGTERM the persistent shell, wedging the Bash tool.
metadata:
  type: feedback
---

When running under Claude Code's persistent Bash shell (which wraps each command in
`zsh -c '... eval '"'"'<your command>'"'"' ...'`), the FULL command line of the
wrapper contains your command text verbatim.

Therefore `pkill -f <pattern>` and `pgrep -f <pattern>` will MATCH THEIR OWN
wrapper process whenever `<pattern>` is a substring of the command being run.

**Observed failure (2026-05-30):** `pkill -f /tmp/test_mcp.run` matched the zsh
wrapper executing the pkill, so pkill SIGTERM'd its own shell → exit code 144
(128 + 16 = SIGTERM). Repeated `pgrep -af` calls then returned the grepper's own
argv as false positives, and the persistent Bash shell became unresponsive
(every subsequent command, even `echo ok`, returned empty) — a real hang.

**Why:** This is the same self-reference class of bug as the QB64PE FUNCTION
self-call. The tool's process list includes the tool itself.

**How to apply:**
- Kill ONLY by exact integer PID (or process GROUP via negative PID): `kill -TERM <pid>` / `kill -TERM -<pid>`. Never `pkill -f <path>`.
- If you must match by name, use `pgrep -x <comm>` (exact process NAME, not full argv) and/or exclude self: `pgrep -f foo | grep -v $$`.
- For GUI binaries launched for screenshot verification, use the self-terminating wrapper [DEV/qb64-shot.sh](../../../DEV/qb64-shot.sh): `setsid timeout -k 2 <secs> <bin> &` + `trap 'kill -TERM -<pid>' EXIT` so the window is torn down by exact PGID and can never outlive the capture. Related: [[reference_qb64pe_mcp_run_screenshot]].
- The qb64pe MCP `run` tool launches a REAL desktop window and does NOT auto-kill it; always tear it down by the exact PID it returns. Confirm with the user before launching GUI windows.
