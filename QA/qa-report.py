#!/usr/bin/env python3
"""
qa-report.py — render ONE QA run as a shareable HTML page.

Project-agnostic: it knows nothing about DRAW or QB64. It reads a single run's
structured results (a TSV of  name<TAB>result<TAB>secs<TAB>notes  rows, written
by the harness) and emits a self-contained, theme-aware report:

  header : project · run date/time · what ran (N tests, pass/fail/skip, total time)
  table  : test · result · secs · notes

Pure stdlib. Reads only.

Usage:
    qa-report.py --project NAME (--run RUN.tsv | --results DIR)
                 [--out FILE] [--junit FILE]

    --project NAME   what to call the suite in the header (default: "QA")
    --run FILE       the run TSV to render
    --results DIR    a results/ dir; renders the newest run-*.tsv in it
    --out FILE       write HTML here (default: stdout, unless --junit given)
    --junit FILE     also write JUnit/surefire XML here (for CI)
"""
import os
import re
import sys
import glob
import datetime as _dt

RUNTS = re.compile(r"run-(\d{8})-(\d{6})\.tsv$")


def _esc(s):
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def run_time(path):
    """Prefer the timestamp encoded in run-YYYYMMDD-HHMMSS.tsv; else file mtime."""
    m = RUNTS.search(os.path.basename(path))
    if m:
        d, t = m.group(1), m.group(2)
        return _dt.datetime(int(d[0:4]), int(d[4:6]), int(d[6:8]),
                            int(t[0:2]), int(t[2:4]), int(t[4:6]))
    try:
        return _dt.datetime.fromtimestamp(os.path.getmtime(path))
    except OSError:
        return None


def load_rows(path):
    """Parse the run TSV → list of dicts (name, result, secs, notes)."""
    rows = []
    with open(path, "r", errors="replace") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if not line.strip():
                continue
            parts = line.split("\t")
            while len(parts) < 4:
                parts.append("")
            name, result, secs, notes = parts[0], parts[1].lower(), parts[2], "\t".join(parts[3:])
            try:
                secs_i = int(float(secs))
            except ValueError:
                secs_i = 0
            rows.append(dict(name=name, result=result, secs=secs_i, notes=notes))
    return rows


def fmt_secs(n):
    return f"{n // 60}:{n % 60:02d}" if n >= 60 else f"{n}s"


CSS = """
<style>
  :root{
    --bg:#f7f8fa; --surface:#ffffff; --surface2:#f0f2f5; --border:#dde1e7;
    --text:#1a1f26; --muted:#657084; --faint:#9aa4b2;
    --accent:#0d9488; --pass:#16a34a; --fail:#dc2626; --skip:#d97706;
    --passbg:#dcfce7; --failbg:#fee2e2; --skipbg:#fef3c7; --cachebg:#eef1f5;
    --shadow:0 1px 2px rgba(16,24,40,.06),0 1px 3px rgba(16,24,40,.04);
  }
  @media (prefers-color-scheme: dark){
    :root:not([data-theme="light"]){
      --bg:#0f1216; --surface:#171b21; --surface2:#1f242c; --border:#2a303a;
      --text:#e7ecf3; --muted:#93a0b4; --faint:#5f6b7c;
      --accent:#2dd4bf; --pass:#4ade80; --fail:#f87171; --skip:#fbbf24;
      --passbg:#0f2a1a; --failbg:#2c1416; --skipbg:#2a2010; --cachebg:#1b2028;
      --shadow:0 1px 2px rgba(0,0,0,.4);
    }
  }
  :root[data-theme="dark"]{
    --bg:#0f1216; --surface:#171b21; --surface2:#1f242c; --border:#2a303a;
    --text:#e7ecf3; --muted:#93a0b4; --faint:#5f6b7c;
    --accent:#2dd4bf; --pass:#4ade80; --fail:#f87171; --skip:#fbbf24;
    --passbg:#0f2a1a; --failbg:#2c1416; --skipbg:#2a2010; --cachebg:#1b2028;
    --shadow:0 1px 2px rgba(0,0,0,.4);
  }
  *{box-sizing:border-box}
  html,body{background:var(--bg);color:var(--text);margin:0}
  .qa{background:var(--bg);color:var(--text);
    font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
    line-height:1.5;padding:32px 24px 64px;max-width:1040px;margin:0 auto}
  .qa h1{font-size:1.5rem;font-weight:680;letter-spacing:-.01em;margin:0 0 4px;text-wrap:balance}
  .qa h1 .proj{color:var(--accent)}
  .qa .sub{color:var(--muted);font-size:.9rem;margin:0 0 24px}
  .mono{font-family:ui-monospace,"SF Mono",SFMono-Regular,Menlo,Consolas,monospace}
  .cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:12px;margin:0 0 24px}
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
  .twrap{overflow-x:auto;border:1px solid var(--border);border-radius:10px;background:var(--surface)}
  table{border-collapse:collapse;width:100%;font-size:.85rem}
  thead th{font-size:.68rem;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);
    text-align:left;font-weight:600;padding:10px 14px;background:var(--surface2);white-space:nowrap}
  td{padding:9px 14px;border-top:1px solid var(--border);vertical-align:top}
  td.t{font-family:ui-monospace,monospace;font-weight:560;white-space:nowrap}
  td.secs{text-align:right;font-variant-numeric:tabular-nums;font-family:ui-monospace,monospace;
    color:var(--muted);white-space:nowrap}
  td.notes{color:var(--muted);font-size:.82rem}
  tr.failrow td.t{color:var(--fail)}
  .pill{display:inline-block;font-size:.7rem;font-weight:700;letter-spacing:.02em;
    padding:2px 9px;border-radius:999px;text-transform:uppercase;white-space:nowrap}
  .pill.pass{background:var(--passbg);color:var(--pass)}
  .pill.fail{background:var(--failbg);color:var(--fail)}
  .pill.skip{background:var(--skipbg);color:var(--skip)}
  .pill.cached{background:var(--cachebg);color:var(--faint)}
  .foot{margin-top:36px;color:var(--faint);font-size:.78rem}
</style>
"""

PILL = {"pass": "pass", "fail": "fail", "skip": "skip", "cached": "cached"}


def render(project, when, rows):
    npass = sum(1 for r in rows if r["result"] == "pass")
    nfail = sum(1 for r in rows if r["result"] == "fail")
    nskip = sum(1 for r in rows if r["result"] in ("skip", "cached"))
    total_secs = sum(r["secs"] for r in rows)
    failing = [r["name"] for r in rows if r["result"] == "fail"]

    when_str = when.strftime("%Y-%m-%d %H:%M") if when else "—"

    def card(n, label, cls=""):
        return f'<div class="card {cls}"><div class="n">{n}</div><div class="l">{_esc(label)}</div></div>'

    out = [CSS, '<div class="qa">']
    out.append(f'<h1><span class="proj">{_esc(project)}</span> — QA Report</h1>')
    out.append(f'<p class="sub">run <span class="mono">{_esc(when_str)}</span> · '
               f'{len(rows)} test{"s" if len(rows) != 1 else ""} · '
               f'{npass} passed, {nfail} failed, {nskip} skipped · '
               f'total <span class="mono">{fmt_secs(total_secs)}</span></p>')

    out.append('<div class="cards">')
    out.append(card(len(rows), "Tests"))
    out.append(card(npass, "Passed", "ok"))
    out.append(card(nfail, "Failed", "bad" if nfail else ""))
    out.append(card(nskip, "Skipped", "warn" if nskip else ""))
    out.append(card(fmt_secs(total_secs), "Total time"))
    out.append("</div>")

    if failing:
        chips = "".join(f'<span class="chip">{_esc(n)}</span>' for n in failing)
        out.append(f'<div class="callout"><h2>Failed ({len(failing)})</h2>'
                   f'<div class="chips">{chips}</div></div>')
    else:
        out.append('<div class="callout clean"><h2>All tests passed ✓</h2></div>')

    # failures first, then alphabetical
    order = {"fail": 0, "pass": 1, "skip": 2, "cached": 3}
    rows_sorted = sorted(rows, key=lambda r: (order.get(r["result"], 9), r["name"]))

    out.append('<div class="twrap"><table><thead><tr>'
               '<th>Test</th><th>Result</th><th style="text-align:right">Secs</th><th>Notes</th>'
               '</tr></thead><tbody>')
    for r in rows_sorted:
        res = r["result"]
        pill = f'<span class="pill {PILL.get(res, "cached")}">{_esc(res)}</span>'
        fcls = " failrow" if res == "fail" else ""
        out.append(
            f'<tr class="{fcls.strip()}">'
            f'<td class="t">{_esc(r["name"])}</td>'
            f'<td>{pill}</td>'
            f'<td class="secs">{r["secs"]}</td>'
            f'<td class="notes">{_esc(r["notes"]) or "—"}</td>'
            f'</tr>')
    out.append("</tbody></table></div>")

    out.append('<p class="foot">Generated by qa-report.py — one row per test in this run.</p>')
    out.append("</div>")
    return "\n".join(out)


def _xml_attr(s):
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace('"', "&quot;"))


def render_junit(project, when, rows):
    """JUnit/surefire XML so CI (GitHub Actions et al.) can surface per-test results.

    cached/skip → <skipped/>; fail → <failure> with the note as the message.
    """
    nfail = sum(1 for r in rows if r["result"] == "fail")
    nskip = sum(1 for r in rows if r["result"] in ("skip", "cached"))
    total = sum(r["secs"] for r in rows)
    cls = f"{project}.QA"
    ts = when.strftime("%Y-%m-%dT%H:%M:%S") if when else ""
    lines = ['<?xml version="1.0" encoding="UTF-8"?>']
    lines.append(f'<testsuites name="{_xml_attr(project)} QA" tests="{len(rows)}" '
                 f'failures="{nfail}" skipped="{nskip}" time="{total}">')
    lines.append(f'  <testsuite name="{_xml_attr(project)} QA" tests="{len(rows)}" '
                 f'failures="{nfail}" skipped="{nskip}" time="{total}"'
                 + (f' timestamp="{ts}"' if ts else "") + '>')
    for r in rows:
        head = (f'    <testcase name="{_xml_attr(r["name"])}" '
                f'classname="{_xml_attr(cls)}" time="{r["secs"]}"')
        if r["result"] == "fail":
            msg = _xml_attr(r["notes"] or "assertion failed")
            lines.append(head + '>')
            lines.append(f'      <failure message="{msg}">{_esc(r["notes"])}</failure>')
            lines.append('    </testcase>')
        elif r["result"] in ("skip", "cached"):
            reason = _xml_attr(r["notes"] or r["result"])
            lines.append(head + '>')
            lines.append(f'      <skipped message="{reason}"/>')
            lines.append('    </testcase>')
        else:
            lines.append(head + '/>')
    lines.append('  </testsuite>')
    lines.append('</testsuites>')
    return "\n".join(lines) + "\n"


def main():
    args = sys.argv[1:]
    project = "QA"
    run = None
    results = None
    out = None
    junit = None
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--project":
            i += 1; project = args[i]
        elif a == "--run":
            i += 1; run = args[i]
        elif a == "--results":
            i += 1; results = args[i]
        elif a == "--out":
            i += 1; out = args[i]
        elif a == "--junit":
            i += 1; junit = args[i]
        i += 1

    if not run and results:
        cands = sorted(glob.glob(os.path.join(results, "run-*.tsv")))
        run = cands[-1] if cands else None
    if not run or not os.path.isfile(run):
        print("qa-report: no run TSV (pass --run FILE or --results DIR)", file=sys.stderr)
        return 2

    rows = load_rows(run)
    when = run_time(run)
    if junit:
        with open(junit, "w") as fh:
            fh.write(render_junit(project, when, rows))
    html = render(project, when, rows)
    if out:
        with open(out, "w") as fh:
            fh.write("<!doctype html>\n<meta charset=utf-8>\n")
            fh.write(f"<title>{_esc(project)} — QA Report</title>\n")
            fh.write(html)
    elif not junit:
        sys.stdout.write(html)
    return 0


if __name__ == "__main__":
    sys.exit(main())
