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

Interactive keys: press 1..N to open that machine's full log in the pager
(scroll with arrows / PgUp / PgDn, q to return); q quits the dashboard. When
stdin is not a TTY it prints one snapshot and exits.

Hosts are declared in HOSTS below as (name, type, drawdir). type = "unix" | "win".
Credentials never live here — hosts are SSH aliases resolved from ~/.ssh/config.
"""
from __future__ import annotations
import base64
import os
import select
import subprocess
import sys
import tempfile
import termios
import time
import tty
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from rich.console import Console, Group
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


def probe_host(host) -> dict:
    name, htype, drawdir = host
    try:
        if htype == "win":
            enc = base64.b64encode(win_probe_ps(drawdir).encode("utf-16-le")).decode()
            out = subprocess.run(
                ["ssh", *SSH_OPTS, name, f"powershell -NoProfile -EncodedCommand {enc}"],
                capture_output=True, text=True, timeout=20).stdout
            out = out.replace("\r", "")  # strip Windows CRLF
        else:
            out = subprocess.run(
                ["ssh", *SSH_OPTS, name, "bash -s"],
                input=unix_probe(drawdir), capture_output=True, text=True, timeout=20).stdout
    except Exception:
        out = ""
    return {"name": name, **parse(out)}


def parse(out: str) -> dict:
    d = {"REACH": "0", "BUILD": "", "BINSZ": "0", "BINMT": "-", "LOGFILE": "", "LOG": []}
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
              title_style="bold cyan", header_style="dim", expand=False, border_style="cyan")
    t.add_column("HOST", style="bold", no_wrap=True)
    t.add_column("REACH", no_wrap=True)
    t.add_column("BUILD", no_wrap=True)
    t.add_column("BINARY", no_wrap=True)
    t.add_column("NEXT (you)", no_wrap=True)
    for name, _, _ in HOSTS:
        r = results[name]
        up = r["REACH"] == "1"
        reach = Text("● up", style="green") if up else Text("○ down", style="red")
        if r["BUILD"] == "building":
            build = Text("⚙ building", style="yellow")
        elif r["BUILD"] == "idle":
            build = Text("idle", style="dim")
        else:
            build = Text("-", style="dim")
        if r["BINSZ"] not in ("0", ""):
            binary = Text.assemble((human(r["BINSZ"]), ""), ("  " + r["BINMT"], "dim"))
        else:
            binary = Text("(none)", style="dim")
        msg, style = next_note(name, r)
        t.add_row(name, reach, build, binary, Text(msg, style=style))
    return t


def build_logs(results: dict):
    """One full-width vertical lane per machine, numbered [N] in the border title so the
    interactive loop can open that host's full log in the pager on the matching key."""
    panels = []
    for i, (name, _, _) in enumerate(HOSTS, 1):
        r = results[name]
        if r["REACH"] != "1":
            body, tail = Text("(unreachable)", style="dim red"), name
        elif not r["LOG"]:
            body, tail = Text("(no recent log)", style="dim"), name
        else:
            body = Text(no_wrap=True, overflow="ellipsis")
            for ln in r["LOG"][-LOG_LANES_LINES:]:
                body.append(ln + "\n")
            tail = f"{name}: {os.path.basename(r['LOGFILE'])}"
        title = Text.assemble((f"[{i}] ", "bold yellow"), (tail, "magenta"))
        panels.append(Panel(body, title=title, title_align="left", border_style="magenta",
                           padding=(0, 1), height=LOG_LANES_LINES + 2))
    return panels


def gather() -> dict:
    with ThreadPoolExecutor(max_workers=len(HOSTS)) as ex:
        return {r["name"]: r for r in ex.map(probe_host, HOSTS)}


def render(interactive: bool = False):
    results = gather()
    parts = [build_table(results), *build_logs(results)]
    if interactive:
        keys = " ".join(f"[{i}]" for i in range(1, len(HOSTS) + 1))
        parts.append(Text(f"{keys} open full log in pager  ·  q quit  ·  auto-refresh",
                          style="dim", justify="center"))
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
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=40).stdout
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
        console.print(render()); return

    # Default & --watch: interactive. Falls back to one-shot when stdin isn't a TTY.
    interval = 3.0
    if args and args[0] == "--watch" and len(args) > 1:
        interval = float(args[1])
    if not sys.stdin.isatty():
        console.print(render()); return
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
    fd = sys.stdin.fileno()
    cooked = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)  # char-at-a-time, but keep Ctrl-C working
        while True:
            console.clear()
            console.print(render(interactive=True))
            r, _, _ = select.select([sys.stdin], [], [], interval)
            if not r:
                continue                      # timeout -> refresh
            ch = sys.stdin.read(1)
            if ch in ("q", "Q", "\x03"):      # q or Ctrl-C
                break
            if ch.isdigit() and ch != "0":
                idx = int(ch) - 1
                if idx < len(HOSTS):
                    view_full_log(fd, cooked, HOSTS[idx][0])
    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, cooked)
        console.clear()


if __name__ == "__main__":
    main()
