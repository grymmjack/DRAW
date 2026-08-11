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


def main():
    args = sys.argv[1:]
    qa_dir = None
    only_cat = None
    only_failing = False
    only_never = False
    include_removed = False
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
