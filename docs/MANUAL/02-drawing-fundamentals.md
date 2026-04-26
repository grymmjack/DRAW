# Ch. 02  🖌️ Core Drawing Fundamentals

> **What you'll learn:** Free-hand brushwork, geometric shapes, polygons, the flood-fill tool, the spray can, and the eraser — the seven tools that account for 90% of pixel art.

---

## Brush, Dot & Freehand Drawing

> 🎯 **Goal:** Master basic freehand pixel drawing.

The two beginner tools you'll meet first are the **Brush** (`B`) for freehand strokes and the **Dot** (`D`) for single-pixel placement. Both share the same brush size and shape state — switching between them is instant and lossless.

| Tool | Icon | Key | Behaviour |
| --- | :---: | :---: | --- |
| Brush | ![brush](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/brush.png) | `B` | Drag to paint a continuous stroke. |
| Dot | ![dot](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/dot.png) | `D` | Click to stamp one pixel (or one brush footprint). |

**Brush size** runs from 1 to 50 pixels and is adjusted with `[` (smaller) and `]` (larger). The **brush shape** toggles between circle and square with `\`. To preview the current footprint and color before committing, hold the backtick key (`` ` ``).

DRAW follows the universal "left = foreground, right = background" convention. **Left-click paints with the FG color**, **right-click paints with the BG color**. Holding `Shift` while drawing constrains the stroke to a perfectly horizontal or vertical axis. Holding `Shift` and right-clicking draws a **connecting line** from the previous click to the current position — invaluable for stitching together long straight lines without ever touching the Line tool.

If you have a steady hand but find that single-pixel stairsteps creep into your strokes, enable **Pixel Perfect mode** with `F6`. DRAW will retroactively remove L-shaped corners as you draw, leaving cleaner outlines.

The Organizer widget on the right contains **four brush size presets** that you can configure for the workflow you use most often (e.g., 1, 2, 4, 8 pixels for sprite work).

> 🎨 **Try it — your first 16×16 sprite**
> 1. `Ctrl+N` for a new canvas at 16×16 pixels.
> 2. Press `D` for the Dot tool, set size to 1 with `[`.
> 3. Sketch out the silhouette of a simple character.
> 4. Switch to `B` (Brush), increase to size 2, and fill the larger regions.
> 5. Save as `.draw` so you can come back later.

> 📸 **Screenshot needed — brush preview overlay**
> - **Setup:** New 64×64 canvas, brush size 6, square shape, FG = bright cyan.
> - **Action:** Press and hold the backtick key over the canvas (do not click).
> - **Capture:** Cropped to canvas, shows the outlined preview footprint and color swatch.
> - **Save as:** `images/ch02-brush-preview.png`

## Lines, Rectangles & Ellipses

> 🎯 **Goal:** Draw clean geometric shapes.

When freehand stops being precise enough you reach for the geometric trio. All three respect the current brush size, color, and symmetry settings.

| Tool | Icon | Outlined | Filled |
| --- | :---: | :---: | :---: |
| Line | ![line](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/line.png) | `L` | — |
| Rectangle | ![rect](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/rect.png) ![rect-filled](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/rect-filled.png) | `R` | `Shift+R` |
| Ellipse / Circle | ![circle](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/circle.png) ![circle-filled](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/circle-filled.png) | `C` | `Shift+C` |

The shared modifier vocabulary across all three:

- **Shift** — constrain (line: H/V; rect: square; ellipse: circle).
- **Ctrl** — perfect aspect (forces square / circle even after you start dragging).
- **Shift while drawing the rect or ellipse** — anchor from the *center* instead of the corner.
- **Ctrl+Shift while drawing a line** — angle snap to 15°/30°/45°/90° increments.

> 🎨 **Try it — house in 30 seconds**
> 1. Filled rectangle for the body.
> 2. Two lines forming the roof triangle.
> 3. Filled circle (the sun).
> 4. A few short lines for the sun's rays.
> 5. Filled rectangle for the ground.

## Polygons & the Fill Tool

> 🎯 **Goal:** Draw complex shapes and fill regions.

The **Polygon** tool comes in two flavours: outlined (`P`) and filled (`Shift+P`). Each click adds a vertex to the in-progress polygon; press `Enter` to close and commit. As with the line tool, **Ctrl+Shift** snaps the segment angle.

The **Flood Fill** tool (`F`, ![fill](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/fill.png)) pours the FG color into every pixel contiguous with the click point that shares its starting color. By default it samples only the active layer; hold `Shift` to sample from the **merged visible composite** (useful when you have outlines and fills on separate layers).

DRAW's flood fill is unusual in two ways:

1. It supports **custom brushes as a tiled fill** — if you have a brush captured (Chapter 9), the fill is rendered as a seamless tiling of that brush rather than a flat color.
2. It also honours the **paint mode** — set Pattern or Gradient mode (Chapter 9) and your fill becomes a dithered gradient or tiled pattern instead of a solid color.

After a tiled fill, press `F8` to open the **Fill Adjustment overlay**. Drag the canvas to reposition the tile origin, mouse-wheel for uniform scale, drag the L-handle for independent X/Y scaling, and drag the rotation handle (small arc) to rotate the tile. `Enter` applies, `Esc` cancels.

> 🎨 **Try it — tileable pattern fill**
> 1. Draw a small 8×8 motif.
> 2. Capture it as a custom brush (see Chapter 9).
> 3. On a fresh layer, flood-fill a large rectangle with the brush active.
> 4. Press `F8` and experiment with scale, rotation, and offset.

![Fill Adjustment Handles](images/ch02-fill-adj.png)

## Spray Tool & Eraser

> 🎯 **Goal:** Use spray-can effects and clean up mistakes.

The **Spray** tool (`K`, ![spray](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/spray.png)) emits randomized dots within a circular nozzle. The nozzle radius **doubles for every brush-size step**, and density scales with radius — small brush = pinpoint mist, large brush = thick coverage. Spray respects custom brushes too: every "drop" stamps the brush instead of a single pixel, which is wonderful for foliage, dust, and confetti.

The **Eraser** (`E`, ![eraser](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/eraser.png)) paints fully transparent pixels — it does not paint with the BG color, it removes alpha. Two non-obvious tricks make it indispensable:

- **Hold `E` to temporarily eraser anything** while a different tool is active. Release `E` to return to your previous tool. This is the fastest way to nudge an outline or clean a stray pixel.
- **Smart Erase** (`Shift` while erasing) operates on **all visible layers at once**, with per-layer history tracking so each layer's undo step is independent.

The eraser uses your current brush size, shape, and even custom-brush stamp. The status bar shows `FG:TRN` to remind you transparent painting is active.

> 💡 **Tip:** Combine the eraser with a layer's **Opacity Lock** (Chapter 4) to clean up overpaint while preserving the layer's silhouette.

---

➡️ Next: [Chapter 3 — Color & Palette Mastery](03-color-palette.md)
