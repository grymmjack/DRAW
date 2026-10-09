#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["rich>=13"]
# ///
"""
qa-dash.py — live status of DRAW QA runs. Sibling of remote-dash.py (same look,
same keys) for the test side: what is running, how far along, when it will be
done, what failed and whether that failure is new.

    uv run DEV/qa-dash.py                 # interactive: auto-refresh + hotkeys
    uv run DEV/qa-dash.py --watch 5       # interactive, refresh every 5s
    uv run DEV/qa-dash.py --once          # one snapshot (also when stdin is not a TTY)
    uv run DEV/qa-dash.py --plan 'dock-'  # tests matching a regex: last results + time estimate
    uv run DEV/qa-dash.py --target "P3 exit check" 'dock-.*' 'popups-over-.*'
                                          # what the current work needs to pass (shown on the dash)
    uv run DEV/qa-dash.py --target-clear

Where the data comes from (nothing to configure):
  * live runs  - every running qa-harness runner (`bin/qa --adapter ...`) found in /proc;
                 its environment says where it writes (QA_RESULTS_DIR, else
                 $QA_HARNESS_ROOT/results) and which checkout it tests (DRAW_ROOT).
  * per run    - the harness's own files in that results dir: status.json (progress,
                 ETA), run-*.tsv (one row per finished test + its first failure reason),
                 run-*.log (the full log), durations.tsv (per-test time history),
                 screenshots/FAIL-*.png.
  * history    - every results dir ever seen is remembered in ~/.cache/qa-dash/dirs.json,
                 so a failure can be judged against earlier runs.
  * verdicts   - QA/known-failures.txt in the run's checkout ("name  reason" per line)
                 marks failures that are already understood (fails on main, flaky, ...).
  * target     - .claude/qa-target.txt: a title line, then test names or `re:REGEX` lines.

Interactive keys:
    1..9         live-follow (tail -F) that run's log; Ctrl+C returns
    Shift+1..9   open that run's newest failure screenshot
    a            toggle auto-refresh          space/g  refresh now
    ?            toggle help                  q/Ctrl-C quit
"""
from __future__ import annotations

import json
import os
import re
import select
import statistics
import subprocess
import sys
import termios
import threading
import time
import tty
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from rich.columns import Columns
from rich.console import Console, Group
from rich.live import Live
from rich.panel import Panel
from rich.progress_bar import ProgressBar
from rich.table import Table
from rich.text import Text

DRAW_HOME = Path(__file__).resolve().parent.parent
HARNESS = Path(os.environ.get("QA_HARNESS", "~/git/qa-harness")).expanduser()
CACHE = Path("~/.cache/qa-dash").expanduser()
REGISTRY = CACHE / "dirs.json"
TARGET_FILE = DRAW_HOME / ".claude" / "qa-target.txt"
RECENT_HOURS = 24
SHIFT_DIGITS = {c: i for i, c in enumerate("!@#$%^&*(", 1)}
ANSI = re.compile(r"\x1b\[[0-9;]*m")
TZ = ZoneInfo(os.environ.get("QA_DASH_TZ", "America/New_York"))   # every time shown is ET, 12-hour

console = Console()


# ── discovery ─────────────────────────────────────────────────────────────────
def _proc_env(pid: str) -> dict:
    try:
        raw = Path(f"/proc/{pid}/environ").read_bytes()
    except OSError:
        return {}
    env = {}
    for kv in raw.split(b"\0"):
        k, _, v = kv.partition(b"=")
        if k:
            env[k.decode(errors="replace")] = v.decode(errors="replace")
    return env


def live_runs() -> dict:
    """{results_dir: {pid, draw_root, args}} for every running harness runner."""
    found = {}
    for p in Path("/proc").iterdir():
        if not p.name.isdigit():
            continue
        try:
            argv = (p / "cmdline").read_bytes().split(b"\0")
        except OSError:
            continue
        args = [a.decode(errors="replace") for a in argv if a]
        if not any(a.endswith("bin/qa") for a in args) or "--adapter" not in args:
            continue
        env = _proc_env(p.name)
        rdir = env.get("QA_RESULTS_DIR") or str(Path(env.get("QA_HARNESS_ROOT", str(HARNESS))) / "results")
        rdir = str(Path(rdir).resolve())
        pid = int(p.name)
        if rdir not in found or pid < found[rdir]["pid"]:
            tests = [a for a in args if a.endswith(".sh")]
            found[rdir] = {"pid": pid, "draw_root": env.get("DRAW_ROOT", str(DRAW_HOME)), "tests": tests}
    return found


def load_registry() -> dict:
    try:
        return json.loads(REGISTRY.read_text())
    except (OSError, ValueError):
        return {}


def save_registry(reg: dict):
    try:
        CACHE.mkdir(parents=True, exist_ok=True)
        REGISTRY.write_text(json.dumps(reg, indent=1))
    except OSError:
        pass


def known_dirs(live: dict) -> dict:
    """Every results dir worth showing / learning from: live ones + remembered ones."""
    reg = load_registry()
    changed = False
    default = str((HARNESS / "results").resolve())
    if default not in reg:
        reg[default] = {"draw_root": str(DRAW_HOME)}
        changed = True
    for d, info in live.items():
        if reg.get(d, {}).get("draw_root") != info["draw_root"]:
            reg[d] = {"draw_root": info["draw_root"]}
            changed = True
    # results dirs beside a known one (runs started side by side with their own
    # QA_RESULTS_DIR) - their history counts too
    for parent in {str(Path(d).parent) for d in reg}:
        for sj in Path(parent).glob("*/status.json"):
            d = str(sj.parent.resolve())
            if d not in reg:
                reg[d] = {"draw_root": ""} # never seen running: its checkout is unknown
                changed = True
    reg = {d: v for d, v in reg.items() if Path(d).is_dir()}
    if changed:
        save_registry(reg)
    return reg


# ── per-run files ─────────────────────────────────────────────────────────────
def newest(d: Path, pattern: str) -> Path | None:
    files = sorted(d.glob(pattern), key=lambda f: f.stat().st_mtime)
    return files[-1] if files else None


def read_status(d: Path) -> dict:
    try:
        return json.loads((d / "status.json").read_text())
    except (OSError, ValueError):
        return {}


def read_tsv(f: Path | None) -> list:
    rows = []
    if not f:
        return rows
    try:
        for ln in f.read_text(errors="replace").splitlines():
            parts = ln.split("\t")
            if len(parts) >= 2:
                rows.append((parts[0], parts[1], parts[2] if len(parts) > 2 else "", parts[3] if len(parts) > 3 else ""))
    except OSError:
        pass
    return rows


def log_failures(f: Path | None) -> dict:
    """{test: [failure messages]} from a run log (covers the test still running)."""
    out, cur = {}, None
    if not f:
        return out
    try:
        for ln in f.read_text(errors="replace").splitlines():
            ln = ANSI.sub("", ln)
            m = re.match(r"^━━━ (\S+) ━━━", ln)
            if m:
                cur = m.group(1)
                continue
            if "✗" in ln and cur:
                msg = ln.split("FAIL —", 1)[-1].strip()
                out.setdefault(cur, []).append(msg)
    except OSError:
        pass
    return out


_git_cache: dict = {}


def branch_of(root: str) -> str:
    if not root:
        return "?"
    now = time.time()
    hit = _git_cache.get(root)
    if hit and now - hit[0] < 30:
        return hit[1]
    try:
        b = subprocess.run(["git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD"], capture_output=True, text=True, timeout=3).stdout.strip()
        s = subprocess.run(["git", "-C", root, "rev-parse", "--short", "HEAD"], capture_output=True, text=True, timeout=3).stdout.strip()
        val = f"{b}@{s}" if b else "?"
    except (OSError, subprocess.SubprocessError):
        val = "?"
    _git_cache[root] = (now, val)
    return val


def short_path(p: str) -> str:
    home = str(Path.home())
    p = p.replace(home, "~")
    p = re.sub(r"^/tmp/claude-\d+/[^/]+/[^/]+/scratchpad", "<claude scratch>", p)
    return p


# ── history, verdicts, estimates ──────────────────────────────────────────────
_hist_cache: dict = {}


def history(reg: dict) -> dict:
    """{test: [(time, result), ...]} oldest first, across every known results dir."""
    out: dict = {}
    for d in reg:
        for f in Path(d).glob("run-*.tsv"):
            try:
                mt = f.stat().st_mtime
            except OSError:
                continue
            key = str(f)
            if key not in _hist_cache or _hist_cache[key][0] != mt:
                _hist_cache[key] = (mt, read_tsv(f))
            for name, res, _, _ in _hist_cache[key][1]:
                out.setdefault(name, []).append((mt, res, key))
    for v in out.values():
        v.sort()
    return out


def durations(reg: dict) -> dict:
    """{test: median seconds of its last 10 timings} across every known results dir."""
    raw: dict = {}
    for d in reg:
        try:
            for ln in (Path(d) / "durations.tsv").read_text().splitlines():
                n, _, s = ln.partition("\t")
                if s.strip().isdigit():
                    raw.setdefault(n, []).append(int(s))
        except OSError:
            pass
    return {n: int(statistics.median(v[-10:])) for n, v in raw.items()}


def known_failures(root: str) -> dict:
    out = {}
    for base in (Path(root), DRAW_HOME):
        f = base / "QA" / "known-failures.txt"
        if f.is_file():
            for ln in f.read_text().splitlines():
                ln = ln.strip()
                if ln and not ln.startswith("#"):
                    name, _, why = ln.partition(" ")
                    out.setdefault(name.strip(), why.strip() or "known")
            break
    return out


def verdict(name: str, hist: dict, this_tsv: str | None, known: dict) -> tuple[str, str]:
    """(label, style) for a failure: known / flaky / NEW / failed before / first run."""
    if name in known:
        return (f"known: {known[name]}", "yellow")
    past = [r for (_, r, f) in hist.get(name, []) if f != this_tsv and r in ("pass", "fail")][-6:]
    if not past:
        return ("first run", "cyan")
    fails = past.count("fail")
    if fails == 0:
        return ("NEW", "bold red")
    if fails == len(past):
        return (f"failed before too ({fails}/{len(past)})", "magenta")
    return (f"flaky ({fails}/{len(past)} failed)", "yellow")


def clock(epoch, secs: bool = False) -> str:
    """A time of day in ET, 12-hour ("2:35 PM")."""
    if not epoch:
        return "?"
    return datetime.fromtimestamp(epoch, TZ).strftime("%-I:%M:%S %p" if secs else "%-I:%M %p")


def started_at(log: Path | None, st: dict) -> float:
    """When a run began: its log's name (run-YYYYMMDD-HHMMSS, local time), else
    the last update minus the elapsed time."""
    if log:
        m = re.search(r"run-(\d{8}-\d{6})", log.name)
        if m:
            try:
                return time.mktime(time.strptime(m.group(1), "%Y%m%d-%H%M%S"))
            except ValueError:
                pass
    if st.get("updated") and st.get("elapsed_s") is not None:
        return float(st["updated"]) - float(st["elapsed_s"])
    return 0.0


def fields(pairs: list) -> Table:
    """One row of LABEL value pairs."""
    g = Table.grid(padding=(0, 1))
    for _ in pairs:
        g.add_column(no_wrap=True)
        g.add_column(no_wrap=True)
    row = []
    for label, value in pairs:
        row.append(Text(label, style="dim"))
        v = value.copy() if isinstance(value, Text) else Text(str(value), style="bold")
        v.append("    ")
        row.append(v)
    g.add_row(*row)
    return g


def fmt_secs(s) -> str:
    try:
        s = int(s)
    except (TypeError, ValueError):
        return "?"
    h, rem = divmod(max(s, 0), 3600)
    m, sec = divmod(rem, 60)
    return f"{h}:{m:02d}:{sec:02d}" if h else f"{m}:{sec:02d}"


# ── gather ────────────────────────────────────────────────────────────────────
def gather() -> dict:
    live = live_runs()
    reg = known_dirs(live)
    hist = history(reg)
    dur = durations(reg)
    runs = []
    now = time.time()
    for d, info in reg.items():
        dp = Path(d)
        st = read_status(dp)
        tsv = newest(dp, "run-*.tsv")
        log = newest(dp, "run-*.log")
        updated = st.get("updated") or (log.stat().st_mtime if log else 0)
        is_live = d in live
        if not is_live and now - updated > RECENT_HOURS * 3600:
            continue
        root = live[d]["draw_root"] if is_live else info.get("draw_root", str(DRAW_HOME))
        kroot = root or str(DRAW_HOME)
        rows = read_tsv(tsv)
        lf = log_failures(log)
        fails = {}
        for name, res, secs, notes in rows:
            if res == "fail":
                fails[name] = lf.get(name, [notes] if notes else ["(no message)"])
        cur = st.get("test")
        if is_live and cur in lf and cur not in fails:
            fails[cur] = lf[cur]                    # failing right now, still running
        runs.append({
            "tests": [Path(x).stem for x in live[d]["tests"]] if is_live else [],
            "dir": d, "label": "harness default" if dp.name == "results" else dp.name.removeprefix("qa-"),
            "root": root, "branch": branch_of(root), "live": is_live, "status": st, "rows": rows,
            "fails": fails, "log": str(log) if log else "", "tsv": str(tsv) if tsv else None,
            "updated": updated, "known": known_failures(kroot), "dir_path": dp,
            "started": started_at(log, st),
        })
    runs.sort(key=lambda r: (not r["live"], -r["updated"]))
    for r in runs:
        r["eta"] = better_eta(r, dur, now)
        r["typical"] = dur.get(r["status"].get("test", ""), 0)
    return {"runs": runs, "hist": hist, "reg": reg, "when": now, "dur": dur}


def better_eta(r: dict, dur: dict, now: float):
    """(left_s, done_epoch) from every results dir's timing history for the tests this
    run still has to do - the harness only knows its own dir's history (a fresh dir
    guesses 20s a test). None when the history covers too little of what is left."""
    st, tests = r["status"], r.get("tests") or []
    cur = int(st.get("current", 0) or 0)
    if not r["live"] or not tests or cur < 1:
        return None
    rest = tests[cur - 1:]
    if not rest:
        return None
    known = [t for t in rest if t in dur]
    if len(known) * 2 < len(rest):
        return None
    left = sum(dur.get(t, 20) for t in rest)
    # minus the time already spent on the current test
    started = r["rows"] and len(r["rows"]) == cur - 1 and r.get("updated")
    if started:
        left -= max(0, int(now - r["updated"]))
    left = max(left, 0)
    return (left, now + left)


# ── target / plan ─────────────────────────────────────────────────────────────
def tests_in(root: str) -> list:
    return sorted(p.stem for p in (Path(root) / "QA" / "tests").glob("*.sh"))


def resolve(patterns: list, root: str) -> list:
    allt = tests_in(root)
    out = []
    for pat in patterns:
        pat = pat.strip()
        if not pat or pat.startswith("#"):
            continue
        # accept the runner's own patterns too (they match file names)
        pat = re.sub(r"(\\\.sh\$|\.sh\$|\.sh)$", "$" if pat.endswith("$") else "", pat)
        rx = re.compile(pat[3:] if pat.startswith("re:") else pat if any(c in pat for c in "^$*.+?[(|") else "^" + re.escape(pat) + "$")
        out += [t for t in allt if rx.search(t) and t not in out]
    return out


def plan_summary(tests: list, hist: dict, dur: dict) -> dict:
    total = sum(dur.get(t, 20) for t in tests)
    last = {t: (hist.get(t) or [(0, "never", "")])[-1][1] for t in tests}
    return {"total": total, "last": last,
            "passing": [t for t in tests if last[t] == "pass"],
            "failing": [t for t in tests if last[t] == "fail"],
            "never": [t for t in tests if last[t] not in ("pass", "fail")]}


def read_target():
    try:
        lines = TARGET_FILE.read_text().splitlines()
    except OSError:
        return None
    if not lines:
        return None
    return lines[0].strip(), lines[1:]


# ── the build farm (DEV/farm-check.sh records, titan's live run over SSH) ─────
FARM_STATE = CACHE / "farm"
FARM_ORDER = ["mac", "titan", "daw", "thinkpad"]
FARM_OS = {"mac": "macOS", "titan": "Linux", "daw": "Windows (WSL build)", "thinkpad": "Windows"}
FARM_LIVE: dict = {}          # host -> {"status":{}, "fails":[(name,msg)], "live":bool, "when":t}
FARM_LOCK = threading.Lock()


def farm_states() -> dict:
    out = {}
    for f in FARM_STATE.glob("*.json"):
        try:
            out[f.stem] = json.loads(f.read_text())
        except (OSError, ValueError):
            pass
    return out


def farm_probe(host: str, rdir: str) -> dict:
    """titan's QA run: status.json, the fail rows of its newest run TSV, runner alive?"""
    sh = (f'cat "{rdir}/status.json" 2>/dev/null; echo; echo ===; '
          f'f=$(ls -t "{rdir}"/run-*.tsv 2>/dev/null | head -1); [ -n "$f" ] && grep -P "\\tfail\\t" "$f"; echo ===; '
          f'pgrep -f "bin/qa --adapter" >/dev/null && echo LIVE || echo GONE')
    try:
        out = subprocess.run(["ssh", "-o", "ConnectTimeout=6", "-o", "BatchMode=yes", host, sh],
                             capture_output=True, text=True, timeout=20).stdout
    except (OSError, subprocess.SubprocessError):
        return {}
    parts = out.split("===")
    st = {}
    try:
        st = json.loads(parts[0].strip().splitlines()[-1]) if parts[0].strip() else {}
    except (ValueError, IndexError):
        st = {}
    fails = []
    if len(parts) > 1:
        for ln in parts[1].strip().splitlines():
            c = ln.split("\t")
            if len(c) >= 2:
                fails.append((c[0], c[3] if len(c) > 3 else ""))
    live = len(parts) > 2 and "LIVE" in parts[2]
    return {"status": st, "fails": fails, "live": live, "when": time.time()}


def farm_refresh_once():
    for host, s in farm_states().items():
        if s.get("results"):
            r = farm_probe(host, s["results"])
            if r:
                with FARM_LOCK:
                    FARM_LIVE[host] = r


def farm_refresher(stop: threading.Event, every: float = 15.0):
    while not stop.is_set():
        farm_refresh_once()
        stop.wait(every)


def farm_panel(host: str, s: dict, hist: dict) -> Panel:
    parts = []
    state = s.get("state", "?")
    style = {"building": "bold yellow", "built": "bold green", "failed": "bold white on red",
             "qa-running": "bold green", "qa-done": "bold"}.get(state, "bold")
    label = {"building": "BUILDING", "built": "BUILT", "failed": "BUILD FAILED"}.get(state, state.upper())
    started, finished = s.get("started", 0), s.get("finished", 0)
    ref = str(s.get("ref", "?")).removeprefix("origin/")
    parts.append(fields([("BUILD", Text(label, style=style)), ("REF", ref), ("SHA", s.get("sha") or "-")]))
    pairs = [("STARTED", clock(started))]
    if finished:
        pairs += [("FINISHED", clock(finished)), ("TOOK", fmt_secs(finished - started))]
    elif state == "building":
        pairs += [("ELAPSED", fmt_secs(time.time() - started))]
    parts.append(fields(pairs))
    if state == "failed" and s.get("msg"):
        parts.append(Text("why: " + s["msg"], style="bold red"))
    with FARM_LOCK:
        lv = dict(FARM_LIVE.get(host, {}))
    if s.get("results"):
        st = lv.get("status") or {}
        cur, total = int(st.get("current", 0) or 0), int(st.get("total", 0) or 0)
        nf = int(st.get("failed", 0) or 0)
        res = Text(f"✓ {st.get('passed', 0)}", style="bold green")
        res.append(f"  ✗ {nf}", style="bold red" if nf else "dim")
        phase = st.get("phase", "")
        if lv.get("live") and phase == "running":
            qs = Text("RUNNING", style="bold green")
        elif phase == "done":
            qs = Text("FINISHED", style="bold")
        elif phase == "aborted":
            qs = Text("ABORTED", style="bold white on red")
        elif not st:
            qs = Text("starting…" if lv else "no data yet", style="dim")
        else:
            qs = Text("STOPPED", style="bold yellow")
        parts.append(fields([("QA", qs), ("RESULT", res)]))
        qpairs = [("STARTED", clock(s.get("qa_started")))]
        if phase == "running":
            qpairs += [("LEFT", "~" + fmt_secs(st.get("remaining_s"))), ("EST", Text(clock(st.get("eta_epoch")), style="bold yellow"))]
        else:
            qpairs += [("ELAPSED", fmt_secs(st.get("elapsed_s")))]
        parts.append(fields(qpairs))
        if total and phase == "running":
            bar = Table.grid(padding=(0, 1)); bar.add_column(width=28); bar.add_column()
            bar.add_row(ProgressBar(total=total, completed=max(cur - 1, 0), width=28),
                        Text.assemble((f"{cur}/{total}", "bold"), "  ", (st.get("test", ""), "cyan")))
            parts.append(bar)
        if st.get("reason"):
            parts.append(Text("why: " + st["reason"], style="bold red"))
        if lv.get("fails"):
            known = known_failures(str(DRAW_HOME))
            ft = Table(box=None, show_header=False, padding=(0, 1), expand=True)
            ft.add_column(style="red", no_wrap=True); ft.add_column(no_wrap=True)
            ft.add_column(style="dim", overflow="ellipsis", no_wrap=True, ratio=1)
            for name, msg in lv["fails"][:8]:
                lab, sty = verdict(name, hist, None, known)
                ft.add_row(name, Text(lab, style=sty), msg)
            parts.append(ft)
        if lv.get("when"):
            parts.append(Text(f"checked {int(time.time() - lv['when'])}s ago", style="dim"))
    title = Text.assemble(("farm: ", "dim"), (host, "bold magenta"), (f"  {FARM_OS.get(host, '')}", "dim"))
    border = "red" if state == "failed" else "magenta" if state in ("building", "qa-running") else "dim"
    return Panel(Group(*parts), title=title, title_align="left", border_style=border, padding=(0, 1))


def farm_section(hist: dict):
    states = farm_states()
    if not states:
        return None
    panels = [farm_panel(h, states[h], hist) for h in FARM_ORDER if h in states]
    panels += [farm_panel(h, s, hist) for h, s in states.items() if h not in FARM_ORDER]
    width = max(60, console.size.width // 2 - 2)
    return Columns(panels, width=width, expand=False)


# ── render ────────────────────────────────────────────────────────────────────
def run_panel(i: int, r: dict, hist: dict) -> Panel:
    st = r["status"]
    body = []
    head = Text()
    head.append(r["branch"], style="bold green")
    head.append("  ·  " + short_path(r["root"]), style="dim")
    body.append(head)
    cur, total = int(st.get("current", 0) or 0), int(st.get("total", 0) or 0)
    if r["live"] and total:
        bar = Table.grid(padding=(0, 1))
        bar.add_column(width=34)
        bar.add_column()
        info = Text.assemble((f"{cur}/{total}", "bold"), "  ", (st.get("test", ""), "cyan"))
        # how long the current test has run (status.json is written as each test
        # starts) against its usual time - progress only moves between tests, so a
        # long test should not look like a hang; far past usual is flagged
        if st.get("updated"):
            inn = max(0, time.time() - float(st["updated"]))
            typ = r.get("typical") or 0
            info.append(f"   {fmt_secs(inn)}", style="bold")
            info.append(f" / usually {fmt_secs(typ)}" if typ else " / no history", style="dim")
            if inn > max(3 * typ, typ + 120, 180):
                info.append("   STALLED?", style="bold white on red")
        bar.add_row(ProgressBar(total=total, completed=max(cur - 1, 0), width=34), info)
        body.append(bar)
    nf = int(st.get("failed", 0) or 0)
    res = Text(f"✓ {st.get('passed', 0)}", style="bold green")
    res.append(f"  ✗ {nf}", style="bold red" if nf else "dim")
    started = r.get("started") or 0
    now = time.time()
    if r["live"]:
        elapsed = now - started if started else st.get("elapsed_s")
        if r.get("eta"):
            left, done = r["eta"]
            est = Text(clock(done), style="bold yellow")
        else:
            left = st.get("remaining_s")
            est = Text(clock(st.get("eta_epoch")), style="bold yellow")
            est.append(" (little history)", style="dim")
        body.append(fields([("STATUS", Text("RUNNING", style="bold green")), ("STARTED", clock(started)),
                            ("ELAPSED", fmt_secs(elapsed)), ("LEFT", "~" + fmt_secs(left)), ("EST", est), ("RESULT", res)]))
    else:
        phase = st.get("phase", "")
        if phase == "done":
            state = Text("FINISHED", style="bold")
        elif phase == "aborted":
            state = Text("ABORTED", style="bold white on red")
        else:
            state = Text("STOPPED", style="bold yellow")   # runner gone without saying why (older harness)
        elapsed = st.get("elapsed_s") if st.get("elapsed_s") is not None else (r["updated"] - started if started else None)
        body.append(fields([("STATUS", state), ("STARTED", clock(started)), ("FINISHED", clock(r["updated"])),
                            ("ELAPSED", fmt_secs(elapsed)), ("RESULT", res)]))
        if st.get("reason"):
            body.append(Text("why: " + st["reason"], style="bold red"))
    if r["fails"]:
        ft = Table(box=None, show_header=False, padding=(0, 1), expand=True)
        ft.add_column("test", style="red", no_wrap=True)
        ft.add_column("verdict", no_wrap=True)
        ft.add_column("why", style="dim", overflow="ellipsis", no_wrap=True, ratio=1)
        for name, msgs in r["fails"].items():
            lab, sty = verdict(name, hist, r["tsv"], r["known"])
            ft.add_row(name, Text(lab, style=sty), msgs[0] if msgs else "")
        body.append(ft)
    elif r["rows"]:
        body.append(Text("no failures", style="green"))
    recent = r["rows"][-3:]
    if r["live"] and recent:
        t = Text("last: ", style="dim")
        for name, res, secs, _ in recent:
            t.append(("✓ " if res == "pass" else "✗ " if res == "fail" else "· ") + name, style="green" if res == "pass" else "red" if res == "fail" else "dim")
            t.append(f" {secs}s   ", style="dim")
        body.append(t)
    title = Text.assemble((f"[{i}] ", "bold yellow"), (r["label"], "bold magenta"),
                          ("  LIVE" if r["live"] else "", "bold green"))
    return Panel(Group(*body), title=title, title_align="left",
                 border_style="magenta" if r["live"] else "dim", padding=(0, 1))


def target_panel(data: dict) -> Panel | None:
    tg = read_target()
    if not tg:
        return None
    title, pats = tg
    tests = resolve(pats, str(DRAW_HOME))
    ps = plan_summary(tests, data["hist"], durations(data["reg"]))
    t = Text()
    t.append(f"{len(tests)} tests", style="bold")
    t.append(f"   ~{fmt_secs(ps['total'])} to run", style="yellow")
    t.append(f" (started now: done ~{clock(time.time() + ps['total'])})", style="dim")
    t.append(f"   last: ✓ {len(ps['passing'])}  ", style="green")
    t.append(f"✗ {len(ps['failing'])}  ", style="bold red" if ps["failing"] else "dim")
    t.append(f"never run {len(ps['never'])}", style="cyan" if ps["never"] else "dim")
    parts = [t]
    if ps["failing"]:
        parts.append(Text("failing last time: " + ", ".join(ps["failing"][:12]) + (" …" if len(ps["failing"]) > 12 else ""), style="red"))
    return Panel(Group(*parts), title=Text.assemble(("needs to pass: ", "dim"), (title, "bold cyan")),
                 title_align="left", border_style="cyan", padding=(0, 1))


RECENT_SHOWN = 5


def visible_runs(runs: list) -> list:
    """Live runs, then the latest few finished ones - the order the 1..9 keys use."""
    live = [r for r in runs if r["live"]]
    done = [r for r in runs if not r["live"] and (r["rows"] or r["status"].get("phase") == "aborted")][:RECENT_SHOWN]
    return (live + done)[:9]


def recent_table(done: list, first: int, hist: dict) -> Panel:
    t = Table(box=None, padding=(0, 1), expand=True, show_header=True, header_style="dim")
    t.add_column("#", style="bold yellow", no_wrap=True)
    t.add_column("run", style="magenta", no_wrap=True)
    t.add_column("branch", style="green", no_wrap=True)
    t.add_column("status", no_wrap=True)
    t.add_column("started", no_wrap=True)
    t.add_column("finished", no_wrap=True)
    t.add_column("elapsed", no_wrap=True, justify="right")
    t.add_column("result", no_wrap=True)
    t.add_column("failures", ratio=1, overflow="ellipsis", no_wrap=True)
    for k, r in enumerate(done, first + 1):
        npass = int(r["status"].get("passed", sum(1 for x in r["rows"] if x[1] == "pass")) or 0)  # checks, as in the live panels
        nfail = int(r["status"].get("failed", len(r["fails"])) or 0)
        res = Text(f"✓ {npass} ", style="green")
        res.append(f"✗ {nfail}", style="bold red" if nfail else "dim")
        ph = r["status"].get("phase")
        if ph == "aborted":
            state = Text("ABORTED", style="bold red")
        elif ph not in ("done", None, ""):
            state = Text("STOPPED", style="yellow")
        else:
            state = Text("FINISHED", style="dim")
        st0 = r.get("started") or 0
        el = r["status"].get("elapsed_s")
        if el is None and st0:
            el = r["updated"] - st0
        fl = Text()
        for name in r["fails"]:
            lab, sty = verdict(name, hist, r["tsv"], r["known"])
            fl.append(name, style="red")
            fl.append(f" ({lab.split(' (')[0].split(':')[0]})  ", style=sty)
        if r["status"].get("reason"):
            fl = Text("why: " + r["status"]["reason"], style="bold red")
        t.add_row(f"[{k}]", r["label"], r["branch"], state, clock(st0), clock(r["updated"]), fmt_secs(el), res,
                  fl if (r["fails"] or r["status"].get("reason")) else Text("—", style="dim"))
    return Panel(t, title=Text("recent runs", style="bold"), title_align="left", border_style="dim", padding=(0, 1))


def build_help() -> Panel:
    body = Text()
    for key, desc in [("1 - 9", "LIVE-follow (tail -F) that run's log; Ctrl+C returns"),
                      ("Shift+1..9", "open that run's newest failure screenshot"),
                      ("a", "toggle auto-refresh on/off"), ("space / g", "refresh now"),
                      ("?", "toggle this help"), ("q / Ctrl-C", "quit")]:
        body.append(f"  {key:<12}", style="bold yellow")
        body.append(desc + "\n")
    body.append("\n  Verdicts: NEW = passed in its last runs · flaky = mixed · failed before too ·\n"
                "  known = listed in QA/known-failures.txt · first run = no history yet.", style="dim")
    return Panel(body, title="hotkeys", title_align="left", border_style="cyan", padding=(1, 2))


def build_footer(interval: float, auto: bool) -> Text:
    f = Text(justify="center")
    for k, d in [("1-9", " log  ·  "), ("⇧1-9", " screenshot  ·  ")]:
        f.append(k, style="bold yellow"); f.append(d, style="dim")
    f.append(f"[a]uto-refresh ({interval:g}s): ON" if auto else "[a]uto-refresh: OFF (space=refresh)",
             style="cyan" if auto else "yellow")
    f.append("  ·  ", style="dim"); f.append("?", style="bold yellow"); f.append(" help  ·  ", style="dim")
    f.append("q", style="bold yellow"); f.append(" quit", style="dim")
    return f


def render(data: dict, interactive=False, interval=3.0, auto=True, show_help=False):
    runs = data["runs"]
    nlive = sum(1 for r in runs if r["live"])
    head = Text.assemble(("DRAW QA", "bold"), (f"   {nlive} running", "bold green" if nlive else "dim"),
                         (f" · {len(runs) - nlive} recent", "dim"),
                         ("   " + clock(data["when"], True) + " ET", "dim"))
    parts = [head]
    tp = target_panel(data)
    if tp:
        parts.append(tp)
    fs = farm_section(data["hist"])
    if fs is not None:
        parts.append(fs)
    if not runs:
        parts.append(Panel(Text("No QA runs in the last day. Start one with QA/draw-qa.sh.", style="dim")))
    shown = visible_runs(runs)
    i = 0
    for r in shown:
        if r["live"]:
            i += 1
            parts.append(run_panel(i, r, data["hist"]))
    done = [r for r in shown if not r["live"]]
    if done:
        parts.append(recent_table(done, i, data["hist"]))
    if show_help:
        parts.append(build_help())
    if interactive:
        parts.append(build_footer(interval, auto))
    return Group(*parts)


# ── actions ───────────────────────────────────────────────────────────────────
def follow_log(fd, cooked, r: dict):
    termios.tcsetattr(fd, termios.TCSADRAIN, cooked)
    if r["log"]:
        print(f"== following {r['log']}   (Ctrl+C to return) ==")
        try:
            subprocess.run(["tail", "-n", "200", "-F", r["log"]])
        except KeyboardInterrupt:
            pass
    tty.setcbreak(fd)


def open_screenshot(r: dict):
    shots = sorted((r["dir_path"] / "screenshots").glob("FAIL-*.png"), key=lambda f: f.stat().st_mtime)
    if shots:
        subprocess.Popen(["xdg-open", str(shots[-1])], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def read_key(fd) -> str:
    ch = os.read(fd, 1).decode("latin-1")
    if ch == "\x1b":                       # swallow escape sequences
        while select.select([fd], [], [], 0.03)[0]:
            os.read(fd, 1)
        return ""
    return ch


def interactive_loop(interval: float):
    fd = sys.stdin.fileno()
    cooked = termios.tcgetattr(fd)
    auto, show_help = True, False
    stop = threading.Event()
    threading.Thread(target=farm_refresher, args=(stop,), daemon=True).start()
    data = gather()
    try:
        tty.setcbreak(fd)
        with Live(console=console, screen=True, auto_refresh=False, transient=False) as live:
            def paint():
                live.update(render(data, True, interval, auto, show_help), refresh=True)
            paint()
            while True:
                r, _, _ = select.select([fd], [], [], interval if auto else None)
                if not r:
                    data = gather(); paint(); continue
                ch = read_key(fd)
                if ch in ("q", "Q", "\x03"):
                    break
                if ch == "?":
                    show_help = not show_help; paint(); continue
                if show_help:
                    show_help = False; paint(); continue
                if ch == "a":
                    auto = not auto; paint(); continue
                if ch in (" ", "g", "G"):
                    data = gather(); paint(); continue
                vis = visible_runs(data["runs"])
                if ch in SHIFT_DIGITS:
                    idx = SHIFT_DIGITS[ch] - 1
                    if idx < len(vis):
                        open_screenshot(vis[idx])
                    continue
                if ch.isdigit() and ch != "0":
                    idx = int(ch) - 1
                    if idx < len(vis):
                        live.stop(); follow_log(fd, cooked, vis[idx]); live.start(refresh=True)
                        data = gather(); paint()
    except KeyboardInterrupt:
        pass
    finally:
        stop.set()
        termios.tcsetattr(fd, termios.TCSADRAIN, cooked)
        console.clear()


def print_plan(patterns: list):
    reg = known_dirs(live_runs())
    tests = resolve(patterns, str(DRAW_HOME))
    hist, dur = history(reg), durations(reg)
    ps = plan_summary(tests, hist, dur)
    t = Table(title=f"{len(tests)} tests · ~{fmt_secs(ps['total'])}", title_justify="left")
    t.add_column("test"); t.add_column("est", justify="right"); t.add_column("last result")
    for name in tests:
        last = ps["last"][name]
        t.add_row(name, fmt_secs(dur.get(name, 20)) + ("" if name in dur else "?"),
                  Text(last, style="green" if last == "pass" else "red" if last == "fail" else "cyan"))
    console.print(t)


def main():
    args = sys.argv[1:]
    if args[:1] == ["--plan"] and len(args) > 1:
        print_plan(args[1:]); return
    if args[:1] == ["--target"] and len(args) > 2:
        TARGET_FILE.parent.mkdir(parents=True, exist_ok=True)
        TARGET_FILE.write_text("\n".join([args[1], *args[2:]]) + "\n")
        console.print(f"target set: [bold]{args[1]}[/] ({len(resolve(args[2:], str(DRAW_HOME)))} tests)"); return
    if args[:1] == ["--target-clear"]:
        TARGET_FILE.unlink(missing_ok=True); console.print("target cleared"); return
    if args[:1] == ["--once"] or not sys.stdin.isatty():
        farm_refresh_once()
        console.print(render(gather())); return
    interval = float(args[1]) if args[:1] == ["--watch"] and len(args) > 1 else 3.0
    interactive_loop(interval)


if __name__ == "__main__":
    main()
