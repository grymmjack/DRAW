#!/usr/bin/env bash
# make-pdf-manual.sh — Build a single PDF from the DRAW user manual.
#
# Combines docs/MANUAL.md (cover + TOC) with docs/MANUAL/*.md (chapters)
# in order, rewrites image paths to absolute file:// URLs, and renders to
# docs/DRAW-Manual.pdf using one of (in order of preference):
#
#   1. pandoc + weasyprint   (best emoji & CSS support, if available)
#   2. pandoc + wkhtmltopdf
#   3. pandoc + xelatex
#   4. md-to-pdf (npx, uses headless Chromium via Puppeteer)
#   5. headless Google Chrome / Chromium (manual MD->HTML via markdown-it)
#
# Usage:
#   ./UTILS/make-pdf-manual.sh                 # build to docs/DRAW-Manual.pdf
#   ./UTILS/make-pdf-manual.sh -o foo.pdf      # custom output
#   ./UTILS/make-pdf-manual.sh --html-only     # leave the intermediate HTML
#   ./UTILS/make-pdf-manual.sh --engine chrome # force a specific engine
#
# Engines: weasyprint | wkhtmltopdf | xelatex | md-to-pdf | chrome
#
# Exit codes:
#   0 success
#   1 no rendering engine found
#   2 manual files missing

set -euo pipefail

# ---- Paths --------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCS_DIR="${REPO_ROOT}/docs"
MANUAL_DIR="${DOCS_DIR}/MANUAL"
COVER_FILE="${DOCS_DIR}/MANUAL.md"

OUT_PDF="${DOCS_DIR}/DRAW-Manual.pdf"
HTML_KEEP=0
FORCE_ENGINE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) OUT_PDF="$2"; shift 2 ;;
        --html-only) HTML_KEEP=1; shift ;;
        --engine)    FORCE_ENGINE="$2"; shift 2 ;;
        -h|--help)
            sed -n '1,30p' "$0"; exit 0 ;;
        *) echo "Unknown arg: $1" >&2; exit 64 ;;
    esac
done

[[ -f "$COVER_FILE" ]] || { echo "Missing $COVER_FILE" >&2; exit 2; }
[[ -d "$MANUAL_DIR" ]] || { echo "Missing $MANUAL_DIR" >&2; exit 2; }

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

COMBINED_MD="${WORK_DIR}/manual.md"
COMBINED_HTML="${WORK_DIR}/manual.html"

# ---- Step 1: concatenate ------------------------------------------------
# Order: cover first, then chapter files sorted by their NN- prefix.
# We add a page-break marker (via raw HTML div) between sections so the
# rendering engines that honour CSS get clean chapter starts.

echo "==> Combining markdown..."
python3 - <<PY > "$COMBINED_MD"
import os, re, sys, base64, mimetypes
from pathlib import Path

repo  = Path("$REPO_ROOT")
cover = Path("$COVER_FILE")
chap_dir = Path("$MANUAL_DIR")

# Inline images as data: URIs so every rendering engine (md-to-pdf's local
# HTTP server, headless Chrome from file://, weasyprint, etc.) can load them
# without cross-origin / file-access issues. Markdown links to other .md
# files become in-document anchors.
img_re  = re.compile(r'(!\[[^\]]*\]\()([^)\s]+)(\s*(?:"[^"]*")?\))')
link_re = re.compile(r'(?<!\!)(\[[^\]]*\]\()([^)\s]+)(\s*(?:"[^"]*")?\))')
htmlsrc_re = re.compile(r'(<img[^>]*\bsrc=")([^"]+)(")', re.IGNORECASE)

def to_data_uri(p: Path) -> str:
    if not p.is_file():
        sys.stderr.write(f"WARN: missing image {p}\n")
        return f"file://{p}"
    mime, _ = mimetypes.guess_type(p.name)
    mime = mime or "application/octet-stream"
    data = base64.b64encode(p.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{data}"

def absolutize(text: str, base: Path) -> str:
    def fix_img(m):
        prefix, target, suffix = m.group(1), m.group(2), m.group(3)
        if target.startswith(("http://","https://","data:","mailto:","#")):
            return m.group(0)
        return f'{prefix}{to_data_uri((base / target).resolve())}{suffix}'
    def fix_link(m):
        prefix, target, suffix = m.group(1), m.group(2), m.group(3)
        if target.startswith(("http://","https://","mailto:","#")):
            return m.group(0)
        if target.endswith(".md"):
            slug = Path(target).stem.lower().replace(" ", "-")
            return f'{prefix}#{slug}{suffix}'
        return m.group(0)
    text = img_re.sub(fix_img, text)
    text = link_re.sub(fix_link, text)
    text = htmlsrc_re.sub(
        lambda m: f'{m.group(1)}{to_data_uri((base / m.group(2)).resolve())}{m.group(3)}'
                  if not m.group(2).startswith(("http://","https://","data:"))
                  else m.group(0),
        text,
    )
    return text

def slug_for(path: Path) -> str:
    return path.stem.lower().replace(" ", "-")

def emit(path: Path, is_cover: bool):
    text = path.read_text(encoding="utf-8")
    text = absolutize(text, path.parent)
    anchor = slug_for(path)
    if not is_cover:
        # page break + anchor target so cross-file links still resolve
        print(f'\n\n<div class="page-break"></div>\n')
        print(f'<a id="{anchor}"></a>\n')
    print(text)

emit(cover, is_cover=True)

# Sort chapter files by their numeric prefix
chapters = sorted(
    (p for p in chap_dir.glob("*.md") if p.name != "SCREENSHOTS.md"),
    key=lambda p: p.name,
)
for ch in chapters:
    emit(ch, is_cover=False)
PY

echo "    -> $(wc -l < "$COMBINED_MD") lines combined"

# ---- Step 2: choose engine ---------------------------------------------
choose_engine() {
    if [[ -n "$FORCE_ENGINE" ]]; then echo "$FORCE_ENGINE"; return; fi
    if command -v pandoc >/dev/null 2>&1; then
        if command -v weasyprint  >/dev/null 2>&1; then echo "weasyprint";  return; fi
        if command -v wkhtmltopdf >/dev/null 2>&1; then echo "wkhtmltopdf"; return; fi
        if command -v xelatex     >/dev/null 2>&1; then echo "xelatex";     return; fi
    fi
    if command -v npx >/dev/null 2>&1; then echo "md-to-pdf"; return; fi
    if command -v google-chrome >/dev/null 2>&1 || command -v chromium >/dev/null 2>&1; then
        echo "chrome"; return
    fi
    echo "none"
}

ENGINE="$(choose_engine)"
echo "==> Using engine: $ENGINE"

# ---- CSS for HTML/Chrome/weasyprint pipelines --------------------------
CSS_FILE="${WORK_DIR}/manual.css"
cat > "$CSS_FILE" <<'CSS'
@page { size: Letter; margin: 0.75in; }
html { font-size: 11pt; }
body {
    font-family: "Inter", "Helvetica Neue", "Segoe UI", "Liberation Sans",
                 "Noto Sans", "Apple Color Emoji", "Noto Color Emoji",
                 sans-serif;
    color: #1a1a1a;
    line-height: 1.5;
    max-width: 7in;
    margin: 0 auto;
}
h1, h2, h3, h4 { font-weight: 700; line-height: 1.2; }
h1 { font-size: 2.2em; border-bottom: 3px solid #3d8bff; padding-bottom: 0.2em; margin-top: 0.5em; }
h2 { font-size: 1.55em; color: #1f4f99; margin-top: 1.6em; }
h3 { font-size: 1.2em; color: #2a2a2a; }
code, pre, kbd {
    font-family: "JetBrains Mono", "Fira Code", "Source Code Pro",
                 "Cascadia Mono", "Liberation Mono", monospace;
    font-size: 0.92em;
}
code { background: #f0f3f8; padding: 0.1em 0.35em; border-radius: 3px; }
pre  { background: #f7f9fc; padding: 0.8em 1em; border-left: 3px solid #3d8bff;
       border-radius: 4px; overflow-x: auto; }
pre code { background: transparent; padding: 0; }
blockquote {
    border-left: 4px solid #ffb84d;
    background: #fff8eb;
    margin: 1em 0; padding: 0.6em 1em;
    border-radius: 4px;
}
a { color: #1f6feb; text-decoration: none; }
a:hover { text-decoration: underline; }
img { max-width: 100%; height: auto; }
table { border-collapse: collapse; margin: 1em 0; width: 100%; }
th, td { border: 1px solid #cdd5e0; padding: 0.4em 0.7em; text-align: left;
         vertical-align: top; }
th { background: #eef3fb; }
hr { border: none; border-top: 1px solid #cdd5e0; margin: 2em 0; }
.page-break { page-break-before: always; break-before: page; }
/* Center the cover block */
body > div:first-of-type[align="center"], body > p:first-child img {
    display: block; margin: 1em auto; text-align: center;
}
CSS

# ---- Step 3: render -----------------------------------------------------
case "$ENGINE" in
    weasyprint)
        pandoc "$COMBINED_MD" -f gfm -t html5 \
            --metadata title="DRAW User Manual" \
            --css "$CSS_FILE" --standalone -o "$COMBINED_HTML"
        weasyprint "$COMBINED_HTML" "$OUT_PDF"
        ;;
    wkhtmltopdf)
        pandoc "$COMBINED_MD" -f gfm -t html5 \
            --metadata title="DRAW User Manual" \
            --css "$CSS_FILE" --standalone -o "$COMBINED_HTML"
        wkhtmltopdf --enable-local-file-access "$COMBINED_HTML" "$OUT_PDF"
        ;;
    xelatex)
        pandoc "$COMBINED_MD" -f gfm \
            --pdf-engine=xelatex \
            -V mainfont="DejaVu Sans" \
            -V monofont="DejaVu Sans Mono" \
            -V geometry:margin=0.75in \
            --metadata title="DRAW User Manual" \
            -o "$OUT_PDF"
        ;;
    md-to-pdf)
        # md-to-pdf reads from stdin and writes to <basename>.pdf next to cwd
        # by default. Use a config file to set CSS + output path explicitly.
        CONFIG_JS="${WORK_DIR}/md-to-pdf.config.js"
        cat > "$CONFIG_JS" <<JS
module.exports = {
    stylesheet:        ["$CSS_FILE"],
    pdf_options:       { format: "Letter", margin: "0.75in",
                         printBackground: true,
                         displayHeaderFooter: true,
                         headerTemplate: '<div></div>',
                         footerTemplate: '<div style="font-size:9px;width:100%;text-align:center;color:#888;">DRAW User Manual — <span class="pageNumber"></span> / <span class="totalPages"></span></div>' },
    launch_options:    { args: ["--no-sandbox","--allow-file-access-from-files"] },
    dest:              "$OUT_PDF",
    marked_options:    { gfm: true, breaks: false },
    basedir:           "$REPO_ROOT",
};
JS
        ( cd "$REPO_ROOT" && \
          npx --yes md-to-pdf --config-file "$CONFIG_JS" "$COMBINED_MD" )
        ;;
    chrome)
        # Convert MD -> HTML via npx markdown-it
        echo "    -> running markdown-it..."
        npx --yes markdown-it --html < "$COMBINED_MD" > "${WORK_DIR}/body.html"
        cat > "$COMBINED_HTML" <<HTML
<!doctype html><html lang="en"><head><meta charset="utf-8">
<title>DRAW User Manual</title>
<link rel="stylesheet" href="file://$CSS_FILE">
</head><body>
HTML
        cat "${WORK_DIR}/body.html" >> "$COMBINED_HTML"
        echo '</body></html>' >> "$COMBINED_HTML"

        CHROME_BIN="$(command -v google-chrome || command -v chromium)"
        "$CHROME_BIN" --headless --disable-gpu --no-sandbox \
            --no-pdf-header-footer \
            --allow-file-access-from-files \
            --print-to-pdf="$OUT_PDF" \
            --print-to-pdf-no-header \
            "file://$COMBINED_HTML"
        ;;
    none|"")
        cat >&2 <<MSG
ERROR: No supported PDF rendering engine found.

Install one of:
  • pandoc + weasyprint  (recommended; best emoji & CSS support)
        sudo apt install pandoc weasyprint
  • pandoc + wkhtmltopdf
        sudo apt install pandoc wkhtmltopdf
  • pandoc + xelatex (texlive-xetex)
        sudo apt install pandoc texlive-xetex texlive-fonts-recommended
  • Node.js (any recent version) with npx — the script will use md-to-pdf
  • Google Chrome or Chromium — for the headless fallback
MSG
        exit 1
        ;;
    *)
        echo "Unknown engine: $ENGINE" >&2; exit 1 ;;
esac

# ---- Step 4: optional html copy ----------------------------------------
if [[ "$HTML_KEEP" -eq 1 && -f "$COMBINED_HTML" ]]; then
    cp "$COMBINED_HTML" "${OUT_PDF%.pdf}.html"
    cp "$CSS_FILE"      "$(dirname "$OUT_PDF")/manual.css"
fi

echo "==> Wrote $OUT_PDF"
ls -lh "$OUT_PDF" | awk '{print "    " $5 "  " $9}'
