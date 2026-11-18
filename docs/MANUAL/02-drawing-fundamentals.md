# Ch. 02  🖌️ Core Drawing Fundamentals

> **What you'll learn:** Free-hand brushwork, geometric shapes, polygons, the flood-fill tool, the spray can, and the eraser — the seven tools that account for 90% of pixel art.

---

## Brush, Dot & Freehand Drawing

> 🎯 **Goal:** Master basic freehand pixel drawing.

The two beginner tools you'll meet first are the **Brush** (`B`) for freehand strokes and the **Dot** (`D`) for single-pixel placement. Both share the same brush size and shape state.

| Tool | Icon | Key | Behaviour |
| --- | :---: | :---: | --- |
| Brush | ![brush](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/brush.png) | `B` | Drag to paint a continuous stroke. |
| Dot | ![dot](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/dot.png) | `D` | Click to stamp one pixel (or one brush footprint). |

**Brush size** runs from 1 to 50 pixels and is adjusted with `[` (smaller) and `]` (larger). The **brush shape** toggles between circle and square with `\`. To preview the current footprint and color before committing, hold the backtick key (`` ` ``).

DRAW follows the universal "left = foreground, right = background" convention. **Left-click paints with the FG color**, **right-click paints with the BG color**. Holding `Shift` while drawing constrains the stroke to a perfectly horizontal or vertical axis. Holding `Shift` and right-clicking draws a **connecting line** from the previous click to the current position — invaluable for stitching together long straight lines without ever touching the Line tool.

If you have a steady hand but find that single-pixel stairsteps creep into your strokes, enable **Pixel Perfect mode** with `F6`. DRAW will retroactively remove L-shaped corners as you draw, leaving cleaner outlines.

The Organizer widget on the left contains **four brush size presets** (1, 3, 5, 9 pixels for sprite work).

<div class="page-break"></div>

> 🎨 **Try it — your first 16×16 sprite**
> 1. `Ctrl+N` for a new canvas at 16×16 pixels.
> 2. Press `D` for the Dot tool, set size to 1 with `[`.
> 3. Sketch out the silhouette of a simple character.
> 4. Switch to `B` (Brush), increase to size 2, and fill the larger regions.
> 5. Save as `.draw` so you can come back later.

![Dot Brush Preview](images/ch02-brush-preview.png)

<div class="page-break"></div>

### Pen Tablets & Pressure

DRAW reads **pen pressure** from a drawing tablet: Wacom, Huion, XP-Pen and Surface Pen are all supported, plus a Force Touch trackpad on a Mac. Pressure can change the Brush and Eraser **size** and **opacity**, and how much paint the mix brush lays down. It changes smoothly within a single stroke. A mouse is never affected.

**View → Pen Control** opens a small panel with everything in one place, on three tabs: **PRESSURE** (below), **SMOOTHING** and **SPEED** (see *Stroke Smoothing* further down). The panel remembers the tab you left it on.

On the **PRESSURE** tab:
- **Live meter:** shows how hard you're pressing.
- **Size, Opacity, Mix Paint:** each has a checkbox and a **LIGHT** slider, which is the value at the lightest touch. Full pressure always gives 100%.
- **Curve slider:** shapes the response; 1.00 is linear.
- **TIP slider:** the tip threshold. The pen draws only once it presses at least this hard (default 3%). It's shown as a red mark on the meter. This stops stray dots when the pen grazes the tablet and registers a click. A graze that never passes the threshold draws nothing and adds no undo step.
- **Response graph:** plots the curve, with a dot that follows your pen.

Opacity by pressure shows live as you draw. Going over the same spot again never builds the paint up past the strongest pressure you used there.

With **Antialias** on and a round brush, a pen stroke sizes smoothly through every width - 1, 2, 3, 4 px and the fractions between - instead of jumping between odd sizes, and thin parts of the stroke (down to 1px) stay soft-edged. Overlapping parts of one stroke never darken each other. With Antialias off, pen strokes stay crisp whole-pixel circles.

- **Setup.** Install the tablet maker's driver.
  - **Windows:** leave **Windows Ink** turned on in the driver's pen settings.
  - **macOS:** keep the driver's tablet app running in the menu bar.
  - **Linux:** most tablets work without any setup, and the maker's driver works too.
- **Settings → Pen Control → Pen Tablet:**
  - **Pen Pressure** turns the feature on or off.
  - **Pressure Sets Brush Size** controls whether pressure changes the size. It applies to brushes bigger than 1px; a 1px pencil stays 1px.
  - **Lightest Touch Size %** is the size at the lightest touch (default 20% of the brush).
  - **Pressure Curve** sets how pressure maps to size, opacity and paint. 100 is linear, lower makes light touches count more, and higher means you press harder.
  - **Tip Threshold %** is the pressure the pen needs before it draws (default 3%).
  - **Pressure Sets Opacity** and **Lightest Touch Opacity %** (default 10%): a light touch paints faintly. Off by default.
  - **Pressure Sets Mix Paint** and **Lightest Touch Paint %**: with the mix brush, a light touch smears and full pressure lays paint.
- **Export.** Pressure-varied strokes export to BAS/QB64 as pixels.

### Stroke Smoothing

Shaky hands, a jittery tablet or a fast flick can make lines wobble. Pen Control can steady the **Brush** and **Eraser** while you draw, in the spirit of Lazy Nezumi. Position smoothing works with a **mouse as well as a pen**.

**SMOOTHING tab — Smooth Position.** Turn it on, pick a mode and set the **Amount**:

| Mode | How it feels | Good for |
|------|--------------|----------|
| **String** (Pulled String) | The line hangs on a string *Amount* screen pixels long. It only moves when the pointer pulls it. | Slow, detailed work with sharp corners |
| **Average** (Moving Average) | The line follows the average of where the pointer has been. | Curved lines, soft corners |
| **EMA** (Exponential Moving Average) | Every movement pulls the line part of the way. | Massive smoothing, long curves |
| **Inertia** | The line has a little weight and glides after the pointer. | Fast, flowy lines |

- **Catch Up** (Average and EMA): when you stop moving or lift, the line keeps going until it reaches the pointer, so a stroke ends where you let go. Turn it off and the stroke stops where the smoothed line was.
- **Guide Line** and **Guide Cursor:** while you draw, a line from the drawing point to the pointer and a ring at the drawing point show how far the line is trailing. Their color is set in Settings.
- Shapes, fills and the Shift smart erase are not smoothed.

**SMOOTHING tab — Smooth Pressure** (pen only). It tames line dynamics:
- **Fixed:** constant pressure, set by *Amount* (%).
- **Hold:** takes the pressure of the first few samples of a stroke, then holds it.
- **Average / EMA:** smooths out flicker in the pressure.

**SPEED tab — Speed Scaling** (pen only). It scales pressure by how fast the pen moves. That gives calligraphy-like strokes, thicker or fainter when you move fast:
- **Slow** is the gain at rest and **Fast** the gain at the **Speed** (screen pixels a second) and above, with an S-curve between. A gain of 1.00 is the pressure as the pen gives it.
- **Smooth** evens out the measured speed.
- The graph plots speed against gain. After each stroke it marks that stroke's **average** speed (dashed) and **top** speed (red). While you draw, a dot shows the live speed. **NOW / AVG / TOP** give the same figures as numbers. Draw a few strokes at your natural pace, then set *Speed* around your top speed.

**Tooltips.** Rest the pointer on any control of the Pen Control panel - a checkbox, a slider, each mode chip, the meter or a graph - for a tooltip that says what it does, how it behaves, and a **TRY:** example with values to start from. The same text shows on the Settings → Pen Control tab.

**Presets.** Right-click the Pen Control panel (anywhere below its title) for **Pen Control Presets**: your saved presets (a tick marks the one your settings are now), then **Save Preset…** (name it; an existing name is replaced), **Rename Preset…** and **Delete Preset…** (they act on the ticked one), and **Open Presets Folder**. A preset holds every Pen Control setting - pressure, smoothing, speed scaling - so you can switch tablets or jobs in one click. They are plain text files (`<name>.pen`) in DRAW's data folder under `PEN-PRESETS`.

All of these are also on the **Pen Control** tab of Settings (`Ctrl+,`), under Position Smoothing, Pressure Processing and Speed Scaling. The command palette has **Pen Control: Toggle Smoothing**, **Next Smoothing Mode**, **More / Less Smoothing** (±5), **Toggle Pressure Smoothing** and **Toggle Speed Scaling**, so you can bind them to keys.

### Pen Control Guide: Example Presets

DRAW ships ten example presets. The first time you open the presets menu, they are copied into your `PEN-PRESETS` folder, next to your own. They are ordinary presets: apply one, tweak it, and **Save Preset…** under a new name. Delete or rename one and it stays that way - an example is only ever copied in once.

| Preset | What it sets | Use it for |
|--------|--------------|------------|
| **Clean Inking** | String 30, Average pressure 20, Light size 15% | Crisp ink lines with sharp corners and tapered ends |
| **Smooth Curves** | Average 45 + Catch Up, Average pressure 25 | Soft, even curves that still end where you lift |
| **Long Sweeps** | EMA 70 + Catch Up, EMA pressure 40, Light size 10% | Hair, rope, long contour lines |
| **Gesture Sketch** | Inertia 35, curve 0.80, opacity by pressure from 30% | Loose, flowing construction lines |
| **Flick Strokes** | Speed scaling (slow 0.40, fast 2.20 at 700 px/s), String 12, curve 1.20 | A brush-pen feel: quick flicks swell bold, slow lines stay fine |
| **Technical Pen** | Fixed pressure 70, String 20 | One even line weight every stroke |
| **Even Hatching** | Hold pressure 20, Average 20 | Hatching where each line keeps the weight it landed with |
| **Soft Shading** | Opacity by pressure from 5%, Light size 60%, curve 0.70, EMA 25 | Building up tone stroke by stroke |
| **Mouse Lines** | String 45 | A mouse: turns a wobbly hand into clean lines |
| **Raw Pen** | The factory settings, every filter off | Back to plain pen input |

**Try it - a five-minute tour.** Open **View → Pen Control**, pick the Brush (`B`) at about 8px, and on a scratch layer:

1. **Raw Pen**, then draw a slow spiral. That is your hand as the tablet reads it.
2. **Clean Inking**, the same spiral. The green guide line is the string: the brush only moves once you pull it taut, so the wobble is gone but corners stay sharp.
3. **Smooth Curves**, then **Long Sweeps**: the same spiral gets rounder and lags further behind. With Catch Up on it still ends where you lift.
4. **Gesture Sketch**: draw fast loops. The brush carries momentum and swings through the curves.
5. **Technical Pen**: press lightly, then hard - the width doesn't change. Then **Even Hatching**: each hatch keeps the weight you put it down with.
6. **Flick Strokes**: draw one slow line and one quick flick. On the **SPEED** tab, read **TOP** after your fastest stroke and move **SPEED** a little under it.

Then make your own: start from the closest example, adjust it (each control's tooltip has a **TRY:** value), and save it as a preset.

## Lines, Rectangles & Ellipses

> 🎯 **Goal:** Draw clean geometric shapes.

When freehand stops being precise enough you reach for the geometric trio. All three respect the current brush size, color, and symmetry settings.

| Tool | Icon | Outlined | Filled |
| --- | :---: | :---: | :---: |
| Line | ![line](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/line.png) | `L` | — |
| Rectangle | ![rect](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/rect.png) ![rect-filled](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/rect-filled.png) | `R` | `Shift+R` |
| Ellipse / Circle | ![circle](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/circle.png) ![circle-filled](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/circle-filled.png) | `C` | `Shift+C` |

**Tip:** While dragging any shape, hold SPACE to move the entire shape with the mouse instead of resizing it. Release SPACE to resume resizing from the new anchor. This works for all geometric and Smart Shape tools, and honors grid snap.

The shared modifier vocabulary across all three:

- **Shift** — constrain (line: H/V; rect: square; ellipse: circle).
- **Ctrl** — perfect aspect (forces square / circle even after you start dragging).
- **Ctrl+Shift while drawing the rect or ellipse** — anchor from the *center* instead of the corner.
- **Ctrl+Shift while drawing a line** — angle snap to 15°/30°/45°/90° increments.

<div class="page-break"></div>

> 🎨 **Try it — house in 30 seconds**
> 1. Filled rectangle for the body. `Shift+R`
> 2. Two lines forming the roof triangle. `L`
> 3. Filled circle (the sun). `Shift+C`
> 4. A few short lines for the sun's rays. `L`
> 5. Filled rectangle for the ground. `Shift+R`

![Try it - house](images/ch02-tryit-house.png)

<div class="page-break"></div>

## Polygons & the Fill Tool

> 🎯 **Goal:** Draw complex shapes and fill regions.

The **Polygon** tool comes in two flavours: outlined (`P`) and filled (`Shift+P`). Each click adds a vertex to the in-progress polygon; press `Enter` to close and commit. As with the line tool, **Ctrl+Shift** snaps the segment angle.

The **Flood Fill** tool (`F`, ![fill](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/fill.png)) pours the FG color into every pixel contiguous with the click point that shares its starting color. By default it samples only the active layer; hold `Shift` to sample from the **merged visible composite** (useful when you have outlines and fills on separate layers).

DRAW's flood fill is unusual in two ways:

1. It supports **custom brushes as a tiled fill** — if you have a brush captured (Chapter 9), the fill is rendered as a seamless tiling of that brush rather than a flat color.
2. It also honours the **paint mode** — set Pattern or Gradient mode (Chapter 9) and your fill becomes a dithered gradient or tiled pattern instead of a solid color.

Press `F8` to enable **Fill Adjustment overlay**. Now when you fill using pattern mode or gradient mode, or with custom brushes in color mode (loaded from the bins), drag the canvas to reposition the tile origin, mouse-wheel for uniform scale, drag the L-handle for independent X/Y scaling, and drag the rotation handle (small arc) to rotate the tile (hold `Ctrl` for 15° steps). `Enter` applies, `Esc` cancels. Tap `D` to dither the fill (any gradient: a pixel dither between its stop colors; a pattern or brush fill is thinned), `D`+wheel sets the amount (for a gradient, how wide the dithered band between two stops is), `D`+drag moves the pattern, `D`+`Shift`+`1`–`9` saves a preset and `D`+`1`–`9` recalls it.

<div class="page-break"></div>

> 🎨 **Try it — tileable pattern fill**
> 1. Draw a small 8×8 motif.
> 2. Capture it as a custom brush (see Chapter 9).
> 3. On a fresh layer, flood-fill a large rectangle with the brush active.
> 4. Press `F8` and experiment with scale, rotation, and offset.

![Fill Adjustment Handles](images/ch02-fill-adj.png)

<div class="page-break"></div>

## Spray Tool & Eraser

> 🎯 **Goal:** Use spray-can effects and clean up mistakes.

The **Spray** tool (`K`, ![spray](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/spray.png)) emits randomized dots within a circular nozzle. The nozzle radius **doubles for every brush-size step**, and density scales with radius — small brush = pinpoint mist, large brush = thick coverage. Spray respects custom brushes too: every "drop" stamps the brush instead of a single pixel, which is wonderful for foliage, dust, and confetti.

The **Eraser** (`E`, ![eraser](../../ASSETS/THEMES/DEFAULT/IMAGES/TOOLBOX/eraser.png)) paints fully transparent pixels — it does not paint with the BG color, it removes alpha. Two non-obvious tricks make it indispensable:

- **Hold `E` to temporarily eraser anything** while a different tool is active. Release `E` to return to your previous tool. This is the fastest way to nudge an outline or clean a stray pixel.
- **Smart Erase** (`Shift` while erasing) operates on **all visible layers at once**, with per-layer history tracking so each layer's undo step is independent.

The eraser uses your current brush size, shape, and even custom-brush stamp. The status bar shows `FG:TRN` to remind you transparent painting is active.

**Any tool erases with a transparent color.** Click the status bar's **X** chip (left-click = FG, right-click = BG), and the brush, dot, spray, line, rectangle, ellipse, polygon, bezier, smart shapes, fill, text and custom brush all erase instead of painting, in gradient and pattern paint modes too. While you drag, the shape shows the transparency checkerboard where it will erase, and a custom brush's cursor shows its footprint as the checkerboard.

> 💡 **Tip:** Combine the eraser with a layer's **Opacity Lock** (Chapter 4) to clean up overpaint while preserving the layer's silhouette.

---

## Smart Shapes & Advanced Tools

> 🎯 **Goal:** Draw parametric shapes, 3D dice, and advanced curves.

### Smart Shapes Tool Group

The **Smart Shapes** tool group is accessed from the toolbar. **Long-press or right-click** the Smart Shapes button to open a flyout menu and pick a sub-tool. Each shape has live drag-time arrow-key tweaks and unique modifiers.

**Tip:** While dragging any Smart Shape, hold SPACE to move the entire shape with the mouse instead of resizing it. Release SPACE to resume resizing from the new anchor. Grid snap is honored.

**Sub-tools:**

---

### Smart Shapes — Detailed Controls & Behaviors

![Smart Shapes Example](images/smart-shapes.png)

The idea of smart shapes is that you begin drawing, then use keys to modify the shape as you create it. All smart shapes snap to the grid and honor grid/symmetry settings, just like regular rectangles and ellipses.

Below are the controls and behaviors for each smart shape:

#### Polygon
> Minimum sides: 3, Maximum: 30

Draws a regular polygon. While dragging, use:
- **Up arrow**: Add edges
- **Down arrow**: Remove edges
- **Left arrow**: Decrease point/star depth (makes a star/burst)
- **Right arrow**: Increase point/star depth

#### Pie / Donut
> Create pie charts or donut shapes with equidistant or custom slices. Left/right arrows add a hole (donut mode).
> Minimum slices: 0, Maximum: 30. Max hole radius: 90% of shape size.

- **Up arrow**: Add segments
- **Down arrow**: Remove segments
- **Left arrow**: Decrease hole size
- **Right arrow**: Increase hole size

#### Rounded Rectangle
> Rectangle with rounded corners. Corner radius can be 1 (almost square) up to 30 (fully rounded), but never so large that corners intersect.

- **Up arrow**: Increase corner radius
- **Down arrow**: Decrease corner radius

#### Tab
> Rounded rectangle with one flat edge. Flat edge can be cycled to any side (top, bottom, left, right).

- **Up arrow**: Round top corners more
- **Down arrow**: Round top corners less
- **Left arrow**: Cycle flat edge left
- **Right arrow**: Cycle flat edge right

#### Pill
> Capsule/oval with dividers for options (like a segmented control). Horizontal by default.

- **Up arrow**: Increase roundness
- **Down arrow**: Decrease roundness
- **Left arrow**: Decrease segments
- **Right arrow**: Increase segments

#### Pac-Man
> Pie chart with a single slice cut out (the mouth). Mouth can be opened/closed. Inner hole for dial/knob effects.

- **Up arrow**: Increase mouth size
- **Down arrow**: Decrease mouth size
- **Left arrow**: Decrease inner hole
- **Right arrow**: Increase inner hole

#### 3D Cube / 3D Polygon (Dice)
> Draws a 3D cube or polyhedral dice wireframe. Press number keys while dragging for dice types: 4 = D4, 6 = D6, 8 = D8, 0 = D10, 1 = D12, 2 = D20, 3 = D30.

- **Up arrow**: Increase Z-depth
- **Down arrow**: Decrease Z-depth
- **Left arrow**: Rotate left
- **Right arrow**: Rotate right
- **Mouse wheel up**: Rotate up
- **Mouse wheel down**: Decrease Z-depth (angle)

#### Bevel Rect
> Rectangle with beveled (angled) edges. Bevel and border size adjustable. Can switch between inner/outer bevel.

- **Up arrow**: Increase bevel size
- **Down arrow**: Decrease bevel size
- **Left arrow**: Decrease border size
- **Right arrow**: Increase border size
- **I**: Switch to inner bevel
- **O**: Switch to outer bevel
- **Mouse wheel up**: Increase Z-depth (angle)
- **Mouse wheel down**: Decrease Z-depth (angle)

#### Arrow
> Arrow with adjustable stem and head. Head can be made concave/curved.

- **Up arrow**: Make stem fatter
- **Down arrow**: Make stem skinnier
- **Left arrow**: Make arrow head shorter
- **Right arrow**: Make arrow head longer
- **Mouse wheel up**: Increase head concavity
- **Mouse wheel down**: Decrease head concavity

---

- **Right-click drag** — solid mode (BG color fill, FG color wireframe)

- Dice type: `4`/`6`/`8`/`0`/`1`/`2` for D4/D6/D8/D10/D12/D20

### Bezier Curve Tool (`Q`)

- `Escape` — cancel

### Line Tool — End Caps

While dragging the Line tool, press `s` / `e` to cycle the start / end cap shape (none → arrow → diamond → circle → square → ...). End caps render in the same FG color as the line.
---

➡️ Next: [Chapter 3 — Color & Palette Mastery](03-color-palette.md)
