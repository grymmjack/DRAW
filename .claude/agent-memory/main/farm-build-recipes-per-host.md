---
name: farm-build-recipes-per-host
description: Per-host build/sync recipes for the DRAW test farm (mac, titan, daw, thinkpad) — exact qb64pe paths, Windows-build-over-SSH method, submodule + compiler-update gotchas
metadata:
  type: reference
---

Verified 2026-09-14 syncing the whole farm to a merged `main`. Hosts are SSH
aliases (~/.ssh/config): mac (192.168.1.120), titan (.172), daw (.77), thinkpad
(.169). All `~/git/DRAW` except daw `/mnt/c/Users/grymm/git/DRAW` and thinkpad
`C:/Users/grymmjack.thinkpad/git/DRAW`. Each has a `-fstest` worktree sibling.

**Compiler (qb64pe) path per host — NOT uniform:**
- mac: `$HOME/git/qb64pe/qb64pe` (default; `make` just works).
- titan: `$HOME/git/**QB64pe**/qb64pe` — **capital QB**, so the lowercase default
  fails on case-sensitive Linux (`Error 127`). Build with `make QB64PE="$HOME/git/QB64pe/qb64pe"`.
- daw: Windows compiler `/mnt/c/Users/grymm/git/**QB64pe**/qb64pe.exe`.
- thinkpad: `C:\Users\grymmjack.thinkpad\git\qb64pe\qb64pe.exe`.

**[Windows] Build over SSH — DON'T use `make`.** thinkpad's SSH shell is cmd.exe;
`make` isn't in PATH and there are 3 conflicting `bash.exe` (WSL System32, Git,
WindowsApps). Invoke the compiler DIRECTLY — this compiles headless over SSH fine
(no window needed for `-x`):
- thinkpad (cmd): `cd /d C:\Users\grymmjack.thinkpad\git\DRAW && C:\Users\grymmjack.thinkpad\git\qb64pe\qb64pe.exe -w -x DRAW.BAS -o DRAW.exe`
- daw (WSL exec of the Windows exe): `cd /mnt/c/Users/grymm/git/DRAW && /mnt/c/Users/grymm/git/QB64pe/qb64pe.exe -w -x DRAW.BAS -o DRAW.exe`
- git works over SSH on both (Git-for-Windows `git.exe`), cmd `&&`-chained on thinkpad.

**[WSL/daw] `cmd.exe` is NOT in the non-interactive SSH PATH** — use the full path
`/mnt/c/Windows/System32/cmd.exe`, or a bare `cmd.exe` silently "command not found"
(and a `2>/dev/null` hides it → step no-ops).

**Updating the qb64pe compiler:**
- Linux (titan): `cd ~/git/QB64pe && git pull --ff-only && ./setup_lnx.sh </dev/null`.
  setup tries to LAUNCH the IDE at the end → "Failed to initialize window / cannot
  open display" over SSH — HARMLESS, the binary already built. No submodules in qb64pe.
- Windows (daw): `git pull`, then rebuild via `/mnt/c/Windows/System32/cmd.exe /c setup_win.cmd`
  (script is `setup_win.cmd`, not `.bat`; ends clean, no IDE launch). Objects already
  built? user's `_relink_qb.cmd` fast-path = `internal\c\c_compiler\bin\mingw32-make.exe -j4 OS=win BUILD_QB64=y EXE=qb64pe.exe`.
- **[Windows] link `Permission denied` writing qb64pe.exe = the exe is still running
  and locking itself.** Stopping the SSH session kills only the Linux side; the Windows
  qb64pe.exe child SURVIVES. Kill it explicitly: `cmd.exe /c "taskkill /IM qb64pe.exe /F"`,
  then relink. WSL↔Windows process trees don't cascade-kill.

**Submodule (QB64_GJ_LIB) — force it.** A host with local edits inside the submodule
makes `git submodule update` ABORT ("Unable to checkout <sha>"), and the DRAW build
then silently uses the WRONG submodule commit (mac was stuck at 909fac1 instead of the
pinned 329d5e19, built once against the wrong lib). After `git reset --hard` + `git
clean -fd` on DRAW, ALSO: `git submodule foreach --recursive 'git reset --hard; git
clean -fdx'` then `git submodule update --init --recursive --force`, and VERIFY
`git -C includes/QB64_GJ_LIB rev-parse --short HEAD` == expected before building.

See [[thinkpad-two-windows-profiles]] (SSH login grymmjack.thinkpad vs desktop grymm),
[[farm-test-worktrees-invisible-to-dash]], [[reference-remote-mac-windows-testing]].
