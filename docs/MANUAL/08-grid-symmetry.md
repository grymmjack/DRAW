# Ch. 08  📐 Grid, Symmetry & Drawing Aids

> **What you'll learn:** How to use DRAW's four grid geometries, three symmetry modes, angle-snap, the crosshair assistant, Pixel Perfect mode, and the pattern tile preview.

---

## Grid System — 4 Geometry Modes

> 🎯 **Goal:** Use grids for precise pixel art layout.

| Action | Key |
| --- | --- |
| Toggle grid visibility | `'` (apostrophe) |
| Toggle pixel grid (≥ 400% zoom) | `Shift+'` |
| Toggle snap-to-grid | `;` (semicolon) |
| Increase grid size | `.` |
| Decrease grid size | `,` |
| Cycle geometry mode | `Ctrl+'` |

Grid sizes range from 2 to 50 pixels per cell.

### Geometry modes

1. **Square** (default) — standard tile grid.
2. **Diagonal** — 45° rotated diamonds.
3. **Isometric** — 2:1 pixel-art standard.
4. **Hexagonal** — flat-top hexagons.

### Alignment

Each geometry can be set to either **Corner alignment** (snap on intersections) or **Center alignment** (snap on cell centers). The choice depends on whether you want to draw *between* cells or *on* them.

### Grid Cell Fill

When grid cell fill is enabled, the fill tool paints whole cells of the active geometry — squares for the square grid, diamonds and triangles for diagonal, and hexagons for hex.

`Ctrl+Shift` while drawing temporarily **bypasses snap**, so you can sketch freely without disabling the grid. All grid state is persisted in `.draw` files.

> 🎨 **Try it — isometric cube**
> 1. `Ctrl+'` to switch to Isometric mode.
> 2. `;` to enable snap.
> 3. Use the Polygon tool to outline the top, left, and right faces of a cube on three layers.
> 4. Apply Multiply/Screen blend modes for top vs. side shading.

> 📸 **Screenshot needed — isometric grid with cube outlined**
> - **Setup:** 256×256 canvas, isometric grid visible, snap on.
> - **Action:** Draw the three quad faces of a cube on three separate layers.
> - **Capture:** Canvas with grid + cube outlines.
> - **Save as:** `images/ch08-isometric-cube.png`

## Symmetry Drawing — Mirror & Kaleidoscope

> 🎯 **Goal:** Create symmetrical art effortlessly.

Press `F7` to cycle symmetry modes:

| Mode | Status bar | Copies | Shape |
| --- | :---: | :---: | --- |
| Off | `SYM:0` | 1 | — |
| Vertical | `SYM:1` (\|) | 2 | Bilateral |
| Cross | `SYM:2` (+) | 4 | Quad |
| Asterisk | `SYM:3` (\*) | 8 | Kaleidoscope |

`Ctrl+Click` repositions the symmetry center anywhere on the canvas. DRAW renders subtle visual guides at the center.

Symmetry works with **every** drawing tool — Brush, Dot, Line, Rect, Ellipse, Polygon, Spray, Custom Brush. `F8` disables symmetry (or, in Fill Adjust contexts, opens the adjust overlay).

> 🎨 **Try it — 8-way mandala**
> 1. New 256×256 canvas.
> 2. `F7` × 3 until status bar reads `SYM:3`.
> 3. `Ctrl+Click` the canvas center.
> 4. Draw one curved stroke from center outward — eight reflections appear instantly.
> 5. Add layers and blend modes to taste.

> 📸 **Screenshot needed — 8-way symmetry mandala**
> - **Setup:** 256×256 canvas, PICO-8 palette, `SYM:3` mode.
> - **Action:** Draw one curving stroke off-center. Capture mid-stroke if possible.
> - **Capture:** Cropped canvas showing all 8 reflections.
> - **Save as:** `images/ch08-symmetry-mandala.png`

## Drawing Aids — Angle Snap, Crosshair & Assists

> 🎯 **Goal:** Use helpers for clean, precise artwork.

### Angle Snap

Hold `Ctrl+Shift` while drawing a Line, Polygon, Brush stroke, or Dot connecting line. DRAW supports two angle-snap regimes:

- **Degree mode** — 15° / 30° / 45° / 90°.
- **Pixel-art mode** — integer-ratio angles like 1:1, 2:1, 1:2, 3:1, etc., which produce visually clean stairsteps without the half-pixel artefacts of 30° / 60° lines.

Choose the mode in `DRAW.cfg`.

### Crosshair Assistant

Hold `Shift` to display a full-screen crosshair through the cursor — invaluable for aligning distant elements. Color, opacity, width, and the optional outline stroke are all themeable.

### Pixel Perfect mode

`F6` toggles **Pixel Perfect** brush smoothing — DRAW retroactively removes L-shaped corners from your strokes for the cleanest possible 1-pixel outlines.

### Other view aids

- **Grayscale Preview** — `Ctrl+Alt+Shift+G`. View the composite as luminance only to check value structure.
- **Pattern Tile Mode** — `Shift+Tab`. Renders the canvas as a 3×3 tiled preview so seamless textures show their seams immediately.
- **Canvas Border** — `#`. Toggles a thin border around the canvas (useful at high zoom over dark themes).

---

➡️ Next: [Chapter 9 — Custom Brushes & Drawer Panel](09-brushes-drawer.md)
