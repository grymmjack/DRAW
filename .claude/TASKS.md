# DRAW KITS — user-sharable/exportable asset kits

Transferred from PLANS/IDEAS.md. A kit is a single sharable archive bundling any
combination of: Themes, Patterns, Gradients, Brushes, Palettes, Fonts (bitmap +
TrueType/etc.), Text styles, Templates — plus a name, description, author info,
and a preview screenshot. Users export the current state to a kit and install
kits from others.

## 🔨 NOW — doing right now

(not started — batch just transferred; awaiting go-ahead + the container decision below)

## Open design decision (blocks task 1)

- **Archive container format.** QB64-PE ships `_DEFLATE$`/`_INFLATE$` (raw DEFLATE,
  already used by the Aseprite loader) but NO zip container. Two ways to satisfy
  "Install from zip / Export to zip":
  1. **Real `.zip`** — implement the PKZIP container (local file headers, central
     directory, CRC-32, EOCD) over `_DEFLATE$`/`_INFLATE$`. Interoperable with OS
     zip tools; more code (CRC-32 + directory structures).
  2. **DRAW-native `.dkit`** — a simple DRAW container (magic + manifest + per-entry
     length-prefixed DEFLATE blobs). Much less code; NOT openable by OS zip tools.
  The IDEAS spec literally says "zip", which argues for option 1. Confirm before task 1.

## Tasks

- [ ] **1. Kit archive I/O + manifest** — read/write the chosen container (see decision
  above); manifest holds name, description, author, screenshot, and the list of
  included asset types/files. CRC-32 helper if real zip.
- [ ] **2. Asset gather/scatter resolver** — one table mapping each shareable type to its
  on-disk source AND its install target: Themes (`ASSETS/THEMES/<name>/`), Patterns +
  Brushes (DSETs), Gradients, Palettes (`.GPL`), Fonts bitmap + TTF, Text styles,
  Templates. Both export and install go through it. (User assets live under
  `PATHS_DATA_DIR$`.)
- [ ] **3. Export dialog** — checkboxes for each type in current state (Themes / Patterns /
  Gradients / Brushes / Palettes / Fonts [Bitmap] [TrueType/etc.] / Text styles /
  Templates) + Name field + Description field + Screenshot chooser + Export button.
- [ ] **4. Export logic** — gather the checked types from the current state via the resolver,
  write them into the kit archive with the manifest + preview image.
- [ ] **5. Install dialog** — choose kit file (file dialog); show the preview image,
  description, and author info; per-type include checkboxes (default all present);
  Install button.
- [ ] **6. Install logic** — extract the selected types into the correct user dirs via the
  resolver; conflict handling (overwrite / skip / keep-both); refresh the in-app lists
  (palettes, DSETs, fonts, themes, text styles) so installed assets appear immediately.
- [ ] **7. Menu wiring + config** — menu entries (e.g. File > Kits > Install Kit… / Export
  Kit…, or a dedicated Kits menu); remember last kit directory in DRAW.cfg.

## Done

_(Prior post-merge bug/feature sweep — 6 items — shipped & pushed to main:
a91c282 text-transform rasterize, fa92e8d preview resize cursor, 3faf4e3 ANSI
Target radio, 7208da4 ANSI region-select, 0fcd6ed scrollbar lane click-to-jump,
0acdc29 apron-aware text render.)_
