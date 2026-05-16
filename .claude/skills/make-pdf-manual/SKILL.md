---
name: make-pdf-manual
description: Build a single PDF (docs/DRAW-Manual.pdf) from the split Markdown user manual under docs/MANUAL/. Combines the cover and all chapter files in order, rewrites image paths, and renders via pandoc/weasyprint, md-to-pdf (Puppeteer), or headless Chrome.
---

# Make PDF Manual Skill

When the user invokes this skill (e.g. "/make-pdf-manual", "build the manual PDF", "make-pdf-manual skill"), execute the steps below **in order**. The skill is fully automatable — there are no required user prompts unless an engine is missing.

---

## Step 1 — Sanity-check inputs

Verify the manual sources exist:

- `docs/MANUAL.md` (cover + master TOC)
- `docs/MANUAL/01-introduction.md` … `docs/MANUAL/20-appendix.md`

If any are missing, stop and report which file(s) are missing. Do **not** attempt to regenerate them — that is a separate task.

---

## Step 2 — Run the builder

The script lives at [`UTILS/make-pdf-manual.sh`](../../../UTILS/make-pdf-manual.sh). From the repo root:

```bash
./UTILS/make-pdf-manual.sh
```

Default behaviour:

- Concatenates `docs/MANUAL.md` + every `docs/MANUAL/NN-*.md` (sorted by NN prefix), skipping `SCREENSHOTS.md`.
- Rewrites every Markdown image / link / `<img>` path to an absolute `file://` URL so that images resolve correctly inside the combined document.
- Rewrites in-document Markdown links between chapter files to `#slug` anchors targeting the combined document.
- Picks the best available rendering engine in this order: `weasyprint` → `wkhtmltopdf` → `xelatex` → `md-to-pdf` (npx, Puppeteer) → headless `google-chrome` / `chromium`.
- Writes `docs/DRAW-Manual.pdf` at US Letter size with a CSS stylesheet that handles emoji, tables, blockquote callouts, code blocks, and chapter page-breaks.

### Useful flags

| Flag | Purpose |
| --- | --- |
| `-o <file>` / `--output <file>` | Custom output path. |
| `--html-only` | Also keep the intermediate HTML next to the PDF (useful for debugging styling). |
| `--engine <name>` | Force a specific engine: `weasyprint`, `wkhtmltopdf`, `xelatex`, `md-to-pdf`, `chrome`. |

---

## Step 3 — Verify

After the script reports `==> Wrote …/DRAW-Manual.pdf`, confirm:

1. The file exists and is non-empty (script already prints size).
2. Open it: `xdg-open docs/DRAW-Manual.pdf` (Linux), `open` (macOS), or `start` (Windows).
3. Spot-check page 1 (cover with the DRAW logo), the master Table of Contents, one chapter heading mid-document, and the appendix.

If any image is missing in the PDF, the cause is almost always one of:

- The image path doesn't exist on disk → fix in the source markdown.
- The chosen engine doesn't allow local-file access → re-run with `--engine md-to-pdf` (most permissive).

---

## Step 4 — Engine prerequisites (only if step 2 says no engine found)

The script will tell you which packages to install. Cheat sheet:

| Engine | Install |
| --- | --- |
| pandoc + weasyprint (best) | `sudo apt install pandoc weasyprint` |
| pandoc + wkhtmltopdf | `sudo apt install pandoc wkhtmltopdf` |
| pandoc + xelatex | `sudo apt install pandoc texlive-xetex texlive-fonts-recommended` |
| md-to-pdf (Puppeteer) | Any Node.js with `npx`. The script downloads `md-to-pdf` on demand. |
| Headless Chrome | Google Chrome or Chromium installed. The script also needs `npx markdown-it` for MD→HTML; auto-fetched. |

---

## Step 5 — Optional: commit the PDF

The PDF is a build artifact. By default the manual lives in `docs/DRAW-Manual.pdf`; keep it out of version control unless the user explicitly asks to commit it. Add `docs/DRAW-Manual.pdf` to `.gitignore` if you want to ensure it's never tracked.

---

## Notes

- The manual uses the chapter emojis from the DRAW XMind feature mindmap (🎬🖌️🎨📚✂️🔄📝📐🪄💾🖥️⚙️🔊🔍🖼️⌨️↩️🎓💡📋). All five engines render emoji glyphs correctly when the system has Noto Color Emoji or Apple Color Emoji installed.
- Chapter-to-chapter Markdown links (e.g. `[Chapter 9](09-brushes-drawer.md)`) become in-document anchors so the PDF's TOC remains clickable.
- Screenshot placeholders (`📸 **Screenshot needed**`) render as styled blockquotes and are tracked in [`docs/MANUAL/SCREENSHOTS.md`](../../../docs/MANUAL/SCREENSHOTS.md). When real screenshots replace them, no script change is required.
