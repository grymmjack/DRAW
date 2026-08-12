#!/usr/bin/env python3
"""
dump-qa-tests.py — categorized status report for the DRAW QA suite.

Cross-references the test files in QA/tests/*.sh with the full run history in
QA/results/run-*.log to show, per test: how many times it actually ran, how many
passed / failed, when it last ran, its last result, and when it last passed /
failed. Grouped by category (the filename prefix before the first '-').

Pure stdlib. Reads only; never launches DRAW or touches draw-qa.sh.

Usage:
    python3 dump-qa-tests.py [QA_DIR] [--category NAME] [--failing] [--never]
                             [--sort runs|name|last] [--no-color]

    QA_DIR        path to the QA/ dir (default: auto-detect from this file, else ./QA)
    --category X  only show category X (e.g. layer, gui, tool)
    --failing     only show tests whose most recent run FAILED
    --never       only show tests that have never actually run
    --sort        order tests within a category (default: name)
"""
import os
import re
import sys
import glob

ANSI = re.compile(r"\x1b\[[0-9;]*m")
# A test block opens with a line like: ━━━ <name> ━━━  (box-drawing U+2501).
HEADER = re.compile(r"^\s*━+\s*(\S.*?)\s*━+\s*$")
RUNLOG = re.compile(r"run-(\d{8})-(\d{6})\.log$")


def strip(s):
    return ANSI.sub("", s).rstrip("\n")


def ts_from_name(path):
    """run-YYYYMMDD-HHMMSS.log -> sortable 'YYYYMMDDHHMMSS' and pretty string."""
    m = RUNLOG.search(os.path.basename(path))
    if not m:
        return None, None
    d, t = m.group(1), m.group(2)
    key = d + t
    pretty = f"{d[0:4]}-{d[4:6]}-{d[6:8]} {t[0:2]}:{t[2:4]}"
    return key, pretty


def parse_log(path):
    """Return {test_name: outcome} for one run log.

    outcome is one of: 'pass', 'fail', 'skip' (intentional), 'cached'
    (skipped only because the passed-cache already had it — did NOT run).
    """
    out = {}
    cur = None
    saw_fail = False
    ran = False

    def flush():
        nonlocal cur, saw_fail, ran
        if cur is None:
            return
        # SKIP lines already recorded a terminal state; only finalize a real run.
        if cur not in out:
            out[cur] = "fail" if saw_fail else ("pass" if ran else "unknown")
        cur, saw_fail, ran = None, False, False

    try:
        with open(path, "r", errors="replace") as fh:
            for raw in fh:
                line = strip(raw)
                h = HEADER.match(line)
                if h:
                    flush()
                    cur = h.group(1).strip()
                    saw_fail = False
                    ran = False
                    continue
                if cur is None:
                    continue
                if "~ SKIP" in line:
                    # "  ~ SKIP — <name> — <reason>"
                    reason = line.split("—")[-1].strip().lower()
                    out[cur] = "cached" if "already passed" in reason else "skip"
                    # terminal for this block; a real run won't also SKIP
                elif "✓ PASS" in line or "► " in line and ": done" in line:
                    ran = True
                elif "✗ FAIL" in line:
                    ran = True
                    saw_fail = True
        flush()
    except OSError:
        pass
    # drop non-run terminal 'unknown'
    return {k: v for k, v in out.items() if v != "unknown"}


def category_of(name):
    return name.split("-", 1)[0] if "-" in name else name


RESULTS = re.compile(r"Results:\s*(\d+)\s+passed\s+(\d+)\s+failed\s+(\d+)\s+skipped")


def latest_full_run(logs):
    """Newest log that looks like a whole-suite run; returns (pretty, passed, failed, skipped)."""
    for lg in reversed(logs):
        try:
            with open(lg, "r", errors="replace") as fh:
                txt = strip(fh.read())
        except OSError:
            continue
        m = RESULTS.search(txt)
        if m and int(m.group(1)) >= 50:  # a real suite, not a single-test run
            _, pretty = ts_from_name(lg)
            return pretty, int(m.group(1)), int(m.group(2)), int(m.group(3))
    return None


def _esc(s):
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


HTML_CSS = """
<style>
  :root{
    --bg:#f7f8fa; --surface:#ffffff; --surface2:#f0f2f5; --border:#dde1e7;
    --text:#1a1f26; --muted:#657084; --faint:#9aa4b2;
    --accent:#0d9488; --pass:#16a34a; --fail:#dc2626; --skip:#d97706;
    --passbg:#dcfce7; --failbg:#fee2e2; --skipbg:#fef3c7; --neverbg:#eef1f5;
    --shadow:0 1px 2px rgba(16,24,40,.06),0 1px 3px rgba(16,24,40,.04);
  }
  :root:not([data-theme="light"]){}
  @media (prefers-color-scheme: dark){
    :root:not([data-theme="light"]){
      --bg:#0f1216; --surface:#171b21; --surface2:#1f242c; --border:#2a303a;
      --text:#e7ecf3; --muted:#93a0b4; --faint:#5f6b7c;
      --accent:#2dd4bf; --pass:#4ade80; --fail:#f87171; --skip:#fbbf24;
      --passbg:#0f2a1a; --failbg:#2c1416; --skipbg:#2a2010; --neverbg:#1b2028;
      --shadow:0 1px 2px rgba(0,0,0,.4);
    }
  }
  :root[data-theme="dark"]{
    --bg:#0f1216; --surface:#171b21; --surface2:#1f242c; --border:#2a303a;
    --text:#e7ecf3; --muted:#93a0b4; --faint:#5f6b7c;
    --accent:#2dd4bf; --pass:#4ade80; --fail:#f87171; --skip:#fbbf24;
    --passbg:#0f2a1a; --failbg:#2c1416; --skipbg:#2a2010; --neverbg:#1b2028;
    --shadow:0 1px 2px rgba(0,0,0,.4);
  }
  *{box-sizing:border-box}
  /* Paint the WHOLE page (incl. the gutters around the centered container) from
     tokens — a transparent body borrows the host's ground and shows white. */
  html,body{background:var(--bg);color:var(--text);margin:0}
  .qa{background:var(--bg);color:var(--text);
    font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
    line-height:1.5;padding:32px 24px 64px;max-width:1120px;margin:0 auto;}
  .qa h1{font-size:1.55rem;font-weight:680;letter-spacing:-.01em;margin:0 0 4px;text-wrap:balance}
  .qa .sub{color:var(--muted);font-size:.9rem;margin:0 0 24px}
  .qa .mono{font-family:ui-monospace,"SF Mono",SFMono-Regular,Menlo,Consolas,monospace}
  .cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin:0 0 24px}
  .card{background:var(--surface);border:1px solid var(--border);border-radius:12px;
    padding:14px 16px;box-shadow:var(--shadow)}
  .card .n{font-size:1.9rem;font-weight:700;font-variant-numeric:tabular-nums;line-height:1.1}
  .card .l{font-size:.72rem;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);margin-top:2px}
  .card.ok .n{color:var(--pass)} .card.bad .n{color:var(--fail)} .card.warn .n{color:var(--skip)}
  .callout{border:1px solid var(--border);border-left:4px solid var(--fail);background:var(--failbg);
    border-radius:10px;padding:14px 16px;margin:0 0 28px}
  .callout.clean{border-left-color:var(--pass);background:var(--passbg)}
  .callout h2{font-size:.95rem;margin:0 0 8px;font-weight:640}
  .callout .chips{display:flex;flex-wrap:wrap;gap:8px}
  .chip{font-family:ui-monospace,monospace;font-size:.8rem;background:var(--surface);
    border:1px solid var(--border);border-radius:999px;padding:3px 10px}
  .cat{margin:26px 0 0}
  .cat-h{display:flex;align-items:baseline;gap:10px;margin:0 0 8px;padding-bottom:6px;border-bottom:1px solid var(--border)}
  .cat-h .name{font-family:ui-monospace,monospace;font-weight:680;font-size:1rem;color:var(--accent)}
  .cat-h .meta{font-size:.8rem;color:var(--muted)}
  .cat-h .fnow{color:var(--fail);font-weight:600}
  .twrap{overflow-x:auto;border:1px solid var(--border);border-radius:10px;background:var(--surface)}
  table{border-collapse:collapse;width:100%;font-size:.83rem}
  thead th{font-size:.68rem;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);
    text-align:left;font-weight:600;padding:9px 12px;background:var(--surface2);white-space:nowrap;position:sticky;top:0}
  td{padding:8px 12px;border-top:1px solid var(--border);white-space:nowrap}
  td.t{font-family:ui-monospace,monospace;font-weight:560}
  td.num{text-align:right;font-variant-numeric:tabular-nums;font-family:ui-monospace,monospace}
  td.num.f{color:var(--fail)} td.num.z{color:var(--faint)}
  td.dt{font-variant-numeric:tabular-nums;color:var(--muted);font-size:.8rem;font-family:ui-monospace,monospace}
  tr.failrow td.t{color:var(--fail)}
  .pill{display:inline-block;font-size:.7rem;font-weight:700;letter-spacing:.02em;
    padding:2px 9px;border-radius:999px;text-transform:uppercase}
  .pill.pass{background:var(--passbg);color:var(--pass)}
  .pill.fail{background:var(--failbg);color:var(--fail)}
  .pill.never{background:var(--neverbg);color:var(--faint)}
  .foot{margin-top:36px;color:var(--faint);font-size:.78rem}
</style>
"""


def render_html(qa_dir, logs, current, stats, include_removed, sort_mode):
    rows_all = {n: r for n, r in stats.items() if (n in current or include_removed)}
    failing = sorted(n for n, r in rows_all.items() if r["last_result"] == "fail")
    never = sorted(n for n in current if stats[n]["runs"] == 0)
    passing = [n for n in current if stats[n]["last_result"] == "pass"]
    total_exec = sum(r["runs"] for n, r in rows_all.items())
    cats = {}
    for n, r in rows_all.items():
        cats.setdefault(category_of(n), []).append((n, r))

    lf = latest_full_run(logs)
    sub_run = ""
    if lf:
        p, pa, fa, sk = lf
        sub_run = (f' · latest full run <span class="mono">{_esc(p)}</span>: '
                   f'<span style="color:var(--pass)">{pa} passed</span>, '
                   f'<span style="color:var(--fail)">{fa} failed</span>, {sk} skipped')

    def card(n, label, cls=""):
        return f'<div class="card {cls}"><div class="n">{n}</div><div class="l">{_esc(label)}</div></div>'

    out = [HTML_CSS, '<div class="qa">']
    out.append("<h1>DRAW QA — Test Status</h1>")
    out.append(f'<p class="sub">{len(logs)} run logs analyzed · {len(current)} test files present'
               f'{sub_run}</p>')

    out.append('<div class="cards">')
    out.append(card(len(current), "Tests"))
    out.append(card(len(passing), "Passing now", "ok"))
    out.append(card(len(failing), "Failing now", "bad" if failing else ""))
    out.append(card(len(never), "Never run", "warn" if never else ""))
    out.append(card(len(cats), "Categories"))
    out.append(card(f"{total_exec:,}", "Executions"))
    out.append("</div>")

    if failing:
        chips = "".join(f'<span class="chip">{_esc(n)}</span>' for n in failing)
        out.append(f'<div class="callout"><h2>Failing on last run ({len(failing)})</h2>'
                   f'<div class="chips">{chips}</div></div>')
    else:
        out.append('<div class="callout clean"><h2>All current tests passing on their last run ✓</h2></div>')

    def tkey(item):
        n, r = item
        failing_first = 0 if r["last_result"] == "fail" else 1
        if sort_mode == "runs":
            return (failing_first, -r["runs"], n)
        if sort_mode == "last":
            return (failing_first, r["last_key"] or "", n)
        return (failing_first, n)

    # categories: those with a current failure first, then alphabetical
    def ckey(c):
        rws = [(n, r) for n, r in cats[c] if n in current or include_removed]
        has_fail = any(r["last_result"] == "fail" for _, r in rws)
        return (0 if has_fail else 1, c)

    for cat in sorted(cats, key=ckey):
        rws = sorted([(n, r) for n, r in cats[cat] if n in current or include_removed], key=tkey)
        if not rws:
            continue
        cruns = sum(r["runs"] for _, r in rws)
        cfail = sum(1 for _, r in rws if r["last_result"] == "fail")
        meta = f'{len(rws)} tests · {cruns} runs'
        if cfail:
            meta += f' · <span class="fnow">{cfail} failing now</span>'
        out.append('<div class="cat">')
        out.append(f'<div class="cat-h"><span class="name">{_esc(cat)}</span>'
                   f'<span class="meta">{meta}</span></div>')
        out.append('<div class="twrap"><table><thead><tr>'
                   '<th>Test</th><th>Runs</th><th>Pass</th><th>Fail</th>'
                   '<th>Last run</th><th>Result</th><th>Last pass</th><th>Last fail</th>'
                   '</tr></thead><tbody>')
        for n, r in rws:
            res = r["last_result"]
            pill = (f'<span class="pill pass">pass</span>' if res == "pass"
                    else f'<span class="pill fail">fail</span>' if res == "fail"
                    else f'<span class="pill never">never</span>')
            fcls = " failrow" if res == "fail" else ""
            fnum = "num f" if r["fails"] else "num z"
            rem = "" if n in current else ' <span style="color:var(--faint)">(removed)</span>'
            out.append(
                f'<tr class="{fcls.strip()}">'
                f'<td class="t">{_esc(n)}{rem}</td>'
                f'<td class="num">{r["runs"]}</td>'
                f'<td class="num">{r["passes"]}</td>'
                f'<td class="{fnum}">{r["fails"]}</td>'
                f'<td class="dt">{_esc(r["last_pretty"] or "—")}</td>'
                f'<td>{pill}</td>'
                f'<td class="dt">{_esc(r["last_pass"] or "—")}</td>'
                f'<td class="dt">{_esc(r["last_fail"] or "—")}</td>'
                f'</tr>')
        out.append("</tbody></table></div></div>")

    out.append(f'<p class="foot">Generated by /dump-qa-tests from {_esc(qa_dir)} · '
               f'"runs" counts real executions only (cache-skips excluded).</p>')
    out.append("</div>")
    return "\n".join(out)


def main():
    args = sys.argv[1:]
    qa_dir = None
    only_cat = None
    only_failing = False
    only_never = False
    include_removed = False
    html_mode = False
    sort_mode = "name"
    use_color = sys.stdout.isatty()
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--category":
            i += 1; only_cat = args[i].lower()
        elif a == "--failing":
            only_failing = True
        elif a == "--never":
            only_never = True
        elif a in ("--all", "--include-removed"):
            include_removed = True
        elif a == "--html":
            html_mode = True
        elif a == "--sort":
            i += 1; sort_mode = args[i]
        elif a == "--no-color":
            use_color = False
        elif not a.startswith("-"):
            qa_dir = a
        i += 1

    # Locate QA dir: explicit arg, else repo-relative to this skill, else ./QA.
    if qa_dir is None:
        here = os.path.dirname(os.path.abspath(__file__))
        repo = os.path.abspath(os.path.join(here, "..", "..", ".."))
        for cand in (os.path.join(repo, "QA"), os.path.join(os.getcwd(), "QA"), "QA"):
            if os.path.isdir(os.path.join(cand, "results")) or os.path.isdir(os.path.join(cand, "tests")):
                qa_dir = cand
                break
    if not qa_dir or not os.path.isdir(qa_dir):
        print("dump-qa-tests: could not find the QA/ directory (pass it as an argument)", file=sys.stderr)
        return 2

    tests_dir = os.path.join(qa_dir, "tests")
    results_dir = os.path.join(qa_dir, "results")

    # Current test files.
    current = set()
    for f in glob.glob(os.path.join(tests_dir, "*.sh")):
        current.add(os.path.basename(f)[:-3])

    # Aggregate history across all run logs, oldest -> newest.
    logs = sorted(glob.glob(os.path.join(results_dir, "run-*.log")), key=lambda p: ts_from_name(p)[0] or "")
    stats = {}  # name -> dict

    def rec(name):
        return stats.setdefault(name, dict(runs=0, passes=0, fails=0, skips=0,
                                           last_key=None, last_pretty=None, last_result=None,
                                           last_pass=None, last_fail=None))

    for lg in logs:
        key, pretty = ts_from_name(lg)
        for name, outcome in parse_log(lg).items():
            r = rec(name)
            if outcome in ("pass", "fail"):
                r["runs"] += 1
                if outcome == "pass":
                    r["passes"] += 1
                    r["last_pass"] = pretty
                else:
                    r["fails"] += 1
                    r["last_fail"] = pretty
                r["last_key"], r["last_pretty"], r["last_result"] = key, pretty, outcome
            elif outcome == "skip":
                r["skips"] += 1

    # Ensure current tests appear even with no history.
    for name in current:
        rec(name)

    if html_mode:
        sys.stdout.write(render_html(qa_dir, logs, current, stats, include_removed, sort_mode))
        return 0

    # Colors
    if use_color:
        C = dict(g="\033[0;32m", r="\033[0;31m", y="\033[0;33m", c="\033[0;36m",
                 dim="\033[2m", b="\033[1m", x="\033[0m")
    else:
        C = {k: "" for k in "grycdimbx"}
        C["dim"] = C["b"] = C["x"] = ""

    def colored_result(res):
        if res == "pass":
            return f"{C['g']}pass{C['x']}"
        if res == "fail":
            return f"{C['r']}FAIL{C['x']}"
        if res is None:
            return f"{C['dim']}never{C['x']}"
        return res

    # Group by category.
    cats = {}
    for name, r in stats.items():
        cats.setdefault(category_of(name), []).append((name, r))

    def test_sort_key(item):
        name, r = item
        if sort_mode == "runs":
            return (-r["runs"], name)
        if sort_mode == "last":
            return (r["last_key"] or "", name)
        return (name,)

    total_tests = 0
    total_current = 0
    total_runs = 0
    total_never = 0
    total_failing = 0

    # Header
    print(f"{C['b']}DRAW QA test status{C['x']}  —  {qa_dir}")
    note = "" if include_removed else f" · {C['dim']}removed tests hidden (--all to show){C['x']}"
    print(f"{C['dim']}{len(logs)} run logs analyzed · {len(current)} test files present{C['x']}{note}")
    print()
    colw = 34
    for cat in sorted(cats):
        rows = sorted(cats[cat], key=test_sort_key)
        # category-level rollup (respect the current-only default)
        roll = [(n, r) for n, r in rows if include_removed or n in current]
        cat_runs = sum(r["runs"] for _, r in roll)
        cat_fail_now = sum(1 for _, r in roll if r["last_result"] == "fail")
        shown = []
        for name, r in rows:
            is_current = name in current
            never = r["runs"] == 0
            failing = r["last_result"] == "fail"
            total_tests += 1
            if is_current:
                total_current += 1
            total_runs += r["runs"]
            if never and is_current:
                total_never += 1
            if failing and (is_current or include_removed):
                total_failing += 1
            if not is_current and not include_removed:
                continue
            if only_cat and cat != only_cat:
                continue
            if only_failing and not failing:
                continue
            if only_never and not (never and is_current):
                continue
            shown.append((name, r, is_current, never, failing))
        if only_cat and cat != only_cat:
            continue
        if not shown:
            continue
        print(f"{C['c']}{C['b']}▎{cat}{C['x']}  {C['dim']}({len(roll)} tests, {cat_runs} runs"
              + (f", {C['r']}{cat_fail_now} failing now{C['dim']}" if cat_fail_now else "")
              + f"){C['x']}")
        print(f"  {C['dim']}{'test':<{colw}} {'runs':>5} {'pass':>5} {'fail':>5}  "
              f"{'last run':<16} {'result':<6} {'last pass':<16} {'last fail':<16}{C['x']}")
        for name, r, is_current, never, failing in shown:
            tag = "" if is_current else f" {C['dim']}(removed){C['x']}"
            nm = name + ("" if is_current else "*")
            print(f"  {nm:<{colw}} {r['runs']:>5} "
                  f"{C['g']}{r['passes']:>5}{C['x']} "
                  f"{(C['r'] if r['fails'] else C['dim'])}{r['fails']:>5}{C['x']}  "
                  f"{(r['last_pretty'] or '—'):<16} "
                  f"{colored_result(r['last_result']):<6} "
                  f"{C['dim']}{(r['last_pass'] or '—'):<16} {(r['last_fail'] or '—'):<16}{C['x']}"
                  f"{tag}")
        print()

    # Grand summary
    print(f"{C['b']}Summary{C['x']}")
    print(f"  categories:      {len(cats)}")
    print(f"  test files:      {total_current} present"
          + (f"  {C['dim']}(+{total_tests - total_current} removed but in history){C['x']}" if total_tests > total_current else ""))
    print(f"  total executions:{total_runs}")
    print(f"  currently failing:{(' ' + C['r'] + str(total_failing) + C['x']) if total_failing else ' 0'}")
    print(f"  never run:        {total_never}")
    if not (only_cat or only_failing or only_never):
        failing_names = sorted(n for n, r in stats.items()
                               if r["last_result"] == "fail" and (n in current or include_removed))
        if failing_names:
            print(f"\n{C['r']}{C['b']}Failing on last run:{C['x']} " + ", ".join(failing_names))
    return 0


if __name__ == "__main__":
    sys.exit(main())
