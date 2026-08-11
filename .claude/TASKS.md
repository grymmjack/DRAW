# DRAW KITS — user-sharable/exportable asset kits

A kit bundles any combination of Themes, Patterns, Gradients, Brushes, Palettes,
Fonts (bitmap + TrueType/etc.), Text styles, and Templates — plus name,
description, author, and a preview screenshot. Export the current setup to a kit;
install kits from others.

## Locked decisions (from the user, 2026-08-11)

1. **Container = real `.zip`** (PKZIP: CRC-32, local file headers, central directory,
   EOCD) built over QB64-PE `_DEFLATE$`/`_INFLATE$`. Openable by OS zip tools.
2. **Export scope = pick items per type.** Each checked type opens a picker list of
   the user's items; only ticked items go in the kit.
3. **Install = per-type checkboxes.** Install dialog lists kit contents (with counts);
   user unchecks any type before installing.
4. **Conflicts = ask, with apply-to-all.** On a name clash, prompt overwrite / skip /
   keep-both, with an "apply to all remaining" checkbox.

Build after each task (`make` only — do NOT run QA; the user tests). Commit per task.

## 🔨 NOW — doing right now

(all 9 tasks complete — DRAW KITS feature done)

## Tasks

## Done

- [x] **1. ZIP writer** — `TOOLS/KIT-ZIP.BI/BM`: CRC-32, LE encoders, streaming writer (STORE +
  DEFLATE); verified against OS `unzip -t`/`-l`/extract; wired into `_ALL.BI/BM`. Commit 87bf2b1.
- [x] **2. ZIP reader** — EOCD scan + central-directory walk + per-entry inflate/CRC; `_INFLATE$`
  needs a zlib wrapper but ignores adler, so raw method-8 streams are wrapped. Verified round-trip
  + OS-`zip` interop (DEFLATE + STORE). Commit 98ea71e.
- [x] **3. Kit manifest** — `TOOLS/KIT.BI/BM`: KIT_TYPE_* types, KIT_MANIFEST, item list, and a
  line-based escaped manifest format; round-trip verified (fields + 7 items). Commit 6b24c22.
- [x] **4. Asset resolver** — `TOOLS/KIT-RESOLVE.BM`: per-type dirs/zip-prefix/is-folder, `KIT_enumerate`
  (themes/palettes/dsets-by-mode/fonts-by-ext/text-styles/templates), `KIT_refresh`. Compile-verified. Commit b0adf0c.
- [x] **5. Export dialog** — `GUI/KIT-DIALOG.BM`: `KIT_export_dialog%` (fields + screenshot chooser +
  per-type check-all/count/Items…) + `KIT_picker_dialog` + `KIT_sel_*` helpers. Compile-verified. Commit b6b148d.
- [x] **6. Export logic** — `TOOLS/KIT-IO.BM`: `KIT_export_write%` (manifest + preview + per-item entries;
  themes via BFS folder walk; text styles merged). Resolver stores real filenames. Compile-verified. Commit 3c939e7.
- [x] **7. Install dialog** — `KIT_install_dialog%` (pick kit, preview + meta + wrapped desc + per-type include
  checkboxes) + manifest/preview loaders. Compile-verified. Commit 0ba6f48. **Artifact published** (both dialogs).
- [x] **8. Install logic** — `KIT_install_apply%` (extract-by-prefix → targets, mkdir -p, text-style merge) +
  `KIT_conflict_dialog%` (overwrite/skip/keep-both + apply-to-all) + `KIT_refresh`. Compile-verified. Commit 34ba166.
- [x] **9. Menu wiring + config** — File ▸ Install Kit… / Export Kit… (actions 2321/2320, dup-CASE clean) →
  dialogs → writer/installer; `CFG.LAST_DIR_KIT$` remembers the dir. Compile-verified. Commit 0506ffd.

_(Prior post-merge sweep, shipped & pushed to main: a91c282 text-transform rasterize,
fa92e8d preview resize cursor, 3faf4e3 ANSI Target radio, 7208da4 ANSI region-select,
0fcd6ed scrollbar lane click-to-jump, 0acdc29 apron-aware text render.)_
