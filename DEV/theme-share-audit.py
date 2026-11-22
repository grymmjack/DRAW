#!/usr/bin/env python3
"""
DEV/theme-share-audit.py - keep theme keys from being shared across kinds of control.

Rule (Rick, 2026-11-21): one kind of control, one set of keys - controls of the same kind
share their kind's keys, never another kind's (see .claude/instructions/draw-theme-edit.md,
"One kind of control, one set of keys"). Two checks:

  1. OWNERS: a key family (prefix) may only be read by the routines that draw that kind.
     Reads from any other routine are reported. Families not listed are not checked yet -
     add a family here when its surface is split.
  2. TEXT IN A BG KEY: `COLOR THEME.<...bg...>` - text drawn in a background colour
     vanishes when a theme sets that background to the colour behind it.

Reads CFG/THEME-USES.BM (DEV/theme-uses-gen.py) for check 1 and the sources for check 2.

  python3 DEV/theme-share-audit.py          report, exit 1 when anything is found
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
USES = os.path.join(ROOT, "CFG", "THEME-USES.BM")
SKIP_DIRS = {"includes", ".git", "QA", "DEV", "PLANS", "docs", "ASSETS", "native", "node_modules"}

# key prefix -> routines allowed to read it (upper case, no suffix)
OWNERS = {
    # dialog toggle buttons / segmented choices
    "DIALOG_TOGGLE_": {"DIALOG_DRAW_TOGGLE", "SW_DRAW_BTN_GROUP", "KIT_DRAW_TOGGLE_L"},
    # dialog sliders
    "DIALOG_SLIDER_": {"DIALOG_DRAW_SLIDER", "SW_DRAW_SLIDER"},
    # dialog checkboxes + radios
    "DIALOG_CHECKBOX_": {"SW_DRAW_CHECKBOX", "SW_DRAW_RADIO", "CTRL_DRAW_CHECK", "DIALOG_CRT_DRAW_CHECKBOX",
                         "PA_DRAW_CHECKBOX_COLORED", "EXTRACT_DRAW_CHECKBOX", "LOSPEC_SHOW_DIALOG"},
    # dialog tabs
    "DIALOG_TAB_": {"SETTINGS_DRAW_TABS"},
}
# routines allowed extra families (a routine that draws several kinds inline)
EXTRA = {}


def uses():
    out = {}
    txt = open(USES, encoding="utf-8").read()
    for m in re.finditer(r'CASE "([A-Z0-9_]+)": THEMEU_keys\$ = (.*)', txt):
        out[m.group(1)] = " ".join(re.findall(r'"([^"]*)"', m.group(2))).split()
    return out


def code_part(line):
    out, q = [], False
    for c in line:
        if c == '"':
            q = not q
            continue
        if q:
            continue
        if c == "'":
            break
        out.append(c)
    return "".join(out)


def main():
    bad = 0
    u = uses()
    for pre, own in OWNERS.items():
        for rtn, keys in sorted(u.items()):
            hit = sorted(k for k in keys if k.startswith(pre))
            if hit and rtn not in own and pre not in EXTRA.get(rtn, ()):
                print("SHARED  %-34s reads %s" % (rtn, " ".join(hit)))
                bad += 1
    rx = re.compile(r"\bCOLOR\s+THEME\.([A-Za-z0-9_]*_bg[A-Za-z0-9_]*)~?&?", re.I)
    for d, dirs, files in os.walk(ROOT):
        rel = os.path.relpath(d, ROOT)
        if rel.split(os.sep)[0] in SKIP_DIRS:
            dirs[:] = []
            continue
        for f in sorted(files):
            if not f.upper().endswith((".BM", ".BAS")):
                continue
            p = os.path.join(d, f)
            for n, line in enumerate(open(p, encoding="utf-8", errors="replace"), 1):
                m = rx.search(code_part(line))
                if m and not m.group(1).lower().endswith("_fg"):
                    print("BG-TEXT %s:%d COLOR THEME.%s" % (os.path.relpath(p, ROOT), n, m.group(1)))
                    bad += 1
    if bad:
        print("theme-share-audit: %d finding(s)" % bad)
        sys.exit(1)
    print("theme-share-audit: clean")


if __name__ == "__main__":
    main()
