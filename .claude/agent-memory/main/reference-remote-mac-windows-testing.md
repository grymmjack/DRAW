---
name: reference-remote-mac-windows-testing
description: How to build & test QB64-PE programs (DRAW) on Rick's real macOS and Windows machines over SSH — hosts, the Windows OpenSSH/key/firewall gotchas, cmd-vs-PowerShell, and why display/DPI probing must run in the interactive session not SSH.
metadata:
  type: reference
---

Rick keeps **real macOS + native-Windows machines online for cross-platform QB64-PE
testing**, reachable over SSH from this Linux box (`~/.ssh/config`). Use them to
build and eyeball-test platform-specific behavior (cursor, DPI, window resize) that
Linux can't reproduce. `[Linux host]` = where these notes were written.

## Hosts (`~/.ssh/config`) — the 4-box "build army" (as of 2026-08-23)
- `mac` — `192.168.1.120`, Apple Silicon, **Retina macOS**. Runs `/Users/grymmjack/git/DRAW/DRAW.run`; qb64pe `~/git/qb64pe`.
- `titan` — `192.168.1.172`, Linux (Debian, **KDE Plasma/X11**, SDDM). Runs `/home/grymmjack/git/DRAW/DRAW.run`. **qb64pe is at `~/git/QB64pe` (capital B!)** — lowercase `~/git/qb64pe` exists but has no `.git`; build DRAW with `make QB64PE=$HOME/git/QB64pe/qb64pe`.
- `thinkpad` — `192.168.1.169`, **native Windows** (build 26200), HiDPI 4K @200% (4× scale). THE HiDPI Windows target. See profile note below.
- `daw` — `192.168.1.77`, **WSL2 on a Windows box (RTX 3070)**. **CORRECTION to old note: daw DOES produce valid native Windows builds** — WSL only launches the *native* Windows `qb64pe.exe` (`/mnt/c/Users/grymm/git/qb64pe/qb64pe.exe`) via interop; the resulting `C:\Users\grymm\git\DRAW\DRAW.exe` is a real native Win32/GLFW binary, byte-equivalent to a cmd.exe build. daw restore-from-maximized repro'd + verified the GLFW fix natively. WSL user is `gj`; the Windows profile is `grymm`; Rick RDPs in as `grymmjack` (so `C:\Users\grymmjack\git` is empty — DRAW lives under `grymm`).

**Whole fleet is pinned to qb64pe `v4.6.0-247-ge048bc093`** (unify via git checkout of that commit + rebuild). titan/daw were rebuilt to match; keep them in sync. `dc` note: `internal/version.txt` says `-UNKNOWN` on git builds — read the real version with `git -C <qb64pe> describe --tags`.

Build everywhere: `qb64pe -w -x -o OUT SRC.BAS`. Windows qb64pe rebuild: **`setup_win.cmd`** run SYNCHRONOUSLY (backgrounded WSL→cmd.exe interop silently no-ops; and a running `qb64pe.exe` locks the output — `taskkill /F /IM qb64pe.exe` first).

## ⛔ The dirty-repo stale-build trap (cost hours on 2026-08-23)
Every "deploy" DRAW copy (mac, titan, thinkpad) had **uncommitted local edits** (stale scp/robocopy leftovers: `M DRAW.BAS`, `M SCREEN.BM`, …) that **silently block `git pull --ff-only`**. The pull fails, the build compiles OLD source, and the "fix doesn't work" — because the fix was never in the binary. titan was even **1541 commits behind** (Feb 2025) with an **uninitialized submodule**. Before building on ANY box to test a fix:
1. `git stash push -u` → `git pull --ff-only origin main` → confirm `git rev-parse --short HEAD` is the expected commit.
2. `git submodule update --init --recursive` (QB64_GJ_LIB; remote is HTTPS).
3. **grep the source for a unique marker of your fix** (e.g. `SCREEN_DEFERRED_W`) and confirm it's present *before* trusting the build.
4. **Verify the RIGHT binary runs:** QB64 bakes the compile-time source path into every log line (`INFO QB64 C:\Users\grymm\git\DRAW\OUTPUT/SCREEN.BM: ... 763: ...`). If the path/line numbers don't match the repo you built, Rick is running a different copy. Rick runs `~/git/DRAW/DRAW.run` (mac/linux/titan) and, on thinkpad, `C:\Users\grymm\git\DRAW\DRAW.exe` by habit though his home is `grymmjack.thinkpad` — point the fixed build where he actually launches.

## Windows SSH setup gotchas (all bit us once — 2026-08-22, Win11)
- **Admin key file:** for an **administrator** account, sshd reads
  `C:\ProgramData\ssh\administrators_authorized_keys`, NOT `~/.ssh/authorized_keys`.
  Owner must be `BUILTIN\Administrators` (or SYSTEM); ACL only SYSTEM+Administrators
  (`icacls f /setowner "BUILTIN\Administrators"` + `/inheritance:r /grant SYSTEM:F /grant "BUILTIN\Administrators:F"`).
- **Firewall:** the OpenSSH inbound rule is often **Profile=Private only**; an
  unclassified/Public LAN then blocks :22 even though sshd listens on `0.0.0.0:22`.
  Fix: `Get-NetFirewallRule -DisplayName '*ssh*' | Set-NetFirewallRule -Profile Any`.
  (Windows blocks ICMP by default, so **ping failing is a red herring** — test port 22.)
- **Profiles split:** SSH logs into the local `grymmjack` account →
  `C:\Users\grymmjack.thinkpad` (fresh). Rick's **interactive/RDP** account is
  `C:\Users\grymmjack`. Admin SSH can read/write across profiles, but a
  **non-elevated Explorer double-click can't write into another user's profile** —
  so **place any test exe + its output dir in the profile that will RUN it**
  (`C:\Users\grymmjack\...` for physical/RDP runs), and clear stale output first.

## Driving Windows over SSH
Default shell is **cmd.exe**; multi-line commands and nested quoting break. Reliable
pattern: write a `.ps1` locally → `scp` it → `ssh host 'powershell -NoProfile
-ExecutionPolicy Bypass -File x.ps1'`. Avoid PS7-only syntax (`??`, ternary) — the
default `powershell` is **Windows PowerShell 5.1**. Large recursive copies: `robocopy
SRC DST /E` (exit 0-7 = success). Logged DRAW run: a `.bat` that sets
`QB64PE_LOG_HANDLERS=console,file`, `QB64PE_LOG_SCOPES=runtime,qb64,libqb`,
`QB64PE_LOG_LEVEL=1`, `QB64PE_LOG_FILE_PATH=X.log` then launches the exe.

## Display / DPI probing MUST be interactive, not SSH
A GUI app launched **over SSH** gets a **headless phantom desktop** (`_DESKTOPWIDTH`
returns 0; `VirtualScreen`=1024×768) — NOT the real monitor. Real display/DPI values
require the **interactive session**: physical console, or RDP. **RDP presents its own
resolution/scale**, not the laptop panel's — so true HiDPI repro needs the **physical
console**. Workflow: build via SSH → Rick double-clicks in his session → read the
output file / log back over SSH.

## Known QB64-PE cross-platform quirk found this way
`_DESKTOPWIDTH = glfwGetVideoMode()->width × monitorContentScale`
(`glut-emu.cpp` `ScreenGetMode`). Correct on **macOS** (mode is *points* → ×2 =
physical 3456) but **doubles on Windows** (mode already *pixels* → 3840×2 = **7680**
on a 4K panel @200%). Upstream QB64-PE inconsistency; DRAW's auto-scale detect must
divide the content scale back out on Windows. See [[hw-cursor-os-plane]] and the
macOS cursor sizing (native-PNG, no displayScale, Cocoa Retina-doubles NSCursor).

## ⛔ QB64-PE `$IF LINUX` is TRUE on macOS (2026-08-23 regression)
macOS is QB64-PE's Unix/"LNX" build, so a bare `$IF LINUX THEN … $END IF` block **compiles into the Mac binary too**. A Linux-only check that inspects `ENVIRON$("DISPLAY")` then false-fires on macOS, which uses Cocoa and has **no DISPLAY env var** (a headless-guard shipped that made every Mac GUI launch print "no display" and exit). QB64-PE `$IF` has **no `NOT` and no `AND`/`OR`** (`$IF NOT MAC` / `$IF LINUX AND NOT MAC` both error "Invalid Resolution of $IF"); `$ELSE` and nesting DO work. To target **real Linux only**, nest: `$IF LINUX THEN` → `$IF MAC THEN $ELSE …real-linux… $END IF` → `$END IF`. DRAW already uses `$IF MAC` / `$IF WIN` everywhere for exactly this reason — never bare `$IF LINUX` for Linux-specific code.
