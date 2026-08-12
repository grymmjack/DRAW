---
name: project_draw_kits
description: DRAW KITS feature — sharable asset-kit export/import; locked design decisions
metadata:
  type: project
---

DRAW KITS = user-sharable/exportable archives bundling any of: Themes, Patterns,
Gradients, Brushes, Palettes, Fonts (bitmap + TrueType), Text styles, Templates
+ name/description/author/screenshot. Export current setup → kit; install kits.

Locked decisions (user, 2026-08-11):
1. Container = **real `.zip`** (PKZIP: CRC-32, local headers, central directory, EOCD)
   built over QB64-PE `_DEFLATE$`/`_INFLATE$`. Openable by OS zip tools.
2. Export scope = **pick items per type** (each checked type opens a picker list).
3. Install = **per-type checkboxes** (dialog lists contents w/ counts; uncheck to skip).
4. Conflicts = **ask, with apply-to-all** (overwrite / skip / keep-both).

Working plan + progress live in `.claude/TASKS.md` (9 tasks). QB64-PE has raw
DEFLATE only, no zip container — the writer/reader are built by hand. User assets
under `PATHS_DATA_DIR$`; themes under `ASSETS/THEMES/`. Build with `make`; user
runs QA (see [[feedback_user_tests_qa]]).
