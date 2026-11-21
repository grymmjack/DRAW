#!/usr/bin/env python3
"""
DEV/theme-props-gen.py - generate CFG/THEME-PROPS.BM from the theme loader.

The theme key list has ONE source of truth: the SELECT CASE in THEME_apply_kv%
(CFG/CONFIG-THEME.BM), which parses a key into the live THEME. This script reads
it and writes the other half Theme Edit mode needs:

  THEMEP_register_all   every key -> UIP_prop_add (type, section, description)
  THEMEP_get$ (key)     the live value as theme-file text (the inverse of the loader)

Types come from the loader's expression (VAL / THEME_parse_rgba / val$ / the BOOL
test) and the target's suffix; file-valued text keys (IMAGE / FONT / SOUND) from
the sample value in ASSETS/THEMES/DEFAULT/THEME.CFG. Sections and descriptions
come from DEFAULT/THEME.CFG and the field comments in CFG/CONFIG-THEME.BI.

  python3 DEV/theme-props-gen.py           write CFG/THEME-PROPS.BM
  python3 DEV/theme-props-gen.py --check   exit 1 when the file is out of date

Re-run after adding a theme key to THEME_apply_kv%.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOADER = os.path.join(ROOT, "CFG", "CONFIG-THEME.BM")
TYPES_BI = os.path.join(ROOT, "CFG", "CONFIG-THEME.BI")
DEFAULT_CFG = os.path.join(ROOT, "ASSETS", "THEMES", "DEFAULT", "THEME.CFG")
OUT = os.path.join(ROOT, "CFG", "THEME-PROPS.BM")

CASE_RE = re.compile(r'^\s*CASE\s+"([A-Z0-9_]+)"\s*:\s*(.+?)\s*=\s*(.+?)\s*$')
IMG_EXT = (".png", ".bmp", ".gif", ".jpg", ".jpeg", ".tga", ".ico", ".qoi")
FONT_EXT = (".ttf", ".otf", ".fon", ".fnt")
SND_EXT = (".wav", ".ogg", ".mp3", ".flac", ".mod", ".xm", ".s3m", ".it", ".mid", ".sf2")


def bas_str(s):
    """A plain-ASCII QB64 string literal (the inspector's font has no UTF-8)."""
    s = s.replace("\u2014", "-").replace("\u2013", "-").replace("\u2192", "->").replace("\u00d7", "x")
    s = "".join(c if 32 <= ord(c) < 127 else "?" for c in s)
    return '"' + s.replace('"', "'") + '"'


def read_cases():
    lines = open(LOADER, encoding="utf-8").read().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("FUNCTION THEME_apply_kv%"))
    end = next(i for i in range(start, len(lines)) if lines[i].startswith("END FUNCTION"))
    out = []
    for l in lines[start:end]:
        if 'CASE "' not in l:
            continue
        m = CASE_RE.match(l)
        if not m:
            sys.exit("theme-props-gen: cannot parse loader line: " + l.strip())
        key, target, expr = m.group(1), m.group(2).strip(), m.group(3).strip()
        if expr == "VAL(val$)":
            kind = "REAL" if target.endswith("!") or target.endswith("#") else "INT"
        elif expr.startswith("THEME_parse_rgba"):
            kind = "COLOR"
        elif expr == "val$":
            kind = "TEXT"
        elif "TRUE" in expr.upper():
            kind = "BOOL"
        else:
            sys.exit("theme-props-gen: unknown value expression for %s: %s" % (key, expr))
        out.append((key, target, kind))
    return out


def read_default_cfg():
    """key -> (section, sample value, comment)"""
    info = {}
    section = "MISC"
    last_comment = ""
    for raw in open(DEFAULT_CFG, encoding="utf-8", errors="replace"):
        l = raw.strip()
        if not l:
            last_comment = ""
            continue
        if l.startswith("#") or l.startswith(";"):
            c = l.lstrip("#;").strip()
            if c and not c.startswith("="):
                last_comment = c
            continue
        if l.startswith("["):
            section = l[1:l.index("]")].strip().upper() if "]" in l else section
            last_comment = ""
            continue
        if "=" in l:
            k, v = l.split("=", 1)
            info[k.strip().upper()] = (section, v.strip(), last_comment)
    return info


def read_field_comments():
    """FIELD_NAME (upper, no suffix) -> comment from the DRAW_THEME TYPE."""
    out = {}
    for l in open(TYPES_BI, encoding="utf-8", errors="replace"):
        m = re.match(r"^\s*([A-Za-z0-9_]+)\s+AS\s+[^']*'\s*(.*)$", l)
        if m:
            out[m.group(1).upper()] = m.group(2).strip()
    return out


def file_kind(key, sample):
    s = sample.lower()
    if s.endswith(IMG_EXT):
        return "IMAGE"
    if s.endswith(FONT_EXT) or (key.endswith("_FONT") or key.endswith("_FONT_FILE")):
        return "FONT"
    if s.endswith(SND_EXT) or (key.startswith("SOUND_") and key.endswith("_FILE")):
        return "SOUND"
    if key.endswith("_FILE") or key.endswith("_ICON"):
        return "IMAGE"
    return "TEXT"


def getter_expr(target, kind):
    if kind == "COLOR":
        return "UIP_rgba_str$(%s)" % target
    if kind == "BOOL":
        return '_IIF(%s, "TRUE", "FALSE")' % target
    if kind in ("INT", "REAL"):
        return "UIP_num_str$(%s)" % target
    return "RTRIM$(%s)" % target


def generate():
    cases = read_cases()
    dflt = read_default_cfg()
    fields = read_field_comments()
    seen = set()
    reg, get = [], []
    for key, target, kind in cases:
        if key in seen:  # the loader's first CASE wins (BASIC semantics)
            continue
        seen.add(key)
        section, sample, cfg_comment = dflt.get(key, ("", "", ""))
        if not section:
            section = key.split("_")[0] if "_" in key else "MISC"
        ptype = file_kind(key, sample) if kind == "TEXT" else kind
        field = re.sub(r"[%&~!#$]+$", "", target.split(".")[-1]).upper() if target.startswith("THEME.") else ""
        desc = fields.get(field, "") or cfg_comment
        reg.append("    UIP_prop_add %s, UIP_T_%s, %s, %s" % (bas_str(key), ptype, bas_str(section), bas_str(desc[:120])))
        get.append("        CASE %s: THEMEP_get$ = %s" % (bas_str(key), getter_expr(target, kind)))
    head = [
        "''",
        "' DRAW - CFG/THEME-PROPS.BM",
        "' =============================================================================",
        "' GENERATED by DEV/theme-props-gen.py from THEME_apply_kv% (CFG/CONFIG-THEME.BM),",
        "' CFG/CONFIG-THEME.BI and ASSETS/THEMES/DEFAULT/THEME.CFG. DO NOT EDIT - re-run:",
        "'     python3 DEV/theme-props-gen.py",
        "'",
        "' The DRAW side of the UIKIT property registry (GUI/UIKIT/UIP): every theme key",
        "' with its type / section / description, and its live value as theme-file text.",
        "' %d keys." % len(reg),
        "'",
        "$INCLUDEONCE",
        "",
        "''",
        "' Register every theme key with the UIKIT property registry.",
        "'",
        "SUB THEMEP_register_all ()",
    ]
    body = head + reg + [
        "END SUB",
        "",
        "''",
        "' The live value of a theme key, in theme-file form (\"\" = unknown key).",
        "' @param pk STRING Theme key (upper case)",
        "' @return STRING value",
        "'",
        "FUNCTION THEMEP_get$ (pk AS STRING)",
        "    SELECT CASE pk",
    ] + get + [
        "        CASE ELSE: THEMEP_get$ = \"\"",
        "    END SELECT",
        "END FUNCTION",
        "",
    ]
    return "\n".join(body), len(reg)


def main():
    text, n = generate()
    if "--check" in sys.argv:
        cur = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
        if cur != text:
            print("theme-props-gen: CFG/THEME-PROPS.BM is out of date - run python3 DEV/theme-props-gen.py")
            sys.exit(1)
        print("theme-props-gen: up to date (%d keys)" % n)
        return
    open(OUT, "w", encoding="utf-8").write(text)
    print("theme-props-gen: wrote CFG/THEME-PROPS.BM (%d keys)" % n)


if __name__ == "__main__":
    main()
