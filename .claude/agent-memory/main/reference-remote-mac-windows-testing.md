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

## Hosts (`~/.ssh/config`)
- `mac` — Apple Silicon, **Retina 2× macOS**. qb64pe at `~/git/qb64pe/qb64pe`; DRAW at `~/git/DRAW`.
- `thinkpad` — `192.168.1.169`, **native Windows 11** (build 26200), 4K panel. THE Windows target.
- `titan` — Linux (Debian). `daw` = **WSL2 Linux, NOT native Windows** (can't repro Windows GLFW/DPI).

Build everywhere: `qb64pe -w -x -o OUT SRC.BAS`. Both `mac` and `thinkpad` run
**today's qb64pe main/GLFW build** (has `_MOUSECURSOR`). Windows qb64pe:
`%USERPROFILE%\git\qb64pe\qb64pe.exe`.

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
