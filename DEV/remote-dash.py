# /// script
# requires-python = ">=3.9"
# dependencies = ["rich>=13"]
# ///
"""
remote-dash.py — at-a-glance status of DRAW builds on remote test machines.

Richer sibling of remote-dash.sh: same idea (SSH each host in parallel, show
reachability / build-running / binary / newest-log-tail), rendered with `rich`.

Run it with uv (auto-installs rich into an ephemeral env):

    uv run DEV/remote-dash.py             # interactive: auto-refresh + hotkeys
    uv run DEV/remote-dash.py --watch 5   # interactive, refresh every 5s
    uv run DEV/remote-dash.py --once      # single snapshot, no interaction
    uv run DEV/remote-dash.py --log thinkpad          # dump a host's newest full log
    uv run DEV/remote-dash.py --set thinkpad "run resize test"   # set NEXT note
    uv run DEV/remote-dash.py --clear thinkpad                   # clear NEXT note

Interactive keys:
    1..9         open that machine's newest log in the pager (scroll, q returns)
    Shift+1..9   SSH into that machine in a new terminal window
    F1..F9       remote desktop with remmina (RDP for Windows, VNC for mac/Linux)
    a            toggle auto-refresh          space/g  refresh now
    ?            toggle help overlay          q/Ctrl-C quit
When stdin is not a TTY it prints one snapshot and exits.

Hosts are declared in HOSTS below as (name, type, drawdir). type = "unix" | "win".
Credentials never live here — hosts are SSH aliases resolved from ~/.ssh/config.
"""
from __future__ import annotations
import base64
import os
import re
import select
import shutil
import subprocess
import sys
import tempfile
import termios
import time
import tty
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from rich.console import Console, Group
from rich.live import Live
from rich.panel import Panel
from rich.table import Table
from rich.text import Text

# ── config ────────────────────────────────────────────────────────────────────
# type: "unix" (native Linux/macOS, builds DRAW.run) | "win" (native Windows, DRAW.exe)
# daw is WSL2 but builds a native DRAW.exe on its Windows side via /mnt/c interop.
HOSTS = [
    ("mac",      "unix", "$HOME/git/DRAW"),
    ("titan",    "unix", "$HOME/git/DRAW"),
    ("daw",      "unix", "/mnt/c/Users/grymm/git/DRAW"),
    ("thinkpad", "win",  r"C:/Users/grymmjack/git/DRAW"),
]
LOG_LANES_LINES = 10  # lines shown per machine lane
# Screen-share protocol per host (F-key launches this via remmina). Note this is the
# DESKTOP's protocol, not the build type: daw is WSL (unix build) but a Windows desktop.
SHARE = {"mac": "vnc", "titan": "rdp", "daw": "rdp", "thinkpad": "rdp"}
# RDP login can differ from the SSH login (e.g. daw: SSH user "gj", Windows user "grymmjack").
# Falls back to the resolved SSH user when a host isn't listed here.
RDP_USER = {"daw": "grymmjack"}
SSH_OPTS = ["-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=accept-new"]
TAIL_N = 18
STATUS_DIR = Path(__file__).resolve().parent.parent / ".claude" / "remote-status"

console = Console()


# ── remote probe payloads ─────────────────────────────────────────────────────
def unix_probe(drawdir: str) -> str:
    return f'''
d="{drawdir}"
echo "REACH=1"
echo "HOSTNAME=$(hostname 2>/dev/null)"
echo "WHOAMI=$(whoami 2>/dev/null)"
echo "OSVER=$(uname -sr 2>/dev/null)"
echo "CWD=$d"
echo "BRANCH=$(cd "$d" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
qbver="-"
for qd in "$HOME/git/qb64pe" "$HOME/git/QB64pe" "/mnt/c/Users/grymm/git/qb64pe"; do
  if [ -d "$qd/.git" ]; then
    v=$(git -C "$qd" describe --tags 2>/dev/null)
    [ -z "$v" ] && v=$(git -C "$qd" rev-parse --short HEAD 2>/dev/null)
    [ -n "$v" ] && {{ qbver=$v; break; }}
  fi
  if [ -f "$qd/internal/version.txt" ]; then v=$(tr -d '\\r\\n' < "$qd/internal/version.txt"); [ "$v" != "-UNKNOWN" ] && [ -n "$v" ] && {{ qbver=$v; break; }}; fi
done
echo "QBVER=$qbver"
if pgrep -x qb64pe >/dev/null 2>&1; then echo "BUILD=building"; else echo "BUILD=idle"; fi
bin="$d/DRAW.run"
[ -f "$bin" ] || bin="$d/DRAW.exe"
if [ -f "$bin" ]; then
  sz=$(stat -c%s "$bin" 2>/dev/null || stat -f%z "$bin" 2>/dev/null)
  mt=$(stat -c "%y" "$bin" 2>/dev/null | awk '{{print $2}}' | cut -d. -f1)
  [ -z "$mt" ] && mt=$(stat -f "%Sm" -t "%H:%M:%S" "$bin" 2>/dev/null)
  echo "BINSZ=$sz"; echo "BINMT=$mt"
else echo "BINSZ=0"; echo "BINMT=-"; fi
log=$(ls -t "$d"/*.log 2>/dev/null | head -1)
echo "LOGFILE=$log"
echo "LOGSTART"
[ -n "$log" ] && tail -{TAIL_N} "$log" 2>/dev/null
echo "LOGEND"
'''


def win_probe_ps(drawdir: str) -> str:
    return f'''
$d = '{drawdir}'
Write-Output "REACH=1"
Write-Output ("HOSTNAME=" + $env:COMPUTERNAME)
Write-Output ("WHOAMI=" + $env:USERNAME)
Write-Output ("OSVER=Windows " + [System.Environment]::OSVersion.Version.ToString())
Write-Output ("CWD=" + $d)
$br = ''
try {{ Push-Location $d; $br = (git rev-parse --abbrev-ref HEAD 2>$null); Pop-Location }} catch {{}}
Write-Output ("BRANCH=" + $br)
$qbv = '-'
foreach ($qd in @('C:/Users/grymmjack/git/qb64pe', 'C:/Users/grymmjack.thinkpad/git/qb64pe', 'C:/Users/grymm/git/qb64pe')) {{
  if (Test-Path (Join-Path $qd '.git')) {{
    $v = (git -C $qd describe --tags 2>$null); if (-not $v) {{ $v = (git -C $qd rev-parse --short HEAD 2>$null) }}
    if ($v) {{ $qbv = $v; break }}
  }}
  $qp = Join-Path $qd 'internal/version.txt'
  if (Test-Path $qp) {{ $t = (Get-Content $qp -Raw).Trim(); if ($t -and $t -ne '-UNKNOWN') {{ $qbv = $t; break }} }}
}}
Write-Output ("QBVER=" + $qbv)
$b = Get-Process qb64pe -ErrorAction SilentlyContinue
Write-Output ("BUILD=" + $(if ($b) {{ 'building' }} else {{ 'idle' }}))
$bin = Join-Path $d 'DRAW.exe'
if (Test-Path $bin) {{ $f = Get-Item $bin; Write-Output ("BINSZ=" + $f.Length); Write-Output ("BINMT=" + $f.LastWriteTime.ToString('HH:mm:ss')) }}
else {{ Write-Output "BINSZ=0"; Write-Output "BINMT=-" }}
$log = Get-ChildItem (Join-Path $d '*.log') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Write-Output ("LOGFILE=" + $(if ($log) {{ $log.FullName }} else {{ '' }}))
Write-Output "LOGSTART"
if ($log) {{ Get-Content $log.FullName -Tail {TAIL_N} }}
Write-Output "LOGEND"
'''


def ssh_meta(name: str) -> dict:
    """Resolve IP / login-user / identity-key locally from `ssh -G` (no network round trip)."""
    ip = user = idfile = ""
    try:
        out = subprocess.run(["ssh", "-G", name], capture_output=True, text=True,
                             errors="replace", timeout=5).stdout
        for line in out.splitlines():
            k, _, v = line.partition(" ")
            k = k.lower()
            if k == "hostname" and not ip:
                ip = v
            elif k == "user" and not user:
                user = v
            elif k == "identityfile" and not idfile:
                idfile = v
    except Exception:
        pass
    key = bool(idfile) and os.path.exists(os.path.expanduser(idfile))
    return {"IP": ip or "?", "SSHUSER": user or "?", "KEY": key,
            "IDFILE": os.path.basename(idfile) if idfile else ""}


def probe_host(host) -> dict:
    name, htype, drawdir = host
    try:
        if htype == "win":
            enc = base64.b64encode(win_probe_ps(drawdir).encode("utf-16-le")).decode()
            out = subprocess.run(
                ["ssh", *SSH_OPTS, name, f"powershell -NoProfile -EncodedCommand {enc}"],
                capture_output=True, text=True, errors="replace", timeout=20).stdout
            out = out.replace("\r", "")  # strip Windows CRLF
        else:
            out = subprocess.run(
                ["ssh", *SSH_OPTS, name, "bash -s"],
                input=unix_probe(drawdir), capture_output=True, text=True,
                errors="replace", timeout=20).stdout
    except Exception:
        out = ""
    return {"name": name, "type": htype, **parse(out), **ssh_meta(name)}


def parse(out: str) -> dict:
    d = {"REACH": "0", "BUILD": "", "BINSZ": "0", "BINMT": "-", "LOGFILE": "", "LOG": [],
         "HOSTNAME": "-", "WHOAMI": "-", "OSVER": "-", "QBVER": "-", "CWD": "-", "BRANCH": "-"}
    in_log = False
    for line in out.splitlines():
        if line == "LOGSTART":
            in_log = True; continue
        if line == "LOGEND":
            in_log = False; continue
        if in_log:
            d["LOG"].append(line); continue
        if "=" in line:
            k, _, v = line.partition("=")
            if k in d:
                d[k] = v
    return d


# ── formatting helpers ────────────────────────────────────────────────────────
def human(b: str) -> str:
    try:
        n = int(b)
    except ValueError:
        return "?"
    if n >= 1 << 20:
        return f"{n / (1 << 20):.1f}M"
    if n >= 1 << 10:
        return f"{n / (1 << 10):.0f}K"
    return f"{n}B"


def derive_next(r: dict) -> str:
    if r["REACH"] != "1":
        return "⚠ host down — check SSH/power"
    if r["BUILD"] == "building":
        return "⏳ wait — build running"
    if r["BINSZ"] not in ("0", ""):
        return "▶ ready — run/test"
    return "—"


def next_note(name: str, r: dict) -> tuple[str, str]:
    """Return (text, style). Explicit note file wins; else a derived hint."""
    f = STATUS_DIR / f"{name}.status"
    if f.exists():
        msg = f.read_text().strip()
        if msg:
            style = "green" if msg[:1] in "✓✔" else "bold cyan"
            return msg, style
    msg = derive_next(r)
    style = {"⚠": "bold red", "⏳": "yellow", "▶": "bold cyan"}.get(msg[:1], "dim")
    return msg, style


# ── views ─────────────────────────────────────────────────────────────────────
def build_table(results: dict) -> Table:
    t = Table(title="DRAW Remote Build Dashboard  ·  " + time.strftime("%H:%M:%S"),
              title_style="bold cyan", header_style="bold dim", expand=True,
              border_style="cyan", pad_edge=False)
    t.add_column("#", style="bold yellow", no_wrap=True)
    t.add_column("HOST", style="bold", no_wrap=True)
    t.add_column("HOSTNAME / IP", no_wrap=True)
    t.add_column("LOGIN", no_wrap=True)
    t.add_column("OS", no_wrap=True)
    t.add_column("QB", no_wrap=True)
    t.add_column("BRANCH / CWD", no_wrap=True, overflow="ellipsis")
    t.add_column("REACH", no_wrap=True)
    t.add_column("BUILD", no_wrap=True)
    t.add_column("BINARY", no_wrap=True)
    t.add_column("NEXT (you)", overflow="fold")
    for i, (name, htype, _) in enumerate(HOSTS, 1):
        r = results[name]
        up = r["REACH"] == "1"

        node = Text.assemble((r.get("HOSTNAME", "-") if up else "-", "bold"),
                             ("\n" + r.get("IP", "?"), "dim"))

        # A successful BatchMode=yes probe proves key/agent auth (no password was possible).
        idf = r.get("IDFILE", "")
        if up:
            keybadge = (f"✓ key ({idf})" if idf else "✓ key", "green")
        elif r.get("KEY"):
            keybadge = (f"key: {idf}" if idf else "key set", "yellow")
        else:
            keybadge = ("✗ no key", "red")
        login = Text.assemble((r.get("SSHUSER", "?"), ""), ("\n", ""), keybadge)
        rdp_user = RDP_USER.get(name)
        if rdp_user and rdp_user != r.get("SSHUSER"):
            login.append(f"\nrdp: {rdp_user}", style="dim cyan")

        os_txt = Text(r.get("OSVER", "-") if up else "-",
                      style="" if up else "dim")
        qb_txt = Text(r.get("QBVER", "-") if up else "-",
                      style="cyan" if (up and r.get("QBVER", "-") not in ("-", "")) else "dim")

        branch = r.get("BRANCH", "-") or "-"
        loc = Text.assemble((branch, "bold green" if branch not in ("-", "") else "dim"),
                            ("\n" + (r.get("CWD", "-") or "-"), "dim"))

        reach = Text("● up", style="green") if up else Text("○ down", style="red")
        if r["BUILD"] == "building":
            build = Text("⚙ building", style="yellow")
        elif r["BUILD"] == "idle":
            build = Text("idle", style="dim")
        else:
            build = Text("-", style="dim")
        if r["BINSZ"] not in ("0", ""):
            binary = Text.assemble((human(r["BINSZ"]), ""), ("\n" + r["BINMT"], "dim"))
        else:
            binary = Text("(none)", style="dim")

        msg, style = next_note(name, r)
        t.add_row(str(i), name, node, login, os_txt, qb_txt, loc,
                  reach, build, binary, Text(msg, style=style))
    return t


def build_logs(results: dict):
    """One full-width vertical lane per machine, numbered [N] in the border title so the
    interactive loop can open that host's full log in the pager on the matching key.
    Lanes with no log collapse to a single line so a lone active log gets the room."""
    panels = []
    for i, (name, _, _) in enumerate(HOSTS, 1):
        r = results[name]
        has_log = r["REACH"] == "1" and r["LOG"]
        if r["REACH"] != "1":
            body, tail, height = Text("(unreachable)", style="dim red"), name, 3
        elif not r["LOG"]:
            body, tail, height = Text("(no recent log)", style="dim"), name, 3
        else:
            body = Text(no_wrap=True, overflow="ellipsis")
            for ln in r["LOG"][-LOG_LANES_LINES:]:
                body.append(ln + "\n")
            tail = f"{name}: {os.path.basename(r['LOGFILE'])}"
            height = LOG_LANES_LINES + 2
        title = Text.assemble((f"[{i}] ", "bold yellow"), (tail, "magenta"))
        panels.append(Panel(body, title=title, title_align="left",
                           border_style="magenta" if has_log else "dim",
                           padding=(0, 1), height=height))
    return panels


def build_help() -> Panel:
    body = Text()
    rows = [
        ("1 - 9", "open that machine's newest log in the pager (scroll, q returns)"),
        ("Shift+1..9", "SSH into that machine in a new terminal window  (! @ # $ % ^ & * ()"),
        ("F1 - F9", "remote desktop with remmina (RDP for Windows, VNC for mac/Linux)"),
        ("a", "toggle auto-refresh on/off"),
        ("space / g", "refresh now"),
        ("?", "toggle this help"),
        ("q / Ctrl-C", "quit the dashboard"),
    ]
    for key, desc in rows:
        body.append(f"  {key:<12}", style="bold yellow")
        body.append(desc + "\n", style="")
    body.append("\n  Hosts are SSH aliases from ~/.ssh/config; RDP targets the resolved IP.",
                style="dim")
    return Panel(body, title="hotkeys", title_align="left", border_style="cyan",
                 padding=(1, 2))


# ── launchers (ssh in a new terminal, rdp via remmina) ─────────────────────────
def open_terminal(cmd_list) -> bool:
    """Spawn cmd_list in a new terminal window; try common emulators in order."""
    for term in (["konsole", "-e"], ["gnome-terminal", "--"],
                 ["x-terminal-emulator", "-e"], ["xterm", "-e"]):
        if shutil.which(term[0]):
            try:
                subprocess.Popen(term + cmd_list, start_new_session=True,
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return True
            except Exception:
                continue
    return False


def ssh_open(name: str):
    open_terminal(["ssh", name])


def share_open(name: str, r: dict):
    """Open a remote-desktop session to a host with remmina, using the host's protocol
    (RDP for Windows desktops, VNC for macOS/Linux). VNC ignores the username."""
    if not shutil.which("remmina"):
        return
    proto = SHARE.get(name, "rdp")
    ip = r.get("IP", "")
    user = RDP_USER.get(name, r.get("SSHUSER", ""))  # RDP login may differ from SSH login
    if proto == "vnc" or not user or user in ("?", ""):
        target = f"{proto}://{ip}"
    else:
        target = f"{proto}://{user}@{ip}"
    try:
        subprocess.Popen(["remmina", "-c", target], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


# ── keyboard: distinguish plain digits, shift-symbols, and F-keys ──────────────
SHIFT_DIGITS = {"!": 1, "@": 2, "#": 3, "$": 4, "%": 5, "^": 6, "&": 7, "*": 8, "(": 9}
_FKEY_SS3 = {"P": 1, "Q": 2, "R": 3, "S": 4}          # ESC O P..S  = F1..F4
_FKEY_CSI = {11: 1, 12: 2, 13: 3, 14: 4,              # ESC [ n ~  = F1..F4 (tilde form)
             15: 5, 17: 6, 18: 7, 19: 8, 20: 9,       # ESC [ n ~  = F5..F12
             21: 10, 23: 11, 24: 12}


def parse_fkey(seq: str):
    """Map an escape-sequence body (chars after ESC) to an F-key number, else None."""
    m = re.match(r"^O([PQRS])$", seq)                 # F1..F4, application mode
    if m:
        return _FKEY_SS3[m.group(1)]
    m = re.match(r"^\[1(?:;\d+)?([PQRS])$", seq)       # F1..F4, CSI (maybe modified)
    if m:
        return _FKEY_SS3[m.group(1)]
    m = re.match(r"^\[(\d+)(?:;\d+)?~$", seq)          # F5.. and others
    if m:
        return _FKEY_CSI.get(int(m.group(1)))
    return None


def read_key(fd):
    """Return ('char', ch) for a normal key, ('fkey', n) for F1..F12, or ('esc', seq)."""
    ch = os.read(fd, 1).decode("latin-1")
    if ch != "\x1b":
        return ("char", ch)
    seq = ""
    while True:                                       # gather the rest of the escape seq
        r, _, _ = select.select([fd], [], [], 0.03)
        if not r:
            break
        seq += os.read(fd, 1).decode("latin-1")
        if seq[-1] in "~PQRS" or (len(seq) >= 2 and seq[-1].isalpha() and seq[0] != "["):
            break
        if len(seq) > 8:
            break
    n = parse_fkey(seq)
    return ("fkey", n) if n else ("esc", seq)


def gather() -> dict:
    with ThreadPoolExecutor(max_workers=len(HOSTS)) as ex:
        return {r["name"]: r for r in ex.map(probe_host, HOSTS)}


def render(results: dict, interactive: bool = False, interval: float = 3.0,
           auto: bool = True, show_help: bool = False):
    parts = [build_table(results), *build_logs(results)]
    if show_help:
        parts.append(build_help())
    if interactive:
        auto_txt = (f"[a]uto-refresh ({interval:g}s): ON" if auto
                    else "[a]uto-refresh: OFF (space=refresh)")
        footer = Text(justify="center")
        footer.append("1-9", style="bold yellow")
        footer.append(" log  ·  ", style="dim")
        footer.append("⇧1-9", style="bold yellow")
        footer.append(" ssh  ·  ", style="dim")
        footer.append("F1-9", style="bold yellow")
        footer.append(" remote  ·  ", style="dim")
        footer.append(auto_txt, style="cyan" if auto else "yellow")
        footer.append("  ·  ", style="dim")
        footer.append("?", style="bold yellow")
        footer.append(" help  ·  ", style="dim")
        footer.append("q", style="bold yellow")
        footer.append(" quit", style="dim")
        parts.append(footer)
    return Group(*parts)


# ── log fetch / dump / note management ────────────────────────────────────────
def fetch_full_log(name: str) -> str:
    """Return the entire newest log from a host (used by --log and the pager view)."""
    host = next((h for h in HOSTS if h[0] == name), None)
    if not host:
        return f"(unknown host: {name})"
    _, htype, d = host
    if htype == "win":
        ps = (f"$l=Get-ChildItem (Join-Path '{d}' '*.log') -EA SilentlyContinue|"
              f"Sort LastWriteTime -Desc|Select -First 1; if($l){{Write-Output $l.FullName; Get-Content $l.FullName}}")
        enc = base64.b64encode(ps.encode("utf-16-le")).decode()
        cmd = ["ssh", *SSH_OPTS, name, f"powershell -NoProfile -EncodedCommand {enc}"]
        strip_cr = True
    else:
        sh = f'l=$(ls -t "{d}"/*.log 2>/dev/null|head -1); echo "== $l =="; [ -n "$l" ] && cat "$l"'
        cmd = ["ssh", *SSH_OPTS, name, sh]
        strip_cr = False
    try:
        out = subprocess.run(cmd, capture_output=True, text=True,
                             errors="replace", timeout=40).stdout
    except Exception as e:
        out = f"(failed to fetch log: {e})"
    return out.replace("\r", "") if strip_cr else out


def dump_log(name: str):
    sys.stdout.write(fetch_full_log(name))


def main():
    args = sys.argv[1:]
    STATUS_DIR.mkdir(parents=True, exist_ok=True)

    if args and args[0] == "--set" and len(args) >= 3:
        (STATUS_DIR / f"{args[1]}.status").write_text(" ".join(args[2:]))
        console.print(f"set NEXT for [bold]{args[1]}[/]: {' '.join(args[2:])}"); return
    if args and args[0] == "--clear" and len(args) >= 2:
        (STATUS_DIR / f"{args[1]}.status").unlink(missing_ok=True)
        console.print(f"cleared NEXT for [bold]{args[1]}[/]"); return
    if args and args[0] == "--log" and len(args) >= 2:
        dump_log(args[1]); return

    if args and args[0] == "--once":
        console.print(render(gather())); return

    # Default & --watch: interactive. Falls back to one-shot when stdin isn't a TTY.
    interval = 3.0
    if args and args[0] == "--watch" and len(args) > 1:
        interval = float(args[1])
    if not sys.stdin.isatty():
        console.print(render(gather())); return
    interactive_loop(interval)


def view_full_log(fd, cooked_attrs, host: str):
    """Restore the terminal, show the host's full log in the pager (scrollable), then
    return to raw mode for the dashboard loop."""
    termios.tcsetattr(fd, termios.TCSADRAIN, cooked_attrs)
    text = fetch_full_log(host)
    path = None
    try:
        with tempfile.NamedTemporaryFile("w", suffix=f"-{host}.log", delete=False) as tf:
            tf.write(text); path = tf.name
        pager = os.environ.get("PAGER", "less -R")
        # +G opens at the end (newest log lines); user scrolls up. q returns.
        subprocess.run(pager.split() + ["+G", path])
    finally:
        if path and os.path.exists(path):
            os.unlink(path)
        tty.setcbreak(fd)


def interactive_loop(interval: float):
    """Live dashboard. Uses rich.Live so a refresh swaps the frame in place instead of
    clearing the screen first (no blank flash while SSH probes are in flight)."""
    fd = sys.stdin.fileno()
    cooked = termios.tcgetattr(fd)
    auto = True
    show_help = False
    results = gather()
    try:
        tty.setcbreak(fd)  # char-at-a-time, but keep Ctrl-C working
        with Live(console=console, screen=True, auto_refresh=False,
                  transient=False) as live:
            def paint():
                live.update(render(results, interactive=True, interval=interval,
                                   auto=auto, show_help=show_help), refresh=True)

            def open_log(idx: int):
                # leave the alt-screen so the pager owns the terminal, then re-enter
                live.stop()
                view_full_log(fd, cooked, HOSTS[idx][0])
                live.start(refresh=True)
                paint()

            paint()
            while True:
                timeout = interval if auto else None
                r, _, _ = select.select([fd], [], [], timeout)
                if not r:                       # auto-refresh tick
                    results = gather(); paint(); continue

                kind, val = read_key(fd)

                if kind == "fkey":              # F1..F9 -> remote desktop (rdp/vnc)
                    if show_help:
                        show_help = False; paint(); continue
                    idx = val - 1
                    if idx < len(HOSTS):
                        share_open(HOSTS[idx][0], results[HOSTS[idx][0]]); paint()
                    continue
                if kind != "char":              # stray escape sequence -> ignore
                    continue

                ch = val
                if ch in ("q", "Q", "\x03"):    # q or Ctrl-C
                    break
                if ch == "?":
                    show_help = not show_help; paint(); continue
                if show_help:                   # any other key dismisses help
                    show_help = False; paint(); continue
                if ch == "a":
                    auto = not auto; paint(); continue
                if ch in (" ", "g", "G"):
                    results = gather(); paint(); continue
                if ch in SHIFT_DIGITS:          # Shift+1..9 -> SSH new terminal
                    idx = SHIFT_DIGITS[ch] - 1
                    if idx < len(HOSTS):
                        ssh_open(HOSTS[idx][0]); paint()
                    continue
                if ch.isdigit() and ch != "0":  # 1..9 -> open log in pager
                    idx = int(ch) - 1
                    if idx < len(HOSTS):
                        open_log(idx)
                    continue
    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, cooked)
        console.clear()


if __name__ == "__main__":
    main()
