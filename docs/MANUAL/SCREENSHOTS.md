# 📸 Screenshot Capture Checklist

This file tracks every `📸 Screenshot needed` placeholder across the manual. Capture each one in the recommended state (default theme, 1× display scale, PNG) unless the entry says otherwise. Drop the result into [`docs/MANUAL/images/`](images/) using the suggested filename and the placeholder will resolve automatically.

When all items are checked off, the manual is fully illustrated.

---

## How to capture

1. Launch DRAW with the default theme.
2. Set display scale 1× and toolbar scale 1× (Settings → General) so screenshots stay legible at typical zoom.
3. Hide notifications, tooltips you don't want, and any unrelated panels.
4. Use your OS region capture tool or `gnome-screenshot --area` (Linux) to crop to the listed region.
5. Save as PNG with the suggested filename.

---

## Checklist

### Chapter 1 — Introduction & Setup

- [ ] **`images/ch01-hero.png`** — Feature highlights reel.
  - Setup: Open one of `SAMPLES/*.draw`. Layer Panel + Toolbar visible.
  - Capture: Full DRAW window, default dark theme.
- [ ] **`images/ch01-ui-overview.png`** — Annotated UI overview.
  - Setup: Default theme, 800×600 canvas, all panels visible.
  - Action: None.
  - Post: Add callout arrows for Menu Bar, Toolbar, Canvas, Layer Panel, Palette Strip, Status Bar.
- [ ] **`images/ch01-command-palette.png`** — Command Palette open.
  - Setup: Any canvas. Press `?`, type `flip`.
  - Capture: Full window or cropped to the palette overlay.

### Chapter 2 — Drawing Fundamentals

- [ ] **`images/ch02-brush-preview.png`** — Brush preview overlay.
  - Setup: 64×64 canvas, brush size 6, square shape, FG = bright cyan.
  - Action: Hold `` ` `` over the canvas (no click).
  - Capture: Cropped to canvas with footprint preview visible.
- [ ] **`images/ch02-fill-adjust.png`** — Fill adjustment overlay.
  - Setup: 256×256 canvas with a custom brush captured. Flood-fill the entire canvas.
  - Action: Press `F8`. Hover an L-handle.
  - Capture: Full canvas with overlay handles.

### Chapter 3 — Color & Palette

- [ ] **`images/ch03-color-mixer.png`** — Color Mixer alongside canvas.
  - Setup: Open `View → Color Mixer`. Drag mixer to right of canvas.
  - Action: Adjust H slider mid-range so swatch is vivid blue/purple.
  - Capture: Full window crop.

### Chapter 4 — Layers

- [ ] **`images/ch04-symbol-layers.png`** — Symbol layers in action.
  - Setup: Three coin sprites at different sizes linked to one parent.
  - Action: Edit the parent so all three update.
  - Capture: Layer Panel + canvas.

### Chapter 5 — Selection & Clipboard

- [ ] **`images/ch05-stroke-selection.png`** — Stroke Selection dialog.
  - Setup: Marquee around a sprite shape on a transparent layer.
  - Action: `Edit → Stroke Selection`. Width = 2, Position = Outside.
  - Capture: Dialog overlapping canvas, before clicking OK.

### Chapter 6 — Transforms & Adjustments

- [ ] **`images/ch06-transform-distort.png`** — Transform overlay (Distort).
  - Setup: Sprite roughly centered. Selection around it. `Edit → TRANSFORM…`. Mode = Distort.
  - Action: Pull two corners outward to create a perspective trapezoid.
  - Capture: Full canvas with overlay frame and four corner handles.
- [ ] **`images/ch06-levels.png`** — Levels dialog with histogram.
  - Setup: Open a colorful image. `Image → Adjustments → Levels`.
  - Action: Drag gamma slider so preview is visibly brightened.
  - Capture: Dialog with histogram and live preview.

### Chapter 7 — Text System

- [ ] **`images/ch07-text-bar.png`** — Text property bar.
  - Setup: New canvas, press `T`, click on canvas to enter text mode.
  - Capture: Property bar at top with font dropdown, size, B/I/U/S toggles visible.
- [ ] **`images/ch07-charmap.png`** — Character Map panel.
  - Setup: VGA font, Character Mode enabled, `Ctrl+M` to open Character Map.
  - Action: Hover a block-shading glyph (e.g. `▒`).
  - Capture: Character Map panel docked right.

### Chapter 8 — Grid & Symmetry

- [ ] **`images/ch08-isometric-cube.png`** — Isometric grid + cube.
  - Setup: 256×256 canvas. Isometric grid visible. Snap on.
  - Action: Outline a cube's three faces on three layers.
  - Capture: Canvas with grid + cube outlines.
- [ ] **`images/ch08-symmetry-mandala.png`** — 8-way symmetry mandala.
  - Setup: 256×256 canvas. PICO-8 palette. Press `F7` × 3 (`SYM:3`).
  - Action: Ctrl+Click center. Draw one curving stroke.
  - Capture: Cropped canvas showing all 8 reflections.

### Chapter 9 — Brushes & Drawer

- [ ] **`images/ch09-drawer-panel.png`** — Drawer panel populated.
  - Setup: Load `DEV/brush-set.dset`. All 30 slots populated.
  - Action: Hover one slot for tooltip.
  - Capture: Drawer panel docked, mini palette visible.

### Chapter 10 — File I/O

- [ ] **`images/ch10-bas-export.png`** — BAS export running.
  - Setup: 32×32 sprite. `File → Export As → QB64 BAS`.
  - Action: Compile and run the resulting `.bas`.
  - Capture: QB64 console window with the rendered sprite next to the same sprite in DRAW.

### Chapter 11 — Canvas & View

- [ ] **`images/ch11-pattern-tile.png`** — Pattern Tile Mode.
  - Setup: 32×32 tile with visible seams.
  - Action: `Shift+Tab`.
  - Capture: Full window showing the 3×3 tiling.

### Chapter 12 — Settings

- [ ] **`images/ch12-settings-general.png`** — Settings dialog (General tab).
  - Setup: `Edit → Settings`.
  - Capture: Full dialog overlapping canvas.

### Chapter 13 — Audio

- [ ] **`images/ch13-audio-menu.png`** — Audio menu open.
  - Setup: Theme with music files in `MUSIC/`. Auto-shuffle on.
  - Action: Click `Audio` in the menu bar.
  - Capture: Open Audio menu with NOW PLAYING entry visible.

### Chapter 14 — Pixel Art Analyzer

- [ ] **`images/ch14-analyzer.png`** — Analyzer overlay.
  - Setup: 32×32 sprite with several orphan pixels and doubles.
  - Action: Run Pixel Art Analyzer; tab to Orphan pixels.
  - Capture: Canvas with highlights + analyzer dialog.

### Chapter 15 — Reference & Import

- [ ] **`images/ch15-import.png`** — Import Image with rotated overlay.
  - Setup: Existing 256×256 canvas. Import a photo larger than the canvas.
  - Action: Rotate import 90° CW; pan inside image.
  - Capture: Full canvas with import overlay and toolbar.

---

## Optional / future captures

These would enrich the manual but are not blocking placeholders:

- Toolbox close-up at 2× toolbar scale.
- Layer Panel close-up showing groups, symbol parent/child, locked layers.
- Reference image at 30% opacity behind a half-traced sprite.
- Per-theme variant of the UI overview (e.g., a light theme).
- Animated GIFs of: 8-way symmetry stroke, transform overlay rotate, palette ops remap (these are excluded from the static manual but useful for the README / website).
