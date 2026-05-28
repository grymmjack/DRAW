---
name: feedback-vscode-task-for-draw-build
description: "User compiles DRAW via VSCode F5 (.vscode/tasks.json 'EXECUTE: Run'). This always works and command output appears in the task. Use it instead of inventing CLI flag variations or poking around qb64pe internals."
metadata:
  node_type: memory
  type: feedback
---

**User directive (explicit):** When the user wants me to "compile" or "build" DRAW, the canonical path is the VSCode task `.vscode/tasks.json` invoked via F5 → "EXECUTE: Run" (which does clean + compile + run). This always works for the user; the task's command output appears in their task pane.

**Why my Bash invocation has been failing while user's F5 succeeds with the SAME compiler command:** Empirically, `qb64pe ... < /dev/null > log 2>&1` from Claude's Bash tool produces a fast-exit-with-no-binary result for code that compiles cleanly via VSCode's F5 task. Strong suspect: QB64-PE's compile phase reads from stdin somewhere (input/setup prompts) and EOF on /dev/null triggers an early bail. VSCode's task runner provides a real pty so the same code path doesn't fault. **Don't try to "fix" this from my end** — even removing `< /dev/null` doesn't help because the Bash tool's stdin is also not a tty. **The correct path: ask the user to F5 and paste any errors from the task pane.** Saves loops of failed `rm -f DRAW.run` cycles.

**The exact task chain** (from `.vscode/tasks.json`):

- `EXECUTE: Run` → dependsOn `BUILD: Compile` → dependsOn `BUILD: Remove`
- `BUILD: Compile` Linux command:
  ```
  ${config:qb64pe.compilerPath} -w -x -f:MaxCompilerProcesses=12 DRAW.BAS -o DRAW.run
  ```
- `BUILD: Remove` deletes the prior binary first.

**How to apply:** When I need a build, either ask the user to hit F5 OR run the same command directly:
```bash
rm -f DRAW.run && /home/grymmjack/git/qb64pe/qb64pe -w -x -f:MaxCompilerProcesses=12 DRAW.BAS -o DRAW.run
```
If the build fails with no useful output (because QB64-PE's TTY error display gets eaten by piping), don't go searching for hidden log files — fix the obvious bug or **ask the user to hit F5 and paste what they see in the task pane**. Their pane shows the real QB64-PE parse errors that bash redirection hides.

**DO NOT** inspect `/home/grymmjack/git/qb64pe/internal/temp/` unless the user explicitly asks. That directory is QB64-PE compiler internals; rooting around in there to "find the error" is wasted effort and the user has called it out as annoying.

**DO NOT** try multiple variations of `-q`, `-m`, `-x` flag combinations hoping one will reveal the error. They all produce the same masked output. Just fix the code or ask the user.

Related: [[feedback-qb64pe-compile-output-capture]] — the MCP `compile_and_verify_qb64pe` tool's SIGTERM behavior is misleading; user has banned it for DRAW builds.
