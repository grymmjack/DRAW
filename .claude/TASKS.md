# More Image Effects — branch `more-image-effects`

Each box = implement (engine + dialog/action + menu wiring) → build clean (0 warnings)
→ commit → add a QA harness guard test (apply effect → region differs) where feasible.
Effects follow the existing `GJ_IMGADJ_*&(sourceImg, ...)` clone-and-return pattern;
dialogs/preview/undo reuse `IMAGE_ADJ_apply_to_layer` / `IMAGE_ADJ_apply_spatial`.
Grep `CMD_execute_action` before allocating each new action ID (gotcha #17).

## Menu organization (Photoshop / Alien-Skin style)

EFFECTS menu is organized into flyout submenu categories:
  ADJUST → · STYLIZE → · DISTORT → · PIXELATE → · NOISE → · RENDER →
  · SHAPE → (Eye Candy Shape) · TEXTURE → (Eye Candy Texture)
The DRAW menubar is currently FLAT (no nested flyouts) — so submenu support is a
foundational task that must land before the categories are usable. Until then,
new effects live under a flat EFFECTS menu and get re-parented into submenus once
the infra exists.

- [ ] **Menubar flyout submenus** — extend MENUBAR to render/hit-test one level of
      nested submenu (parent item opens a child column), then reorganize EFFECTS
      into ADJUST/STYLIZE/DISTORT/PIXELATE/NOISE/RENDER/SHAPE/TEXTURE. Foundational.

## 🔨 NOW — doing right now

- [ ] ➡️ Wave 2b · **Bevel (light-angle)** — rich bevel + dialog + EFFECTS menu + QA test

<!-- QA note: invoke effects via the EFFECTS menu (click 395,6 then item at
     viewport y = 20 + index*12), NOT the command palette — palette-open is racy
     under the harness. Commit dialogs with `key Return`. Snap AFTER dialog close. -->


## Wave 0 — Activate dormant engine effects (math already implemented + tested)

- [x] Wire **Gamma** (GJ_IMGADJ_Gamma) — EFFECTS menu + cmd palette + dialog + QA test (effect-gamma.sh)
- [x] Wire **Sepia** (GJ_IMGADJ_Sepia) — one-shot + EFFECTS menu + cmd palette + QA test (effect-sepia.sh)
- [x] Wire **Threshold** (GJ_IMGADJ_Threshold) — LEVEL slider + INVERT toggle dialog + menu + QA test (effect-threshold.sh)
- [x] Wire **Colorize** (GJ_IMGADJ_Colorize) — HUE + SATURATION tint dialog + menu + QA test (effect-colorize.sh). NOTE: distinct from existing Hue/Saturation (2002) — Colorize *replaces* all hues (monotone tint); Hue/Sat *shifts* them.
- [x] Wire **Glow** (GJ_IMGADJ_Glow) — RADIUS + INTENSITY dialog + menu + QA test (effect-glow.sh, menu-click invocation)
- [x] Wire **Film Grain** (GJ_IMGADJ_FilmGrain) — AMOUNT dialog + menu + QA test (effect-filmgrain.sh)
- [x] Wire **Vignette** (GJ_IMGADJ_Vignette) — STRENGTH dialog + menu + QA test (effect-vignette.sh)
- [ ] Wire **Pixel Scaler** (GJ_IMGADJ_PixelScaler, xBR/HQx/MMPX) — DEFERRED: unlike every other effect it *resizes* the image 2–4×, so it needs canvas+all-layers resize integration (like RESIZE IMAGE WITH CONTENT), not the same-size apply_to_layer path. Revisit after Wave 1. Mode-picker dialog + action + menu + QA test.

## Wave 1 — Tier-1 pixel-art effects (new engine)

- [x] **Outline / Stroke** — alpha-edge border, THICKNESS 1-8 + INSIDE/OUTSIDE, FG colour, apply_spatial + menu + QA test (effect-outline.sh, transparent-layer). NEW engine IMAGE_ADJ_outline&.
- [x] **Edge Detect (Sobel)** — 3x3 Sobel line art, STRENGTH 10-300 + INVERT + menu + QA test (effect-edgedetect.sh). NEW engine IMAGE_ADJ_edgedetect&.
- [x] **Gradient Map** — luminance → BG..FG 2-colour ramp (256-entry LUT) + SWAP toggle + menu + QA test (effect-gradientmap.sh). NEW engine IMAGE_ADJ_gradientmap&.
- [x] **Grow / Shrink (Dilate/Erode)** — alpha morphology, AMOUNT 1-8 + SHRINK toggle, apply_spatial + menu + QA test (effect-growshrink.sh). NEW engine IMAGE_ADJ_growshrink&.

## Wave 2 — Retro / stylize (new engine)

- [x] **Chromatic Aberration** — horizontal R/B channel split, AMOUNT 0-20px + menu + QA test (effect-chromatic.sh). NEW engine IMAGE_ADJ_chromatic&.
- [x] **Emboss / Bevel** — directional grey relief, STRENGTH 1-10 + menu + QA test (effect-emboss.sh). NEW engine IMAGE_ADJ_emboss&.
- [x] **Solarize** — per-channel invert above THRESHOLD 0-255 (Sabattier) + menu + QA test (effect-solarize.sh). NEW engine IMAGE_ADJ_solarize&.
- [x] **Duotone / Tritone** — discrete 2/3-band flat tone map (BG..FG), TRITONE toggle + menu + QA test (effect-duotone.sh). NEW engine IMAGE_ADJ_duotone&.
- [x] **Drop Shadow (flat)** — offset softened BG-colour silhouette composited behind, OFFSET 1-20 + SOFTNESS 0-8, apply_spatial + menu + QA test (effect-dropshadow.sh). NEW engine IMAGE_ADJ_dropshadow&.
- [x] **Perspective / 3D Shadow** — "long shadow": solid diagonal cast trail (BG colour), LENGTH 1-40, apply_spatial + menu + QA test (effect-longshadow.sh). NEW engine IMAGE_ADJ_longshadow&.

## Wave 2b — Layer Styles (Alien Skin / Eye Candy feel)

- [ ] **Bevel (light-angle)** — rich bevel: light angle, height, softness, highlight/shadow color + dialog + menu + QA test
- [ ] **Outer Glow** — colored glow radiating outside alpha edges + dialog + menu + QA test
- [ ] **Inner Glow** — colored glow inside alpha edges + dialog + menu + QA test
- [ ] **Chrome / Metallic** — gradient-mapped bevel for a shiny metal look + dialog + menu + QA test

## Wave 3 — Distort filters (one-shot, whole layer)

- [ ] **Wave / Ripple** — sinusoidal displacement + dialog + menu + QA test
- [ ] **Twirl** — angular swirl around center + dialog + menu + QA test
- [ ] **Pinch / Bulge (Spherize)** — radial displacement + dialog + menu + QA test
- [ ] **Kaleidoscope** — sample one wedge and mirror-tile it radially into a mandala; SEGMENTS (3..24), centre X/Y, rotation, mirror on/off; live preview/setup dialog + menu + QA test. (Applies to EXISTING art — distinct from draw-time symmetry which only mirrors new strokes.)

## Wave 4 — Photoshop Pixelate / Stylize family (new engine)

- [ ] **Crystallize** — Voronoi cells, average color per cell + dialog + menu + QA test
- [ ] **Stained Glass** — Voronoi + dark cell borders (shares crystallize engine) + dialog + menu + QA test
- [ ] **Mosaic / Tessellate** — regular polygon tiling, average color + dialog + menu + QA test
- [ ] **Extrude** — 3D block/pyramid tiles from cell brightness + dialog + menu + QA test
- [ ] **Pointillize** — random dots on background color + dialog + menu + QA test
- [ ] **Wind** — directional streaking of edges + dialog + menu + QA test

## Wave 5 — Render / generative (fill a layer; no source needed)

- [ ] **Clouds** — plasma/Perlin noise in FG↔BG colors + dialog + menu + QA test
- [ ] **Difference Clouds** — clouds blended via difference with existing pixels + menu + QA test
- [ ] **Lens Flare** — bright core + halo rings + streaks at a point + dialog + menu + QA test
- [ ] **Terrain** — diamond-square fractal heightmap → color ramp + dialog + menu + QA test

## Wave 5b — Noise (render / filter)

- [ ] **Add Noise** — Gaussian + Uniform, mono/color, amount + dialog + menu + QA test
- [ ] **Median / Despeckle** — 3×3 median denoise (removes speckle, keeps edges) + dialog + menu + QA test
- [ ] **Reduce Noise / Dust & Scratches** — thresholded median cleanup + dialog + menu + QA test

## Wave 5c — Render: Grid & Sky

- [ ] **Render Grid** — configurable grid: cell shape (square/hex/triangle/lines),
      spacing, line color/width, + perspective/vanishing-point mode + dialog + menu + QA test
- [ ] **Render Sky** — procedural sky: mode (day/night/space), gradient horizon,
      stars, optional planets/moon + dialog + menu + QA test

## Wave 7 — Eye Candy: SHAPE → submenu

- [ ] **Backlight** — rays/light burst behind the shape from a point + dialog + QA test
- [ ] **Bevel (Eye Candy)** — covered by Wave 2b Bevel; add SHAPE-menu entry
- [ ] **Chrome** — covered by Wave 2b Chrome/Metallic; add SHAPE-menu entry
- [ ] **Corona** — soft eclipse-style ring glow around alpha edges + dialog + QA test
- [ ] **Drip** — liquid drips hanging off the bottom of shapes + dialog + QA test
- [ ] **Electrify** — jagged lightning tendrils around edges + dialog + QA test
- [ ] **Extrude** — covered by Wave 4 Extrude; add SHAPE-menu entry
- [ ] **Fire** — flame render rising from the shape (gradient + noise) + dialog + QA test
- [ ] **Glass** — refractive glassy shading + highlight + dialog + QA test
- [ ] **Glow (Outer/Inner)** — covered by Wave 2b; add SHAPE-menu entries
- [ ] **Icicles** — ice spikes hanging off the bottom edge + dialog + QA test
- [ ] **Motion Trail** — directional smeared copies (speed blur) + dialog + QA test
- [ ] **Rust** — corroded noise overlay masked to shape + dialog + QA test
- [ ] **Shadow** — covered by Wave 2 Drop/Perspective Shadow; add SHAPE-menu entry
- [ ] **Smoke** — wispy smoke render rising from shape (noise plume) + dialog + QA test
- [ ] **Snow** — snow cap on top edges + falling flecks + dialog + QA test
- [ ] **Cutout** — inset shadow so shape looks punched through the layer + dialog + QA test
- [ ] **Jiggle / Water Drops** — bubble/droplet displacement bumps + dialog + QA test

## Wave 8 — Eye Candy: TEXTURE → submenu (procedural fills / overlays)

- [ ] **Animal Fur** — directional furry noise + dialog + QA test
- [ ] **Brick Wall** — brick tiling with mortar + color jitter + dialog + QA test
- [ ] **Brushed Metal** — anisotropic horizontal streak noise + dialog + QA test
- [ ] **Clouds (texture)** — covered by Wave 5 Clouds; add TEXTURE-menu entry
- [ ] **Diamond Plate** — tromp-l'oeil metal tread pattern + dialog + QA test
- [ ] **Lightning** — branching bolt between two points + dialog + QA test
- [ ] **Marble** — turbulence-veined marble (perlin + sine) + dialog + QA test
- [ ] **Reptile Skin** — scale cell pattern (Voronoi + shading) + dialog + QA test
- [ ] **Ripples** — concentric water ripple displacement + dialog + QA test
- [ ] **Stone Wall** — irregular stone tiling with mortar + dialog + QA test
- [ ] **Swirl** — covered by Wave 3 Twirl; add TEXTURE-menu entry
- [ ] **Texture Noise / HSB Noise** — per-channel/HSB noise overlay + dialog + QA test
- [ ] **Water Drops** — refractive droplet bumps scattered over layer + dialog + QA test
- [ ] **Weave** — over/under basket-weave pattern + dialog + QA test
- [ ] **Wood** — concentric wood-grain rings + grain noise + dialog + QA test

## Wave 6 — Liquify tool ("Kai's Power Goo") — big, own design pass

- [ ] **TOOL_LIQUIFY** scaffold — BI/BM, CONST, _ALL chains, tool button, keybind, tool-switch reset, undo snapshot
- [ ] **Liquify: Push/Smudge (move)** — drag displaces pixels along cursor motion (radius + strength)
- [ ] **Liquify: Pinch / Bulge** — radial squeeze/expand under cursor
- [ ] **Liquify: Twirl** — rotational warp under cursor (CW/CCW)
- [ ] Liquify live preview + commit-to-history + QA test (best-effort; interactive tool)

## Wrap-up

- [ ] Update CHEATSHEET.md + docs (new Image/Render menu entries, Liquify tool + hotkey)
- [ ] Full suite QA run (`cd QA && ./draw-qa.sh`) green; final clean build; open PR to main
