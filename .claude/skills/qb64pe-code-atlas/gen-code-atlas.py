#!/usr/bin/env python3
"""
gen-code-atlas.py — build an interactive LOC / dead-code report ("Code Atlas")
for ANY QB64-PE project, by orchestrating the sibling skills:
    ../loc-by-file/loc-by-file.sh      (per-file code LOC)
    ../loc-by-subfunc/loc-by-subfunc.sh (per SUB/FUNCTION body LOC)

On top of the skill numbers it adds a reference / dead-code analysis: for each
routine, count references to its (sigil-stripped) name OUTSIDE its own body across
comment-stripped source; external==0 => defined-but-never-called candidate.

DEPENDENCIES: git submodules (from .gitmodules) are auto-detected and any that
contain QB64-PE source are analysed as a broken-out "dependency" — its files and
routines are reported separately, and each dependency routine gets a "by project"
count (references from the HOST project's own files) so you can see what the
project actually uses. Add extra dep dirs with --lib <relpath> (repeatable);
disable auto-detection with --no-auto-lib.

Usage:
    gen-code-atlas.py [ROOT] [--name NAME] [--lib RELPATH]... [--no-auto-lib] [--out FILE]
      ROOT         project root to analyse (default: git toplevel of cwd, else cwd)
      --name       project display name (default: basename of ROOT)
      --lib        extra dependency dir (repo-relative), repeatable
      --no-auto-lib  do not auto-detect submodules as dependencies
      --out        output .html path (default: <ROOT>/<NAME>-Code-Atlas.html)

Prints the output path. The SKILL then publishes it as an Artifact.
"""
import csv, io, json, os, re, subprocess, sys, time, argparse
from collections import Counter, defaultdict

SKILL_DIR = os.path.dirname(os.path.abspath(__file__))
SK_FILE = os.path.normpath(os.path.join(SKILL_DIR, "..", "loc-by-file", "loc-by-file.sh"))
SK_SUB  = os.path.normpath(os.path.join(SKILL_DIR, "..", "loc-by-subfunc", "loc-by-subfunc.sh"))
TEMPLATE = os.path.join(SKILL_DIR, "atlas-template.html")

IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
SIGIL = re.compile(r"[%&!#$~]+$")
HEAD  = re.compile(r"^\s*(sub|function)\s+([A-Za-z_][A-Za-z0-9_]*[%&!#$~]*)", re.I)
ENDR  = re.compile(r"^\s*end\s+(sub|function)\b", re.I)
INC   = re.compile(r"\$INCLUDE\s*:\s*['\"]([^'\"]+)['\"]", re.I)

def die(msg):
    sys.stderr.write("gen-code-atlas: " + msg + "\n"); sys.exit(1)

for p, n in ((SK_FILE, "loc-by-file"), (SK_SUB, "loc-by-subfunc"), (TEMPLATE, "atlas-template.html")):
    if not os.path.exists(p):
        die(f"missing {n} at {p} — install the loc-by-file & loc-by-subfunc skills alongside this one")

ap = argparse.ArgumentParser(add_help=True)
ap.add_argument("root", nargs="?", default=None)
ap.add_argument("--name", default=None)
ap.add_argument("--lib", action="append", default=[])
ap.add_argument("--no-auto-lib", action="store_true")
ap.add_argument("--ignore-dirs", action="append", default=[])
ap.add_argument("--all-dep-files", action="store_true")
ap.add_argument("--out", default=None)
A = ap.parse_args()

# repo-relative path prefixes to exclude from the PROJECT (not the build, e.g. DEV/
# experiments); excluded from the report AND the reference corpus so a routine called
# only from an ignored dir still reads as unused. Comma-separated and/or repeated.
IGNORE = []
for it in A.ignore_dirs:
    IGNORE += [x.strip().rstrip("/") for x in it.split(",") if x.strip()]
IGNORE = list(dict.fromkeys(IGNORE))
def ignored(p):
    return any(p == e or p.startswith(e + "/") for e in IGNORE)

# ---- resolve ROOT -----------------------------------------------------------
ROOT = A.root or os.getcwd()
try:
    ROOT = subprocess.run(["git","-C",ROOT,"rev-parse","--show-toplevel"],
                          capture_output=True,text=True).stdout.strip() or ROOT
except Exception:
    pass
ROOT = os.path.abspath(ROOT)
NAME = A.name or os.path.basename(ROOT.rstrip("/")) or "Project"

def sh(args, cwd=ROOT):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=True).stdout

def rev_of(path):
    try:
        b = subprocess.run(["git","-C",path,"rev-parse","--abbrev-ref","HEAD"],
                           capture_output=True,text=True).stdout.strip()
        h = subprocess.run(["git","-C",path,"rev-parse","--short","HEAD"],
                           capture_output=True,text=True).stdout.strip()
        return (b + " @ " + h) if h else "—"
    except Exception:
        return "—"
REV = rev_of(ROOT)

# ---- discover dependency dirs (submodules + --lib) --------------------------
libs = list(A.lib)
if not A.no_auto_lib:
    gm = os.path.join(ROOT, ".gitmodules")
    if os.path.exists(gm):
        for m in re.finditer(r"^\s*path\s*=\s*(.+?)\s*$", open(gm).read(), re.M):
            libs.append(m.group(1).strip())
# keep only dep dirs that exist and hold QB64 source
def has_src(d):
    for dp,_,fs in os.walk(os.path.join(ROOT,d)):
        if ".git" in dp: continue
        if any(f.lower().endswith((".bas",".bi",".bm")) for f in fs): return True
    return False
libs = [l for l in dict.fromkeys(libs) if os.path.isdir(os.path.join(ROOT,l)) and has_src(l)]
lib_set = set(libs)
def lib_of(path):
    for l in libs:
        if path == l or path.startswith(l + "/"): return l
    return None

# ---- helpers ----------------------------------------------------------------
def is_code(line):
    t = line.lstrip()
    if t == "": return False
    if t[0] == "'": return t[1:2] == "$"
    low = t.lower()
    if low == "rem" or low.startswith("rem ") or (low.startswith("rem") and t[3:4] in (" ","\t")):
        return False
    return True

def strip_comment(line):
    t = line.lstrip()
    if t == "" or (t[0] == "'" and t[1:2] != "$"): return ""
    low = t.lower()
    if low == "rem" or low.startswith("rem "): return ""
    out, inq = [], False
    for ch in line:
        if ch == '"': inq = not inq
        elif ch == "'" and not inq: break
        out.append(ch)
    return "".join(out)

def loc_by_file(root):
    """returns list of dicts with path relative to `root`."""
    rows = []
    for r in csv.DictReader(io.StringIO(sh([SK_FILE,"--csv",root]))):
        rows.append({"path":r["path"],"loc":int(r["loc"]),"lines":int(r["lines"]),
                     "comments":int(r["comments"]),"blank":int(r["blank"])})
    return rows

# ---- 1. enumerate files: project (excludes submodules) + each dep -----------
proj_rows = [r for r in loc_by_file(ROOT) if not ignored(r["path"])]
all_files = []   # {path(rel ROOT), loc,lines,comments,blank, lib(name or None)}
for r in proj_rows:
    all_files.append({**r, "lib": None})
lib_rows_all = {}   # lib -> ALL rows present in the dependency (before closure)
for l in libs:
    rows = loc_by_file(os.path.join(ROOT, l))
    lib_rows_all[l] = rows
    for r in rows:
        all_files.append({**r, "path": l + "/" + r["path"], "lib": l})

def topdir(p):
    return p.split("/",1)[0] if "/" in p else "(root)"

# ---- 1b. read every source once + compute the $INCLUDE closure --------------
# Only files reachable via $INCLUDE from a PROJECT entry (a top-level .BAS, never
# a dependency's own demo programs) are compiled into the build. Dependencies are
# restricted to that closure so we measure only what the project actually builds
# (e.g. DRAW pulls 34 of QB64_GJ_LIB's 190 files). --all-dep-files keeps them all.
raw_by = {}
present = {f["path"] for f in all_files}
for f in all_files:
    try:
        raw_by[f["path"]] = open(os.path.join(ROOT, f["path"]), errors="replace").read().splitlines()
    except Exception:
        raw_by[f["path"]] = []

def inc_targets(p):
    out = []
    for ln in raw_by.get(p, []):
        m = INC.search(ln)
        if not m: continue
        ip = m.group(1).strip().lstrip("./").replace("\\", "/")
        for c in (os.path.normpath(os.path.join(os.path.dirname(p), ip)), os.path.normpath(ip)):
            if c in present: out.append(c); break
    return out

entries = [f["path"] for f in all_files
           if f["lib"] is None and f["path"].lower().endswith(".bas")]
closure = set(); stack = list(entries)
while stack:
    x = stack.pop()
    if x in closure: continue
    closure.add(x)
    for e in inc_targets(x):
        if e not in closure: stack.append(e)

if not A.all_dep_files:
    all_files = [f for f in all_files if f["lib"] is None or f["path"] in closure]

# ---- 2. per-routine LOC via loc-by-subfunc (skill) --------------------------
skill_routines = defaultdict(list)   # path -> [(kind,name,loc)]
for f in all_files:
    out = sh([SK_SUB, f["path"], "--csv"])
    for r in csv.DictReader(io.StringIO(out)):
        skill_routines[f["path"]].append((r["kind"], r["name"], int(r["loc"])))

# ---- 3. parse spans + corpus (project + INCLUDED deps) ----------------------
freq_all = Counter()
freq_proj = Counter()          # non-dependency files only
file_lines = {}                # path -> stripped lines
spans = defaultdict(list)      # path -> [(kind,name,start,end)]
for f in all_files:
    p = f["path"]; raw = raw_by[p]
    stripped = [strip_comment(l) for l in raw]
    file_lines[p] = stripped
    isproj = f["lib"] is None
    for l in stripped:
        for m in IDENT.finditer(l):
            k = m.group(0).lower()
            freq_all[k] += 1
            if isproj: freq_proj[k] += 1
    inblk=False; kind=name=None; start=0
    for i,l in enumerate(raw):
        if not inblk:
            m = HEAD.match(l)
            if m: inblk=True; kind=m.group(1).upper(); name=m.group(2); start=i
        elif ENDR.match(l):
            spans[p].append((kind,name,start,i)); inblk=False
    if inblk: spans[p].append((kind,name,start,len(raw)-1))

# ---- 4. build routine records ----------------------------------------------
def own_count(p, span, base):
    if not span: return 0
    s,e = span; n=0
    for l in file_lines[p][s:e+1]:
        n += sum(1 for m in IDENT.finditer(l) if m.group(0).lower()==base)
    return n

routines=[]; lib_routines=[]
for f in all_files:
    p=f["path"]; libname=f["lib"]
    span_by={ (k,n):(s,e) for (k,n,s,e) in spans[p] }
    for (kind,name,loc) in skill_routines[p]:
        d = topdir(p)
        if kind=="MODULE":
            rec={"file":p,"dir":d,"name":"(module-level)","kind":"MODULE","loc":loc,
                 "refs":None,"external":None,"dead":False}
            if libname is None: routines.append(rec)
            else: rec.update({"lib":libname,"byProject":None,"unused":False}); lib_routines.append(rec)
            continue
        base = SIGIL.sub("",name).lower()
        own = own_count(p, span_by.get((kind,name)), base)
        external = max(freq_all.get(base,0)-own, 0)
        rec={"file":p,"dir":d,"name":name,"kind":kind,"loc":loc,
             "refs":freq_all.get(base,0),"external":external,"dead":external==0}
        if libname is None:
            routines.append(rec)
        else:
            byproj = freq_proj.get(base,0)     # refs from the host project's own files
            rec.update({"lib":libname,"byProject":byproj,"unused":byproj==0})
            lib_routines.append(rec)

# ---- 5. split files, dirs, totals ------------------------------------------
proj_files=[f for f in all_files if f["lib"] is None]
lib_files =[f for f in all_files if f["lib"] is not None]
for f in all_files:
    f["dir"]=topdir(f["path"]); f["density"]=round(f["loc"]/f["lines"],3) if f["lines"] else 0.0

dirs=defaultdict(lambda:{"loc":0,"lines":0,"comments":0,"blank":0,"files":0})
for f in proj_files:
    d=dirs[f["dir"]]
    for k in ("loc","lines","comments","blank"): d[k]+=f[k]
    d["files"]+=1
dirs_list=[{"dir":k,**v} for k,v in dirs.items()]

def tot(fs):
    return {"files":len(fs),"loc":sum(f["loc"] for f in fs),"lines":sum(f["lines"] for f in fs),
            "comments":sum(f["comments"] for f in fs),"blank":sum(f["blank"] for f in fs)}

nsub=sum(1 for r in routines if r["kind"]=="SUB")
nfun=sum(1 for r in routines if r["kind"]=="FUNCTION")
totals=tot(proj_files)
totals.update({"subs":nsub,"functions":nfun,
    "routine_loc":sum(r["loc"] for r in routines if r["kind"]!="MODULE"),
    "module_loc":sum(r["loc"] for r in routines if r["kind"]=="MODULE"),
    "dead_candidates":sum(1 for r in routines if r["dead"])})

lib_summary=[]
for l in libs:
    lf=[f for f in lib_files if f["lib"]==l]
    lr=[r for r in lib_routines if r.get("lib")==l and r["kind"]!="MODULE"]
    t=tot(lf)
    pres=lib_rows_all.get(l,[])
    lib_summary.append({"name":l,"loc":t["loc"],"lines":t["lines"],"files":t["files"],
        "files_present":len(pres),"loc_present":sum(r["loc"] for r in pres),
        "routines":len(lr),
        "used_by_project":sum(1 for r in lr if r["byProject"]),
        "unused_by_project":sum(1 for r in lr if not r["byProject"])})

report={
 "generated":time.strftime("%Y-%m-%d %H:%M"),"project":NAME,"rev":REV,
 "ignored":IGNORE,
 "totals":totals,
 "dirs":sorted(dirs_list,key=lambda x:-x["loc"]),
 "files":sorted([{k:f[k] for k in ("path","dir","loc","lines","comments","blank","density")} for f in proj_files],key=lambda x:-x["loc"]),
 "routines":sorted(routines,key=lambda x:-x["loc"]),
 "libs":lib_summary,
 "libFiles":sorted([{**{k:f[k] for k in ("path","dir","loc","lines","comments","blank","density")},"lib":f["lib"]} for f in lib_files],key=lambda x:-x["loc"]),
 "libRoutines":sorted(lib_routines,key=lambda x:-x["loc"]),
}

# ---- 6. splice into template + write ---------------------------------------
tpl=open(TEMPLATE).read()
data=json.dumps(report,separators=(",",":")).replace("</","<\\/")
html=(tpl.replace("__PROJECT__",NAME).replace("__REV__",REV).replace("__DATA__",data))
out=A.out or os.path.join(ROOT, re.sub(r"[^\w.-]","_",NAME)+"-Code-Atlas.html")
open(out,"w").write(html)

print(f"project={NAME}  rev={REV}" + (f"  ignoring={','.join(IGNORE)}" if IGNORE else ""))
print(f"files={totals['files']} loc={totals['loc']} subs={nsub} funcs={nfun} "
      f"dead={totals['dead_candidates']}")
for s in lib_summary:
    print(f"  dep {s['name']}: INCLUDED {s['files']}/{s['files_present']} files, "
          f"{s['loc']}/{s['loc_present']} LOC · {s['routines']} routines · "
          f"{s['used_by_project']} used / {s['unused_by_project']} unused by project")
print(f"OUT={out} ({os.path.getsize(out)} bytes)")
