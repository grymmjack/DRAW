# Ch. 18  🎓 Real-World Pixel Art Workflows

> **What you'll learn:** Step-by-step recipes for the most common pixel-art tasks: a 16×16 sprite, a seamless tile, isometric building, mandala, ANSI art, sprite-sheet assembly, and converting a photo into pixel art.

---

## Workflow — Game Sprite (16×16 Character)

> 🎯 **Goal:** Create a complete game character sprite.

1. **`Ctrl+N`** — new canvas, 16×16, grid = 1, snap on.
2. **Choose a limited palette** — NES or PICO-8 are great starting points.
3. **Layer 1: Silhouette** — draw the outline in a single dark color.
4. **Layer 2: Base colors** — turn on Opacity Lock and fill regions.
5. **Layer 3: Shading** — set blend mode to Multiply, paint cool desaturated tones in shadow areas.
6. **Layer 4: Highlights** — set blend mode to Screen, dab warm light tones on edges facing your imaginary light source.
7. **Run the Pixel Art Analyzer** — fix orphans, doubles, jaggies, banding.
8. **Export** — File → Export As → PNG (plain) for engines, or save as `.draw` to keep the layers editable.

<div class="page-break"></div>

## Workflow — Seamless Tile Texture

> 🎯 **Goal:** Create a tileable background pattern.

1. **`Ctrl+N`** — new canvas, 32×32 or 64×64.
2. **`Shift+Tab`** — enable Pattern Tile Mode. The 3×3 preview will reveal seams instantly.
3. Draw your base pattern.
4. Watch the seams in the preview. Fix them at the canvas edges by painting through the wrap.
5. Capture the result as a custom brush.
6. On a fresh test canvas, flood-fill with the brush to verify seamlessness.
7. Export as a plain PNG tile.

<div class="page-break"></div>

## Workflow — Isometric Pixel Art

> 🎯 **Goal:** Create isometric buildings and objects.

1. **`Ctrl+'`** — set grid geometry to Isometric.
2. **`;`** — enable snap.
3. The grid guides ensure perfect 2:1 ratio. (Also try Edit → Angle Snap: Pixel Art)
4. Use the Polygon tool for angled surfaces (top, left, right faces of a cube).
5. Put each face on its own layer.
6. Use Multiply / Screen blend modes for light/shadow on each face.
7. Group the layers per object so you can move it as a unit.

<div class="page-break"></div>

## Workflow — Symmetrical Mandala / Pattern

> 🎯 **Goal:** Create complex symmetrical artwork.

1. **`F7` × 3** — enable 8-way (asterisk) symmetry.
2. **`Ctrl+Click`** the canvas center.
3. Draw one slice — eight reflections appear instantly.
4. Layer subsequent strokes on different layers with different blend modes.
5. Vary opacity for depth.
6. Use custom-brush stamps (small flowers, dots, geometric shapes) for ornamentation.

<div class="page-break"></div>

## Workflow — ANSI / Text Art with Character Mode

> 🎯 **Goal:** Create text-mode art using block characters.

1. Press `T`, switch to the VGA font.
2. Enable Character Mode.
3. Open the Character Map (`Ctrl+M`).
4. Use `F1`–`F12` for the ANSI block-shading characters (`░ ▒ ▓ █ ▀ ▄ ▌ ▐`).
5. Navigate with the virtual cursor.
6. `Alt+U` picks colors from any existing character cell.
7. The DOT and RECT tools fill cells with the active glyph instead of pixels.
8. Toggle CP437 mode (`Ctrl+Shift+U`) for the classic DOS feel.

<div class="page-break"></div>

## Workflow — Sprite Sheet Assembly & Export

> 🎯 **Goal:** Assemble sprites into a sheet and re-extract.

1. Create individual sprites on separate layers.
2. Use grid + snap for consistent spacing.
3. Use **layer groups** per animation frame.
4. Use **Align & Distribute** for perfect layout.
5. Export the full sheet as PNG.
6. Use **Extract Images** to decompose the sheet into individual PNGs (Chapter 10).
7. Save the project as `.draw` to preserve layers for future edits.

<div class="page-break"></div>

## Workflow — Photo to Pixel Art

> 🎯 **Goal:** Convert a photograph into pixel art.

1. **`Ctrl+R`** — load the photo as a reference image.
2. Choose a limited palette (Endesga 32 is a great default).
3. Set reference opacity to ~60% with `Ctrl+Shift`+Wheel.
4. Trace key shapes on a new layer with line and polygon tools.
5. Fill regions with flood fill.
6. Add detail with the brush and dot tools.
7. Apply Image Adjustments (Levels, Hue/Sat) for color tweaking.
8. Run **Posterize** if you want pixel-art-friendly value steps.
9. Hide the reference and evaluate the standalone result.

---

➡️ Next: [Chapter 19 — Tips, Tricks & Advanced Techniques](19-tips.md)
