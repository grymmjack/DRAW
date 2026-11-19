#!/usr/bin/env python3
"""
command-icons-kit.py - build the icon review "field kit" page from the icon specs.

Renders every icon in DEV/tools/command-icons/*.txt (both sizes, DEFAULT + DARK) into
DEV/tools/command-icons-kit.html, with the command's name / id / category / hotkey from
PLANS/_/COMMAND-ICONS.csv and the spec's about: line. Each icon carries a fingerprint of
its pixels (rev), so a redrawn icon shows as a "new attempt" against the reviewer's old mark.

  DEV/tools/command-icons-kit.py -o kit.html                 # every icon
  DEV/tools/command-icons-kit.py -o kit.html --only-from DEV/tools/command-icons/view-ui.txt
  DEV/tools/command-icons-kit.py --notes                     # also copy about: into the CSV notes
  DEV/tools/command-icons-kit.py --install DIR               # write the APPROVED icons into the themes

--install takes the kit's "reviews" collection saved as JSON files (one <name>.json per
doc, as ArtifactData list --out_dir writes them, the folder holding them or its parent) and
writes the PNGs (DEFAULT + DARK, both sizes) only for icons marked approved whose rev still
matches the drawing - a mark made on an older drawing installs nothing. It never replaces
a PNG these scripts did not write or that was edited since (written.json; --force). Approved rows are
set to status "approved" in the CSV.

The page keeps reviews in its artifact database (collection "reviews", doc id = icon name:
{status: approved|redo|skip, note, rev}); publish it with capabilities {db: {}, user: {}}.
"""
import argparse, base64, csv, datetime, hashlib, importlib.util, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("mci", os.path.join(HERE, "make-command-icons.py"))
mci = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mci)

TEMPLATE = os.path.join(HERE, "command-icons-kit.html")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-o", "--out", required=False, help="the page to write")
    ap.add_argument("--spec", action="append", help="spec file or folder (default DEV/tools/command-icons/)")
    ap.add_argument("--only-from", action="append", help="only icons defined in this spec file")
    ap.add_argument("--install", help="folder of review JSON docs: write the approved icons into ASSETS")
    ap.add_argument("--force", action="store_true", help="--install: also replace PNGs not made by these scripts / edited since")
    ap.add_argument("--notes", action="store_true", help="write each about: into the CSV's notes column (status 'drawn')")
    a = ap.parse_args()

    entries = mci.read_specs(mci.spec_files(a.spec or [mci.DEFAULT_SPEC]))
    names = [n for n in entries if not n.startswith("@")]
    if a.only_from:
        allowed = set()
        for f in a.only_from:
            allowed |= set(mci.read_specs([f]))
        names = [n for n in names if n in allowed]
    rows = mci.csv_rows()
    by_name = {}
    for r in rows:
        for key in (r["file_name"][:-4], "cmd-" + r["action_id"]):
            by_name.setdefault(key, []).append(r)

    if a.install:
        import glob as _g
        d = a.install
        if os.path.isdir(os.path.join(d, "reviews")):
            d = os.path.join(d, "reviews")
        revs = {}
        for f in _g.glob(os.path.join(d, "*.json")):
            j = json.load(open(f))
            doc = j.get("data", j)
            revs[os.path.splitext(os.path.basename(f))[0]] = doc
        st = {t: mci.theme_style(t, "marquee-rect.png", "eb-copy.png") for t in ("DEFAULT", "DARK")}
        mci.check_names([n for n in names if (revs.get(n) or {}).get("status") == "approved"], rows)
        wr = mci.Writer(a.force)
        done, stale = [], []
        for n in names:
            r = revs.get(n)
            if not r or r.get("status") != "approved":
                continue
            c11, c16 = mci.compose(entries, n, "11"), mci.compose(entries, n, "16")
            rev = hashlib.sha1(("".join("".join(x) for x in c11) + "|" + "".join("".join(x) for x in c16)).encode()).hexdigest()[:10]
            if r.get("rev") != rev:
                stale.append(n)
                continue
            for t in ("DEFAULT", "DARK"):
                base = os.path.join(mci.THEMES, t, "IMAGES", "COMMANDS")
                wr.write(os.path.join(base, "TOOLBOX", n + ".png"), mci.png_bytes(mci.render11(st[t], c11)))
                wr.write(os.path.join(base, n + ".png"), mci.png_bytes(mci.render16(st[t], c16)))
            done.append(n)
        for r in rows:
            if r["file_name"][:-4] in done:
                r["status"] = "approved"
        with open(mci.CSV_PATH, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
        wr.close()
        print("installed %d approved icons (x DEFAULT, DARK x 11, 16)" % len(done))
        if stale:
            print("approved on an older drawing, NOT installed (%d): %s" % (len(stale), " ".join(stale)))
        if not a.out:
            return

    if a.notes:
        about = {n: entries[n].get("about", "") for n in names}
        changed = 0
        for r in rows:
            n = r["file_name"][:-4]
            if n in about and about[n] and r["art_now"] == "tile":
                if r.get("notes") != about[n] or r.get("status") not in ("drawn", "approved", "redo"):
                    r["notes"] = about[n]
                    if r.get("status") in ("", "todo", None):
                        r["status"] = "drawn"
                    changed += 1
        with open(mci.CSV_PATH, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
        print("CSV notes updated on %d rows" % changed)
        if not a.out:
            return

    if not a.out:
        sys.exit("-o OUT is required (or --notes / --install alone)")
    st = {t: mci.theme_style(t, "marquee-rect.png", "eb-copy.png") for t in ("DEFAULT", "DARK")}
    b64 = lambda img: base64.b64encode(mci.png_bytes(img)).decode()
    icons = []
    for n in names:
        c11, c16 = mci.compose(entries, n, "11"), mci.compose(entries, n, "16")
        if not c11 or not c16:
            print("skipping %s: it lacks a %s picture" % (n, "11" if not c11 else "16"), file=sys.stderr)
            continue
        rs = by_name.get(n, [])
        rev = hashlib.sha1(("".join("".join(r) for r in c11) + "|" + "".join("".join(r) for r in c16)).encode()).hexdigest()[:10]
        cmds = []
        for r in rs:
            if r["command"] not in cmds:
                cmds.append(r["command"])
        icons.append({
            "n": n, "rev": rev,
            "cmd": " / ".join(cmds) or n,
            "ids": " ".join("#" + r["action_id"] for r in rs) or "-",
            "cat": rs[0]["category"] if rs else "?",
            "hot": next((r["hotkey"] for r in rs if r["hotkey"]), ""),
            "about": entries[n].get("about", ""),
            "grp": os.path.splitext(os.path.basename(entries[n]["file"]))[0],
            "d11": b64(mci.render11(st["DEFAULT"], c11)), "d16": b64(mci.render16(st["DEFAULT"], c16)),
            "k11": b64(mci.render11(st["DARK"], c11)), "k16": b64(mci.render16(st["DARK"], c16)),
        })
    html = open(TEMPLATE).read()
    html = html.replace("/*__ICONS__*/[]", json.dumps(icons, separators=(",", ":")))
    html = html.replace("__BUILT__", datetime.date.today().isoformat()).replace("__COUNT__", str(len(icons)))
    with open(a.out, "w") as f:
        f.write(html)
    print("wrote %s: %d icons, %d KB" % (a.out, len(icons), os.path.getsize(a.out) // 1024))


if __name__ == "__main__":
    main()
