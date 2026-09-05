---
name: make-shortcuts-card
description: Build a clean, at-a-glance DRAW shortcuts reference (DRAW-Shortcuts.md + DRAW-Shortcuts.pdf) for end users — a compact "these keys do this" card distilled from SHORTCUTS.md, with all the developer material (registry/dispatch notes, action ids, the generated binding index, internal-behavior appendix) stripped out.
---

# Make Shortcuts Card Skill

When the user invokes this skill (e.g. "/make-shortcuts-card", "make the shortcuts
cheat sheet", "build the at-a-glance shortcuts PDF"), run the steps below. It is
fully automatable — no prompts required.

This produces a **user-facing** reference, distinct from `SHORTCUTS.md` (which is the
developer source of truth with dispatch status, action ids, and the auto-generated
binding index). The card keeps only the "Keys → what it does" activity tables.

---

## Step 1 — Run the builder

From the repo root:

```bash
./tools/make-shortcuts-card.sh
```

What it does:

- Reads `SHORTCUTS.md` and extracts **only the user-facing activity sections** —
  from `## Global / Application` up to (not including) `## Command Line`. That drops
  the dev-facing "How to read this" registry notes, the `## Command Line` flags, the
  `## Pixel Art Analyzer` overlay, the `## Appendix: internal behaviors`, and the
  auto-generated `## Generated binding index` (with its central/legacy + action-id
  columns).
- Prepends a clean title + a one-line legend (Primary = Ctrl/⌘, Hold X + …, mouse
  notation), stamped with `APP_VERSION$` from `_COMMON.BI` and today's date.
- Writes **`DRAW-Shortcuts.md`** (the Markdown card) at the repo root.
- Renders **`DRAW-Shortcuts.pdf`** via `pandoc` → HTML (`--embed-resources`, so the
  stylesheet is inlined) → headless Chrome, styled by `tools/shortcuts-card.css`
  (compact 2-column reference card: teal section headers, key badges, US Letter).

If `pandoc` + a Chromium/Chrome are not both present, it still writes the `.md` and
says so (see Step 4).

---

## Step 2 — Verify

```bash
# clean = no developer material leaked in
grep -cE "Generated binding index|central \||legacy \||dispatched|actionId" DRAW-Shortcuts.md   # expect 0
# pdf sanity
pdfinfo DRAW-Shortcuts.pdf | grep -E "Pages|Page size"                                          # ~6 pages, letter
```

To eyeball a page, render it rather than opening a viewer:

```bash
pdftoppm -f 1 -l 1 -r 90 -png DRAW-Shortcuts.pdf /tmp/card && open/read /tmp/card-1.png
```

Spot-check: the title + legend at the top, teal section bars (Global / File / Edit …),
keys shown as small badges, and two balanced columns.

---

## Step 3 — Hand it to the user

Send `DRAW-Shortcuts.pdf` (and/or `DRAW-Shortcuts.md`) to the user. The PDF is the
"print it / keep it open on a second monitor" artifact; the MD is handy for pasting
into a wiki or README.

---

## Step 4 — Engine prerequisites (only if Step 1 says no engine)

The `.md` always builds. For the PDF the script needs **pandoc** plus a **Chromium/Chrome**:

| Need | Install |
| --- | --- |
| pandoc | `sudo apt install pandoc` (or `brew install pandoc`) |
| Chromium | `sudo apt install chromium` (or use Google Chrome) |

(The sibling `make-pdf-manual` skill's `DEV/make-pdf-manual.sh` supports more engines
— weasyprint/wkhtmltopdf/xelatex — if you'd rather add one of those as a fallback.)

---

## Notes

- **Single source of truth.** The card is *derived* from `SHORTCUTS.md`; never hand-edit
  `DRAW-Shortcuts.md` — change `SHORTCUTS.md` (or, for the binding facts, the registry
  via `tools/gen-shortcuts.sh`) and re-run this skill.
- **What's included vs not** is controlled by the section range in
  `tools/make-shortcuts-card.sh` (the `awk` `## Global / Application` → `## Command Line`
  window). To add/drop a section on the card, adjust that window or the section headers
  in `SHORTCUTS.md`.
- **Styling** lives in `tools/shortcuts-card.css` (column count, badge look, page size).
- Both outputs are small; commit them alongside `SHORTCUTS.md` changes so the printable
  card never lags the source.
