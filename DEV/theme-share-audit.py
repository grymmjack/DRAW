#!/usr/bin/env python3
"""
DEV/theme-share-audit.py - keep theme keys from being shared across kinds of control.

Rule (Rick, 2026-11-21): one kind of control, one set of keys - controls of the same kind
share their kind's keys, never another kind's (see .claude/instructions/draw-theme-edit.md,
"One kind of control, one set of keys"). Two checks:

  1. OWNERS: a key family (prefix) may only be read by the routines that draw that kind.
     Reads from any other routine are reported. Families not listed are not checked yet -
     add a family here when its surface is split. SURFACES: a dialog routine reading a
     PANEL_ key, or a panel routine reading a DIALOG_ key.
  2. TEXT IN A BG KEY: `COLOR THEME.<...bg...>` - text drawn in a background colour
     vanishes when a theme sets that background to the colour behind it.
  3. ALPHA: a key's alpha replaced by a fixed one in code (`THEME.x AND &H00FFFFFF`,
     `_RGBA32(_RED32(THEME.x) ...`) - the theme can't fade the part; use THEME_fade~&.

Reads CFG/THEME-USES.BM (DEV/theme-uses-gen.py) for check 1 and the sources for check 2.

  python3 DEV/theme-share-audit.py          report, exit 1 when anything is found
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
USES = os.path.join(ROOT, "CFG", "THEME-USES.BM")
SKIP_DIRS = {"includes", ".git", "QA", "DEV", "PLANS", "docs", "ASSETS", "native", "node_modules"}

# key prefix -> routines allowed to read it (upper case, no suffix): a set, or a regex
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
    # the Color Mixer / Color Picker's own (QB64_GJ_LIB COLOR_PICKER CP_THEME) - panels use PANEL_
    "CP_": {"COLORMIXER_ENSURE_INITIALIZED", "DRAW_PICK_COLOR"},
    # the file browser (File dialogs + Image Browser): FD_THEME
    "FILE_DIALOG_": r"^DRAW_FD_",
    # panel-only component groups: read by their own panel's routines
    "LAYER_PANEL_": r"^(LAYER_|DOCK_|THEMEED_TREE|PSURF_BG$)",  # (DOCK_ / THEMEED_: LAYER_PANEL_HEADER_HEIGHT, a size; PSURF_bg: its footprint)
    "DOCK_": r"^DOCK_",
    "PEN_METER_": r"^PENP_", "PEN_GRAPH_": r"^PENP_", "PEN_HINT_": r"^PENP_",
    "SWATCHES_": r"^SWP_",
    "TOOLBAR_EDITOR_": r"^TBED_",
    "ANIM_SHEET_": r"^ANIM", "ANIM_LANE_": r"^(ANIM|SETTINGS_RENDER_ANIMATION$)", "ANIM_SOUND_": r"^ANIM",
    "ANIM_SEEK_": r"^ANIM", "ANIM_WIDGET_": r"^ANIM",
}
# surfaces: a dialog routine never reads a panel key, a panel routine never a dialog key
SURFACES = {
    "DIALOG_": r"^(FPANEL_|PENP_|SWP_|TBED_|ANIM|DOCK_|LAYER_|PA_|PIXEL_ANALYZER|ADVCP_|CS3D_)",
    "PANEL_": r"^(DIALOG_|SW_|SETTINGS_|CTRL_|KIT_|AI_|WSC_|RESIZE_|EXTRACT_)",
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
            ok = re.match(own, rtn) if isinstance(own, str) else rtn in own
            if hit and not ok and pre not in EXTRA.get(rtn, ()):
                print("SHARED  %-34s reads %s" % (rtn, " ".join(hit)))
                bad += 1
    for pre, rx_bad in SURFACES.items():
        for rtn, keys in sorted(u.items()):
            hit = sorted(k for k in keys if k.startswith(pre))
            if hit and re.match(rx_bad, rtn):
                print("SURFACE %-34s reads %s" % (rtn, " ".join(hit)))
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
    # 3. ALPHA: a theme key's alpha replaced by the code's (use THEME_fade~&)
    rxa = re.compile(r"THEME\.([A-Za-z0-9_]+)~?&?\s+AND\s+&H00FFFFFF|_RGBA32?\(\s*_RED32\(\s*THEME\.([A-Za-z0-9_]+)", re.I)
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
                m = rxa.search(code_part(line))
                if m:
                    print("ALPHA   %s:%d THEME.%s (alpha replaced - THEME_fade~&)" % (os.path.relpath(p, ROOT), n, m.group(1) or m.group(2)))
                    bad += 1
    if bad:
        print("theme-share-audit: %d finding(s)" % bad)
        sys.exit(1)
    print("theme-share-audit: clean")


if __name__ == "__main__":
    main()
