#!/usr/bin/env python3
"""
command-icons.py - the command icon work list (CSV) for the toolbar editor.

Every command DRAW can put on the toolbox / edit bar / advanced bar (the
Customize Toolbars "Available" list: the command palette's commands plus the
menu commands the palette lacks), with:
  - the art it has now (a bar icon, or a toolbox tool), or "tile" = it shows a
    text tile (up to 3 letters) until someone draws it,
  - the files to make and where they live in the theme:
      ASSETS/THEMES/<theme>/IMAGES/COMMANDS/<name>.png          16x16 RGBA (bars, editor lists; toolbox fallback)
      ASSETS/THEMES/<theme>/IMAGES/COMMANDS/TOOLBOX/<name>.png  11x11 RGBA (optional: the toolbox's own size)
    <name> is the command's name in lower case, words joined by "-" (the same
    rule as GUI/BUTTON-LIST.BM BL_cmd_slug$); cmd-<action id>.png also works.
    DRAW looks in the active theme first, then DEFAULT.

  DEV/tools/command-icons.py                # writes PLANS/_/COMMAND-ICONS.csv
  DEV/tools/command-icons.py -o out.csv     # elsewhere
  DEV/tools/command-icons.py --check        # also report which art files exist now

Parses the source (GUI/COMMAND.BM, GUI/MENUBAR.BM, GUI/EDITBAR.BM,
GUI/ADVANCEDBAR.BM, the DEFAULT theme's THEME.BI), so rerun it after adding
commands. Rows already marked done in an existing CSV keep their notes /
status columns.
"""
import argparse, csv, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

CATS = {"CMD_CAT_TOOL": (1, "Tool"), "CMD_CAT_FILE": (2, "File"), "CMD_CAT_EDIT": (3, "Edit"),
        "CMD_CAT_VIEW": (4, "View"), "CMD_CAT_COLOR": (5, "Color"), "CMD_CAT_BRUSH": (6, "Brush"),
        "CMD_CAT_LAYER": (7, "Layer"), "CMD_CAT_CANVAS": (8, "Canvas"), "CMD_CAT_ASSIST": (9, "Assist"),
        "CMD_CAT_CUSTOM": (10, "Custom"), "CMD_CAT_GRID": (11, "Grid"), "CMD_CAT_SYMM": (12, "Symmetry"),
        "CMD_CAT_SELECT": (13, "Select"), "CMD_CAT_HELP": (14, "Help"), "CMD_CAT_IMAGE": (15, "Image")}
# tool-select commands the editor offers as toolbox tools instead (TBED_TOOL_ACTS$)
TOOL_ACTS = {101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 117, 118, 119,
             120, 121, 122, 1701, 1702, 1706}
WS_SLOTS = range(2410, 2442)  # View > Workspace > <name> rows (WS_ACT_SLOT0 + 1 .. + WS_MAX)


def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8", errors="replace") as f:
        return f.read()


def consts():
    """CONST NAME = number, from every .BI (for symbolic action ids)."""
    out = {}
    for dp, _, fs in os.walk(ROOT):
        if "/.git" in dp or "/includes" in dp:
            continue
        for fn in fs:
            if fn.upper().endswith(".BI"):
                try:
                    txt = open(os.path.join(dp, fn), encoding="utf-8", errors="replace").read()
                except OSError:
                    continue
                for m in re.finditer(r"(?im)^\s*CONST\s+(\w+)[%&!#~]*\s*=\s*(-?\d+)\b", txt):
                    out.setdefault(m.group(1).upper(), int(m.group(2)))
    return out


def slug(label):
    s = ""
    for ch in label.lower():
        if ch.isascii() and (ch.isalpha() or ch.isdigit()):
            s += ch
        elif s and not s.endswith("-"):
            s += "-"
    return s.strip("-")


def tile_text(label, act):
    """GUI/BUTTON-LIST.BM BL_tile_text$."""
    nm = label.upper()
    if not nm:
        return str(act)[:3]
    words = re.findall(r"[A-Z0-9]+", nm)[:8]
    if not words:
        return "?"
    first = 1 if len(words) > 1 and words[0] in ("TOGGLE", "SHOW") else 0
    if len(words[first]) <= 3 and len(words) > first + 1:
        nxt = words[first + 1]
        r = words[first][0] + nxt[0]
        for ch in nxt[1:]:
            if len(r) >= 3:
                break
            if ch not in "AEIOU" and ch != r[-1]:
                r += ch
        return r
    w = words[first]
    r = w[0]
    for ch in w[1:]:
        if len(r) >= 3:
            break
        if ch not in "AEIOU" and ch != r[-1]:
            r += ch
    for k in words[first + 1:]:
        if len(r) >= 3:
            break
        r += k[0]
    if len(r) < 2 and len(w) > 1:
        r = w[:3]
    return r


def bar_icons(theme_bi):
    """action id -> (bar, icon file) from the bars' tables + the theme defaults."""
    tvars = dict((m.group(1).upper(), m.group(2)) for m in
                 re.finditer(r'(?im)^\s*THEME\.(\w+)\$\s*=\s*"([^"]*)"', theme_bi))
    out = {}
    for rel, arr, bar, sub in (("GUI/EDITBAR.BM", "EDIT_BAR_ITEMS", "edit bar", "EDITBAR"),
                               ("GUI/ADVANCEDBAR.BM", "ADV_BAR_ITEMS", "advanced bar", "ADVANCEDBAR")):
        src = read(rel)
        acts = dict((int(m.group(1)), int(m.group(2))) for m in
                    re.finditer(arr + r"\((\d+)\)\.actionID%\s*=\s*(\d+)", src))
        files = dict((int(m.group(1)), m.group(2).upper()) for m in
                     re.finditer(arr + r"\((\d+)\)\.iconFile\$\s*=\s*THEME\.(\w+)\$", src))
        for i, a in acts.items():
            if a and a not in out:
                f = tvars.get(files.get(i, ""), "")
                out[a] = (bar, "ASSETS/THEMES/DEFAULT/IMAGES/%s/%s" % (sub, f) if f else "")
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-o", "--out", default=os.path.join(ROOT, "PLANS", "_", "COMMAND-ICONS.csv"))
    ap.add_argument("--check", action="store_true", help="print which art files exist now")
    a = ap.parse_args()

    cs = consts()
    cmd_src = read("GUI/COMMAND.BM")
    rows, seen = [], set()

    def act_of(tok):
        tok = tok.strip()
        if re.fullmatch(r"-?\d+", tok):
            return int(tok)
        return cs.get(tok.upper().rstrip("%&"))

    for m in re.finditer(r'CMD_register\s+"([^"]*)",\s*"([^"]*)",\s*(\w+),\s*([\w%&]+)', cmd_src):
        name, hk, cat, tok = m.groups()
        act = act_of(tok)
        if not act or act in seen or not name.strip():
            continue
        seen.add(act)
        order, catname = CATS.get(cat.upper(), (99, "Other"))
        rows.append(dict(act=act, name=name.strip(), hotkey=hk.strip(), cat=catname, order=order, source="palette"))

    menu_src = read("GUI/MENUBAR.BM")
    for m in re.finditer(r'MENUBAR_register_(?:item|submenu_child)\s+"([^"]*)",\s*"([^"]*)",\s*[^,]+,\s*(\d+)', menu_src):
        label, hk, tok = m.groups()
        act = int(tok)
        if act <= 0 or act in seen or label.strip() in ("", "---") or act in WS_SLOTS:
            continue
        seen.add(act)
        rows.append(dict(act=act, name=label.strip(), hotkey=hk.strip(), cat="Menu", order=100, source="menu"))

    bars = bar_icons(read("ASSETS/THEMES/DEFAULT/THEME.BI"))
    rows.sort(key=lambda r: (r["order"], r["source"] != "palette"))

    # keep what someone already filled in
    old = {}
    if os.path.exists(a.out):
        with open(a.out, newline="", encoding="utf-8") as f:
            for r in csv.DictReader(f):
                old[r.get("action_id", "")] = r

    cols = ["action_id", "command", "category", "hotkey", "art_now", "existing_file", "tile_text",
            "file_name", "bar_icon_path", "bar_icon_size", "toolbox_icon_path", "toolbox_icon_size",
            "status", "notes"]
    n_tile = 0
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    with open(a.out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols, lineterminator="\n")
        w.writeheader()
        for r in rows:
            act, nm = r["act"], r["name"]
            s = slug(nm) or "cmd-%d" % act
            if act in bars:
                art, existing = "bar icon (%s)" % bars[act][0], bars[act][1]
            elif act in TOOL_ACTS:
                art, existing = "toolbox tool (offered as the tool)", ""
            else:
                art, existing = "tile", ""
                n_tile += 1
            prev = old.get(str(act), {})
            status = prev.get("status") or ("has art" if art != "tile" else "todo")
            w.writerow({
                "action_id": act, "command": nm, "category": r["cat"], "hotkey": r["hotkey"],
                "art_now": art, "existing_file": existing, "tile_text": tile_text(nm, act),
                "file_name": s + ".png",
                "bar_icon_path": "ASSETS/THEMES/DEFAULT/IMAGES/COMMANDS/%s.png" % s,
                "bar_icon_size": "16x16 RGBA",
                "toolbox_icon_path": "ASSETS/THEMES/DEFAULT/IMAGES/COMMANDS/TOOLBOX/%s.png" % s,
                "toolbox_icon_size": "11x11 RGBA (optional)",
                "status": status, "notes": prev.get("notes", ""),
            })
            if a.check:
                for p in (os.path.join(ROOT, "ASSETS/THEMES/DEFAULT/IMAGES/COMMANDS", s + ".png"),
                          os.path.join(ROOT, "ASSETS/THEMES/DEFAULT/IMAGES/COMMANDS/TOOLBOX", s + ".png")):
                    if os.path.exists(p):
                        print("exists:", os.path.relpath(p, ROOT))
    print("%d commands, %d show a text tile today -> %s" % (len(rows), n_tile, os.path.relpath(a.out, ROOT)))


if __name__ == "__main__":
    sys.exit(main())
