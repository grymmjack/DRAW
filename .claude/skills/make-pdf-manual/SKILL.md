---
name: make-pdf-manual
description: Build DRAW-Manual.pdf from the split Markdown user manual under docs/MANUAL/. Combines the cover and all chapter files in order, stamps the version, rewrites image paths, and renders via pandoc/weasyprint, md-to-pdf (Puppeteer), or headless Chrome.
---

# Make PDF Manual Skill

When the user invokes this skill (e.g. "/make-pdf-manual", "build the manual PDF", "make-pdf-manual skill"), execute the steps below **in order**. The skill is fully automatable — there are no required user prompts unless an engine is missing.

---

## Step 1 — Sanity-check inputs

Verify the manual sources exist:

- `docs/MANUAL.md` (cover + master TOC)
- `docs/MANUAL/NN-*.md` chapter files

Do **not** hardcode a chapter count. The script globs `docs/MANUAL/*.md` and
sorts by the `NN-` prefix, so chapters can be added or removed without touching
it — as of manual revision 2026-08-02 there are 21, ending with
`21-ai-generation.md`. Only `SCREENSHOTS.md` is skipped.

If the cover or the chapter directory is missing, stop and report which. Do
**not** attempt to regenerate them — that is a separate task.

---

## Step 2 — Run the builder

The script lives at [`DEV/make-pdf-manual.sh`](../../../DEV/make-pdf-manual.sh),
with its stylesheet alongside it at `DEV/make-pdf-manual.css`. From the repo root:

```bash
./DEV/make-pdf-manual.sh
```

Default behaviour:

- Concatenates `docs/MANUAL.md` + every `docs/MANUAL/NN-*.md` (sorted by NN prefix), skipping `SCREENSHOTS.md`.
- Rewrites every Markdown image / link / `<img>` path to an absolute `file://` URL so that images resolve correctly inside the combined document.
- Rewrites in-document Markdown links between chapter files to `#slug` anchors targeting the combined document.
- Picks the best available rendering engine in this order: `weasyprint` → `wkhtmltopdf` → `xelatex` → `md-to-pdf` (npx, Puppeteer) → headless `google-chrome` / `chromium`.
- Stamps `{{VERSION}}` from `APP_VERSION$` in `_COMMON.BI` and `{{DATE}}` with today's date, so the cover always matches the build.
- Renders at US Letter size using `DEV/make-pdf-manual.css`, which handles emoji, tables, blockquote callouts, code blocks, and chapter page-breaks.
- Builds to `docs/DRAW-Manual.pdf` and then **moves it to the repo root** as `DRAW-Manual.pdf`. That is the final location — the `docs/` copy will not exist when the script finishes.

### Useful flags

| Flag | Purpose |
| --- | --- |
| `-o <file>` / `--output <file>` | Custom output path. Note the script still moves the result to the repo root under the same basename unless the path already is the repo root. |
| `--html-only` | Also keep the intermediate HTML next to the PDF (useful for debugging styling). |
| `--engine <name>` | Force a specific engine: `weasyprint`, `wkhtmltopdf`, `xelatex`, `md-to-pdf`, `chrome`. |

---

## Step 3 — Verify

The script prints `==> Wrote …/docs/DRAW-Manual.pdf` and then
`==> Moved to …/DRAW-Manual.pdf`. **The second path is the real one.** Confirm:

1. The file exists and is non-empty (the script prints its size).
2. Check the page count and that new content actually made it in — far more
   reliable than opening it and eyeballing:
   ```bash
   pdfinfo DRAW-Manual.pdf | grep -E "Pages|Page size"
   pdftotext DRAW-Manual.pdf - | grep -c "<a phrase from the new chapter>"
   ```
3. To inspect a page visually, find and render it rather than scrolling a viewer:
   ```bash
   for p in $(seq 1 $(pdfinfo DRAW-Manual.pdf | awk '/^Pages/{print $2}')); do
       pdftotext -f $p -l $p DRAW-Manual.pdf - | grep -q "Chapter 21" && echo "page $p"
   done
   pdftoppm -f <page> -l <page> -r 70 -png DRAW-Manual.pdf /tmp/mpage
   ```
   Then read `/tmp/mpage-<page>.png`.
4. Spot-check the cover (DRAW logo), the master TOC, a mid-document chapter
   heading, and the appendix.

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

## Step 5 — Commit the PDF

`DRAW-Manual.pdf` at the repo root **is tracked in this repository** — check
with `git ls-files | grep DRAW-Manual`. It ships with the project, so a rebuild
that is not committed leaves a stale PDF next to updated Markdown.

Commit it whenever the manual sources change. It is a ~5 MB binary, so do not
rebuild and commit it for unrelated work.

---

## Notes

- The manual uses a chapter emoji per heading (🎬🖌️🎨📚✂️🔄📝📐🪄💾🖥️⚙️🔊🔍🖼️⌨️↩️🎓💡📋🤖). All five engines render emoji glyphs correctly when the system has Noto Color Emoji or Apple Color Emoji installed.
- **Adding a chapter** takes three edits beyond the chapter file itself: the master TOC in `docs/MANUAL.md`, the directory listing further down that same file, and — if it introduces shortcuts — the keyboard summary in `docs/MANUAL/20-appendix.md`. The build script itself needs no change.
- Chapter-to-chapter Markdown links (e.g. `[Chapter 9](09-brushes-drawer.md)`) become in-document anchors so the PDF's TOC remains clickable.
- Screenshot placeholders (`📸 **Screenshot needed**`) render as styled blockquotes and are tracked in [`docs/MANUAL/SCREENSHOTS.md`](../../../docs/MANUAL/SCREENSHOTS.md). When real screenshots replace them, no script change is required.
