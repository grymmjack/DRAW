#!/usr/bin/env bash
# Build a clean, at-a-glance DRAW shortcuts reference (MD + PDF) from SHORTCUTS.md.
#
# It takes ONLY the user-facing activity sections (Global/Application .. Hold-Key
# Chords) and drops all the developer material — the "How to read this" registry
# notes, the generated binding index (central/legacy, action ids), internal-behavior
# appendix, and command-line flags. Output: DRAW-Shortcuts.md + DRAW-Shortcuts.pdf
# at the repo root.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1   # repo root (script lives in DEV/tools/)

SRC="SHORTCUTS.md"
OUT_MD="DRAW-Shortcuts.md"
OUT_PDF="DRAW-Shortcuts.pdf"
CSS="DEV/tools/shortcuts-card.css"
[ -f "$SRC" ] || { echo "make-shortcuts-card: $SRC not found"; exit 1; }

VERSION="$(grep -oE 'APP_VERSION\$[[:space:]]*=[[:space:]]*"[^"]+"' _COMMON.BI | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
DATE="$(date +%Y-%m-%d)"

# --- 1. Clean header + one-line legend (replaces the dev "How to read this") ---
{
  echo "# DRAW — Keyboard & Mouse Shortcuts"
  echo ""
  echo "**Quick reference · v${VERSION:-2.0.0} · ${DATE}**"
  echo ""
  echo "> **Primary** = Ctrl (Windows/Linux) or ⌘ Cmd (macOS).  **Hold X + …** = hold that key, then press/click/drag.  **L/R/M-Click** = left / right / middle mouse · **Wheel** = scroll.  Keys only do the listed thing when not typing in a text field."
  echo ""
  echo "---"
  echo ""
} > "$OUT_MD"

# --- 2. Extract the user-facing activity sections only ---
#     from "## Global / Application" up to (not incl.) "## Command Line"
awk '
  /^## Global \/ Application/ { on=1 }
  /^## Command Line/          { on=0 }
  on { print }
' "$SRC" >> "$OUT_MD"

echo "make-shortcuts-card: wrote $OUT_MD ($(wc -l < "$OUT_MD") lines)"

# --- 3. Render PDF (pandoc -> HTML -> headless Chrome) ---
CHROME=""
for c in google-chrome google-chrome-stable chromium chromium-browser; do command -v "$c" >/dev/null && { CHROME="$c"; break; }; done
if command -v pandoc >/dev/null && [ -n "$CHROME" ]; then
  TMPHTML="$(mktemp --suffix=.html)"
  # --embed-resources inlines the CSS so headless Chrome (rendering file:///tmp/…)
  # doesn't try to resolve the stylesheet relative to /tmp and 404.
  pandoc "$OUT_MD" -f gfm -t html5 --standalone --embed-resources \
    --metadata title="DRAW Shortcuts" ${CSS:+-c "$CSS"} -o "$TMPHTML"
  "$CHROME" --headless=new --disable-gpu --no-sandbox --no-pdf-header-footer \
    --print-to-pdf="$OUT_PDF" "file://$TMPHTML" >/dev/null 2>&1 \
    || "$CHROME" --headless --disable-gpu --no-sandbox --print-to-pdf="$OUT_PDF" "file://$TMPHTML" >/dev/null 2>&1
  rm -f "$TMPHTML"
  if [ -s "$OUT_PDF" ]; then
    echo "make-shortcuts-card: wrote $OUT_PDF ($(du -h "$OUT_PDF" | cut -f1))"
  else
    echo "make-shortcuts-card: PDF render failed — $OUT_MD is still valid"
  fi
else
  echo "make-shortcuts-card: no pandoc+chrome — produced $OUT_MD only (install pandoc + chromium for PDF)"
fi
